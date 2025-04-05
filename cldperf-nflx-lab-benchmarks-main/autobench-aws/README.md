# Cloud Performance Benchmarking Framework
This repository contains a comprehensive benchmarking framework designed to evaluate performance across various AWS EC2 instance types.

The benchmarking framework allows for running a variety of standard performance benchmarks with optional profiling tools to gather detailed performance metrics. The system automatically detects instance information, configures appropriate settings, and organizes results in a structured format.

### Prerequisites

- AWS EC2 instance running Ubuntu
- permissions to S3 bucket

### Installation

1. Clone this repository to your EC2 instance
2. Run the setup script:

```bash
./startup.sh
```

This will install all necessary dependencies, set up the environment, and prepare the benchmarking tools.

### Running Benchmarks

To run benchmarks, use the start-benchmarks.sh script with one of the following options:

```bash
./start-benchmarks.sh [option]
```

Where `[option]` is one of:
- `no`: Run benchmarks without profiling
- `perfspec`: Run benchmarks with PerfSpec profiling
- `uProf`: Run benchmarks with AMD uProf profiling
- `auto`: Run all benchmarks automatically with PerfSpec profiling

## Available Benchmarks

The framework includes the following benchmarks:

- **mlc**: Intel Memory Latency Checker
- **compress-7zip**: 7-Zip compression benchmark
- **specjvm2008**: Java VM benchmark suite
- **renaissance**: JVM benchmark suite for modern workloads
- **ffmpeg**: Media processing benchmark
- **specjbb2015**: Java business benchmark
- **lmbench-bw**: LMbench bandwidth benchmark
- **lmbench-mem**: LMbench memory benchmark
- **lmbench-ops**: LMbench operations benchmark
- **openssl**: Cryptography performance benchmark
- **stream**: Memory bandwidth benchmark
- **sysbench-cpu**: CPU performance benchmark
- **sysbench-mem**: Memory performance benchmark

## Profiling Options

The framework supports three profiling modes:

1. **No Profiling**: Runs benchmarks without additional performance monitoring
2. **PerfSpec**: Uses the PerfSpec tool to collect detailed performance metrics during benchmark execution
3. **AMD uProf**: Uses AMD uProf for profiling (optimized for AMD processors)

## Results

Benchmark results are stored in the following locations:

- **Per-run results**: `/home/ubuntu/benchmark_results/[instance]-[os]-[kernel]-[jvm]-[gc]-[heap]-[timestamp]/`
- **Latest results**: `/home/ubuntu/benchmark_results/[instance]-LATEST/`

Each results directory contains:
- Benchmark output files
- System information
- Profiling data (when applicable)
- INFO file with metadata about the run


# Netflix Cloud Performance Benchmarking Framework

This repository contains a comprehensive benchmarking framework designed to evaluate performance across various AWS EC2 instance types. It supports multiple benchmarking tools with different profiling options to provide detailed insights into system performance.

## Overview

The benchmarking framework allows for running a variety of standard performance benchmarks with optional profiling tools to gather detailed performance metrics. The system automatically detects instance information, configures appropriate settings, and organizes results in a structured format.

## Getting Started

### Prerequisites

- AWS EC2 instance running Ubuntu
- Proper permissions to install packages and run benchmarks
- Java 17 (automatically installed by setup script)
- AWS CLI and proper S3 bucket permissions (for result uploads)

### Installation

1. Clone this repository to your EC2 instance
2. Run the setup script:

```bash
./startup.sh
```

This will install all necessary dependencies including AWS CLI, set up the environment, and prepare the benchmarking tools.

### Running Benchmarks

To run benchmarks, use the start-benchmarks.sh script with one of the following options:

```bash
./start-benchmarks.sh [option]
```

Where `[option]` is one of:
- `no`: Run benchmarks without profiling
- `perfspec`: Run benchmarks with PerfSpec profiling
- `uProf`: Run benchmarks with AMD uProf profiling
- `auto`: Run all benchmarks automatically with PerfSpec profiling

## Available Benchmarks

The framework includes the following benchmarks:

- **mlc**: Intel Memory Latency Checker
- **compress-7zip**: 7-Zip compression benchmark
- **specjvm2008**: Java VM benchmark suite
- **renaissance**: JVM benchmark suite for modern workloads
- **ffmpeg**: Media processing benchmark
- **specjbb2015**: Java business benchmark
- **lmbench-bw**: LMbench bandwidth benchmark
- **lmbench-mem**: LMbench memory benchmark
- **lmbench-ops**: LMbench operations benchmark
- **openssl**: Cryptography performance benchmark
- **stream**: Memory bandwidth benchmark
- **sysbench-cpu**: CPU performance benchmark
- **sysbench-mem**: Memory performance benchmark

## Profiling Options

The framework supports three profiling modes:

1. **No Profiling**: Runs benchmarks without additional performance monitoring
2. **PerfSpec**: Uses the PerfSpec tool to collect detailed performance metrics during benchmark execution
3. **AMD uProf**: Uses AMD uProf for profiling (optimized for AMD processors)

## Results

Benchmark results are stored in the following locations:

- **Per-run results**: `/home/ubuntu/benchmark_results/[instance]-[os]-[kernel]-[jvm]-[gc]-[heap]-[timestamp]/`
- **Latest results**: `/home/ubuntu/benchmark_results/[instance]-LATEST/`

Each results directory contains:
- Benchmark output files
- System information
- Profiling data (when applicable)
- INFO file with metadata about the run

### Uploading Results to S3

The framework includes a script to upload benchmark results to an S3 bucket:

```bash
./upload-results.sh
```

This script will:
- Source the benchmark environment variables
- Format the instance type name (replacing dots with hyphens)
- Upload all results to: `s3://netflix-files-us-west2/nfx-benchmark-results/[instance-type]_results/`

The script requires AWS CLI to be installed and configured with appropriate permissions.
