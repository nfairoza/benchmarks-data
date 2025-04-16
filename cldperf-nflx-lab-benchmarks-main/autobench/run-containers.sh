#!/usr/bin/env bash
set -euo pipefail

wait_for_benchmark_containers() {
  echo "⏳ Waiting for all benchmark containers to finish..."
  while docker ps --filter "name=benchmark-" --format '{{.ID}}' | grep -q .; do
    sleep 5
  done
  echo "✅ All benchmark containers have exited."
}

run_step() {
  local shape="$1"
  echo "▶️  Running $shape"
  ./launch_containers-concurrent.sh "$shape"
  wait_for_benchmark_containers
}

# Sequential execution with enforced waits between steps
run_step xlarge
run_step 2xlarge
run_step 4xlarge
run_step 8xlarge
run_step 12xlarge
run_step 16xlarge
run_step 24xlarge

echo "🎉 Finished all benchmarks"

