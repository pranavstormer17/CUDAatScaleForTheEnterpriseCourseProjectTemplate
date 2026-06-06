#include <iostream>
#include <cmath>
#include <cuda_runtime.h>
#include "kernel.h"

// CUDA Kernel: Processes a batch of signals in parallel
__global__ void BatchSignalProcessorKernel(const float* __restrict__ d_input,
                                           float* __restrict__ d_output,
                                           int signal_count,
                                           int samples_per_signal,
                                           float filter_cutoff) {
  // Map thread to specific signal index and sample index
  int signal_idx = blockIdx.y;
  int sample_idx = blockIdx.x * blockDim.x + threadIdx.x;

  if (signal_idx < signal_count && sample_idx < samples_per_signal) {
    int global_idx = signal_idx * samples_per_signal + sample_idx;

    // Fetch input sample
    float raw_sample = d_input[global_idx];

    // Compute Hann Window function coefficient dynamically on-device
    float pi_val = 3.14159265358979323846f;
    float phase = 2.0f * pi_val * static_cast<float>(sample_idx) / 
                  static_cast<float>(samples_per_signal - 1);
    float window_coef = 0.5f * (1.0f - cosf(phase));

    // Apply windowing transformation
    float processed_val = raw_sample * window_coef;

    // Perform high-pass baseline attenuation
    if (fabsf(processed_val) < filter_cutoff) {
      processed_val = 0.0f;
    }

    // Write transformed feature output
    d_output[global_idx] = processed_val;
  }
}

// Host execution wrapper
void LaunchSignalProcessingPipeline(const float* h_input_signals,
                                    float* h_output_features,
                                    const SignalConfig& config,
                                    int block_size) {
  size_t total_elements = static_cast<size_t>(config.signal_count) * config.samples_per_signal;
  size_t allocation_size = total_elements * sizeof(float);

  float* d_input = nullptr;
  float* d_output = nullptr;

  CUDA_CHECK(cudaMalloc(&d_input, allocation_size));
  CUDA_CHECK(cudaMalloc(&d_output, allocation_size));
  CUDA_CHECK(cudaMemcpy(d_input, h_input_signals, allocation_size, cudaMemcpyHostToDevice));

  int blocks_per_signal = (config.samples_per_signal + block_size - 1) / block_size;
  dim3 grid_dims(blocks_per_signal, config.signal_count, 1);
  dim3 block_dims(block_size, 1, 1);

  cudaEvent_t start, stop;
  CUDA_CHECK(cudaEventCreate(&start));
  CUDA_CHECK(cudaEventCreate(&stop));
  CUDA_CHECK(cudaEventRecord(start, 0));

  BatchSignalProcessorKernel<<<grid_dims, block_dims>>>(
      d_input, d_output, config.signal_count, config.samples_per_signal, config.filter_cutoff);
  
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaEventRecord(stop, 0));
  CUDA_CHECK(cudaEventSynchronize(stop));

  float elapsed_time_ms = 0.0f;
  CUDA_CHECK(cudaEventElapsedTime(&elapsed_time_ms, start, stop));
  std::cout << ">>> GPU Kernel Execution Completed in: " << elapsed_time_ms << " ms" << std::endl;

  CUDA_CHECK(cudaMemcpy(h_output_features, d_output, allocation_size, cudaMemcpyDeviceToHost));

  CUDA_CHECK(cudaEventDestroy(start));
  CUDA_CHECK(cudaEventDestroy(stop));
  CUDA_CHECK(cudaFree(d_input));
  CUDA_CHECK(cudaFree(d_output));
}