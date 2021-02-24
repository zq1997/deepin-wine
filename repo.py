from collections import defaultdict
import re
import copy

NAME_SELECTOR = re.compile(r' ([a-z\d][a-z\d.+\-]+)(?: :(\S+))?(?: \( ([<=>]+) (\S+) \))? '.replace(' ', r'\s*'))


def split(text, sep):
    return () if text is None else [x.strip() for x in text.split(sep)]


class Package:
    def __init__(self, f):
        lines = self.lines = []
        while True:
            line = f.readline()
            if line.isspace():
                if lines:
                    break
            elif not line:
                if lines:
                    if not lines[-1].endswith('\n'):
                        lines[-1] += '\n'
                    break
                raise StopIteration
            elif line[0].isspace():
                lines[-1] += line
            else:
                lines.append(line)

    def __str__(self):
        return ''.join(self.lines)

    def __repr__(self):
        return '%s:%s v%s' % (self['Package'], self['Architecture'], self['Version'])

    def _search_filed(self, key):
        key = key.lower()
        for i, line in enumerate(self.lines):
            k, v = line.split(':', 1)
            if k.lower() == key:
                return i, k, v.strip()
        return None, None, None

    def __getitem__(self, key):
        return self._search_filed(key)[2]

    def __setitem__(self, key, set_value):
        i, k, v = self._search_filed(key)
        self.lines[i] = '%s: %s\n' % (k, set_value(v))


def make_repo_meta(packages_file):
    entries = defaultdict(list)
    try:
        while True:
            offset = packages_file.tell()
            pkg = Package(packages_file)
            entries[pkg['Package']].append(offset)
            for provide in split(pkg['Provides'], ','):
                m = re.fullmatch(NAME_SELECTOR, provide)
                entries[m.group(1)].append(offset)
    except StopIteration:
        return dict(entries)


# TODO: check pkg version and arch
class Site:
    def __init__(self, name):
        self.name = name
        self.updated = False
        self.length = 0
        self.url_list = []
        self.path_list = []
        self.meta_list = []
        self.file_list = None
        self.visited = None

    def __getitem__(self, name):
        entries = []
        for i in range(self.length):
            file = self.file_list[i]
            for offset in self.meta_list[i].get(name, ()):
                file.seek(offset)
                entries.append((i | (offset << 8), Package(file)))
        return entries

    def __contains__(self, name):
        for meta in self.meta_list:
            if name in meta:
                return True
        return False

    def add(self, updated, url, path, meta):
        self.updated |= updated
        self.length += 1
        assert self.length <= (1 << 8)
        self.url_list.append(url)
        self.path_list.append(path)
        self.meta_list.append(meta)

    def open(self, use_copy):
        if use_copy:
            site = copy.copy(self)
            site.visited = set()
        else:
            site = self
        site.file_list = [open(path, 'rt') for path in site.path_list]
        return site

    def close(self):
        for f in self.file_list:
            f.close()

    def diff(self, dest, selector):
        m = re.fullmatch(NAME_SELECTOR, selector)
        name, arch, op, version = m.groups()
        if name in dest:
            return []

        ok = False
        broken_chains = []
        for index, pkg in self[name]:
            if index not in self.visited:
                self.visited.add(index)
                and_ok = True
                # 还有Pre-Depends
                for and_dep in split(pkg['Depends'], ','):
                    or_ok = False
                    or_broken_chains = []
                    for or_dep in split(and_dep, '|'):
                        dep_broken_chains = self.diff(dest, or_dep)
                        or_broken_chains.extend('%s <- %s' % (x, selector) for x in dep_broken_chains)
                        or_ok |= not dep_broken_chains
                    if not or_ok:
                        and_ok = False
                        broken_chains.extend(or_broken_chains)
                ok |= and_ok
        return [] if ok else broken_chains

    def dump(self, index_list, f):
        for index in index_list:
            i = index & 0xff
            offset = index >> 8
            file = self.file_list[i]
            file.seek(offset)
            pkg = Package(file)
            pkg['Filename'] = lambda v: self.url_list[i].replace('://', '/') + '/' + v
            f.write(str(pkg))
            f.write('\n')
