#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"

mkdir -p repo/deepin/
python3 extract_deepin_repo.py

mkdir -p repo/ubuntu-fix/
cd repo/ubuntu-fix/
deb_name='libjpeg62-turbo_1.5.1-2_i386.deb'
if [[ '../../libjpeg62-turbo/DEBIAN/control' -nt $deb_name ]]; then
  dpkg-deb -b ../../libjpeg62-turbo/ .
  dpkg-scanpackages . > Packages
fi
cd ../..

cd repo
for repo in deepin ubuntu-fix; do
    cd $repo
    if [[ Packages -nt InRelease ]]; then
      echo "更新仓库索引：${repo}"
      gzip -knf Packages
      apt-ftparchive release . > Release
      gpg --yes --armor --detach-sign --sign -o Release.gpg Release
      gpg --yes --clearsign -o InRelease Release
    fi
    cd ..
done
