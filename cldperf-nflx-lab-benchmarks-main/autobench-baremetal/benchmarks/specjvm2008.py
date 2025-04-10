#!/usr/bin/python3

import subprocess
import re
import io
import os
from common import javatests
from common import javatestcommand
from common import javaregexList
from common import logfile
from common import errfile

cwd = os.getcwd()
#cmd = 'sudo /usr/lib/jvm/zulu-17-amd64/bin/java -jar /efs/SPECJVM2008/SPECjvm2008_1_01_setup.jar -i silent > /dev/null 2>&1'
#os.system(cmd)
#cmd = 'sudo mkdir /mnt/SPECjvm2008; sudo cp -r /SPECjvm2008/* /mnt/SPECjvm2008 > /dev/null 2>&1'
if os.path.exists("/mnt/SPECjvm2008") == False:
   cmd = 'sudo mkdir /mnt/SPECjvm2008; sudo cp -r ./binaries/SPECJVM2008/* /mnt/SPECjvm2008 > /dev/null 2>&1'
else:
   cmd = 'sudo cp -r ./binaries/SPECJVM2008/* /mnt/SPECjvm2008 > /dev/null 2>&1'
os.system(cmd)
for test in javatests:
  os.chdir("/mnt/SPECjvm2008")
  arr=[]
  javatestcommand.append(test)
  if test == 'compiler.compiler' or test == 'compiler.sunflow':
     del javatestcommand[-1]
     continue
  proc = subprocess.Popen(javatestcommand, universal_newlines=True, stdout=logfile, stderr=errfile)
  stdout,stderr = proc.communicate()
  os.chdir(cwd)
  with open("logfile.txt") as f:
     for line in f:
         gotMatch=0
         for regex in javaregexList:
             s = re.search(regex,line)
             if s:
                gotMatch +=1
         if gotMatch == len(javaregexList):
               arr.append(re.findall("\d+.\d+",line))
  del javatestcommand[-1]

DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("specjvm2008.csv","w")
i = 0
for test in javatests:
  if test == 'compiler.compiler' or test == 'compiler.sunflow':
      print ('{},{}'.format(test,'NaN'),file=csv)
  else:
      if len(arr) > 0:
         print ('{},{:.2f}'.format(test,float(arr[i][0])),file=csv)
      i += 1
if os.path.exists("logfile.txt"):
   os.remove("logfile.txt")
csv.close()
