#! /usr/bin/env python3

import gzip
import json
import os
import re
import urllib.parse
import urllib.request
from collections import defaultdict, OrderedDict


def get_path(path):
    return os.path.join(os.path.dirname(os.path.realpath(__file__)), path)


def request_url(url, gunzip=False, decode=False):
    cache_dir = get_path('cache')
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


class Package:
    COMMENT_PATTERN = compile_re(r'^#.*', re.M)
    FILED_PATTERN = compile_re(r'^(\S+) *: *(.*(?:\n .*)*)', re.M)

    def __init__(self, control_info):
        control_info = re.sub(Package.COMMENT_PATTERN, '', control_info, re.M)
        self.fields = OrderedDict(map(
            lambda kv: (kv[0].lower(), (kv[0], kv[1].strip())),
            re.findall(Package.FILED_PATTERN, control_info)
        ))

    def __getitem__(self, key):
        if key.lower() in self.fields:
            return self.fields[key.lower()][1]
        return None

    def __setitem__(self, key, value):
        if key.lower() in self.fields:
            key = self.fields[key.lower()][0]
        self.fields[key.lower()] = (key, value)

    def __str__(self):
        return '\n'.join(': '.join(self.fields[k]) for k in self.fields.keys())


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
                depends = re.sub(r'\([\s\S]+?\)', '', raw_depends)
                depends = re.split('[|,]', depends)
                depends = set(filter(bool, map(str.strip, depends)))
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


if __name__ == '__main__':
    with open(get_path('config.json')) as f:
        config = json.load(f)

    common_packages_file = None
    deepin_repo = Repository(config['deepin_repository'])
    for host, host_config in config['host_repositories'].items():
        print('>>> ', host)
        host_repo = Repository(host_config)
        ignored = set(config.get('ignored_packages', []) + host_config.get('ignored_packages', []))
        host_packages_file = extract_apps(deepin_repo, host_repo, config['apps'], ignored)
        if common_packages_file is None:
            common_packages_file = host_packages_file
        else:
            assert common_packages_file, host_packages_file

    with open(get_path('repo/deepin/Packages'), 'wt') as f:
        f.write(common_packages_file)
