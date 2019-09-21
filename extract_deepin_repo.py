#! /usr/bin/env python3

import gzip
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from collections import defaultdict, OrderedDict


def relative_path(path):
    return os.path.join(os.path.dirname(os.path.realpath(__file__)), path)


def request_url(url, gunzip=False, decode=False):
    cache_dir = relative_path('cache')
    cache_file = os.path.join(cache_dir, urllib.parse.quote(url, safe=''))
    if os.path.isfile(cache_file):
        with open(cache_file, 'rb') as fin:
            content = fin.read()
    else:
        response = urllib.request.urlopen(url)
        assert response.status == 200
        content = response.read()
        if os.path.isdir(cache_dir):
            with open(cache_file, 'wb') as fount:
                fount.write(content)
    if gunzip:
        content = gzip.decompress(content)
    if decode:
        encoding = content if isinstance(content, str) else 'UTF-8'
        content = content.decode(encoding)
    return content


def compile_re(pattern, flags):
    return re.compile(pattern.replace(' ', r'[^\S\n]'), flags)


class Package(OrderedDict):
    COMMENT_PATTERN = compile_re(r'^#.*', re.M)
    FILED_PATTERN = compile_re(r'^(\S+) *: *(.*?) *(?=\n\S|\n?\Z)', re.M | re.S)

    class InsensitiveString(str):
        def __hash__(self):
            return self.lower().__hash__()

        def __eq__(self, other):
            return self.lower().__eq__(other.lower())

    def __init__(self, control_info):
        control_info = re.sub(Package.COMMENT_PATTERN, '', control_info)
        super().__init__(re.findall(Package.FILED_PATTERN, control_info))

    def __getitem__(self, key):
        key = Package.InsensitiveString(key)
        return super().__getitem__(key) if key in self.keys() else None

    def __setitem__(self, key, value):
        super().__setitem__(Package.InsensitiveString(key), value)

    def __str__(self):
        return '\n'.join(': '.join(item) for item in self.items())


class Repository:
    NAME_PATTERN = compile_re(r'\n*package *: *(\S+)', re.I)

    def __init__(self, repo_config):
        self.packages = defaultdict(list)
        for url in repo_config['packages_files']:
            url = repo_config['location'] + url
            gunzip = url.endswith('.gz')
            packages_file = request_url(url, gunzip, True)
            for control_info in packages_file.split('\n\n'):
                match = re.match(Repository.NAME_PATTERN, control_info)
                if match is not None:
                    self.packages[match.group(1)].append(control_info)

    def search_packages(self, name, parse=True):
        if parse:
            return [Package(m) for m in self.packages[name]]
        else:
            return name in self.packages


def extract_packages(repo, minus_repo, package_names, extracted):
    depends_pattern = re.compile(r'\s*(\S+?)(?::\S+)?\s*(?:\(.+?\))?\s*(?:[,|]|$)')
    missing_packages = []
    for name in package_names:
        if name in extracted or minus_repo.search_packages(name, False):
            continue
        packages = repo.search_packages(name)
        if len(packages) == 0:
            missing_packages.append([name])
        else:
            extracted[name].extend(packages)
            for raw_depends in set(p['depends'] or '' for p in packages):
                depends = re.findall(depends_pattern, raw_depends)
                for missing_dep in extract_packages(repo, minus_repo, depends, extracted):
                    missing_packages.append([name] + missing_dep)
    return missing_packages


def extract_apps(repo, minus_repo, app_names, ignored_packages):
    extracted_packages = defaultdict(list)
    missing_packages = extract_packages(repo, minus_repo, app_names, extracted_packages)
    for missing in missing_packages:
        if missing[-1] not in ignored_packages:
            print('缺失软件包:', ' -> '.join(missing))
    packages_file = ''
    for name in sorted(extracted_packages.keys()):
        for pkg in extracted_packages[name]:
            pkg['filename'] = 'files/' + pkg['filename']
            packages_file += str(pkg) + '\n\n'
    return packages_file


def extract_deepin_repo(output_filepath):
    with open(relative_path('extraction_config.json'), 'rt') as f:
        config = json.load(f)

    deepin_repo = Repository(config['deepin_repository'])
    app_names = []
    for rule in config['apps']:
        rule_type, rule_content = rule.split('=')
        if rule_type == 're':
            pattern = re.compile(rule_content)
            app_names.extend(filter(lambda x: re.fullmatch(pattern, x), deepin_repo.packages.keys()))
        elif rule_type == '':
            app_names.append(rule_content)

    extracted_packages_for_hosts = set()
    for host, host_config in config['host_repositories'].items():
        print('>>> ', host)
        host_repo = Repository(host_config)
        ignored = set(config.get('ignored_packages', []) + host_config.get('ignored_packages', []))
        extracted_packages_for_hosts.add(extract_apps(deepin_repo, host_repo, app_names, ignored))

    assert len(extracted_packages_for_hosts) == 1
    extracted_packages = next(iter(extracted_packages_for_hosts))
    try:
        with open(output_filepath, 'rt') as f:
            assert f.read() == extracted_packages
    except (FileNotFoundError, AssertionError):
        with open(output_filepath, 'wt') as f:
            f.write(extracted_packages)


if __name__ == '__main__':
    extract_deepin_repo(sys.argv[1])
