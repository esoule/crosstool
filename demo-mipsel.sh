#!/bin/sh
set -ex
# Create a toolchain for the Linksys wrt54g
# See http://seattlewireless.net/index.cgi/LinksysWrt54g
#     http://www.batbox.org/wrt54g-linux.html
# Note: recent wrt54g firmware contains a subsetted glibc;
# see http://www.linuxdevices.com/articles/AT9220599952.html for
# how they probably did it.
# This means you'll either have to 
#  a) not call the missing functions,
#  b) use a stub library like http://www.xse.com/leres/tivo/downloads/libtivohack/
# or c) link your programs statically if you want them to run on
# the wrt54g.

export TARBALLS_DIR=~/tarballs
export RESULT_TOP=/opt/crosstool

# Really, you should do the mkdir before running this,
# and chown /opt/crosstool to yourself so you don't need to run as root.
mkdir -p /opt/crosstool

# Build the toolchain.  Takes a couple hours and a couple gigabytes.
eval `cat mipsel.dat gcc-3.2.3-glibc-2.2.3.dat` sh all.sh --notest

echo Done.
