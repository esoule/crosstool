#!/bin/sh
# Compile local patched copy of distcc for use by crosstool

set -ex

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

test -z "${RESULT_TOP}"       && abort "Please set RESULT_TOP to the top of the crosstool tree"
test -z "${TARBALLS_DIR}"     && abort "Please set TARBALLS_DIR to the directory to download tarballs to."

while [ $# -gt 0 ]; do
      case "$1" in
	--buildrpm|-buildrpm)
	   opt_buildrpm=1
	   ;;
	*)
	   abort "Usage: mkdistcc.sh [--buildrpm]"
      esac
      shift
done

# Most subdirectories of $RESULT_TOP are for target architectures;
# create a new one just to hold stuff targeting the build machine.
PREFIX=$RESULT_TOP/common
rm -rf $PREFIX
mkdir -p $PREFIX/bin $PREFIX/etc
chmod 755 $PREFIX $PREFIX/bin $PREFIX/etc

# Install mkdistcclinks.sh, which creates symlinks and install-distccd.sh
install mkdistcclinks.sh $PREFIX/bin

# Install config.guess, which comes in handy when trying to figure
# out what kind of machine we're running on
install config.guess $PREFIX/bin

# Install templates that will be expanded and installed by install-distccd.sh
install -m 644 crosstool-distccd-linux.sh.in $PREFIX/etc
install -m 644 crosstool-distccd-cygwin.sh.in $PREFIX/etc
install -m 644 crosstool-distccd-mac.sh.in $PREFIX/etc
install -m 644 StartupParameters.plist $PREFIX/etc

# Make a scratch directory for building
BUILD_DIR=`pwd`/build
mkdir -p $BUILD_DIR
cd $BUILD_DIR

#----- Distcc -----
DISTCC=distcc-2.16
if test ! -f $TARBALLS_DIR/$DISTCC.tar.bz2; then
   wget -P $TARBALLS_DIR -c http://distcc.samba.org/ftp/distcc/$DISTCC.tar.bz2
fi
rm -rf $DISTCC
tar -xjvf $TARBALLS_DIR/$DISTCC.tar.bz2
cd $DISTCC
for a in ../../patches/$DISTCC/*.patch; do
    if test -f $a; then
	patch -g0 -p1 < $a
    fi
done
./configure --prefix=$PREFIX $EXTRA_DISTCC_CONFIG
make 
make install
cd ../..

# Create a unique name for this distcc in case startup scripts want one
ln -s $PREFIX/bin/distccd $PREFIX/bin/crosstool-distccd

# Build an RPM if desired
if test "$opt_buildrpm" = "1"; then
    sed -e "s,__PREFIX__,$RESULT_TOP/common,g" < crosstool-distcc.spec.in > $BUILD_DIR/$DISTCC/crosstool-distcc.spec
    mkrpmstuff $BUILD_DIR/$DISTCC $TARBALLS_DIR

    test -d $BUILD_DIR/$DISTCC/BUILD || mkdir $BUILD_DIR/$DISTCC/BUILD
    test -d $BUILD_DIR/$DISTCC/RPMS || mkdir $BUILD_DIR/$DISTCC/RPMS
    test -d $BUILD_DIR/$DISTCC/SRPMS || mkdir $BUILD_DIR/$DISTCC/SRPMS

    rpmbuild --rcfile=$BUILD_DIR/$DISTCC/rpmrc --macros=$BUILD_DIR/$DISTCC/rpmmacros -bb $BUILD_DIR/$DISTCC/crosstool-distcc.spec
fi
