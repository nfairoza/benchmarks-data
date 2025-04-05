This repository provides tools and scripts for running benchmarks on AWS EC2 instances, On-prem AMD Servers and On-prem AMD servers with docker containers emulating EC2 instances. Follow the instructions below to set up and execute benchmarks efficiently.

---

## **📌 Benchmark Environment**  
All benchmark specific files and setup are located in autobench folder
- **benchmarks_environment.sh** contains benchmark environment
- **benchmarks_environment.sh**: Sets up environment variables
- **run-benchmarks*.sh**: Scripts for running benchmarks with different profiling options
- **start-benchmarks.sh**: Main entry point for selecting profiling mode
- **upload-results.sh**: Script to upload results to S3
- **benchmarks/**: Directory containing individual benchmark scripts
- **binaries/**: Directory containing profiling tools
---

# 🏃 Running Benchmarks on the on AWS Cloud EC2 instances
The `autobench-aws` directory contains a comprehensive benchmarking framework designed to evaluate performance across various AWS EC2 instance types. This framework extends the lab benchmarking capabilities to cloud environments.

## Getting Started with AWS Benchmarking

### Prerequisites

- AWS EC2 instance running Ubuntu
- AWS CLI and proper S3 bucket permissions

### Installation

1. Log into your AWS EC2 instance
2. Run the setup script:

```bash
cd autobench-aws
./startup.sh
```

This will install all necessary dependencies including AWS CLI, set up the environment, and prepare the benchmarking tools.

### Running Benchmarks on AWS

To run benchmarks, use the start-benchmarks.sh script with one of the following options:

```bash
./start-benchmarks.sh [option]
```
Where `[option]` is one of:
- `no`: Run benchmarks without profiling
- `perfspec`: Run benchmarks with PerfSpec profiling
- `uProf`: Run benchmarks with AMD uProf profiling
- `auto`: Run all benchmarks automatically with PerfSpec profiling

### Results in AWS Ec2

Benchmark results are stored in the following locations:

- **Per-run results**: `/home/ubuntu/benchmark_results/[instance]-[os]-[kernel]-[jvm]-[gc]-[heap]-[timestamp]/`
- **Latest results**: `/home/ubuntu/benchmark_results/[instance]-LATEST/`

You can change it from the benchmarks_environment variables

Each results directory contains:
- Benchmark output files
- System information
- Profiling data (when applicable)
- INFO file with metadata about the run

### Uploading AWS Results to S3

The framework includes a script to upload benchmark results to an S3 bucket:

```bash
./upload-results.sh
```
---
# 🏃 Running Benchmarks on the on prem Host (Without Containers)

To execute benchmarks directly on the host machine, use the following script:

$ cd autobench; ./run-benchmarks#

Results are  dumped in folder: **$RESULTS** (set in benchmarks_environement.sh) in the format:
- $RESULTS/Family-InstanceType-UbuntuRelease-KernelVersion-JavaVersion-JVM_GarbageCollector-JVM_HeapSize-datestamp
- $RESULTS/Family-InstanceType-LATEST

Among benchmark results (CSV), folder will also contain benchmark evnironment setting (**INFO**) file, results, logs, system performance and profiling data

**Example:**
- Genoa-metal-48xl-jammy-680-52-generic-OpenJDK17-G1GC-128g-03-11-2025_1741723630
- Genoa-metal-48xl-LATEST *(LATEST always contains the most recent run.)*
---
# Running Benchmarks in Docker Containers in the on-prem Host 🐳  

## Building the Benchmark Docker Image  

A **Dockerfile** is provided in autobench folder to build the benchmark-container. Ensure that the Dockerfile is in the same directory before proceeding.  

### 📌 Build the Docker Image  
$ docker build -t benchmark-container .   
- Make sure to name the image benchmark-container

## Launching Containers for Benchmarking 🚀  

Container launch script support container shapes that mimic popular AWS instance types in terms of vcpu and memory configured. Supported shapes are::
- **xlarge, 2xlarge, 4xlarge, 8xlarge, 12xlarge, 16xlarge, 24xlarge, 32xlarge, metal-48xl**


 To start benchmarking, use the provided script:  

$ ./launch_containers-concurrent.sh xlarge 2xlarge 4xlarge  

This command launches **three containers** with different shapes
- xlarge, 2xlarge, 4xlarge

You can also run multiple containers of the same shapes by specifying the count in the format below
$ ./launch_containers-concurrent.sh 10.xlarge 8.2xlarge 8xlarge

This command launches **10 xlarge, 8 2xlarge and 1 8xlarge containers** with different shapes
- xlarge, 2xlarge, 8xlarge


## 📂 Directory Structure for Benchmark Results  

### 1️⃣ Running a Single Container  

$ ./launch_containers-concurrent.sh 8xlarge

If you run **one** container, results are stored in **$RESULT** directory in similar format as running without container

- $RESULTS/Family-InstanceType-UbuntuRelease-KernelVersion-JavaVersion-JVM_GarbageCollector-JVM_HeapSize-datestamp  
- $RESULTS/Family-InstanceType-LATEST  *(LATEST always contains the most recent run.)*  


**Example:**  
- Genoa-metal-48xl-jammy-680-52-generic-OpenJDK17-G1GC-128g-03-11-2025_1741723630  
- Genoa-metal-LATEST



### 2️⃣ Running Multiple Containers Concurrently  

When multiple containers are launched:  
$ ./launch_containers-concurrent.sh xlarge 2xlarge 4xlarge ...  

Results are grouped under a **GROUP-count.shape1_count.shape2_...-YYYY-MM-DD_HH-MM-SSr**:  
**Example: GROUP-10.xlarge_8.2xlarge_8xlarge-YYYY-MM-DD_HH-MM-SS/**  

Each container’s results are stored in the same format inside this folder.  
Keeping concurrent benchmark results in the same folder allows us to analyze:  
- **External factors affecting performance** (other workloads running)  
- **System-wide impact on benchmark results**  

---

## 🔍 Key Takeaways  
✅ Use **autobench-aws** for running benchmarks on AWS EC2 instance.  
✅ Use **run-benchmarks** for running benchmarks on host  
✅ Use **benchmark-container** image for running benchmarks in Docker container  
✅ Launch single or multiple containers using launch_containers-concurrent.sh

✅ Results are stored $RESULTS folder. Folder name is based on AWS instance/Model names,sizes.. and timestamp**  
✅ **LATEST** folder always holds results of the **most recent run of benchmark**  
✅ When multiple containers are launched, all results will be stored together under **Group-datestamps** folder

✅ **Group-based results** help analyze performance under load when other containers are concurrently running.

🚀 **Now you’re ready to run benchmarks efficiently!**  
