import os
import shutil
import urllib.request
import urllib.error
import argparse
import queue
import threading
from datetime import datetime


def fetch(local_path, remote_url, verbose):
    time_format = '%a, %d %b %Y %H:%M:%S GMT'
    request = urllib.request.Request(remote_url)
    if os.path.isfile(local_path):
        mtime = datetime.fromtimestamp(os.path.getmtime(local_path)).strftime(time_format)
        request.add_header('If-Modified-Since', mtime)
    try:
        with urllib.request.urlopen(request) as response:
            with open(local_path, 'wb') as fout:
                shutil.copyfileobj(response, fout)
            mtime = response.headers['Last-Modified']
            if mtime is not None:
                mtime = datetime.strptime(mtime, time_format).timestamp()
                os.utime(local_path, (mtime, mtime))
            if verbose:
                print('下载结束：', local_path)
    except urllib.error.HTTPError as e:
        if e.code != 304:
            raise e
        if verbose:
            print('无需更新：', local_path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-j', '--jobs', type=int, default=4)
    parser.add_argument('-v', '--verbose', action='store_true')
    parser.add_argument('-t', '--template')
    parser.add_argument('-s', '--separator')
    parser.add_argument('-d', '--directory', default='.')
    parser.add_argument('-f', '--file', nargs='+', action='append', default=[])
    args = parser.parse_args()

    tasks = queue.Queue()
    for filename, *remote_url in args.file:
        if remote_url:
            remote_url = remote_url[0]
        else:
            remote_url = args.template.format(*filename.split(args.separator))
        local_path = os.path.join(args.directory, filename)
        tasks.put((local_path, remote_url, args.verbose))

    def run():
        while True:
            try:
                fetch(*tasks.get(block=False))
            except queue.Empty:
                break

    workers = [threading.Thread(target=run) for _ in range(min(args.jobs, len(args.file)))]
    for w in workers:
        w.start()
    for w in workers:
        w.join()


if __name__ == '__main__':
    main()
