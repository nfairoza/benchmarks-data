#!/usr/bin/python3

import subprocess
import re
import io
import os
from common import opensslcommand
from common import opensslregexList
from common import logfile
from common import errfile


#                  sign    verify    sign/s verify/s
# rsa 4096 bits 0.000864s 0.000014s   1157.3  73213.0

arr=[]
results=[]
cpus=os.cpu_count()
opensslcommand.append(str(cpus))
opensslcommand.append('rsa4096')
proc = subprocess.Popen(opensslcommand, universal_newlines=True, stdout= logfile, stderr=errfile)
stdout,stderr = proc.communicate()
with open("logfile.txt") as f:
   for line in f:
       gotMatch=0
       for regex in opensslregexList:
           s = re.search(regex,line)
           if s:
              gotMatch +=1
       if gotMatch == len(opensslregexList):
            arr.append(re.findall("\d+.\d+",line))

DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("openssl.csv","w")
print ('{},{:.2f}'.format("sign/s",float(arr[0][3])),file=csv)
print ('{},{:.2f}'.format("verify/s",float(arr[0][4])),file=csv)
csv.close()
