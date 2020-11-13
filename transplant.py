import argparse
import os
import re


class Package:
    def __init__(self, control, repo_path):
        self.control = control
        self.repo_path = repo_path
        self.visited = False

    def _search_key(self, key):
        pattern = r'(^KEY *: *)(.+(?:\n .+)*)'.replace('KEY', re.escape(key)).replace(' ', r'[^\S\n]')
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
    def __init__(self, paths):
        self.files = map(open, paths)
        self.packages = {}

    def __enter__(self):
        name = None
        provides = []
        seek_pos = 0
        line_count = 0
        for f in self.files:
            while True:
                line = f.readline()
                if not line or line.isspace():
                    if name is not None:
                        location = (f, seek_pos, line_count)
                        if name in self.packages:
                            self.packages[name].append(location)
                        else:
                            self.packages[name] = [location]
                        for provide in provides:
                            self.packages[provide] = [location]
                        name = None
                        provides = []
                    if not line:
                        break
                    seek_pos = f.tell()
                    line_count = 0
                else:
                    line_count += 1
                    if not line[0].isspace() and line[0] != '#':
                        key, value = line.split(':', 1)
                        key = key.rstrip().lower()
                        if key == 'package':
                            name = value.strip()
                        elif key == 'provides':
                            provides = [s.split()[0] for s in value.split(',')]

        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        for f in self.files:
            f.close()

    def __getitem__(self, name):
        packages = []
        for f, seek_start, line_count in self.packages.get(name, []):
            f.seek(seek_start)
            lines = [f.readline() for _ in range(line_count)]
            if lines[-1][-1] != '\n':
                lines[-1] += '\n'
            control = ''.join(filter(lambda s: not s.startswith('#'), lines))
            packages.append(Package(control, f.name))
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
        for pkg in packages:
            if pkg.visited:
                found = True
                continue
            pkg.visited = True
            pkg['Filename'] = re.search(r'(?<=^build/).+/(?=dists/)', pkg.repo_path).group() + pkg['Filename']

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


def write_if_updated(file, text):
    if os.path.isfile(file):
        with open(file, 'rb') as f:
            old_text = f.read()
    else:
        old_text = None
    text = text.encode()
    if text != old_text:
        with open(file, 'wb') as f:
            f.write(text)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-o', '--output', required=True)
    subparsers = parser.add_subparsers(dest='action')
    subparsers.required = True

    parser_transplant = subparsers.add_parser('transplant')
    parser_transplant.add_argument('-s', '--source', nargs='+')
    parser_transplant.add_argument('-t', '--target', nargs='+')
    parser_transplant.add_argument('apps', nargs='+')

    parser_merge = subparsers.add_parser('merge')
    parser_merge.add_argument('package_files', nargs='+')

    args = parser.parse_args()

    try:
        if args.action == 'transplant':
            with Repository(args.source) as source, Repository(args.target) as target:
                unmet_chains, packages = transplant(source, target, args.apps)
                if unmet_chains:
                    raise Exception('未解决依赖\n' + '\n'.join(unmet_chains))
        elif args.action == 'merge':
            packages = set()
            for file in args.package_files:
                with open(file) as f:
                    packages.update(re.findall(r'(?:.+\n)+', f.read()))
            packages = sorted(sorted(packages))
        else:
            raise Exception('未识别动作:', args.action)
    except Exception:
        raise
    else:
        write_if_updated(args.output, '\n'.join(packages))


if __name__ == '__main__':
    main()
