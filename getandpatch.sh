#!/bin/sh
# Download and unpack gnu toolchain source tarballs, and apply any local patches.
# Local patches are found in subdirectories of patches/ with the same name as the tarball but without .tar.gz
# Copyright 2003 Ixia Communications
# Licensed under the GPL
set -xe

abort() {
	echo $@
	exec /bin/false
}

# Meant to be invoked from another shell script.
# Usage: seven environment variables must be set, namely:
test -z "${BINUTILS_DIR}"     && abort "Please set BINUTILS_DIR to the bare filename of the binutils tarball or directory"
test -z "${SRC_DIR}"          && abort "Please set SRC_DIR to the directory where the source tarballs are to be unpacked"
test -z "${GCC_DIR}"          && abort "Please set GCC_DIR to the bare filename of the gcc tarball or directory"
test -z "${GLIBC_DIR}"        && abort "Please set GLIBC_DIR to the bare filename of the glibc tarball or directory"
test -z "${LINUX_DIR}"        && abort "Please set LINUX_DIR to the bare filename of the kernel tarball or directory"
test -z "${TARBALLS_DIR}"     && abort "Please set TARBALLS_DIR to the directory to download tarballs to."
test -z "${PTXDIST_DIR}"      && abort "Please set PTXDIST_DIR to the bare filename of the ptxdist tarball or directory."

# Make all paths absolute (it's so confusing otherwise)
# FIXME: this doesn't work well with some automounters
SRC_DIR=`cd $SRC_DIR; pwd`

# And one is derived.
GLIBCTHREADS_FILENAME=`echo $GLIBC_DIR | sed 's/glibc-/glibc-linuxthreads-/'`

# Pattern in a patch log to indicate failure
PATCHFAILMSGS="^No file to patch.  Skipping patch.|^Hunk .* FAILED at"

# Download, unpack, and patch the given tarball.
# Assumes that the tarball unpacks to a name guessable from its url,
# and that patches already exist locally in a directory named after the tarball.
getUnpackAndPatch() {
	ARCHIVE_NAME=`echo $1 | sed 's,.*/,,;'`
        BASENAME=`echo $ARCHIVE_NAME | sed 's,\.tar\.gz$,,;s,\.tar\.bz2$,,;'`
	ZIP_METHOD=`echo $ARCHIVE_NAME | sed 's,.*\.tar\.,,;'`

	# Download if not present
	test -d ${SRC_DIR}/$ARCHIVE_NAME && { echo "directory $ARCHIVE_NAME already present"; return 0 ; }
	test -f ${TARBALLS_DIR}/$ARCHIVE_NAME || wget -P ${TARBALLS_DIR} -c $1
	test -f ${TARBALLS_DIR}/$ARCHIVE_NAME || { echo "file $ARCHIVE_NAME not found"; return 1 ; }

	cd $SRC_DIR

	if test $ZIP_METHOD = "gz" ; then
	    tar -xzvf $TARBALLS_DIR/$ARCHIVE_NAME || abort cannot unpack $TARBALLS_DIR/$ARCHIVE_NAME
	elif test $ZIP_METHOD = "bz2"; then
	    tar -xjvf $TARBALLS_DIR/$ARCHIVE_NAME || abort cannot unpack $TARBALLS_DIR/$ARCHIVE_NAME
	else 
	    abort "Bad compress format $ZIP_METHOD for tarball"
	fi

	# Fix path of old linux source trees
	if [ -d linux ]; then
		mv linux $BASENAME
	fi

	# Apply any patches for this component
	# -f is required for patches that delete files, like
	# patches/glibc-2.2.5/hhl-powerpc-fpu.patch,
	# else patch will think the patch is reversed :-(
	# Since -f tells patch to ignore failures, grep log to look for errors
	# use max --fuzz=1 since default fuzz is too dangerous for automation
	cd $BASENAME
	for p in $TOP_DIR/patches/$BASENAME/*patch* \
		 $TOP_DIR/patches/$BASENAME/*.diff; do
	    if test -f $p; then
	        patch --fuzz=1 -p1 -f < $p > patch$$.log 2>&1 || { cat patch$$.log ; abort "patch $p failed" ; }
		cat patch$$.log
		egrep -q "$PATCHFAILMSGS" patch$$.log && abort "patch $p failed"
		rm -f patch$$.log
	    fi
	done
}

# Special version for glibc addons.  Only very slightly different.
getGlibcAddon() {
	ARCHIVE_NAME=`echo $1 | sed 's,.*/,,;'`
        BASENAME=`echo $ARCHIVE_NAME | sed 's,\.tar\.gz$,,;s,\.tar\.bz2$,,;'`
	ZIP_METHOD=`echo $ARCHIVE_NAME | sed 's,.*\.tar\.,,;'`

	# Download if not present
	test -d ${SRC_DIR}/$ARCHIVE_NAME && { echo "directory $ARCHIVE_NAME already present"; return 0 ; }
	test -f ${TARBALLS_DIR}/$ARCHIVE_NAME || wget -P ${TARBALLS_DIR} -c $1
	test -f ${TARBALLS_DIR}/$ARCHIVE_NAME || { echo "file $ARCHIVE_NAME not found"; return 1 ; }

	cd $SRC_DIR/$GLIBC_DIR

	if test $ZIP_METHOD = "gz" ; then
	    tar -xzvf $TARBALLS_DIR/$ARCHIVE_NAME || abort cannot unpack $TARBALLS_DIR/$ARCHIVE_NAME
	elif test $ZIP_METHOD = "bz2"; then
	    tar -xjvf $TARBALLS_DIR/$ARCHIVE_NAME || abort cannot unpack $TARBALLS_DIR/$ARCHIVE_NAME
	else
	    abort "Bad compress format $ZIP_METHOD for patch"
	fi

	# Apply any patches for this component
	# -f is required for patches that delete files, like
	# patches/glibc-2.2.5/hhl-powerpc-fpu.patch,
	# else patch will think the patch is reversed :-(
	# Since -f tells patch to ignore failures, grep log to look for errors
	# use max --fuzz=1 since default fuzz is too dangerous for automation
	for p in $TOP_DIR/patches/$BASENAME/*patch* \
		 $TOP_DIR/patches/$BASENAME/*.diff; do
	    if test -f $p; then
	        patch --fuzz=1 -p1 -f < $p > patch$$.log 2>&1 || { cat patch$$.log ; abort "patch $p failed" ; }
		cat patch$$.log
		egrep -q "$PATCHFAILMSGS" patch$$.log && abort "patch $p failed"
		rm -f patch$$.log
	    fi
	done
}

# Remember where source is.
TOP_DIR=${TOP_DIR-`pwd`}

mkdir -p $SRC_DIR $TARBALLS_DIR

# Download, unpack, and patch all the needed source tarballs,

# even if we're not building userland, let's grab it...
getUnpackAndPatch http://www.kegel.com/crosstool/$PTXDIST_DIR.tar.gz || getUnpackAndPatch http://www.pengutronix.de/software/ptxdist/$PTXDIST_DIR.tgz

getUnpackAndPatch $BINUTILS_URL/$BINUTILS_DIR.tar.bz2 || getUnpackAndPatch $BINUTILS_URL/$BINUTILS_DIR.tar.gz
case $GCC_DIR in
   gcc-3.3.3-2004*)
      dir=`echo $GCC_DIR | sed s/gcc-/prerelease-/`
      getUnpackAndPatch ftp://gcc.gnu.org/pub/gcc/$dir/$GCC_DIR.tar.gz ;;
   gcc-3.3-200*|gcc-3.4-200*)
      dir=`echo $GCC_DIR | sed 's/gcc-//'`
      getUnpackAndPatch ftp://gcc.gnu.org/pub/gcc/snapshots/$dir/$GCC_DIR.tar.bz2 ;;
   gcc-3.3.2-*)
      getUnpackAndPatch ftp://ftp.gnu.org/pub/gnu/gcc/$GCC_DIR.tar.bz2 ;;
   *)
      getUnpackAndPatch ftp://ftp.gnu.org/pub/gnu/gcc/$GCC_DIR.tar.gz ;;
esac
getUnpackAndPatch ftp://ftp.gnu.org/pub/gnu/glibc/$GLIBC_DIR.tar.bz2 || getUnpackAndPatch ftp://ftp.gnu.org/pub/gnu/glibc/$GLIBC_DIR.tar.gz
case $LINUX_DIR in
  *2.4*) getUnpackAndPatch http://www.kernel.org/pub/linux/kernel/v2.4/$LINUX_DIR.tar.bz2 || getUnpackAndPatch http://www.kernel.org/pub/linux/kernel/v2.4/$LINUX_DIR.tar.gz ;;
  *2.6*) getUnpackAndPatch http://www.kernel.org/pub/linux/kernel/v2.6/$LINUX_DIR.tar.bz2 || getUnpackAndPatch http://www.kernel.org/pub/linux/kernel/v2.6/$LINUX_DIR.tar.gz ;;
  *) abort "unknown version $LINUX_DIR of linux, expected 2.4 or 2.6 in name?" ;;
esac
# Glibc addons must come after glibc
getGlibcAddon     ftp://ftp.gnu.org/pub/gnu/glibc/$GLIBCTHREADS_FILENAME.tar.bz2 || getGlibcAddon ftp://ftp.gnu.org/pub/gnu/glibc/$GLIBCTHREADS_FILENAME.tar.gz
test x$GLIBCCRYPT_FILENAME = x || getGlibcAddon     ftp://ftp.gnu.org/pub/gnu/glibc/$GLIBCCRYPT_FILENAME.tar.gz || getGlibcAddon ftp://ftp.gnu.org/pub/gnu/glibc/$GLIBCCRYPT_FILENAME.tar.bz22

# gcc's contrib/test_summary expects version stamp, normally created by contrib/update_gcc
test -f $SRC_DIR/$GCC_DIR/LAST_UPDATED || echo $GCC_DIR > $SRC_DIR/$GCC_DIR/LAST_UPDATED

# binutils-2.14.90.0.3 and up want you to apply a patch
if grep -q "/bin/sh patches/README" $SRC_DIR/$BINUTILS_DIR/patches/README; then
  if '!' test -f $SRC_DIR/$BINUTILS_DIR/patches/README.done; then
    cd $SRC_DIR/$BINUTILS_DIR
    /bin/sh patches/README
    touch patches/README.done
  fi
fi
