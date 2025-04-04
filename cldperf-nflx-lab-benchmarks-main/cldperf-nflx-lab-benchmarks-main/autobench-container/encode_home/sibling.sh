#!/bin/bash
for num in `cat /proc/cpuinfo|grep processor|awk '{print $3}'`
do
 echo sibling of cpu$num
 cat /sys/devices/system/cpu/cpu$num/topology/thread_siblings_list
done
