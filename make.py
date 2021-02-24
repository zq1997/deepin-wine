from concurrent.futures import ThreadPoolExecutor
from threading import Semaphore
import asyncio
from urllib import request, parse
import os
import shutil
import re
import hashlib
import lzma
import gzip
import bz2
import pickle

import repo

DOWNLOAD = False

BUILD_DIR = './build'
OUTPUT = './repo/Packages'

DEEPIN_SITE_SOURCE = '''
    amd64 https://community-packages.deepin.com/deepin apricot main non-free
    i386 https://community-packages.deepin.com/deepin apricot main non-free
    i386 https://community-store-packages.deepin.com/appstore eagle appstore
'''
SITE_SOURCES = {
    'debian-stable': 'amd64 https://mirrors.tuna.tsinghua.edu.cn/debian stable main',
    'debian-testing': 'amd64 https://mirrors.tuna.tsinghua.edu.cn/debian testing main',
    'ubuntu-bionic': 'amd64 https://mirrors.tuna.tsinghua.edu.cn/ubuntu bionic main',
    'ubuntu-focal': 'amd64 https://mirrors.tuna.tsinghua.edu.cn/ubuntu focal main',
    'ubuntu-groovy': 'amd64 https://mirrors.tuna.tsinghua.edu.cn/ubuntu groovy main',
}

CACHE = {}
print_lock = Semaphore()


def log(*args):
    with print_lock:
        print(*args)


def download(url, size=None, sha256=None):
    path = os.path.join(BUILD_DIR, parse.quote_plus(url))
    if os.path.exists(path):
        if not DOWNLOAD:
            return False, path
        with open(path, 'rb') as f:
            f.seek(0, os.SEEK_END)
            if f.tell() == size:
                f.seek(0)
                hasher = hashlib.sha256()
                while True:
                    data = f.read(hasher.block_size)
                    if not data:
                        break
                    hasher.update(data)
                if sha256 is not None and hasher.hexdigest().lower() == sha256:
                    return False, path
    log('Downloading:', url)
    with open(path, 'wb') as f:
        with request.urlopen(url, timeout=10) as resp:
            shutil.copyfileobj(resp, f)
        return True, path


def get_release(url, dist):
    _, path = download('%s/dists/%s/Release' % (url, dist))
    with open(path, 'rt') as f:
        release = f.read()
    return re.search(r'\nSHA256:\s*((?:\n\s+.+)+)', release).group(1)


def get_packages(url, dist, path, size, sha256):
    url = '%s/dists/%s/%s' % (url, dist, path)
    updated, download_path = download(url, size, sha256)
    file_path, ext = os.path.splitext(download_path)
    meta_path = file_path + '.meta'
    if updated or not os.path.exists(file_path) or not os.path.exists(meta_path):
        log('Updating Packages:', url)
        if file_path != download_path:
            uncompressor = {'.xz': lzma, '.bz2': bz2, '.gz': gzip}
            with uncompressor[ext].open(download_path) as fin:
                with open(file_path, 'wb') as fout:
                    shutil.copyfileobj(fin, fout)
        with open(file_path, 'rt') as f:
            meta = repo.make_repo_meta(f)
        with open(meta_path, 'wb') as f:
            pickle.dump(meta, f)
    else:
        with open(meta_path, 'rb') as f:
            meta = pickle.load(f)
    return updated, file_path, meta


def get_diff(src, dest, apps):
    diff_path = os.path.join(BUILD_DIR, dest.name + '.diff')
    if not src.updated and not dest.updated and os.path.exists(diff_path):
        with open(diff_path, 'rb') as f:
            return False, pickle.load(f)

    log('Diff:', dest.name)
    src = src.open(True)
    dest = dest.open(False)
    for app in apps:
        src.diff(dest, app)
    src.close()
    dest.close()
    diff = src.visited
    with open(diff_path, 'wb') as f:
        pickle.dump(diff, f)
    return True, diff


async def run_in_executor(*func_args, use_cache=True):
    if use_cache and func_args in CACHE:
        future = CACHE[func_args]
    else:
        future = asyncio.wrap_future(pool.submit(*func_args))
        if use_cache:
            CACHE[func_args] = future
    return await future


async def add_source_line(site, source_line):
    arch, url, dist, *comps = source_line.split()
    release = await run_in_executor(get_release, url, dist)
    tasks = []
    for comp in comps:
        for suffix in ('.xz', '.bz2', '.gz', ''):
            match = re.search(r'^.+\s+%s/binary-%s/Packages%s\s*$' % (comp, arch, suffix), release, re.M)
            if match:
                sha256, size, path = match.group(0).split()
                tasks.append(run_in_executor(get_packages, url, dist, path, int(size), sha256))
                break
        else:
            raise Exception('No Packages indices')

    for updated, file_path, meta in await asyncio.gather(*tasks):
        site.add(updated, url, file_path, meta)


async def create_site(name, site_source):
    site = repo.Site(name)
    await asyncio.gather(*[add_source_line(site, x) for x in filter(str.strip, site_source.splitlines())])
    return site


async def main():
    other_sites = [asyncio.create_task(create_site(*x)) for x in SITE_SOURCES.items()]
    deepin_site = await asyncio.create_task(create_site(None, DEEPIN_SITE_SOURCE))

    apps = [x for meta in deepin_site.meta_list for x in meta if x.endswith('.deepin')]

    tasks = []
    for site in asyncio.as_completed(other_sites):
        tasks.append(asyncio.create_task(run_in_executor(get_diff, deepin_site, await site, apps, use_cache=False)))
    result = await asyncio.gather(*tasks)

    if any(x[0] for x in result) or not os.path.exists(OUTPUT):
        log('Dumping:', OUTPUT)
        deepin_site.open(False)
        with open(OUTPUT, 'wt') as f:
            deepin_site.dump(set.union(*[x[1] for x in result]), f)
        deepin_site.close()


pool = ThreadPoolExecutor()
asyncio.run(main())
