#!/bin/sh
# Prepare a copy for distribution
rm -rf *.log boards build dejagnu-1.4.3 dejagnu-1.4.3.tar.gz result tarballs jail.tar.gz *.sum2
find . -type f | xargs chmod 644
find . -type d | xargs chmod 755
