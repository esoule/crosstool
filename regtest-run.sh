#!/bin/sh
# Simple parallelized way to test building a given crosstool tarball
# on a bunch of machines connected via ssh 
# No NFS needed
# Copyright (C) 2005, Dan Kegel, Google
# License: GPL
#
# Requires that you have already used ssh-keygen, ssh-agent, ssh-add, etc. 
# to set up a no-prompt way of using ssh to run remote commands
# Creates $HOME/crosstooltest and $HOME/downloads on all machines
# Accumulates results in directory 'jobdir' on current machine
# Run regtest-report.sh afterwards to generate nice HTML matrix of build results

set -x

# Run this command as 'nohup ssh-agent sh crosstool-0.30/regtest-run.sh'
ssh-add

rm -rf jobdir
mkdir jobdir

# Which version of crosstool to test
CROSSTOOL=crosstool-0.30

# Edit this line to specify the hosts to run the script on
ALLNODES="k8 fast fast2 dual2"

WORKDIR=`pwd`

# Edit this line to specify which toolchain combos to build
TOOLS="\
gcc-2.95.3-glibc-2.1.3 \
gcc-2.95.3-glibc-2.2.5 \
gcc-3.3.4-glibc-2.2.5 \
gcc-3.3.4-glibc-2.3.2 \
gcc-3.3.4-glibc-2.3.3 \
gcc-3.4.2-glibc-2.2.5 \
gcc-3.4.2-glibc-2.3.3 \
gcc-4.0-20050305-glibc-2.2.5 \
gcc-4.0-20050305-glibc-2.3-20050307 \
gcc-4.0-20050305-glibc-2.3.3 \
gcc-4.0-20050305-glibc-2.3.4 \
"

# Edit this line to specify which CPUs to build for
CPUS="\
alpha \
arm-iwmmxt \
arm-softfloat \
arm-xscale \
arm \
arm9tdmi \
armeb \
armv5b-softfloat \
i686 \
ia64 \
m68k \
mips \
mipsel \
powerpc-405 \
powerpc-440 \
powerpc-604 \
powerpc-7450 \
powerpc-750 \
powerpc-860 \
powerpc-970 \
s390 \
sh3 \
sh4 \
sparc \
sparc64 \
x86_64 \
"

for cpu in $CPUS; do
   for toolcombo in $TOOLS; do
       cat > jobdir/$cpu-$toolcombo.sh <<_EOF_
set -x
cd $CROSSTOOL
TARBALLS_DIR=$HOME/downloads
export TARBALLS_DIR
RESULT_TOP=$HOME/crosstooltest
export RESULT_TOP
GCC_LANGUAGES=c,c++
export GCC_LANGUAGES
QUIET_EXTRACTIONS=1
export QUIET_EXTRACTIONS
mkdir -p \$RESULT_TOP
if  awk '/bogomips/ {n++}; END {print n}' < /proc/cpuinfo > cpus; then
	PARALLELMFLAGS=-j\`cat cpus\`
	export PARALLELMFLAGS
fi
rm -rf build
time eval \`cat $cpu.dat $toolcombo.dat\` sh all.sh --notest --testlinux
df
_EOF_
   done
done

# usage: runjobs node tarball
# Unpacks the given tarball on the remote node, then runs jobs on the given node until none are left
# Should work whether or not the nodes share a common filesystem
runjobs() {
    if test $# != 2; then
        echo "usage: runjobs node tarball"
        exec /bin/false
    fi
    node=$1
    tarball=$2
    NODEDIR=$WORKDIR/jobdir.$node
    ssh -n -x -T $node "rm -rf $NODEDIR; mkdir -p $NODEDIR"
    scp $tarball ${node}:$NODEDIR
    ssh -n -x -T $node "cd $NODEDIR; tar -xzvf $tarball"
    cd jobdir
    while jobs=`ls *.sh`; do
	set $jobs
	job=$1
	if mv $job $job.$node.running; then
	    echo Starting job $job on node $node
	    echo Starting job $job on node $node > $job.log
	    scp $job.$node.running ${node}:$NODEDIR
	    time ssh -n -x -T $node "cd $NODEDIR; sh $job.$node.running" >> $job.log 2>&1  || true
	    echo Finished job $job on node $node
	    echo Finished job $job on node $node >> $job.log
	    mv $job.$node.running $job.ran
	else
	    echo curses, foiled again
	    sleep 1
	fi
    done
}

for NODE in $ALLNODES; do
	runjobs $NODE $CROSSTOOL.tar.gz > $NODE.log 2>&1 &
done

time while ls jobdir/*.sh || ls jobdir/*.running; do
	sleep 10
done
wait

echo "all jobs done."
ls -l jobdir

