This repository provides tools and scripts for running benchmarks on [Netflix Lab machines](https://netflix.atlassian.net/wiki/spaces/OCPERFLAB/overview?homepageId=1937706945) either **inside Docker containers** or **directly on the host machine**. Follow the instructions below to set up and execute benchmarks efficiently.

---

## **📌 Benchmark Environment**  
All benchmark specific files and setup are located in autobench folder
-  **benchmarks_environment.sh** contains benchmark environment
-  **binaries** folder contains benchmarks binaries
-  **benchmarks** folder contains benchmark scripts

🏃 Running Benchmarks on the Host (Without Containers)

To execute benchmarks directly on the host machine, use the following script:

$ cd autobench; ./run-benchmarks#

Results are  dumped in folder: **$RESULTS** (set in benchmarks_environement.sh) in the format:
- $RESULTS/Family-InstanceType-UbuntuRelease-KernelVersion-JavaVersion-JVM_GarbageCollector-JVM_HeapSize-datestamp
- $RESULTS/Family-InstanceType-LATEST

Among benchmark results (CSV), folder will also contain benchmark evnironment setting (**INFO**) file, results, logs, system performance and profiling data

**Example:**
- Genoa-metal-48xl-jammy-680-52-generic-OpenJDK17-G1GC-128g-03-11-2025_1741723630
- Genoa-metal-48xl-LATEST *(LATEST always contains the most recent run.)*

# Running Benchmarks in Docker Containers 🐳  

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

---

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

✅ Use **run-benchmarks** for running benchmarks on host  
✅ Use **benchmark-container** image for running benchmarks in Docker container  
✅ Launch single or multiple containers using launch_containers-concurrent.sh

✅ Results are stored $RESULTS folder. Folder name is based on AWS instance/Model names,sizes.. and timestamp**  
✅ **LATEST** folder always holds results of the **most recent run of benchmark**  
✅ When multiple containers are launched, all results will be stored together under **Group-datestamps** folder

✅ **Group-based results** help analyze performance under load when other containers are concurrently running.

🚀 **Now you’re ready to run benchmarks efficiently!**  
