#!/bin/sh
# Script to create a distcc masquerade directory for all cross-compilers
# installed by crosstool.
# If you move the crosstool hierarchy after installation, you must rerun 
# this script after the copy.
# Run this from the directory you installed the toolchain to (not a subdirectory).
# (It will tell you if you run it from the wrong place.)

set -e

abort() {
    echo $@
    exec false
}

# Make distcc masquerade directory for a particular toolchain
# On entry, `pwd` is top of that toolchain, and TARGET is set
masq_one_toolchain() {
  ABSBIN="`pwd`/bin"
  # No gcc?  OK, just skip that directory.  Must be garbage left over from an uninstall?
  test -x $ABSBIN/$TARGET-gcc || return 0

  # Get list of executables to run via distcc
  # This is a bit messy, since executables in Cygwin usually end in .exe, yet
  # gcc's Makefile installs the versioned gcc executable without .exe  
  DISTRIB_APPS=`cd bin; find . -type f -perm -100 -name "$TARGET-c++$EXEEXT" -o -name "$TARGET-g++$EXEEXT" -o -name "$TARGET-gcc$EXEEXT" -o -name "$TARGET-gcc-[0-9]*[0-9]"  -o -name "$TARGET-gcc-[0-9]*[0-9]$EXEEXT"`

  echo ""
  echo masq_one_toolchain:
  echo TARGET is $TARGET
  echo ABSBIN is $ABSBIN
  echo DISTRIB_APPS is $DISTRIB_APPS
  
  rm -rf distributed
  mkdir distributed
  cd distributed

  # Make symlinks to all subdirs of real directory
  ln -s ../* .
  # but remove symlinks to special cases
  rm bin distributed
  mkdir bin

  # Make symlinks to all apps in real bin
  cd bin
  for app in `cd ../../bin; ls`; do
      ln -s ../../bin/$app .
  done
  # but remove symlinks to special cases
  rm $DISTRIB_APPS

  # and create shell scripts for the special cases
  for app in $DISTRIB_APPS; do
    if test x$EXEEXT != x; then
      # shell scripts must not end in $EXEEXT in Windows
      # else they are misinterpreted in an amusing and fatal way
      app=`echo $app | sed "s/$EXEEXT//"`
    fi
    # canonicalize path by getting rid of extra ./ by find .
    app=`echo $app | sed "s,^\./,,g"`
    cat > $app <<_EOF_
#!/bin/sh
$ABSDISTCC $ABSBIN/$app "\$@"
_EOF_
    chmod 755 $app 
    # Update master list of remote-runnable apps
    echo $ABSBIN/$app >> $ABSAPPS
  done
  cd ../..

}

ABSTOP=`pwd`

ABSDISTCC=$ABSTOP/common/bin/distcc
test -f $ABSDISTCC || abort "Please run this script at the top of the crosstool result hierarchy."

# demo-cluster.sh installs each toolchain in a directory named after the GNU host that will run the compiler
GNU_HOST=`basename $ABSTOP`
# but if that convention isn't followed, just assume the current machine type will run the compiler
case $GNU_HOST in
*-*-*-*) ;;
*) GNU_HOST=`sh $ABSTOP/common/bin/config.guess`
esac

# Create master list of remote-runnable apps
mkdir -p common/etc/distcc
chmod 755 common/etc/distcc
ABSAPPS=$ABSTOP/common/etc/distcc/apps
test -f $ABSAPPS && rm -f $ABSAPPS 
touch $ABSAPPS && chmod 644 $ABSAPPS 

# On Cygwin, to rm an app, must use .exe suffix!
case $GNU_HOST in
  *cygwin*) EXEEXT=".exe" ;;
  *)        EXEEXT=""
esac

# Iterate through all the toolchains
# but ignore toolchains which are just symlinks
for TARGET in *-*-*-*; do
  if test ! -h $TARGET; then
    cd $TARGET
    for TOOLCOMBO in gcc*-*; do
      if test -d $TOOLCOMBO && test ! -h $TOOLCOMBO; then
	olddir="`pwd`"
	cd $TOOLCOMBO
	masq_one_toolchain
	cd $olddir
      fi
    done
    cd ..
  fi
done

# mkdistcc.sh already installs common/etc/crosstool-distccd-*.sh.in
# as templates ready to be expanded.
# Now create script common/bin/install-distccd.sh that takes that
# template and installs it as a service.

case $GNU_HOST in
  *linux*)
cat > common/bin/install-distccd.sh <<_EOF_
#!/bin/sh
sed "s,__ABSTOP__,${ABSTOP}," < $ABSTOP/common/etc/crosstool-distccd-linux.sh.in > /etc/init.d/crosstool-distccd
chmod 755 /etc/init.d/crosstool-distccd
/sbin/chkconfig --add crosstool-distccd
/sbin/chkconfig crosstool-distccd on
echo Now to start the service, either reboot or execute
echo  /sbin/service crosstool-distccd start
_EOF_
    ;;

  *cygwin*)
cat > common/bin/install-distccd.sh <<_EOF_
#!/bin/sh
sed "s,__ABSTOP__,${ABSTOP}," < $ABSTOP/common/etc/crosstool-distccd-cygwin.sh.in > $ABSTOP/common/bin/crosstool-distccd.sh
chmod +x $ABSTOP/common/bin/crosstool-distccd.sh
cygrunsrv -I crosstool-distccd -p $ABSTOP/common/bin/crosstool-distccd.sh -y tcpip -d 'Cygwin crosstool distccd' -e 'CYGWIN=ntsec tty'
echo Now to start the service, either reboot or execute
echo   cygrunsrv -S crosstool-distccd
_EOF_
    ;;

  *arwin*)
cat > common/bin/install-distccd.sh <<_EOF_
#!/bin/sh
mkdir -p /Library/StartupItems/crosstool-distccd
sed "s,__ABSTOP__,${ABSTOP}," < $ABSTOP/common/etc/crosstool-distccd-mac.sh.in > /Library/StartupItems/crosstool-distccd/crosstool-distccd
cp $ABSTOP/common/etc/StartupParameters.plist /Library/StartupItems/crosstool-distccd/StartupParameters.plist
chmod -R -w /Library/StartupItems/crosstool-distccd
chown -R root:wheel /Library/StartupItems/crosstool-distccd
echo Now to start the service, either reboot or execute
echo   SystemStarter start crosstool-distccd
_EOF_
    ;;
  *)
    echo "I don't know how to create an install script for system type '$GNU_HOST' yet" ;;
esac

chmod 755 common/bin/*.sh

