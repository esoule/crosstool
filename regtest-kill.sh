ALLNODES="k8 fast fast2 dual2"
ps augxw | grep regtest | grep -v kill | grep -v grep | awk '{print $2}' > procs
kill `cat procs`
for node in $ALLNODES; do
  echo $node
  ssh -n -x -T $node "ps augx" | egrep 'jobdir|gcc.*glibc.*running|crosstool.sh|make' | awk '{print $2}' > procs
  ssh -n -x -T $node "kill "`cat procs`
  sleep 1
done
