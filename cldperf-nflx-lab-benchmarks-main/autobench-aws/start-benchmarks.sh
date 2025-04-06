#!/bin/bash
if [ "$#" -lt 1 ]; then
    echo "Please provide profile as first argument with no/perfspec/uProf options.
          Example: ./start-benchmark no
                   ./start-benchmark perfspec
                   ./start-benchmark uProf
                   ./start-benchmark auto  # Run all benchmarks automatically"
    exit 1
fi

profile="$1"

if [ "$profile" = "no" ]; then
  LOCAL_RESULTS_DIR="/home/ubuntu/benchmark_results/noprofile_results"
  export LOCAL_RESULTS_DIR=$(echo "$LOCAL_RESULTS_DIR")
    ./run-benchmarks-noprofile
elif [ "$profile" = "perfspec" ]; then
  LOCAL_RESULTS_DIR="/home/ubuntu/benchmark_results/perfspect_results"
  export LOCAL_RESULTS_DIR=$(echo "$LOCAL_RESULTS_DIR")
    ./run-benchmarks-perfspec
elif [ "$profile" = "uProf" ]; then
  LOCAL_RESULTS_DIR="/home/ubuntu/benchmark_results/uProf_results"
  export LOCAL_RESULTS_DIR=$(echo "$LOCAL_RESULTS_DIR")
    ./run-benchmarks-uProf
elif [ "$profile" = "auto" ]; then
  LOCAL_RESULTS_DIR="/home/ubuntu/benchmark_results/auto_results"
  export LOCAL_RESULTS_DIR=$(echo "$LOCAL_RESULTS_DIR")
    ./run-benchmarks.sh
else
    echo "Please provide profile as first argument with no/perfspec/uProf/auto options."
    exit 1
fi
