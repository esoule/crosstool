#!/bin/sh
set -xe
mkdir -p result/dejagnu
PREFIX=`pwd`/result/dejagnu
wget -c http://mirrors.usc.edu/pub/gnu/dejagnu/dejagnu-1.4.3.tar.gz
# FIXME: use same tarball directory as crosstool.sh
tar -xzvf dejagnu-1.4.3.tar.gz
cd dejagnu-1.4.3
for a in ../patches/dejagnu-1.4.3/*.patch; do
	patch -p1 < $a
done
./configure --prefix=$PREFIX
make
make install
