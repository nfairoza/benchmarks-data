#!/usr/bin/python3
import io
import os
java_home = os.environ.get("JAVA_HOME")  # Fetch JAVA_HOME from environment
if java_home is None:
    raise RuntimeError("JAVA_HOME is not set in the environment.")
if os.path.exists("logfile.txt"):
  os.remove("logfile.txt")
logfile = open("logfile.txt",'w+')
if os.path.exists("errfile.txt"):
  os.remove("errfile.txt")
errfile = open("errfile.txt", 'w+')

# MLC (memory latency checker tests) Harshad
mlctestcommand = ['sudo','./binaries/mlc/Linux/mlc']
mlcregexList = ['']

# java concurrency tests, make sure to append $test
#jctestcommand = ['sudo','/usr/lib/jvm/zulu-17-amd64/bin/java','-XX:+PreserveFramePointer','-jar','renaissance-gpl-0.16.0.jar']
jctestcommand = ['sudo',f"{java_home}/bin/java",'-XX:+PreserveFramePointer','-jar','renaissance-gpl-0.16.0.jar']
jctests = ['akka-uct','als','chi-square','db-shootout','dec-tree','dotty','finagle-chirper','finagle-http','fj-kmeans','future-genetic','gauss-mix','log-regression','mnemonics','movie-lens','naive-bayes','neo4j-analytics','page-rank','par-mnemonics','philosophers','reactors','rx-scrabble','scala-doku','scala-kmeans','scala-stm-bench7','scrabble']
jcregexList = ['completed', 'iteration']
#
# specjvm2008 tests. make sure to append $test
#javatestcommand = ['sudo','/usr/lib/jvm/zulu-17-amd64/bin/java','-Xbootclasspath/a:lib/javac.jar','--add-exports','java.xml/com.sun.org.apache.xerces.internal.parsers=ALL-UNNAMED','--add-exports','java.xml/com.sun.org.apache.xerces.internal.util=ALL-UNNAMED','-XX:+PreserveFramePointer','-jar','SPECjvm2008.jar','-ikv','-wt','5s','-it','240s','-ict']
javatestcommand = ['sudo',f"{java_home}/bin/java",'-Xbootclasspath/a:lib/javac.jar','--add-exports','java.xml/com.sun.org.apache.xerces.internal.parsers=ALL-UNNAMED','--add-exports','java.xml/com.sun.org.apache.xerces.internal.util=ALL-UNNAMED','-XX:+PreserveFramePointer','-jar','SPECjvm2008.jar','-ikv','-wt','5s','-it','240s','-ict']
javatests = ['compiler.compiler','compiler.sunflow','compress','crypto.aes','crypto.rsa','crypto.signverify','derby','mpegaudio','scimark.fft.large','scimark.fft.small','scimark.lu.large','scimark.lu.small','scimark.monte_carlo','scimark.sor.large','scimark.sor.small','scimark.sparse.large','scimark.sparse.small','serial','sunflow','xml.transform','xml.validation']
javaregexList = ['Score', 'ops']
#
# 7zip compress/decompress tests. Run 3 times and take average
comp7zipcommand = ['sudo','7z','b']
comp7zipregexList = ['Avr']
#
# openssl, make sure to append $ncpus. Run 3 times and take average
opensslcommand = ['sudo','/usr/bin/openssl','speed','-multi']
opensslregexList = ['rsa','bits']
# 
# TBD: Replace with encoding benchmarks
# ffmpeg, make sure to append: '-threads','$ncpus'. Run 3 times and take average
#ffmpegcommand = ['sudo','/usr/bin/ffmpeg','-i','/mnt/HD2-h264.ts','-f','rawvideo','-y','-target','ntsc-dv','/dev/null','-threads']
# 
# stream
streamcommand = ['sudo','./binaries/stream-bin']
streamregexList = ['Copy','Scale','Add','Triad']
# small instance stream benchmark
#smallstreamcommand = ['sudo','../binaries/stream-bin-8Millions']
#smallstreamregexList = ['Copy','Scale','Add','Triad']
#
# sysbench, make sure to append: '--thread=$ncpus'. Run 3 times and take average
sysbenchcpucommand = ['sudo','sysbench','--events=10000000','cpu','--cpu-max-prime=200000','run']
sysbenchcpuregexList =  ['total number of events']
sysbenchmemcommand = ['sudo','sysbench','--memory-block-size=1M','memory','run']
sysbenchmemregexList =  ['MiB/s']
#
# lmbench mem bandwidth. Make sure to append $test
#membwcommand = ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/bw_mem','-P','16','250m']
membwcommand = ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/bw_mem','250m']
membwtests = ['rd','wr','rdwr','cp','fwr','frd','fcp','bzero','bcopy']

# lmbench mhz
mhzcommand = ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/mhz']
mhzregexList = ['MHz','nanosec','clock']

# lmbench  mem latency, 
latmemrdcommand = ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_mem_rd','2000','64']
#
# lmbench memory operation latency
latopscommands = [
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_mmap','-W 10000','128M','/mnt/zeros'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_pagefault','-W 10000','/mnt/zeros'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_syscall','-W 10000','null'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_syscall','-W 10000','write','/mnt/zeros'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_syscall','-W 10000','read','/mnt/zeros'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_syscall','-W 10000','stat','/mnt/zeros'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_syscall','-W 10000','fstat','/mnt/zeros'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_syscall','-W 10000','open','/mnt/zeros'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_proc','-W 10000','fork'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_proc','-W 10000','exec'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_pipe','-W 10000'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_tcp','-W 10000','localhost'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_udp','-W 10000','localhost'],
                    ['sudo','/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_unix','-W 10000']
                 ]
