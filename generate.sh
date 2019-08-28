#!/bin/sh
set -e

mkdir -p repo/ubuntu-fix/ repo/deepin/
python3 extract_deepin_repo.py

cd repo/ubuntu-fix/
rm -f *.deb
dpkg-deb -b ../../libjpeg62-turbo_*/ .
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
