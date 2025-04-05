#!/usr/bin/python3
import io
import os
if os.path.exists("logfile.txt"):
  os.remove("logfile.txt")
logfile = open("logfile.txt",'w+')
if os.path.exists("errfile.txt"):
  os.remove("errfile.txt")
errfile = open("errfile.txt", 'w+')
