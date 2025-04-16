#!/usr/bin/python3

import subprocess
import re
import io
import os
from common import latmemrdcommand
from common import logfile
from common import errfile

arr=[]
proc = subprocess.Popen(latmemrdcommand, universal_newlines=True, stdout= logfile, stderr=subprocess.STDOUT)
stdout,stderr = proc.communicate()
with open("logfile.txt") as f:
   for line in f:
       s = re.search("stride",line)
       if not s:
          arr.append(re.findall(r"\d+.\d+",line))
DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("lmbench-mem.csv","w")
#print('{}'.format("\n"), end = '',file=csv)
for i in range(len(arr) - 1):
    if i < (len(arr) - 2):
        print('{}{}'.format(arr[i][1],"\n"), end = '',file=csv)
    else:
        print('{}'.format(arr[i][1]),file=csv)
csv.close()
