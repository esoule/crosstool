#!/bin/sh

RESULT_TOP=/opt/cegl-2.0
export RESULT_TOP
TARBALLS_DIR=${HOME}/ixia_tarballs
export TARBALLS_DIR
#export TARGET=powerpc-405-linux-gnu
export TARGET=powerpc-750-linux-gnu
#export TARGET=sh4-unknown-linux-gnu
#export GCC_DIR=gcc-3.3.1
export GCC_DIR=gcc-2.95.3
#export GLIBC_DIR=glibc-2.3.2
export GLIBC_DIR=glibc-2.2.2
#export GLIBC_DIR=glibc-2.2.5
sh ptx.sh
