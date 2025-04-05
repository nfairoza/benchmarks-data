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

## Framework Structure

- **benchmarks_environment.sh**: Sets up environment variables
- **run-benchmarks*.sh**: Scripts for running benchmarks with different profiling options
- **start-benchmarks.sh**: Main entry point for selecting profiling mode
- **benchmarks/**: Directory containing individual benchmark scripts
- **binaries/**: Directory containing profiling tools

## Customization

You can modify `benchmarks_environment.sh` to customize:
- Results directory location
- JVM heap size settings
- Garbage collector options
- Other benchmark parameters

## Troubleshooting

If you encounter issues:

1. Check the LOG file in the results directory
2. Verify that all prerequisites are installed
3. Ensure proper permissions for all script files (`chmod +x`)
4. Check system resource availability

## Contributing

To contribute to this framework:

1. Fork the repository
2. Add or improve benchmarks
3. Submit a pull request with detailed descriptions of changes

## License

This project is licensed under the terms of the Netflix Open Source License.
