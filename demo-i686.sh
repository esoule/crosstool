#!/bin/sh
set -ex
TARBALLS_DIR=$HOME/downloads
RESULT_TOP=/opt/crosstool
export TARBALLS_DIR RESULT_TOP
GCC_LANGUAGES="c,c++"
export GCC_LANGUAGES

# Really, you should do the mkdir before running this,
# and chown /opt/crosstool to yourself so you don't need to run as root.
mkdir -p $RESULT_TOP

# Build the toolchain.  Takes a couple hours and a couple gigabytes.
#
#eval `cat i686.dat gcc-2.95.3-glibc-2.1.3.dat` sh all.sh --notest
#eval `cat i686.dat gcc-2.95.3-glibc-2.2.2.dat` sh all.sh --notest --gdb
#eval `cat i686.dat gcc-3.2.3-glibc-2.2.5.dat`  sh all.sh --notest --nounpack
#eval `cat i686.dat gcc-3.3-20040630-glibc-2.1.3.dat`  sh all.sh --notest 
#eval `cat i686.dat gcc-3.3-20040630-glibc-2.2.5.dat`  sh all.sh --notest 
#eval `cat i686.dat gcc-3.3-20040630-glibc-2.3.2.dat`  sh all.sh --notest 
#eval `cat i686.dat gcc-3.3.3-glibc-2.1.3.dat`  sh all.sh --notest 
#eval `cat i686.dat gcc-3.3.3-glibc-2.2.5.dat`  sh all.sh --notest 
#eval `cat i686.dat gcc-3.3.3-glibc-2.3.2.dat`  sh all.sh --notest 
#eval `cat i686.dat gcc-3.3.4-glibc-2.1.3.dat`  sh all.sh --notest
#eval `cat i686.dat gcc-3.3.4-glibc-2.2.5.dat`  sh all.sh --notest 
#eval `cat i686.dat gcc-3.3.4-glibc-2.3.2.dat`  sh all.sh --notest 
 eval `cat i686.dat gcc-3.3.4-glibc-2.3.3.dat`  sh all.sh --notest
#eval `cat i686.dat gcc-3.3.5-glibc-2.3.2.dat`  sh all.sh --notest 
#eval `cat i686.dat gcc-3.4.0-glibc-2.1.3.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.0-glibc-2.2.5.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.0-glibc-2.3.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.1-glibc-2.1.3.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.1-glibc-2.2.5.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.1-glibc-2.3.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.1-glibc-2.3.3.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.1-glibc-20040827.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.2-20040829-glibc-2.3.3.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.2-glibc-2.3.3.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.3-glibc-2.2.2-hdrs-2.6.11.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.3-glibc-2.2.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.3-glibc-2.2.5.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.3-glibc-2.3.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.3-glibc-2.3.3.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.3-glibc-2.3.4.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.3-glibc-2.3.5-hdrs-2.6.11.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.3-glibc-2.3.5.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.4.4-glibc-2.3.2-hdrs-2.6.11.2.dat` sh all.sh --notest
#eval `cat i686-static.dat gcc-3.4.4-glibc-2.2.2-hdrs-2.6.11.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-4.0.0-glibc-2.2.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-4.0.0-glibc-2.2.5.dat` sh all.sh --notest
#eval `cat i686.dat gcc-4.0.0-glibc-2.3-20050307.dat` sh all.sh --notest
#eval `cat i686.dat gcc-4.0.0-glibc-2.3.3.dat` sh all.sh --notest
#eval `cat i686.dat gcc-4.0.0-glibc-2.3.4.dat` sh all.sh --notest
#eval `cat i686.dat gcc-4.0.0-glibc-2.3.5-hdrs-2.6.11.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-4.0.1-glibc-2.2.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-4.0.1-glibc-2.3.2-hdrs-2.6.11.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-4.0.2-glibc-2.3.2-hdrs-2.6.11.2.dat` sh all.sh --notest
#eval `cat i686.dat gcc-4.1-20050716-glibc-2.3.2-hdrs-2.6.11.2.dat` sh all.sh --notest --testlinux
#eval `cat i686.dat gcc-4.1-20060210-glibc-2.2.2-hdrs-2.6.11.2.dat` sh all.sh --notest --testlinux

echo Done.
