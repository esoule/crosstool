#!/bin/sh
set -x
set -e

abort() {
    echo $@
    exec false
}

RECROSSTOOLRPM=recrosstoolrpm
CROSSTOOLVERSION=0.43
CROSSTOOLRPMRELEASE=1.1.2
DDD=`date +%Y%m%d_%H%M`

test ! -d crosstool-edit && abort "${RECROSSTOOLRPM}: Directory crosstool-edit not found"
test ! -d crosstool-edit/crosstool-${CROSSTOOLVERSION} && abort "${RECROSSTOOLRPM}: Directory crosstool-edit/crosstool-${CROSSTOOLVERSION} not found"

(


(
  cd crosstool-edit
  find crosstool-${CROSSTOOLVERSION} -type f -name '*~' -print -delete
  find crosstool-${CROSSTOOLVERSION} -type f -name '*.orig' -print -delete
  tar --exclude ./crosstool-${CROSSTOOLVERSION}/.git  -zcf crosstool-${CROSSTOOLVERSION}-${DDD}.tar.gz ./crosstool-${CROSSTOOLVERSION}

  rm -v -f ../crosstool-${CROSSTOOLVERSION}.tar.gz
  cp crosstool-${CROSSTOOLVERSION}-${DDD}.tar.gz ../crosstool-${CROSSTOOLVERSION}.tar.gz
)

export TOOLCOMBOS="gcc-3.2.3-glibc-2.2.5"

rm -rf ./crosstool-${CROSSTOOLVERSION}

rm -rf ./build ./rpmbuild

tar -xf crosstool-${CROSSTOOLVERSION}.tar.gz

export RESULT_TOP=/opt/crosstool
export TARBALLS_CACHE_DIR=${PWD}/build_cache/tarballs-all
sh ./crosstool-${CROSSTOOLVERSION}/buildsrpms.sh
unset RESULT_TOP
unset TARBALLS_CACHE_DIR

mv rpmbuild/SRPMS rpmbuild-INCOMING

rm -rf rpmbuild
mkdir rpmbuild
mv rpmbuild-INCOMING rpmbuild/INCOMING

echo RPM is placed into rpmbuild/INCOMING/*.src.rpm
echo Rebuild it as follows:
echo rpmbuild --without all --with powerpc_405 --rebuild rpmbuild/INCOMING/crosstool-${TOOLCOMBOS}-${CROSSTOOLVERSION}-${CROSSTOOLRPMRELEASE}.src.rpm

) 2>&1 | tee ${RECROSSTOOLRPM}-log-${DDD}.txt
