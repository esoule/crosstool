#!/bin/sh
abort() {
    echo $@
    exec false
}
# Script to download sources for, build, and test a gnu/linux toolchain
# Copyright (c) 2003 by Dan Kegel, Ixia Communications.
# All rights reserved.  This script is provided under the terms of the GPL.
# For questions, comments or improvements see the crossgcc mailing
# list at http://sources.redhat.com/ml/crossgcc, but do your homework first.
# As Bill Gatliff says, "THINK!"
#
# Meant to be invoked from another shell script.
# Usage: six environment variables must be set, namely:
test -z "${TARGET}"           && abort "Please set TARGET to the Gnu target identifier (e.g. pentium-linux)"
test -z "${TARGET_CFLAGS}"    && abort "Please set TARGET_CFLAGS to any compiler flags needed when building glibc (-O recommended)"
test -z "${BINUTILS_DIR}"     && abort "Please set BINUTILS_DIR to the bare filename of the binutils tarball or directory"
test -z "${GCC_DIR}"          && abort "Please set GCC_DIR to the bare filename of the gcc tarball or directory"

# When building a cygwin target LINUX_DIR and GLIBC_DIR are not needed.
if test "${CYGWIN_DIR}" = ""; then
  test -z "${LINUX_DIR}"        && abort "Please set LINUX_DIR to the bare filename of the kernel tarball or directory"
  test -z "${GLIBC_DIR}"        && abort "Please set GLIBC_DIR to the bare filename of the glibc tarball or directory"
fi

# Four environment variables are optional, namely:
test -z "${DEJAGNU}"          && echo  "DEJAGNU not set, so not running any regression tests"
test -z "${GCC_EXTRA_CONFIG}" && echo  "GCC_EXTRA_CONFIG not set, so not passing any extra options to gcc's configure script"
test -z "${GLIBC_ADDON_OPTIONS}" && echo "GLIBC_ADDON_OPTIONS not set, so building all glibc add-on's"
test -z "${KERNELCONFIG}"     && echo  "KERNELCONFIG not set, so not configuring linux kernel"

test -z "${KERNELCONFIG}" || test -r "${KERNELCONFIG}"  || abort  "Can't read file KERNELCONFIG = $KERNELCONFIG, please fix."

set -ex

TOOLCOMBO=$GCC_DIR-$GLIBC_DIR
BUILD_DIR=`pwd`/build/$TARGET/$TOOLCOMBO

TOP_DIR=`pwd`

# These environment variables are optional:
if test -z "${SRC_DIR}"; then
   SRC_DIR=$BUILD_DIR
   echo  "SRC_DIR not set, so source tarballs will be unpacked in the build directory"
fi

# Sanity checks
case x$PREFIX in
x/) abort "Don't set PREFIX to /, as \$PREFIX gets deleted!" ;;
x/usr) abort "Don't set PREFIX to /usr, as \$PREFIX gets deleted!" ;;
*) ;;
esac

case x$USER in
xroot) abort "Don't run all.sh or crosstool.sh as root, it's dangerous" ;;
*) ;;
esac

test -w /tmp || abort "Cannot write to /tmp.  This makes patch and configure scripts unhappy.  Please fix."

# Arbitrary locations for the input and output of the build.
# Change or override these to your taste.
TARBALLS_DIR=${TARBALLS_DIR-$TOP_DIR/tarballs}
RESULT_TOP=${RESULT_TOP-$TOP_DIR/result}
PREFIX=${PREFIX-$RESULT_TOP/$TARGET/$TOOLCOMBO}

export TOOLCOMBO
export PREFIX
export BUILD_DIR
export SRC_DIR
export TARBALLS_DIR
export TOP_DIR

# Download/unpack/patch tarballs, if desired
while [ $# -gt 0 ]; do
    case "$1" in
	--nounpack|-nounpack) 
	   opt_no_unpack=1
	   ;;
	--nobuild|-nobuild) 
	   opt_no_build=1
	   ;;
	--builduserland|-builduserland) 
	   opt_builduserland=1
	   ;;
	--notest|-notest) 
	   opt_no_test=1
	   ;;
	--testlinux|-testlinux) 
	   opt_testlinux=1
	   ;;
	--buildrpm|-buildrpm)
	   opt_buildrpm=1
	   ;;
	*)
	    abort "Usage: all.sh [--nounpack|--nobuild|--testlinux|--builduserland|--notest|--buildrpm]"
    esac
    shift
done

if test "$opt_no_unpack" = ""; then
   if test "$opt_builduserland" = "1"; then
      # Ah, nobody would want to change this :-)
      PTXDIST_DIR=ptxdist-testing-20031113
      export PTXDIST_DIR
   fi
   # Download and patch
   rm -rf $BUILD_DIR; mkdir -p $BUILD_DIR
   sh getandpatch.sh
fi

if test "$opt_no_build" = ""; then
    # Build
    rm  -rf  $PREFIX
    mkdir -p $PREFIX
    mkdir -p $BUILD_DIR
    cd $BUILD_DIR
    if test "${CYGWIN_DIR}" = ""; then
        sh $TOP_DIR/crosstool.sh
    else
        sh ${TOP_DIR}/crosstool-cygwin.sh
    fi
    cd $TOP_DIR

    sh testhello.sh
fi
if test "$opt_testlinux" = "1"; then
    # Build a Linux kernel to see if we can
    sh testlinux.sh
fi

if test "$opt_builduserland" = "1"; then
    # Build /bin/sh and any other non-toolchain things configured in ptx.config
    # Only needed if you can't run the target's normal /bin/sh with the new toolchain
    cd $BUILD_DIR
    sh $TOP_DIR/ptx.sh
fi

if test "$opt_no_test" = ""; then
    # Beefy test that lasts for hours
    cd $BUILD_DIR
    sh $TOP_DIR/crosstest.sh 
fi

if test "$opt_buildrpm" = "1"; then
    # Generate a .spec file in case the user wants to build an RPM
    sh $TOP_DIR/buildrpm.sh
fi
