#!/bin/bash

###############################################################################
# Sample script for running SPECjbb2015 in MultiJVM mode.
# 
# This sample script demonstrates running the Controller, TxInjector(s) and 
# Backend(s) in separate JVMs on the same server.
###############################################################################

# Save current kernel values
#def_sched_rt_runtime_us=`cat /proc/sys/kernel/sched_rt_runtime_us`
#def_sched_latency_ns=`cat /proc/sys/kernel/sched_latency_ns`
#def_sched_migration_cost_ns=`cat /proc/sys/kernel/sched_migration_cost_ns`
#def_sched_min_granularity_ns=`cat /proc/sys/kernel/sched_min_granularity_ns`
#def_sched_wakeup_granularity_ns=`cat /proc/sys/kernel/sched_wakeup_granularity_ns`
#def_dirty_expire_centisecs=`cat /proc/sys/vm/dirty_expire_centisecs`
#def_dirty_writeback_centisecs=`cat /proc/sys/vm/dirty_writeback_centisecs`
#def_dirty_ratio=`cat /proc/sys/vm/dirty_ratio`
#def_dirty_background_ratio=`cat /proc/sys/vm/dirty_background_ratio`
#def_swappiness=`cat /proc/sys/vm/swappiness`
#def_numa_stat=`cat  /proc/sys/vm/numa_stat`
#def_numa_balancing=`cat /proc/sys/kernel/numa_balancing`
#def_thp_enabled=`cat /sys/kernel/mm/transparent_hugepage/enabled | sed 's/.*\[\([^]]*\)].*/\1/'`
#def_thp_defrag=`cat /sys/kernel/mm/transparent_hugepage/defrag | sed 's/.*\[\([^]]*\)].*/\1/'`

# Kernel Tuning
#echo 950000 > /proc/sys/kernel/sched_rt_runtime_us
#echo 100000000 > /proc/sys/kernel/sched_latency_ns
#echo 80000 > /proc/sys/kernel/sched_migration_cost_ns
#echo 600000 > /proc/sys/kernel/sched_min_granularity_ns
#echo 100000 > /proc/sys/kernel/sched_wakeup_granularity_ns
#
#echo 10000 > /proc/sys/vm/dirty_expire_centisecs
#echo 1500 > /proc/sys/vm/dirty_writeback_centisecs
#echo 40 > /proc/sys/vm/dirty_ratio
#echo 10 > /proc/sys/vm/dirty_background_ratio
#echo 10 > /proc/sys/vm/swappiness
#echo 0 > /proc/sys/vm/numa_stat
##
#echo 0 > /proc/sys/kernel/numa_balancing
#echo always > /sys/kernel/mm/transparent_hugepage/enabled
#echo always > /sys/kernel/mm/transparent_hugepage/defrag

# Launch command: java [options] -jar specjbb2015.jar [argument] [value] ...

# Number of Groups (TxInjectors mapped to Backend) to expect
GROUP_COUNT=1
#TODO: increase number of TxInjectors to have more load  if running benchmark on a instance 24xl or larger
# Number of Groups (TxInjectors mapped to Backend) to expect
#GROUP_COUNT=2

# Number of TxInjector JVMs to expect in each Group
TI_JVM_COUNT=1

# Benchmark options for Controller / TxInjector JVM / Backend
# Please use -Dproperty=value to override the default and property file value
# Please add -Dspecjbb.controller.host=$CTRL_IP (this host IP) to the benchmark options for the all components
# and -Dspecjbb.time.server=true to the benchmark options for Controller 
# when launching MultiJVM mode in virtual environment with Time Server located on the native host.
#----
#SPEC_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT"
#----
SPEC_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.heartbeat.period=2000 -Dspecjbb.heartbeat.threshold=9000000 -Dspecjbb.controller.handshake.timeout=900000 -Dspecjbb.controller.handshake.period=20000"
#SPEC_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.heartbeat.period=2000 -Dspecjbb.heartbeat.threshold=9000000 -Dspecjbb.controller.handshake.timeout=900000 -Dspecjbb.controller.handshake.period=20000 -Dspecjbb.forkjoin.workers.Tier1=140 -Dspecjbb.forkjoin.workers.Tier2=1 -Dspecjbb.forkjoin.workers.Tier3=20 -Dspecjbb.comm.connect.selector.runner.count=16 -Dspecjbb.mapreducer.pool.size=64"
#----
#
#SPEC_OPTS_TI=""
SPEC_OPTS_TI="-Dspecjbb.comm.connect.selector.runner.count=4 -Dspecjbb.comm.connect.worker.pool.min=2 -Dspecjbb.comm.connect.worker.pool.max=150 -Dspecjbb.comm.connect.client.pool.size=150"
#SPEC_OPTS_TI="-Dspecjbb.comm.connect.selector.runner.count=8 -Dspecjbb.comm.connect.worker.pool.min=4 -Dspecjbb.comm.connect.worker.pool.max=150 -Dspecjbb.comm.connect.client.pool.size=150"
#-----
#
#SPEC_OPTS_BE=""
SPEC_OPTS_BE="-Dspecjbb.comm.connect.selector.runner.count=4 -Dspecjbb.comm.connect.worker.pool.min=2 -Dspecjbb.comm.connect.worker.pool.max=150 -Dspecjbb.comm.connect.client.pool.size=150"
#SPEC_OPTS_BE="-Dspecjbb.comm.connect.selector.runner.count=8 -Dspecjbb.comm.connect.worker.pool.min=4 -Dspecjbb.comm.connect.worker.pool.max=150 -Dspecjbb.comm.connect.client.pool.size=150"
#-----
#

# Java options for Controller / TxInjector / Backend JVM
#JAVA_OPTS_C=""
JAVA_OPTS_C="-Xms2g -Xmx2g -Xmn1536m -XX:+UseParallelGC -XX:ParallelGCThreads=2 -XX:CICompilerCount=4"
#-----
#
#JAVA_OPTS_TI=""
JAVA_OPTS_TI="-Xms2g -Xmx2g -Xmn1536m -XX:+UseParallelGC -XX:ParallelGCThreads=2 -XX:CICompilerCount=4"
#----
#
#JAVA_OPTS_BE=""
mem=`free -g|grep Mem:|awk '{print $2}'`
xmx=`awk -vp=$mem 'BEGIN{printf "%d" , p * 0.7}'`
xmn=`expr $xmx - 1`
GB='g'
# Garbage collectors: SerialGC,ParallelGC,G1GC,ZGC,ShenandoahGC, 
# https://www.freecodecamp.org/news/garbage-collection-in-java-what-is-gc-and-how-it-works-in-the-jvm/
# G1GC: https://www.redhat.com/en/blog/collecting-and-reading-g1-garbage-collector-logs-part-2
GC='G1GC'
JAVA_OPTS_BE="-Xms$xmx$GB -Xmx$xmx$GB -Xmn$xmn$GB -server -XX:MetaspaceSize=256m -XX:AllocatePrefetchInstr=2 -XX:LargePageSizeInBytes=2m -XX:-UsePerfData -XX:-UseAdaptiveSizePolicy -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+Use$GC -XX:SurvivorRatio=65 -XX:TargetSurvivorRatio=80 -XX:MaxTenuringThreshold=15 -XX:InitialCodeCacheSize=25m -XX:InlineSmallCode=10k -XX:MaxGCPauseMillis=200 -XX:+UseCompressedOops -XX:ObjectAlignmentInBytes=32 -XX:+UseTransparentHugePages"
#JAVA_OPTS_BE="-Xms$xmx$GB -Xmx$xmx$GB -Xmn$xmn$GB -server -XX:MetaspaceSize=256m -XX:AllocatePrefetchInstr=2 -XX:LargePageSizeInBytes=2m -XX:-UsePerfData -XX:-UseAdaptiveSizePolicy -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseParallelGC -XX:SurvivorRatio=65 -XX:TargetSurvivorRatio=80 -XX:ParallelGCThreads=16 -XX:MaxTenuringThreshold=15 -XX:InitialCodeCacheSize=25m -XX:InlineSmallCode=10k -XX:MaxGCPauseMillis=200 -XX:+UseCompressedOops -XX:ObjectAlignmentInBytes=32 -XX:+UseTransparentHugePages"
#JAVA_OPTS_BE="-Xms45g -Xmx45g -Xmn44g -server -XX:MetaspaceSize=256m -XX:AllocatePrefetchInstr=2 -XX:LargePageSizeInBytes=2m -XX:-UsePerfData -XX:-UseAdaptiveSizePolicy -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+UseParallelGC -XX:SurvivorRatio=65 -XX:TargetSurvivorRatio=80 -XX:ParallelGCThreads=16 -XX:MaxTenuringThreshold=15 -XX:InitialCodeCacheSize=25m -XX:InlineSmallCode=10k -XX:MaxGCPauseMillis=200 -XX:+UseCompressedOops -XX:ObjectAlignmentInBytes=32 -XX:+UseTransparentHugePages"


# Optional arguments for multiController / TxInjector / Backend mode 
# For more info please use: java -jar specjbb2015.jar -m <mode> -h
MODE_ARGS_C=""
MODE_ARGS_TI=""
MODE_ARGS_BE=""

# Number of successive runs
NUM_OF_RUNS=1

###############################################################################
# This benchmark requires a JDK7 compliant Java VM.  If such a JVM is not on
# your path already you must set the JAVA environment variable to point to
# where the 'java' executable can be found.
#
# If you are using a JDK9 (or later) Java VM, see the FAQ at:
#                       https://spec.org/jbb2015/docs/faq.html
# and the Known Issues document at:
#                       https://spec.org/jbb2015/docs/knownissues.html
###############################################################################

JAVA=java

which $JAVA > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Could not find a 'java' executable. Please set the JAVA environment variable or update the PATH."
    exit 1
fi

for ((n=1; $n<=$NUM_OF_RUNS; n=$n+1)); do

  # Create result directory                
  timestamp=$(date '+%y-%m-%d_%H%M%S')
  #result=./$timestamp
  result="/efs/html/AUTOBENCH/SCRIPTS-REPORTING/SPECjbb2015-TESTING/RESULTS/$timestamp"
  mkdir "$result"

  # Copy current config to the result directory
  cp -r config $result

  cd $result

  # Get System Details
  /efs/html/SPECjbb2015/get_sysconfig.sh > sut.txt 2>&1

  echo "Run $n: $timestamp"
  echo "Launching SPECjbb2015 in MultiJVM mode..."
  echo

  echo "Start Controller JVM"
  $JAVA $JAVA_OPTS_C $SPEC_OPTS_C -jar /efs/html/SPECjbb2015/specjbb2015.jar -m MULTICONTROLLER  $MODE_ARGS_C 2>controller.log > controller.out &
  #----
  #TODO: Test with numa binding
  #numactl --interleave=all $JAVA $JAVA_OPTS_C $SPEC_OPTS_C -jar ../specjbb2015.jar -m MULTICONTROLLER $MODE_ARGS_C 2>controller.log > controller.out &
  #----

  CTRL_PID=$!
  echo "Controller PID = $CTRL_PID"

  sleep 3

  for ((gnum=1; $gnum<$GROUP_COUNT+1; gnum=$gnum+1)); do

    GROUPID=Group$gnum
    echo -e "\nStarting JVMs from $GROUPID:"
    let node=(${gnum}-1)

    for ((jnum=1; $jnum<$TI_JVM_COUNT+1; jnum=$jnum+1)); do

        JVMID=txiJVM$jnum
        TI_NAME=$GROUPID.TxInjector.$JVMID

        echo "    Start $TI_NAME"
        $JAVA $JAVA_OPTS_TI $SPEC_OPTS_TI -jar /efs/html/SPECjbb2015/specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID $MODE_ARGS_TI > $TI_NAME.log 2>&1 &
	#----
	#TODO: Test with numa binding
        #numactl --cpunodebind=$node --localalloc $JAVA $JAVA_OPTS_TI $SPEC_OPTS_TI -jar ../specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID $MODE_ARGS_TI > $TI_NAME.log 2>&1 &
	#-----
        echo -e "\t$TI_NAME PID = $!"
        sleep 1
    done

    JVMID=beJVM
    BE_NAME=$GROUPID.Backend.$JVMID

    echo "    Start $BE_NAME"
    $JAVA $JAVA_OPTS_BE $SPEC_OPTS_BE -Xloggc:$GROUPID-gc.log -XX:+PrintGCDetails -XX:+PrintGCApplicationStoppedTime -XX:+PrintGCApplicationConcurrentTime -XX:+PrintGCDateStamps -XX:-PrintCommandLineFlags $SPEC_OPTS_BE -jar /efs/html/SPECjbb2015/specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID $MODE_ARGS_BE > $BE_NAME.log 2>&1 &
    #----
    #TODO: Test with numa binding
    #numactl --cpunodebind=$node --localalloc $JAVA $JAVA_OPTS_BE -Xloggc:$GROUPID-gc.log $SPEC_OPTS_BE -jar ../specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID $MODE_ARGS_BE > $BE_NAME.log 2>&1 &
    #----
    echo -e "\t$BE_NAME PID = $!"
    sleep 1

  done

  echo
  echo "SPECjbb2015 is running..."
  echo "Please monitor $result/controller.out for progress"

  wait $CTRL_PID
  echo
  echo "Controller has stopped"

  echo "SPECjbb2015 has finished"
  echo
  
  cd ..

done
# Restore saved kernel values
#echo $def_sched_rt_runtime_us > /proc/sys/kernel/sched_rt_runtime_us
#echo $def_sched_latency_ns > /proc/sys/kernel/sched_latency_ns
#echo $def_sched_migration_cost_ns > /proc/sys/kernel/sched_migration_cost_ns
#echo $def_sched_min_granularity_ns > /proc/sys/kernel/sched_min_granularity_ns
#echo $def_sched_wakeup_granularity_ns > /proc/sys/kernel/sched_wakeup_granularity_ns
#echo $def_dirty_expire_centisecs > /proc/sys/vm/dirty_expire_centisecs
#echo $def_dirty_writeback_centisecs > /proc/sys/vm/dirty_writeback_centisecs
#echo $def_dirty_ratio > /proc/sys/vm/dirty_ratio
#echo $def_dirty_background_ratio > /proc/sys/vm/dirty_background_ratio
#echo $def_swappiness > /proc/sys/vm/swappiness
#echo $def_numa_stat >  /proc/sys/vm/numa_stat
#echo $def_numa_balancing > /proc/sys/kernel/numa_balancing
#echo $def_thp_enabled > /sys/kernel/mm/transparent_hugepage/enabled
#echo $def_thp_defrag > /sys/kernel/mm/transparent_hugepage/defrag
#
exit 0
