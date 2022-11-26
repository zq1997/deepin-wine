import html
import datetime

import repo

INPUT = './repo/Packages'
TEMPLATE = './index.html'
OUTPUT = './repo/index.html'

result = []
site = repo.Site()
site.add(INPUT)
site.open(False)
for name in (x for meta in site.meta_list for x in meta if x.endswith('.deepin')):
    for _, pkg in site.get_package_entries(name):
        url = '%s://%s' % tuple(pkg['Filename'].split('/', 1))
        result.append((url, pkg['Package'], pkg['Version'], pkg['Description']))
site.close()

with open(TEMPLATE) as f:
    template = f.read()
before_t, the_t, after_t = template.split('<!--template-->')

result.sort(key=lambda x: x[1])
with open(OUTPUT, 'wt') as f:
    f.write(before_t)
    for x in result:
        f.write(the_t % tuple(map(html.escape, x)))
    update_time = (datetime.datetime.utcnow() + datetime.timedelta(hours=8)).strftime('%Y-%m-%d %H:%M:%S')
    f.write(after_t.replace('<!--update_time-->', update_time))
