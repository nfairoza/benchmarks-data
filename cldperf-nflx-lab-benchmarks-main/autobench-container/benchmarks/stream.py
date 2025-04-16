#!/usr/bin/python3

import subprocess
import re
import io
import os
from common import streamcommand
from common import streamregexList
from common import logfile
from common import errfile
from statistics import mean
#Function    Best Rate MB/s  Avg time     Min time     Max time
#Copy:        >   77553.8     0.022956     0.020631     0.033058
#Scale:       >   62982.3     0.027191     0.025404     0.037839
#Add:         >   71124.1     0.035454     0.033744     0.045267
#Triad:       >   70756.6     0.035560     0.033919     0.045984

metrics= {'Copy': [], 'Scale': [], 'Add': [], 'Triad': [] }
for i in range(0,3):
    proc = subprocess.Popen(streamcommand, universal_newlines=True, stdout= logfile, stderr=errfile)
    stdout,stderr = proc.communicate()
with open("logfile.txt") as f:
    for line in f:
        for regex in streamregexList:
            s = re.search(regex,line)
            if s:
               if "Copy" in line:
                   arr=re.findall(r"\d+.\d+",line)
                   metrics["Copy"].append(arr)
               elif "Scale" in line:
                   arr=re.findall(r"\d+.\d+",line)
                   metrics["Scale"].append(arr)
               elif "Add" in line:
                   arr=re.findall(r"\d+.\d+",line)
                   metrics["Add"].append(arr)
               elif "Triad" in line:
                   arr=re.findall(r"\d+.\d+",line)
                   metrics["Triad"].append(arr)
DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("stream.csv","w")
for key, value in metrics.items():
    print ('{},{:.2f}'.format(key,mean([float(value[0][0]),float(value[1][0]),float(value[2][0])])),file=csv)
csv.close()
