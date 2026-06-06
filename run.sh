#!/bin/sh
set -e

echo "=== Stage 1: Compiling Code Pipeline ==="
make clean
make

echo ""
echo "=== Stage 2: Running Benchmark Simulations ==="
# Execute the binary from the bin/ directory
./bin/signal_processor --signals 500 --samples 8192 --cutoff 0.005 --blocksize 512

echo ""
echo "=== Stage 3: Packaging Evidence Artifacts ==="
if [ -f "data/execution_output.log" ]; then
    tar -czf execution_artifacts.tar.gz data/execution_output.log
    echo ">>> Packaging complete: 'execution_artifacts.tar.gz' ready for submission."
else
    echo ">>> Error: Execution verification data missing."
    exit 1
fi