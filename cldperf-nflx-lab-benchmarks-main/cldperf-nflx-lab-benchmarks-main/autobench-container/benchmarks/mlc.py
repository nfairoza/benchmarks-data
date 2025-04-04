#!/usr/bin/python3

import subprocess
import re
import os
import csv
from common import mlctestcommand
from common import logfile
from common import errfile

# MLC Required settings
try:
    os.system('echo 4000 | sudo tee /proc/sys/vm/nr_hugepages > /dev/null')
except Exception as e:
    print(f"Error setting hugepages: {e}")
    exit(1)

metrics = {
    "idle_latency": [],
    "loaded_latency": [],
    "c2c_latency": {}
}

# Run the benchmark
try:
    proc = subprocess.Popen(mlctestcommand, universal_newlines=True, stdout=logfile, stderr=errfile)
    stdout, stderr = proc.communicate()
    if proc.returncode != 0:
        raise RuntimeError(f"MLC test command failed with return code {proc.returncode}")
except FileNotFoundError as e:
    print(f"Command not found: {e}")
    exit(1)
except Exception as e:
    print(f"Error running the benchmark: {e}")
    exit(1)

# Check if logfile.txt exists
if not os.path.isfile("logfile.txt"):
    print("Error: logfile.txt not found.")
    exit(1)

try:
    with open("logfile.txt") as f:
        content = f.read()
except Exception as e:
    print(f"Error reading logfile.txt: {e}")
    exit(1)

# Parse Idle Latencies
idlelat_pattern = r"Measuring idle latencies.*?Numa node\s+0\s+\d+\s+([\d.]+)"
match_idlelat = re.search(idlelat_pattern, content, re.DOTALL)
if match_idlelat:
    metrics['idle_latency'] = match_idlelat.group(1)
else:
    print("Warning: Idle latency pattern not found.")

# Parse peak bandwidths
bw_pattern = r"^\s*(ALL Reads|[0-9:]+ Reads-Writes|Stream-triad like)\s*:\s*([\d\.]+)\s*$"
match_bw = re.findall(bw_pattern, content, re.MULTILINE)
if match_bw:
    for traffic_type, bw_value in match_bw:
        traffic_type = traffic_type.strip()
        metrics[traffic_type] = bw_value
else:
    print("Warning: No bandwidth patterns found.")

# Parse Loaded Latency
ldlat_pattern = r"^\s*(\d+)\s+([\d\.]+)\s+([\d\.]+)\s*$"
match_ldlat = re.findall(ldlat_pattern, content, re.MULTILINE)
if match_ldlat:
    for inject_delay, latency, bandwidth in match_ldlat:
        metrics["loaded_latency"].append({
            "lat_ns": float(latency),
            "bw_MBps": float(bandwidth)
        })
else:
    print("Warning: No loaded latency patterns found.")

# Parse c2c Latencies
c2c_pattern = r"(HITM|HIT)\s+latency\s+([\d\.]+)"
match_c2c = re.findall(c2c_pattern, content)
if match_c2c:
    for c2c_type, latency in match_c2c:
        metrics["c2c_latency"][c2c_type] = float(latency)
else:
    print("Warning: No c2c latency patterns found.")

# Writeback results
DIR = os.getenv('DIR')
os.chdir(DIR)

try:
    # Write Loaded Latencies to mlc-loaded.csv
    with open("mlc-loaded.csv", "w", newline="") as loaded_csvfile:
        loaded_writer = csv.writer(loaded_csvfile)
        for item in metrics["loaded_latency"]:
            loaded_writer.writerow(list(item.values()))
    
    # Write the rest of the metrics to mlc-idle.csv
    with open("mlc-idle.csv", "w", newline="") as idle_csvfile:
        idle_writer = csv.writer(idle_csvfile)
        for key, value in metrics.items():
            if key == "loaded_latency":
                continue  # Skip loaded_latency as it's already written to mlc-loaded.csv
            if isinstance(value, (str, int, float)):  # Simple values
                idle_writer.writerow([key, value])
            elif isinstance(value, dict):  # Nested dictionaries
                for sub_key, sub_value in value.items():
                    idle_writer.writerow([f"{key}-{sub_key}", sub_value])
            elif isinstance(value, list):  # Simple list values
                for item in value:
                    idle_writer.writerow([item])
except Exception as e:
    print(f"Error writing CSV file: {e}")
    exit(1)

