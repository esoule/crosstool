#!/bin/sh
set -ex
export TARBALLS_DIR=~/downloads
export RESULT_TOP=/opt/crosstool

# Really, you should do the mkdir before running this,
# and chown /opt/crosstool to yourself so you don't need to run as root.
mkdir -p /opt/crosstool

# Build the toolchain.  Takes a couple hours and a couple gigabytes.
eval `cat sh4.dat gcc-3.3-20040126-glibc-2.3.2.dat` sh all.sh --nounpack --nobuild

echo Done.
