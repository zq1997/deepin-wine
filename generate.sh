#!/bin/sh
set -e

mkdir -p repo/ubuntu-fix/ repo/deepin/
python3 extract_deepin_repo.py
dpkg-deb -b libjpeg62-turbo_1.5.2-2+b1_i386/ repo/ubuntu-fix
cd repo/ubuntu-fix/
dpkg-scanpackages . > Packages
cd ../..

cd repo
for repo in deepin ubuntu-fix; do
    cd $repo
    gzip -knf Packages
    apt-ftparchive release . > Release
    gpg --yes --armor --detach-sign --sign -o Release.gpg Release
    gpg --yes --clearsign -o InRelease Release
    cd ..
done
