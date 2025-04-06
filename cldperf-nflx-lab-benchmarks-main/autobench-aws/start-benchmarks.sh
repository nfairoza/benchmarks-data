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
    ./run-benchmarks-noprofile
elif [ "$profile" = "perfspec" ]; then
    ./run-benchmarks-perfspec
elif [ "$profile" = "uProf" ]; then
    ./run-benchmarks-uProf
elif [ "$profile" = "auto" ]; then
    ./run-benchmarks.sh
else
    echo "Please provide profile as first argument with no/perfspec/uProf/auto options."
    exit 1
fi
