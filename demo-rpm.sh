#!/bin/sh
set -ex

TARBALLS_DIR=$HOME/downloads
TIPPY_TOP=/opt/crosstool    

if test ! -w $TIPPY_TOP; then
    echo "Cannot write to $TIPPY_TOP.  This makes it hard to install stuff there :-)"
    exit 1
fi
# Clear a few variables known to cause problems if set randomly
unset PREFIX

GNU_BUILD=`./config.guess`
if test x$GNU_BUILD = x; then echo "config.guess broken?"; exit 1; fi
RESULT_TOP=$TIPPY_TOP/$GNU_BUILD
export RESULT_TOP TARBALLS_DIR
GCC_LANGUAGES="c,c++"
export GCC_LANGUAGES

# Build distcc.
 sh mkdistcc.sh --buildrpm

# Build all the compilers you want your compile cluster to support.
# Note: adding --nounpack --nobuild will let you build RPMs after the fact,
# which is quite handy for debugging the spec file!
 eval `cat i686.dat gcc-2.95.3-glibc-2.1.3.dat`   sh all.sh --notest --buildrpm
#eval `cat i686.dat gcc-3.4.1-glibc-2.1.3.dat`    sh all.sh --notest --buildrpm
#eval `cat x86_64.dat gcc-3.4.1-glibc-2.3.2.dat`  sh all.sh --notest --buildrpm

echo Done.  Result:
ls -l build/distcc*/RPMS/*.rpm build/*/*/RPMS/*.rpm
