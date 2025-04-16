#!/bin/bash
PATH=/bin:/usr/bin:/usr/sbin:$PATH
BASE_DIR=$(dirname "$(realpath "$0")")/..
###############################################################################
# Sample script for running SPECjbb2015 in MultiJVM mode.
# 
# This sample script demonstrates running the Controller, TxInjector(s) and 
# Backend(s) in separate JVMs on the same server.
###############################################################################

# Launch command: java [options] -jar specjbb2015.jar [argument] [value] ...

# Number of Groups (TxInjectors mapped to Backend) to expect
if [[ $EC2_INSTANCE_TYPE =~ ".medium" ]]; then
  GROUP_COUNT=1
elif [[ $EC2_INSTANCE_TYPE =~ ".large" ]]; then
  GROUP_COUNT=1
elif [[ $EC2_INSTANCE_TYPE =~ ".xlarge" ]]; then
  GROUP_COUNT=1
elif [[ $EC2_INSTANCE_TYPE =~ ".2xlarge" ]]; then
  GROUP_COUNT=1
else
  GROUP_COUNT=2
fi
# Number of TxInjector JVMs to expect in each Group
TI_JVM_COUNT=1

# Benchmark options for Controller / TxInjector JVM / Backend
# Please use -Dproperty=value to override the default and property file value
# Please add -Dspecjbb.controller.host=$CTRL_IP (this host IP) to the benchmark options for the all components
# and -Dspecjbb.time.server=true to the benchmark options for Controller 
# when launching MultiJVM mode in virtual environment with Time Server located on the native host.
#----
#SPEC_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.heartbeat.period=100000 -Dspecjbb.heartbeat.threshold=9000000 -Dspecjbb.controller.handshake.timeout=900000 -Dspecjbb.controller.handshake.period=20000"
#-------
SPEC_OPTS_C="-Dspecjbb.group.count=$GROUP_COUNT -Dspecjbb.txi.pergroup.count=$TI_JVM_COUNT -Dspecjbb.comm.connect.client.pool.size=232 -Dspecjbb.comm.connect.selector.runner.count=1 -Dspecjbb.comm.connect.timeouts.connect=600000 -Dspecjbb.comm.connect.timeouts.read=600000 -Dspecjbb.comm.connect.timeouts.write=600000 -Dspecjbb.comm.connect.worker.pool.max=81 -Dspecjbb.comm.connect.worker.pool.min=24 -Dspecjbb.forkjoin.workers.Tier1=140 -Dspecjbb.forkjoin.workers.Tier2=1 -Dspecjbb.forkjoin.workers.Tier3=20 -Dspecjbb.mapreducer.pool.size=223 -Dspecjbb.customerDriver.threads.probe=69 -Dspecjbb.customerDriver.threads.saturate=85 -Dspecjbb.controller.maxir.maxFailedPoints=1"

SPEC_OPTS_TI="-Dspecjbb.comm.connect.selector.runner.count=4 -Dspecjbb.comm.connect.worker.pool.min=2 -Dspecjbb.comm.connect.worker.pool.max=150 -Dspecjbb.comm.connect.client.pool.size=150"
#-----
SPEC_OPTS_BE="-Dspecjbb.comm.connect.selector.runner.count=4 -Dspecjbb.comm.connect.worker.pool.min=2 -Dspecjbb.comm.connect.worker.pool.max=150 -Dspecjbb.comm.connect.client.pool.size=150"

# Java options for Controller / TxInjector / Backend JVM
JAVA_OPTS_C="-Xms2g -Xmx2g -Xmn1536m -XX:+UseParallelGC -XX:ParallelGCThreads=2 -XX:CICompilerCount=4"
JAVA_OPTS_TI="-Xms2g -Xmx2g -Xmn1536m -XX:+UseParallelGC -XX:ParallelGCThreads=2 -XX:CICompilerCount=4"

if [[ $EC2_INSTANCE_TYPE =~ "c6i.xlarge" ]] || [[ $EC2_INSTANCE_TYPE =~ "c6a.xlarge" ]]; then
   JAVA_OPTS_BE="-Xms$Heap -Xmx$Heap -server -XX:MetaspaceSize=256m -XX:AllocatePrefetchInstr=2 -XX:-UsePerfData -XX:-UseAdaptiveSizePolicy -XX:+Use$GC -XX:SurvivorRatio=65 -XX:TargetSurvivorRatio=80 -XX:MaxTenuringThreshold=15 -XX:InitialCodeCacheSize=25m -XX:InlineSmallCode=10k -XX:MaxGCPauseMillis=200 -XX:+UseCompressedOops -XX:ObjectAlignmentInBytes=32"
else
JAVA_OPTS_BE="-Xms$Heap -Xmx$Heap -server -XX:MetaspaceSize=256m -XX:AllocatePrefetchInstr=2 -XX:LargePageSizeInBytes=2m -XX:-UsePerfData -XX:-UseAdaptiveSizePolicy -XX:+AlwaysPreTouch -XX:+UseLargePages -XX:+Use$GC -XX:SurvivorRatio=65 -XX:TargetSurvivorRatio=80 -XX:MaxTenuringThreshold=15 -XX:InitialCodeCacheSize=25m -XX:InlineSmallCode=10k -XX:MaxGCPauseMillis=200 -XX:+UseCompressedOops -XX:ObjectAlignmentInBytes=32 -XX:+UseTransparentHugePages"
fi

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

#JAVA=/usr/lib/jvm/zulu-17-amd64/bin/java
JAVA=$JAVA_HOME/bin/java

which $JAVA > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Could not find a 'java' executable. Please set the JAVA environment variable or update the PATH."
    exit 1
fi

for ((n=1; $n<=$NUM_OF_RUNS; n=$n+1)); do
  # Create result directory
  timestamp=$(date '+%y-%m-%d_%H%M%S')
  result="/mnt/SPECjbb2015"
  if [ -d "$result" ];
  then
   sudo rm -rf $result
   sudo chmod 777 "$result"
  fi
  sudo mkdir "$result"
  sudo chmod 777 "$result"
  # Copy current config to the result directory
  cp -r $BASE_DIR/binaries/config $result

  cd $result

  # Get System Details
  $BASE_DIR/binaries/get_sysconfig.sh > sut.txt 2>&1

  echo "Run $n: $timestamp"
  echo "Launching SPECjbb2015 in MultiJVM mode..."
  echo

  echo "Start Controller JVM"
  $JAVA $JAVA_OPTS_C $SPEC_OPTS_C -jar $BASE_DIR/binaries/SPECjbb2015/specjbb2015.jar -m MULTICONTROLLER  $MODE_ARGS_C 2>controller.log > controller.out &

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
        $JAVA $JAVA_OPTS_TI $SPEC_OPTS_TI -jar $BASE_DIR/binaries/SPECjbb2015/specjbb2015.jar -m TXINJECTOR -G=$GROUPID -J=$JVMID $MODE_ARGS_TI > $TI_NAME.log 2>&1 &
        echo -e "\t$TI_NAME PID = $!"
        sleep 1
    done

    JVMID=beJVM
    BE_NAME=$GROUPID.Backend.$JVMID

    echo "    Start $BE_NAME"
    $JAVA $JAVA_OPTS_BE $SPEC_OPTS_BE -Xlog:gc:$GROUPID-gc.log -XX:+PrintGCDetails -XX:-PrintCommandLineFlags -XX:+PreserveFramePointer $SPEC_OPTS_BE -jar $BASE_DIR/binaries/SPECjbb2015/specjbb2015.jar -m BACKEND -G=$GROUPID -J=$JVMID $MODE_ARGS_BE > $BE_NAME.log 2>&1 &
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

# move gc file to $DIR directory and create a csv file call it specjbb2015.csv
cd $DIR
sudo mkdir specjbb2015
sudo chmod 777 specjbb2015
cp $result/Group1-gc.log $DIR/specjbb2015/specjbb2015-gc.log 
cp $result/sut.txt $DIR/specjbb2015/sut.txt 
cp $result/result/*/*/specjbb2015*.html $DIR/specjbb2015/specjbb2015.html
cp $result/result/*/*/specjbb2015*.raw  $DIR/specjbb2015/specjbb2015.raw
cp $result/result/*/*/specjbb2015.css  $DIR/specjbb2015/specjbb2015.css
cp -r $result/result/*/*/images $DIR/specjbb2015/images
cp -r $result/result/*/*/data $DIR/specjbb2015/data
cp -r $result/result/*/*/logs $DIR/specjbb2015/logs
#
# generate csv file, specjbb2015.csv, for reporting 
metrics=("max-tput" "SLA-crit" "SLA-10ms" "SLA-25ms" "SLA-50ms" "SLA-75ms" "SLA-100ms")
i=0
while IFS= read -r line
do
	echo $line|sed 's/\/s//g'
	echo " -----"
	echo $line| awk -v myvar=${metrics[$i]} -F'=' '{print myvar","$2}' >> $DIR/specjbb2015.csv
	i=`expr $i+1`
done <<< $(grep "\-jOPS" $DIR/specjbb2015/specjbb2015.raw) 
exit 0
