#!/bin/sh
set -ex
export TARBALLS_DIR=~/downloads

# To use all.sh, just set the eight or nine environment variables it wants, then run it.
# Or better yet, read it, understand it, and *then* run it.
# See also doc/crosstool-howto.html
# Options to all.sh:
# --nounpack avoids unpacking the source tarballs and re-configuring; useful for quick redos.
# --nobuild  avoids building; useful if you just want to unpack sources or rerun regression tests.
# --notest   avoids running regression tests; they're hard to set up, so this is recommended when starting.
#
# Here's a demo for the impatient, showing all the configurations I've tested.
# It uses eval so it can store some of the environment variables in a file.
# If you don't like eval, you can set the environment variables some other way.
# Uncomment the one(s) you want to build, and comment out the others.
# Once that works, please try running the regression test by removing the --notest arg
# and setting up a chroot environment as described in doc/crosstool-howto.html.
# Total disk requirement: about 1.5GB per toolchain.
#
# This demo can build various toolchains for eleven processors: 
# alpha, arm, cris, i686, ia64, m68k, mips, powerpc750, powerpc405, sh4, and sparc.
# It can almost, but not quite, build toolchains for three processors:
# hppa, s390 and x86_64.
#

if false; then
# Alpha
# Can't build glibc-2.95.3 for alpha yet; it fails with
#  build/alpha-unknown-linux-gnu/gcc-2.95.3-glibc-2.2.2/gcc-2.95.3/gcc/libgcc-2.c: In function `__muldi3':
#  libgcc-2.c:298: Internal compiler error in `expand_assignment', at expr.c:3393
# Can't build glibc-2.2.5 with gcc-3.3 for alpha yet; it fails with
#  internals.h:381: error: asm-specifier for variable `__self' conflicts with asm clobber list
#  make[2]: *** [alpha-unknown-linux-gnu/gcc-3.3-glibc-2.2.5/build-glibc/linuxthreads/attr.o] Error 1
#
# Can't build glibc-2.3.2+gcc-3.3 or later with binutils-2.14.90.* for alpha; it fails with
# linuxthreads/sysdeps/unix/sysv/linux/alpha/vfork.S:63: Warning: .ent directive without matching .end
# linuxthreads/sysdeps/unix/sysv/linux/alpha/vfork.S:63: Error: can't resolve `0' {.text section} - `L0
# make[2]: *** [/home/dank/crosstool-0.27/build/alpha-unknown-linux-gnu/gcc-3.3-glibc-2.3.2/build-glibc/posix/vfork.o] Error 1

#eval `cat alpha.dat gcc-3.3.2-glibc-2.3.2.dat`    sh all.sh --notest
#eval `cat alpha.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest
#eval `cat alpha.dat gcc-3.3-20040126-glibc-2.3.2.dat`    sh all.sh --notest
#
# Following combinations seem to build, though:
#eval `cat alpha.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest
#eval `cat alpha.dat gcc-3.3-glibc-2.3.2.dat`    sh all.sh --notest
#eval `cat alpha.dat gcc-3.3.1-glibc-2.3.2.dat`    sh all.sh --notest
#eval `cat alpha.dat gcc-3.3.2-glibc-2.3.2.dat`    sh all.sh --notest
eval `cat alpha.dat gcc-3.3.3-20040131-glibc-2.3.2.dat`    sh all.sh --notest

# Arm 
# Worked earlier, have not yet verified in 0.26-pre3
#eval `cat arm.dat gcc-3.3-glibc-2.2.5.dat`    sh all.sh --notest
#eval `cat arm.dat gcc-3.3-glibc-2.3.2.dat`    sh all.sh --notest
#eval `cat arm.dat gcc-3.3.1-glibc-2.3.2.dat`  sh all.sh --notest
eval `cat arm.dat gcc-3.3.2-glibc-2.3.2.dat`  sh all.sh --notest
eval `cat arm.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --notest
eval `cat arm.dat gcc-3.3.3-20040131-glibc-2.3.2.dat`    sh all.sh --notest
# build verified 0.26-pre3
#  eval `cat arm.dat gcc-2.95.3-glibc-2.2.2.dat` sh all.sh --notest
   eval `cat arm.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest
#  eval `cat arm.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest

# Arm9tdmi
# Worked earlier, have not yet verified in 0.26-pre3
#eval `cat arm9tdmi.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest
#eval `cat arm9tdmi.dat gcc-3.2.3-glibc-2.3.2.dat`  sh all.sh --notest

# Cris
# Worked earlier, have not yet verified in 0.26-pre3
#eval `cat cris.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest
# cris doesn't build with glibc-2.3.2;
# fails with "errno-loc.c:39: error: `pthread_descr' undeclared" in glibc build.
# The cris glibc maintainer is aware of the problem and is looking at a fix.
#eval `cat cris.dat gcc-3.3-glibc-2.3.2.dat`  sh all.sh --notest
#eval `cat cris.dat gcc-3.3.1-glibc-2.3.2.dat` sh all.sh --notest

# i686 / Pentium
# Worked earlier, have not yet verified in 0.26-pre3
#eval `cat i686.dat gcc-3.3-glibc-2.2.5.dat`    sh all.sh --notest
#eval `cat i686.dat gcc-3.3-glibc-2.3.2.dat`    sh all.sh --notest
eval `cat i686.dat gcc-3.3.2-glibc-2.3.2.dat`  sh all.sh --notest
eval `cat i686.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --notest
# build verified 0.26-pre3
#eval `cat i686.dat gcc-2.95.3-glibc-2.2.2.dat` sh all.sh --notest
eval `cat i686.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest
#eval `cat i686.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest


# ia64 / Itanic
# Worked earlier, have not yet verified in 0.26-pre3
eval `cat ia64.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest
#eval `cat ia64.dat gcc-3.3-glibc-2.3.2.dat`    sh all.sh --notest
eval `cat ia64.dat gcc-3.3.2-glibc-2.3.2.dat`  sh all.sh --notest
eval `cat ia64.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --notest
# build verified 0.26-pre3
#eval `cat ia64.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest

fi

# m68k (680x0)
# Worked earlier, have not yet verified in 0.26-pre3
#eval `cat m68k.dat gcc-3.3-glibc-2.3.2.dat`    sh all.sh --notest
eval `cat m68k.dat gcc-3.3.2-glibc-2.3.2.dat`  sh all.sh --notest
eval `cat m68k.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --notest
# build verified 0.26-pre3
#eval `cat m68k.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest

# Mips
# Worked earlier, have not yet verified in 0.26-pre3
eval `cat mipsel.dat gcc-3.2.3-glibc-2.2.5.dat` sh all.sh --notest
#eval `cat mipsel.dat gcc-3.3-glibc-2.3.2.dat`   sh all.sh --notest
eval `cat mipsel.dat gcc-3.3.2-glibc-2.3.2.dat` sh all.sh --notest
eval `cat mipsel.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --notest
# build verified 0.26-pre3
#eval `cat mipsel.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest

# PPC
# note: must call target powerpc rather than ppc if you want to run testcases

# PPC 405
eval `cat powerpc-405.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest
#eval `cat powerpc-405.dat gcc-3.3-glibc-2.2.5.dat`    sh all.sh --notest
#eval `cat powerpc-405.dat gcc-3.3-glibc-2.3.2.dat`    sh all.sh --notest
eval `cat powerpc-405.dat gcc-3.3.2-glibc-2.3.2.dat`  sh all.sh --notest
eval `cat powerpc-405.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --notest
# build verified 0.26-pre3
#eval `cat powerpc-405.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest

# PPC 750
#eval `cat powerpc-750.dat gcc-2.95.3-glibc-2.2.2.dat` sh all.sh --notest
eval `cat powerpc-750.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest
#eval `cat powerpc-750.dat gcc-3.3-glibc-2.2.5.dat`    sh all.sh --notest
#eval `cat powerpc-750.dat gcc-3.3-glibc-2.3.2.dat`    sh all.sh --notest
#eval `cat powerpc-750.dat gcc-3.3.1-glibc-2.3.2.dat`  sh all.sh --notest
eval `cat powerpc-750.dat gcc-3.3.2-glibc-2.3.2.dat`  sh all.sh --notest
eval `cat powerpc-750.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --notest
#eval  `cat powerpc-750.dat gcc-3.4-20030813-glibc-2.3.2.dat`  sh all.sh --notest
# build verified 0.26-pre3
#eval `cat powerpc-750.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest

# SH-4
# note: binutils < 2.13 doesn't know about sh4, so don't try building gcc-2.95
# note: gcc-3.2.3 has ICE compiling glibc for sh4 (http://gcc.gnu.org/PR6954), so don't try building gcc-3.2.3
#eval `cat sh4.dat gcc-3.3-glibc-2.2.5.dat`    sh all.sh --notest
#eval `cat sh4.dat gcc-3.3-glibc-2.3.2.dat`    sh all.sh --notest 
eval `cat sh4.dat gcc-3.3.2-glibc-2.3.2.dat`  sh all.sh --notest 
eval `cat sh4.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --notest
# build verified 0.26-pre3
# eval `cat sh4.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest

# Sparc
#eval `cat sparc.dat gcc-2.95.3-glibc-2.2.2.dat` sh all.sh --notest
eval `cat sparc.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest
#eval `cat sparc.dat gcc-3.3-glibc-2.2.5.dat`    sh all.sh --notest
#eval `cat sparc.dat gcc-3.3-glibc-2.3.2.dat`    sh all.sh --notest
eval `cat sparc.dat gcc-3.3.2-glibc-2.3.2.dat`  sh all.sh --notest
#eval `cat sparc.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest
eval `cat sparc.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --notest

# x86_64 / AMD64 / Opteron / Hammer
# build verified 0.26-pre3
#eval `cat x86_64.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest
eval `cat x86_64.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --notest

#--------- Fully broken arches below ----------

# HP-PA / parisc
# Not yet supported by glibc.
# If you want to compile it, you'll need the experimental patches described at
# http://lists.debian.org/debian-glibc/2003/debian-glibc-200303/msg00472.html
# See patches/glibc-2.3.2/README-hppa
#eval `cat hppa.dat gcc-3.3-glibc-2.3.2.dat`  sh all.sh --notest
# Fails with error "errno-loc.c:39: error: `pthread_descr' undeclared" when building glibc.
#eval `cat hppa.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest

# s390
# fails with "soinit.c:25: internal compiler error: in named_section_flags, at varasm.c:412"
# see http://gcc.gnu.org/PR9552
#eval `cat s390.dat gcc-3.3-glibc-2.3.2.dat`    sh all.sh --notest
# fails with "chown.c:65: `__libc_missing_32bit_uids' undeclared"
# maybe there's a patch for this in Debian's glibc combo patch,
# http://security.debian.org/debian-security/pool/updates/main/g/glibc/glibc_2.2.5-11.5.diff.gz
#eval `cat s390.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest
#eval `cat s390.dat gcc-3.3-20040112-glibc-2.3.2.dat` sh all.sh --notest

