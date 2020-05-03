import argparse
import os
import re


class Package:
    def __init__(self, control):
        self.control = control
        self.visited = False

    def _search_key(self, key):
        pattern = rf'(^{re.escape(key)} *: *)(.+(?:\n .+)*)'.replace(' ', r'[^\S\n]')
        return re.search(pattern, self.control, re.I | re.M)

    def __setitem__(self, key, value):
        match = self._search_key(key)
        self.control = self.control[:match.start(0)] + match.group(1) + value + self.control[match.end(0):]

    def __getitem__(self, key):
        match = self._search_key(key)
        return match.group(2) if match else None


def filter_packages(packages, _):
    # TODO 根据版本和架构筛选软件包
    return packages


class Repository:
    def __init__(self, filepath):
        self.filepath = filepath
        self.packages = {}

    def __enter__(self):
        self.f = open(self.filepath, 'rt')

        name = None
        seek_pos = 0
        line_count = 0
        while True:
            line = self.f.readline()
            if not line:
                break
            elif line.isspace():
                if name is not None:
                    location = (seek_pos, line_count)
                    if name in self.packages:
                        self.packages[name].append(location)
                    else:
                        self.packages[name] = [location]
                    name = None
                seek_pos = self.f.tell()
                line_count = 0
            else:
                if name is None:
                    key, value = line.split(':', 1)
                    assert key.strip().lower() == 'package'
                    name = value.strip()
                line_count += 1
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.f.close()

    def __getitem__(self, name):
        packages = []
        for seek_start, line_count in self.packages.get(name, []):
            self.f.seek(seek_start)
            control = ''.join(self.f.readline() for _ in range(line_count))
            packages.append(Package(control))
        return packages

    def __contains__(self, name):
        return name in self.packages


def transplant(source, target, app_selectors):
    selector_re = re.compile(r' (\S+?)(?: : (\S+?))?(?: \( ([<=>]+) (\S+?) \))? '.replace(' ', r'\s*'))
    patch = {}

    def extract_package(selector):
        name, *_ = selector_re.fullmatch(selector).groups()
        if filter_packages(target[name], _):
            return []
        if name in patch:
            packages = patch[name]
        else:
            packages = patch[name] = source[name]
        packages = filter_packages(packages, _)
        if not packages:
            return [selector]

        found = False
        selector_unmet = []
        for pkg in filter_packages(packages, _):
            if pkg.visited:
                found = True
                continue
            pkg.visited = True
            pkg['Filename'] = 'deepin_mirror/' + pkg['Filename']

            and_satisfied = True
            for and_dep in filter(len, map(str.strip, (pkg['Depends'] or '').split(','))):
                or_satisfied = False
                or_unmet = []
                for or_dep in filter(len, map(str.strip, and_dep.split('|'))):
                    unmet = extract_package(or_dep)
                    or_satisfied |= not len(unmet)
                    or_unmet.extend(unmet)
                and_satisfied &= or_satisfied
                if not or_satisfied:
                    selector_unmet.extend(map(lambda x: x + ' <-- ' + selector, or_unmet))
            found |= and_satisfied
        return [] if found else selector_unmet

    unmet_chains = [u for s in app_selectors for u in extract_package(s)]
    transplanted_packages = [p.control for ps in patch.values() for p in ps if p.visited]
    return unmet_chains, transplanted_packages


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--output', required=True)
    subparsers = parser.add_subparsers(dest='action')
    subparsers.required = True

    parser_transplant = subparsers.add_parser('transplant')
    parser_transplant.add_argument('-s', '--source', required=True)
    parser_transplant.add_argument('-t', '--target', required=True)
    parser_transplant.add_argument('apps', nargs='+')

    parser_merge = subparsers.add_parser('merge')
    parser_merge.add_argument('package_files', nargs='+')

    args = parser.parse_args()

    try:
        with open(args.output, 'wt') as output:
            if args.action == 'transplant':
                with Repository(args.source) as source, Repository(args.target) as target:
                    unmet_chains, transplanted_packages = transplant(source, target, args.apps)
                    if unmet_chains:
                        raise Exception('未解决依赖\n' + '\n'.join(unmet_chains))
                    else:
                        output.write('\n'.join(transplanted_packages))
            elif args.action == 'merge':
                packages = set()
                for file in args.package_files:
                    with open(file) as f:
                        packages.update(re.findall(r'(?:.+\n)+', f.read()))
                output.write('\n'.join(sorted(packages)))
    except Exception as e:
        os.remove(args.output)
        raise e


if __name__ == '__main__':
    main()
