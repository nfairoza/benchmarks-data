#!/usr/bin/python3

import subprocess
import re
import io
import os
from common import membwcommand
from common import membwtests
from common import logfile
from common import errfile

for test in membwtests:
  arr=[]
  membwcommand.append(test)
  proc = subprocess.Popen(membwcommand, universal_newlines=True, stdout= logfile, stderr=subprocess.STDOUT)
  stdout,stderr = proc.communicate()
  with open("logfile.txt") as f:
     for line in f:
          arr.append(re.findall(r"\d+.\d+",line))
  del membwcommand[-1]
  i=0
DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("lmbench-bw.csv","w")
for test in membwtests:
    print ('{},{:.2f}'.format(test,float(arr[i][1])),file=csv)
    i += 1
csv.close()
