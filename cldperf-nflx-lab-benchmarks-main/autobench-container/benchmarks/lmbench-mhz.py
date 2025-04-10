#!/usr/bin/python3
import subprocess
import re
import io
import os
import time
from common import mhzcommand
from common import mhzregexList
from common import logfile
from common import errfile

# sample output: >> 3097 MHz, 0.3229 nanosec clock

arr=[]
for i in range(0,3):
    proc = subprocess.Popen(mhzcommand, universal_newlines=True, stdout= logfile, stderr=subprocess.STDOUT)
    stdout,stderr = proc.communicate()
    time.sleep(5)
with open("logfile.txt") as f:
   for line in f:
       gotMatch=0
       for regex in mhzregexList:
           s = re.search(regex,line)
           if s:
              gotMatch +=1
       if gotMatch == len(mhzregexList):
            arr.append(re.findall("\d+.\d+",line))

arr = [[float(float(j)) for j in i] for i in arr] #convert to floats in order to take average of the times
flat_list = [i for sublist in arr for i in sublist] #convert to single list instead of list of list
flat_list = flat_list[::2]
flat_list = sum(flat_list) / len(flat_list)
DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("lmbench-hz.csv","w")
print ('{},{:.2f}'.format("hz",flat_list), file = csv)
csv.close()
