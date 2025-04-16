#!/usr/bin/python3
import subprocess
import re
import io
import os
from common import sysbenchmemcommand
from common import sysbenchmemregexList
from common import logfile
from common import errfile

# sysbench mem: 102400.00 MiB transferred (108216.69 MiB/sec)
arr=[]
for i in range(0,3):
    proc = subprocess.Popen(sysbenchmemcommand, universal_newlines=True, stdout= logfile, stderr=errfile)
    stdout,stderr = proc.communicate()
with open("logfile.txt") as f:
   for line in f:
       gotMatch=0
       for regex in sysbenchmemregexList:
           s = re.search(regex,line)
           if s:
               s = re.search(regex,line)
           if s:
              gotMatch +=1
       if gotMatch == len(sysbenchmemregexList):
            arr.append(re.findall(r"\d+.\d+",line))

arr = [[float(float(j)) for j in i] for i in arr] #convert to floats in order to take average of the times
avg = [float(sum(i)) / len(i) for i in zip(*arr)] #take average of times
DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("sysbench-mem.csv","w")
print ("MB/s, " + str(round(avg[1],2)), file = csv)
csv.close()
