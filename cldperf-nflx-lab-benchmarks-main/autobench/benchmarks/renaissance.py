#!/usr/bin/python3

import subprocess
import re
import os
from common import jctests
from common import jctestcommand
from common import jcregexList
from common import logfile
from common import errfile

arr=[]
results=[]
cwd = os.getcwd()

subprocess.run(['sudo', 'mkdir', '-p', '/mnt'], check=True)
subprocess.run(['sudo', 'mkdir', '-p', '/mnt/renaissance'], check=True)
subprocess.run(['sudo', 'chmod', '777', '/mnt/renaissance'], check=True)

os.system("cp ../binaries/renaissance-gpl-0.16.0.jar /mnt/renaissance/renaissance-gpl-0.16.0.jar")

DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("renaissance.csv","w")

for test in jctests:
  os.chdir("/mnt")
  jctestcommand.append(test)
  proc = subprocess.Popen(jctestcommand, universal_newlines=True, stdout= logfile, stderr=errfile)
  stdout,stderr = proc.communicate()
  os.chdir(cwd)
  with open("logfile.txt") as f:
     for line in f:
         gotMatch = 0
         regexList=jcregexList+[test]
         for regex in regexList:
             s = re.search(regex,line)
             if s:
                gotMatch +=1
         if gotMatch == len(regexList):
               arr.append(re.findall("\d+.\d+",line))
               #print(arr)
     for i in arr:
        results.append(i[0])
     for i in range(0, len(results)):
         results[i] = float(results[i])
  os.chdir(DIR)
  #print(results)
  if (len(results) != 0):
      print('{},{:.2f}'.format(test,sum(results)/len(results)),file=csv)
  else:
      print('{},{:.2f}'.format(test,0),file=csv)
  os.chdir(cwd)
  arr=[]
  results=[]
  del jctestcommand[-1]
if os.path.exists("logfile.txt"):
  os.remove("logfile.txt")
csv.close()
