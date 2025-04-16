#!/usr/bin/python3
import subprocess
import re
import io
import os
from common import sysbenchcpucommand
from common import sysbenchcpuregexList
from common import logfile
from common import errfile
from statistics import mean

arr=[]
for i in range(0,3):
    proc = subprocess.Popen(sysbenchcpucommand, universal_newlines=True, stdout= logfile, stderr=errfile)
    stdout,stderr = proc.communicate()
with open("logfile.txt") as f:
   for line in f:
       gotMatch=0
       for regex in sysbenchcpuregexList:
           s = re.search(regex,line)
           if s:
               s = re.search(regex,line)
           if s:
              gotMatch +=1
       if gotMatch == len(sysbenchcpuregexList):
            arr.append(re.findall(r"\d+",line))

arr = [[float(float(j)) for j in i] for i in arr] #convert to floats in order to take average of the times
avg = [float(sum(i)) / len(i) for i in zip(*arr)] #take average
DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("sysbench-cpu.csv","w")
print("total number of events," + str(round(avg[0],2)), file = csv)           #output average of total number of events, rounding to 2 decimal points
csv.close()
