#!/usr/bin/python3

import subprocess
import re
import io
import os
from common import latopscommands
from common import logfile
from common import errfile

subprocess.run(['sudo', 'mkdir', '-p', '/mnt'], check=True)
subprocess.run(['sudo', 'mkdir', '-p', '/mnt/lmbench-ops'], check=True)
subprocess.run(['sudo', 'chmod', '777', '/mnt/lmbench-ops'], check=True)

tests = ['mmap','pagefault','syscal_null','syscal_write','syscal_read','syscal_stat','syscal_fstat','syscal_open','proc_fork','proc_exec','pipe','tcp','udp','unix']
os.system("dd if=/dev/zero of=/mnt/lmbench-ops/zeros bs=1M count=1K")
os.system("/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_tcp -s")
os.system("/usr/lib/lmbench/bin/x86_64-linux-gnu/lat_udp -s")

for command in latopscommands:
    arr=[]
    proc = subprocess.Popen(command, universal_newlines=True, stdout= logfile, stderr=subprocess.STDOUT)
    stdout,stderr = proc.communicate()
    with open("logfile.txt") as f:
      for line in f:
          arr.append(re.findall("\d+.\d+",line))
i = 0
DIR = os.getenv('DIR')
os.chdir(DIR)
csv = open("lmbench-ops.csv","w")
for test in tests:
    s = re.search("mmap",test)
    if s:
        print('{},{:.2f}'.format(test,float(arr[i][1])),file=csv)
    else:
        print ('{},{:.2f}'.format(test,float(arr[i][0])),file=csv)
    i += 1
csv.close()
