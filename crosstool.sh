#!/bin/sh

abort() {
    echo $@
    exec /bin/false
}

#
# crosstool.sh
# Build a GNU/Linux toolchain
#
# Copyright (c) 2001 by Bill Gatliff, bgat@billgatliff.com 
# Copyright (c) 2003 by Dan Kegel, dkegel@ixiacom.com, Ixia Communications, 
# All rights reserved.  This script is provided under the terms of the GPL.
# For questions, comments or improvements see the crossgcc mailing
# list at http://sources.redhat.com/ml/crossgcc, or contact the
# authors, but do your homework first.  As Bill says, "THINK!"
#
# Meant to be invoked from another shell script.
# Usage: nine environment variables must be set, namely:
test -z "${PREFIX}"           && abort "Please set PREFIX to where you want the toolchain installed."
test -z "${BUILD_DIR}"        && abort "Please set BUILD_DIR to the directory where the tools are to be built"
test -z "${SRC_DIR}"          && abort "Please set SRC_DIR to the directory where the source tarballs are to be unpacked"
test -z "${BINUTILS_DIR}"     && abort "Please set BINUTILS_DIR to the bare filename of the binutils tarball or directory"
test -z "${GCC_DIR}"          && abort "Please set GCC_DIR to the bare filename of the gcc tarball or directory"
test -z "${GLIBC_DIR}"        && abort "Please set GLIBC_DIR to the bare filename of the glibc tarball or directory"
test -z "${LINUX_DIR}"        && abort "Please set LINUX_DIR to the bare filename of the kernel tarball or directory"
test -z "${TARGET}"           && abort "Please set TARGET to the Gnu target identifier (e.g. pentium-linux)"
test -z "${TARGET_CFLAGS}"    && abort "Please set TARGET_CFLAGS to any compiler flags needed when building glibc (-O recommended)"

test -z "${BINUTILS_EXTRA_CONFIG}" && echo  "BINUTILS_EXTRA_CONFIG not set, so not passing any extra options to binutils' configure script"
test -z "${GCC_EXTRA_CONFIG}" && echo  "GCC_EXTRA_CONFIG not set, so not passing any extra options to gcc's configure script"
test -z "${GLIBC_EXTRA_CONFIG}" && echo "GLIBC_EXTRA_CONFIG not set, so not passing any extra options to glibc's configure script"
test -z "${GLIBC_EXTRA_ENV}"  && echo "GLIBC_EXTRA_ENV not set, so not passing any extra environment variables to glibc's configure script"
test -z "${KERNELCONFIG}" && test -z ${LINUX_DIR}/.config  && echo  "KERNELCONFIG not set, and no .config file found, so not configuring linux kernel"
test -z "${USE_SYSROOT}"     && echo  "USE_SYSROOT not set, so not configuring with --with-sysroot"

test -z "${KERNELCONFIG}" || test -r "${KERNELCONFIG}"  || abort  "Can't read file KERNELCONFIG = $KERNELCONFIG, please fix."

# And one is derived.
GLIBCTHREADS_FILENAME=`echo $GLIBC_DIR | sed 's/glibc-/glibc-linuxthreads-/'`

# Check for a few prerequisites that have tripped people up.
awk '/x/' < /dev/null  || abort "You need awk to build a toolchain."
test -z "${CFLAGS}"    || abort "Don't set CFLAGS, it screws up the build"
test -z "${CXXFLAGS}"  || abort "Don't set CXXFLAGS, it screws up the build"

set -ex

# map TARGET to Linux equivalent
case $TARGET in
    alpha*)   ARCH=alpha ;;
    arm*)     ARCH=arm ;;
    cris*)    ARCH=cris ;;
    hppa*)    ARCH=parisc ;;
    i*86*)    ARCH=i386 ;;
    ia64*)    ARCH=ia64 ;;
    mips*)    ARCH=mips ;;
    m68k*)    ARCH=m68k ;;
    powerpc*) ARCH=ppc ;;
    ppc*)     abort "Target $TARGET incompatible with binutils and gcc regression tests; use target powerpc-* instead";;
    s390*)    ARCH=s390 ;;
    sh*)      ARCH=sh ;;
    sparc64*) ARCH=sparc64 ;;
    sparc*)   ARCH=sparc ;;
    x86_64*)  ARCH=x86_64 ;;
    *) abort "Bad target $TARGET"
esac

# Make all paths absolute (it's so confusing otherwise)
# FIXME: this doesn't work well with some automounters
PREFIX=`cd $PREFIX; pwd`
BUILD_DIR=`cd $BUILD_DIR; pwd`
SRC_DIR=`cd $SRC_DIR; pwd`
BINUTILS_DIR=`cd ${SRC_DIR}/${BINUTILS_DIR}; pwd`
GCC_DIR=`cd ${SRC_DIR}/${GCC_DIR}; pwd`
LINUX_DIR=`cd ${SRC_DIR}/${LINUX_DIR}; pwd`
GLIBC_DIR=`cd ${SRC_DIR}/${GLIBC_DIR}; pwd`

# make sure the build product's binaries are in the search path
PATH="${PREFIX}/bin:${PATH}"
export PATH

# test that we have write permissions to the install dir
mkdir -p ${PREFIX}/${TARGET}
touch ${PREFIX}/${TARGET}/test-if-write
test -w ${PREFIX}/${TARGET}/test-if-write || abort "You don't appear to have write permissions to ${PREFIX}/${TARGET}."
rm -f ${PREFIX}/${TARGET}/test-if-write

if test -z "$USE_SYSROOT"; then
    # plain old way.  all libraries in prefix/target/lib
    SYSROOT=${PREFIX}/${TARGET}
    HEADERDIR=$SYSROOT/include
    # hack!  Always use --with-sysroot for binutils.
    # binutils 2.14 and later obey it, older binutils ignore it.
    # Lets you build a working 32->64 bit cross gcc
    BINUTILS_SYSROOT_ARG="--with-sysroot=${SYSROOT}"
    # Use --with-headers, else final gcc will define disable_glibc while building libgcc, and you'll have no profiling
    GCC_SYSROOT_ARG_CORE="--without-headers"
    GCC_SYSROOT_ARG="--with-headers=${HEADERDIR}"
    GLIBC_SYSROOT_ARG=prefix=
else
    # spiffy new sysroot way.  libraries split between
    # prefix/target/sys-root/lib and prefix/target/sys-root/usr/lib
    SYSROOT=${PREFIX}/${TARGET}/sys-root
    HEADERDIR=$SYSROOT/usr/include
    BINUTILS_SYSROOT_ARG="--with-sysroot=${SYSROOT}"
    GCC_SYSROOT_ARG="--with-sysroot=${SYSROOT}"
    GCC_SYSROOT_ARG_CORE=$GCC_SYSROOT_ARG
    GLIBC_SYSROOT_ARG=""
    # glibc's prefix must be exactly /usr, else --with-sysroot'd
    # gcc will get confused when $sysroot/usr/include is not present
    # Note: --prefix=/usr is magic!  See http://www.gnu.org/software/libc/FAQ.html#s-2.2
fi

# Make lib directory in sysroot, else the ../lib64 hack used by 32 -> 64 bit
# crosscompilers won't work, and build of final gcc will fail with 
#  "ld: cannot open crti.o: No such file or directory"
mkdir -p $SYSROOT/lib
mkdir -p $SYSROOT/usr/lib

echo
echo Building for:
echo "    --target=$TARGET"
echo "    --prefix=$PREFIX"

# Get description of the build machine from autotools, but since old
# autotools (e.g. the one in gcc-2.95) barfs if you're on an x86_64,
# let user override it if needed
BUILD=${BUILD-`$GCC_DIR/config.guess`}

# Set HOST to something almost, but not completely, identical to BUILD
# This strange operation causes gcc to always generate a cross-compiler
# even if the build machine is the same kind as the host.
HOST=`echo $BUILD | sed s/-/-host_/`

#---------------------------------------------------------
echo Prepare kernel headers

cd $LINUX_DIR

if test -f "$KERNELCONFIG" ; then
    cp $KERNELCONFIG .config
fi
if test -f .config; then
    yes "" | make ARCH=$ARCH oldconfig
fi

make ARCH=$ARCH symlinks include/linux/version.h

mkdir -p $HEADERDIR
cp -r include/linux $HEADERDIR
cp -r include/asm-${ARCH} $HEADERDIR/asm
cp -r include/asm-generic $HEADERDIR/asm-generic

cd $BUILD_DIR

#---------------------------------------------------------
echo Build binutils

mkdir -p build-binutils; cd build-binutils

if test '!' -f Makefile; then
    ${BINUTILS_DIR}/configure --target=$TARGET --prefix=$PREFIX --disable-nls ${BINUTILS_EXTRA_CONFIG} $BINUTILS_SYSROOT_ARG
fi

make all 
make install 

cd ..

# test to see if this step passed
test -x ${PREFIX}/bin/${TARGET}-ld || abort Build failed during binutils 

#---------------------------------------------------------
echo "Install glibc headers needed to build bootstrap compiler -- but only if gcc-3.x"

# Only need to install bootstrap glibc headers for gcc-3.0 and above?  Or maybe just gcc-3.3 and above?
# This will change for gcc-3.5, I think.
# See also http://gcc.gnu.org/PR8180, which complains about the need for this step.
# Don't install them if they're already there (it's really slow)
if grep -q gcc-3 ${GCC_DIR}/ChangeLog && test '!' -f $HEADERDIR/features.h; then
    mkdir -p build-glibc-headers; cd build-glibc-headers

    if test '!' -f Makefile; then
        # The following three things have to be done to build glibc-2.3.x, but they don't hurt older versions.
        # 1. override CC to keep glibc's configure from using $TARGET-gcc. 
        # 2. disable linuxthreads, which needs a real cross-compiler to generate tcb-offsets.h properly
        # 3. build with gcc 3.2 or later
        # Compare these options with the ones used when building glibc for real below - they're different.
	# As of glibc-2.3.2, to get this step to work for hppa-linux, you need --enable-hacker-mode
	# so when configure checks to make sure gcc has access to the assembler you just built...
	# Alternately, we could put ${PREFIX}/${TARGET}/bin on the path.
        # Set --build so maybe we don't have to specify "cross-compiling=yes" below (haven't tried yet)
        # Note: the warning
        # "*** WARNING: Are you sure you do not want to use the `linuxthreads'"
        # *** add-on?"
        # is ok here, since all we want are the basic headers at this point.
        CC=gcc \
            ${GLIBC_DIR}/configure --host=$TARGET --prefix=/usr \
	    --build=$BUILD \
            --without-cvs --disable-sanity-checks --with-headers=$HEADERDIR \
	    --enable-hacker-mode
    fi

    if grep -q GLIBC_2.3 ${GLIBC_DIR}/ChangeLog; then
        # glibc-2.3.x passes cross options to $(CC) when generating errlist-compat.c, which fails without a real cross-compiler.
        # Fortunately, we don't need errlist-compat.c, since we just need .h files, 
        # so work around this by creating a fake errlist-compat.c and satisfying its dependencies.
        # Another workaround might be to tell configure to not use any cross options to $(CC).
        # The real fix would be to get install-headers to not generate errlist-compat.c.
        make sysdeps/gnu/errlist.c
	mkdir -p stdio-common
        touch stdio-common/errlist-compat.c
    fi
    make cross-compiling=yes install_root=${SYSROOT} $GLIBC_SYSROOT_ARG install-headers

    # Two headers -- stubs.h and features.h -- aren't installed by install-headers,
    # so do them by hand.  We can tolerate an empty stubs.h for the moment.
    # See e.g. http://gcc.gnu.org/ml/gcc/2002-01/msg00900.html

    mkdir -p $HEADERDIR/gnu
    touch $HEADERDIR/gnu/stubs.h
    cp ${GLIBC_DIR}/include/features.h $HEADERDIR/features.h
    # Building the bootstrap gcc requires either setting inhibit_libc, or
    # having a copy of stdio_lim.h... see
    # http://sources.redhat.com/ml/libc-alpha/2003-11/msg00045.html
    cp bits/stdio_lim.h $HEADERDIR/bits/stdio_lim.h

    cd ..
fi

#---------------------------------------------------------
echo "Build gcc-core (just enough to build glibc)"

mkdir -p build-gcc-core; cd build-gcc-core

# Use --with-local-prefix so older gccs don't look in /usr/local (http://gcc.gnu.org/PR10532)

if test '!' -f Makefile; then
    ${GCC_DIR}/configure --target=$TARGET --host=$HOST --prefix=$PREFIX \
	--with-local-prefix=${SYSROOT} \
	--disable-multilib \
	--with-newlib \
        ${GCC_EXTRA_CONFIG} \
	${GCC_SYSROOT_ARG_CORE} \
	--disable-nls \
	--enable-threads=no \
	--enable-symvers=gnu \
	--enable-__cxa_atexit \
        --enable-languages=c \
	--disable-shared
fi

make all-gcc install-gcc 

cd ..

test -x ${PREFIX}/bin/${TARGET}-gcc || abort Build failed during gcc-core 

#---------------------------------------------------------
echo Build glibc and linuxthreads

mkdir -p build-glibc; cd build-glibc

# sh4 really needs to set configparms as of gcc-3.4/glibc-2.3.2
# note: this is awkward, doesn't work well if you need more than one line in configparms
echo ${GLIBC_CONFIGPARMS} > configparms

if test '!' -f Makefile; then
    # Configure with --prefix the way we want it on the target...
    # There are a whole lot of settings here.  You'll probably want
    # to read up on what they all mean, and customize a bit.
    # e.g. I picked --enable-kernel=2.4.3 here just because it's the kernel Bill 
    # used in his example gcc2.95.3 script.  That means some backwards compatibility 
    # stuff is turned on in glibc that you may not need if you're using a newer kernel.
    # Compare these options with the ones used when installing the glibc headers above - they're different.
    # Adding "--without-gd" option to avoid error "memusagestat.c:36:16: gd.h: No such file or directory" 
    # See also http://sources.redhat.com/ml/libc-alpha/2000-07/msg00024.html. 
    # The --enable-clocale=gnu is recomended by LFS; see http://bugs.linuxfromscratch.org/show_bug.cgi?id=411
    # Set BUILD_CC, or you won't be able to build datafiles
    # Set --build, else glibc-2.3.2 will think you're not cross-compiling, and try to run the test programs

    BUILD_CC=gcc CFLAGS="$TARGET_CFLAGS" CC=${TARGET}-gcc AR=${TARGET}-ar RANLIB=${TARGET}-ranlib \
        ${GLIBC_DIR}/configure --host=$TARGET --prefix=/usr \
	--build=$BUILD \
        ${GLIBC_EXTRA_CONFIG} \
        --without-tls --without-__thread --enable-kernel=2.4.3 \
        --without-cvs --disable-profile --disable-debug --without-gd \
	--enable-clocale=gnu \
        --enable-add-ons --with-headers=$HEADERDIR
fi

# If this fails with an error like this:
# ...  linux/autoconf.h: No such file or directory 
# then you need to set the KERNELCONFIG variable to point to a .config file for this arch.
# The following architectures are known to need kernel .config: alpha, arm, ia64, s390, sh, sparc
make
make install install_root=${SYSROOT} $GLIBC_SYSROOT_ARG

# Fix problems in linker scripts.
# 
# 1. Remove absolute paths
# Any file in a list of known suspects that isn't a symlink is assumed to be a linker script.
# FIXME: test -h is not portable
# FIXME: probably need to check more files than just these three...
# Need to use sed instead of just assuming we know what's in libc.so because otherwise alpha breaks
# But won't need to do this at all once we use --with-sysroot (available in gcc-3.3.3 and up)
#
# 2. Remove lines containing BUG per http://sources.redhat.com/ml/bug-glibc/2003-05/msg00055.html,
# needed to fix gcc-3.2.3/glibc-2.3.2 targeting arm
#
# To make "strip *.so.*" not fail (ptxdist does this), rename to .so_orig rather than .so.orig
for file in libc.so libpthread.so libgcc_s.so; do
  for lib in lib lib64 usr/lib usr/lib64; do
	if test -f ${SYSROOT}/$lib/$file && test ! -h ${SYSROOT}/$lib/$file; then
		mv ${SYSROOT}/$lib/$file ${SYSROOT}/$lib/${file}_orig
		if test -z "$USE_SYSROOT"; then
		  sed 's,/usr/lib/,,g;s,/usr/lib64/,,g;s,/lib/,,g;s,/lib64/,,g;/BUG in libc.scripts.output-format.sed/d' < ${SYSROOT}/$lib/${file}_orig > ${SYSROOT}/$lib/$file
	        else
		  sed '/BUG in libc.scripts.output-format.sed/d' < ${SYSROOT}/$lib/${file}_orig > ${SYSROOT}/$lib/$file
		fi
	fi
    done
done
cd ..

test -f ${SYSROOT}/lib/libc.a || test -f ${SYSROOT}/lib64/libc.a || test -f ${SYSROOT}/usr/lib/libc.a || test -f ${SYSROOT}/usr/lib64/libc.a || abort Building libc failed

#---------------------------------------------------------
echo Build final gcc

mkdir -p build-gcc; cd build-gcc

if test '!' -f Makefile; then
    # --enable-symvers=gnu really only needed for sh4 to work around a detection problem
    # only matters for gcc-3.2.x and later, I think
    # --disable-nls to work around crash bug on ppc405, but also because embedded
    # systems don't really need message catalogs...
    ${GCC_DIR}/configure --target=$TARGET --host=$HOST --prefix=$PREFIX \
        ${GCC_EXTRA_CONFIG} \
        $GCC_SYSROOT_ARG \
	--with-local-prefix=${SYSROOT} \
	--disable-nls \
	--enable-threads=posix \
	--enable-symvers=gnu \
	--enable-__cxa_atexit \
        --enable-languages=c,c++ \
	--enable-shared \
	--enable-c99 \
        --enable-long-long
fi

make all 
make install 

echo "kludge: If the chip does not have a floating point unit "
echo "(i.e. if GLIBC_EXTRA_CONFIG contains --without-fp),"
echo "and there are shared libraries in /lib/nof, copy them to /lib"
echo "so they get used by default."
echo "FIXME: only rs6000/powerpc seem to use nof.  See MULTILIB_DIRNAMES"
echo "in $GCC_DIR/gcc/config/$TARGET/* to see what your arch calls it."
case "$GLIBC_EXTRA_CONFIG" in
   *--without-fp*)
      if test -d ${SYSROOT}/lib/nof; then
          cp -af ${SYSROOT}/lib/nof/*.so* ${SYSROOT}/lib
      fi
      ;;
esac

cd ..
cd ..

test -x ${PREFIX}/bin/${TARGET}-gcc || Build failed during final gcc 

#---------------------------------------------------------
echo Cross-toolchain build complete.
exit 0

