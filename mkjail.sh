#!/bin/sh
# Create a tarball containing the shared libraries and executables from gcc/glibc
# (but not any shared libraries or executables that are otherwise crucial for a chroot jail).
# After this finishes, transfer jail.tar.gz and initjail.sh to the target, then
# run initjail.sh and tell it where you'd like the jail; it will unpack this tarball
# and complete the jail.

abort() {
    echo $@
    exec /bin/false
}
set -x
test $# -ge 2 || abort "Usage: $0 PREFIX ETCPASSWD [PREFIX2], where PREFIX/lib/libc.so.* is the C library to grab, ETCPASSWD is the passwd file to use in the jail, and PREFIX2/bin contains busybox"
test -d "$1" || abort "Error: $1 is not a directory"
test -f "$2" || abort "Error: $2 is not a file"
if test $# -eq 3; then
   test -d "$3" && PREFIX2=`cd $3; pwd` || abort "Error: $3 is not a directory"
fi
PREFIX=`cd $1; pwd`

echo $PREFIX/lib/libc.so.* | grep -q '\*' && abort "Couldn't find $PREFIX/lib/libc.so.*"
STRIPDIR=`cd $PREFIX/../bin; pwd`
STRIP=`echo $STRIPDIR/*-strip`
test -x "$STRIP" || abort "Error: $STRIP not executable"
set -e -x

ORIGDIR=`pwd`
WORKDIR=/tmp/mkjail.$$.tmp
rm -rf $WORKDIR
mkdir $WORKDIR
mkdir $WORKDIR/etc
cp $2 $WORKDIR/etc/passwd
cd $WORKDIR
mkdir bin dev home lib opt proc sbin tmp usr var
mkdir usr/bin usr/sbin usr/lib
cd $PREFIX

for lib in \
 ld libBrokenLocale libSegFault libanl libc libcrypt libdl libgcc_s libgcc_s_nof libm \
 libmemusage libnsl libnss_compat libnss_dns libnss_files libnss_hesiod libnss_nis \
 libnss_nisplus libpcprofile libpthread libresolv librt libstdc++ libthread_db libutil; do
	ls     lib/$lib[-.]*so* || /bin/true
	ls usr/lib/$lib[-.]*so* || /bin/true
done 2> /dev/null | cpio -pvm $WORKDIR

for prog in \
 ldconfig ldd catchsegv; do
	ls      bin/$prog || /bin/true
	ls  usr/bin/$prog || /bin/true
	ls     sbin/$prog || /bin/true
	ls usr/sbin/$prog || /bin/true
done 2> /dev/null |  cpio -pvm $WORKDIR

if test "$PREFIX2" != ""; then
	cd $PREFIX2
	for prog in \
	 busybox; do
		ls      bin/$prog || /bin/true
		ls  usr/bin/$prog || /bin/true
		ls     sbin/$prog || /bin/true
		ls usr/sbin/$prog || /bin/true
	done 2> /dev/null |  cpio -pvm $WORKDIR
fi

cd $WORKDIR

# Strip all the shared libraries that aren't just ascii files or symlinks
find $WORKDIR -type f -name '*.so*' -size +1k | xargs $STRIP

tar -czf $ORIGDIR/jail.tar.gz *
rm -rf $WORKDIR

echo Done.  Result in $ORIGDIR/jail.tar.gz
