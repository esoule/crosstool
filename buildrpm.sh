#!/bin/sh
# Create specfiles and RPMs from the results of a crosstool build.

abort() {
    echo $@
    exec false
}

# Create rpmrc and rpmmacros for our rpmbuild
# Usage: mkrpmstuff RESULTDIR TARBALLSDIR
mkrpmstuff() {
  test -f $1/rpmrc || cat >$1/rpmrc <<_EOF_
include: /usr/lib/rpm/rpmrc
macrofiles: /usr/lib/rpm/macros:/usr/lib/rpm/%{_target}/macros:/etc/rpm/macros.specspo:/etc/rpm/macros:/etc/rpm/%{_target}/macros:$1/rpmmacros
_EOF_
  test -f $1/rpmmacros || cat >$1/rpmmacros <<_EOF_
%_topdir        $1
%_sourcedir     $2
%_specdir       %{_topdir}
%_tmppath       %{_topdir}/tmp
%_builddir      %{_topdir}/BUILD
%_buildroot     %{_tmppath}/%{name}-root
%_rpmdir        %{_topdir}/RPMS
%_srcrpmdir     %{_topdir}/SRPMS
%_rpmfilename   %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm
%packager       `whoami`@`hostname`
_EOF_
  test -d $1/BUILD || mkdir $1/BUILD
  test -d $1/RPMS || mkdir $1/RPMS
  test -d $1/SRPMS || mkdir $1/SRPMS
}

# Meant to be invoked from another shell script.
# Usage: seven environment variables must be set, namely:
test -z "${TARGET}"           && abort "Please set TARGET to the Gnu target identifier (e.g. pentium-linux)"
test -z "${TARGET_CFLAGS}"    && abort "Please set TARGET_CFLAGS to any compiler flags needed when building glibc (-O recommended)"
test -z "${BINUTILS_DIR}"     && abort "Please set BINUTILS_DIR to the bare filename of the binutils tarball or directory"
test -z "${BUILD_DIR}"        && abort "Please set BUILD_DIR to the directory where the tools are to be built"
test -z "${GCC_DIR}"          && abort "Please set GCC_DIR to the bare filename of the gcc tarball or directory"
test -z "${LINUX_DIR}"        && abort "Please set LINUX_DIR to the bare filename of the kernel tarball or directory"
test -z "${GLIBC_DIR}"        && abort "Please set GLIBC_DIR to the bare filename of the glibc tarball or directory"

set -ex

#FIXME: this should be higher in the script execution chain
VERSION=0.29
MUNGEDVERSION=`echo $VERSION | sed -e "s/-/_/g"`

TOP_DIR=${TOP_DIR-`pwd`}
TARBALLS_DIR=${TARBALLS_DIR-$TOP_DIR/tarballs}
TOOLCOMBO=$GCC_DIR-$GLIBC_DIR
RESULT_TOP=${RESULT_TOP-$TOP_DIR/result}
PREFIX=${PREFIX-$RESULT_TOP/$TARGET/$TOOLCOMBO}

test -f ${TARBALLS_DIR}/crosstool-$VERSION.tar.gz || abort "Please put a copy of the crosstool source tarball in $TARBALLS_DIR to make rpmbuild happy"

test -d $BUILD_DIR || mkdir -p $BUILD_DIR

# FIXME: need better way to extract version numbers?
GCCVERSION=`echo $GCC_DIR | sed -e 's/.*gcc-//'`
GLIBCVERSION=`echo $GLIBC_DIR | sed -e 's/.*glibc-//'`
BINUTILSVERSION=`echo $BINUTILS_DIR | sed -e 's/.*binutils-//'`
KERNELVERSION=`echo $LINUX_DIR | sed -e 's/.*linux-//'`
# This gnarly thing deletes the libgcc and libstdc++ subpackages from the
# specfile if we're building gcc-2*
NOLIBPKGS=`case $GCCVERSION in 2.* ) echo '/%package %{gnutarget}-libgcc/,$d';; esac`
sed -e "s,__GCCVERSION__,$GCCVERSION,g" \
    -e "s,__GLIBCVERSION__,$GLIBCVERSION,g" \
    -e "s,__BINUTILSVERSION__,$BINUTILSVERSION,g" \
    -e "s,__KERNELVERSION__,$KERNELVERSION,g" \
    -e "s,__TARGET__,$TARGET,g" \
    -e "s,__PREFIX__,$PREFIX,g" \
    -e "s,__VERSION__,$VERSION,g" \
    -e "s,__MUNGEDVERSION__,$MUNGEDVERSION,g" \
    -e "$NOLIBPKGS" \
    < crosstool-generic.spec.in \
    > ${BUILD_DIR}/crosstool-$TARGET-$TOOLCOMBO.spec

mkrpmstuff $BUILD_DIR $TARBALLS_DIR

# Remove cruft from testhello.sh
rm -rf $PREFIX/tmp

cd $BUILD_DIR
rpmbuild --rcfile=$BUILD_DIR/rpmrc --macros=$BUILD_DIR/rpmmacros -bb crosstool-$TARGET-$TOOLCOMBO.spec
