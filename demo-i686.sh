#!/bin/sh
set -ex
export TARBALLS_DIR=~/downloads
export RESULT_TOP=/opt/crosstool

# Really, you should do the mkdir before running this,
# and chown /opt/crosstool to yourself so you don't need to run as root.
mkdir -p /opt/crosstool

# Build the toolchain.  Takes a couple hours and a couple gigabytes.
#eval `cat i686.dat gcc-2.95.3-glibc-2.1.3.dat` sh all.sh --notest
#eval `cat i686.dat gcc-3.2.3-glibc-2.2.5.dat` sh all.sh --notest 
eval `cat i686.dat gcc-3.3.2-glibc-2.3.2.dat` sh all.sh --notest 

#eval `cat i686.dat gcc-3.3-20040105-glibc-2.3.2.dat` sh all.sh --notest

echo Done.
