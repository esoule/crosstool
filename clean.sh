#!/bin/sh
# Prepare a copy for distribution
set -x
rm -rf log log[0-9] *.log boards build dejagnu-1.4.3 dejagnu-1.4.3.tar.gz result tarballs jail.tar.gz *.sum2
find . -type f | xargs chmod 644
find . -type d | xargs chmod 755
find . -name '*.sh' | xargs chmod 755
chmod +x config.guess
