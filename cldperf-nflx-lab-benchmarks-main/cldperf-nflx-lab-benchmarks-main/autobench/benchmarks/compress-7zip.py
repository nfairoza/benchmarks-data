#!/usr/bin/python3

import subprocess
import re
import io
import os
from common import comp7zipcommand
from common import comp7zipregexList
from common import logfile
from common import errfile

#Avr:            1319   2988  >39453  |             1551   2242  >34777
arr=[]
results=[]
proc = subprocess.Popen(comp7zipcommand, universal_newlines=True, stdout= logfile, stderr=errfile)
stdout,stderr = proc.communicate()
with open("logfile.txt") as f:
   for line in f:
       gotMatch=0
       for regex in comp7zipregexList:
           s = re.search(regex,line)
           if s:
              gotMatch +=1
       if gotMatch == len(comp7zipregexList):
            arr.append(re.findall("\d+",line))
DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("compress-7zip.csv","w")
print ('{},{:.2f}'.format("compress",float(arr[0][2])),file=csv)
print ('{},{:.2f}'.format("decompress",float(arr[0][-1])),file=csv)
csv.close()
