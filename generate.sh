#!/usr/bin/env sh
set -e
cd "$(dirname "$0")"/repo

GPG_KEY_FILE='i-m.dev.gpg'
if [ ! -f "${GPG_KEY_FILE}" ]; then
  gpg --export -o "${GPG_KEY_FILE}"
fi

mkdir -p deepin/
python3 ../extract_deepin_repo.py deepin/Packages

mkdir -p ubuntu-fix/
cd ubuntu-fix/
NEED_RESCAN=0
for pkg in ../../ubuntu-fix-packages/*; do
  if [ "$(find . -name "${pkg##*/}_*.deb" -newer "${pkg}/DEBIAN/control" | wc -l)" -eq 0 ]; then
      dpkg-deb -b "${pkg}" .
      NEED_RESCAN=1
  fi
done
if [ $NEED_RESCAN -eq 1 ]; then
  dpkg-scanpackages . > Packages
fi
cd ../

for repo in deepin ubuntu-fix; do
    cd $repo
    if [ ! Packages -ot InRelease ]; then
      echo "更新仓库索引：${repo}"
      gzip -knf9 Packages
      apt-ftparchive release . > Release
      gpg --yes --detach-sign --armor -o Release.gpg Release
      gpg --yes --clear-sign -o InRelease Release
    fi
    cd ..
done
