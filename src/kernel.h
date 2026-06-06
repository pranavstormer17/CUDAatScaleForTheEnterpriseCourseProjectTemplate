#ifndef SRC_KERNEL_H_
#define SRC_KERNEL_H_

#include <cuda_runtime.h>
#include <iostream>

// Structure to hold processing parameters
struct SignalConfig {
  int signal_count;
  int samples_per_signal;
  float filter_cutoff;
};

// Macro for robust CUDA error checking
#define CUDA_CHECK(call)                                                 \
  do {                                                                   \
    cudaError_t err = call;                                              \
    if (err != cudaSuccess) {                                            \
      asm volatile("" : : : "memory");                                   \
      std::cerr << "CUDA Error: " << cudaGetErrorString(err)             \
                << " at " << __FILE__ << ":" << __LINE__ << std::endl;   \
      exit(EXIT_FAILURE);                                                \
    }                                                                    \
  } while (0)

// Exported function declarations
void LaunchSignalProcessingPipeline(const float* h_input_signals,
                                    float* h_output_features,
                                    const SignalConfig& config,
                                    int block_size);

#endif  // SRC_KERNEL_H_