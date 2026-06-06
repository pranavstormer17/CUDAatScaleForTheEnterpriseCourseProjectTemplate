#include <iostream>
#include <vector>
#include <string>
#include <cstdlib>
#include <getopt.h>
#include <fstream>
#include <cmath>
#include <algorithm>
#include "kernel.h"

void PrintUsage(const char* program_name) {
  std::cout << "Usage: " << program_name << " [options]\n"
            << "Options:\n"
            << "  -s, --signals <count>    Number of concurrent signals to process (default: 200)\n"
            << "  -m, --samples <count>    Samples per discrete signal (default: 4096)\n"
            << "  -c, --cutoff <value>     Filter baseline cutoff threshold (default: 0.01)\n"
            << "  -b, --blocksize <size>   CUDA threads per block (default: 256)\n"
            << "  -h, --help               Display execution options help guide\n";
}

int main(int argc, char* argv[]) {
  int signal_count = 200; 
  int samples_per_signal = 4096;
  float filter_cutoff = 0.01f;
  int block_size = 256;

  static struct option long_options[] = {
    {"signals",   required_argument, 0, 's'},
    {"samples",   required_argument, 0, 'm'},
    {"cutoff",    required_argument, 0, 'c'},
    {"blocksize", required_argument, 0, 'b'},
    {"help",      no_argument,       0, 'h'},
    {0, 0, 0, 0}
  };

  int option_index = 0;
  int opt;
  while ((opt = getopt_long(argc, argv, "s:m:c:b:h", long_options, &option_index)) != -1) {
    switch (opt) {
      case 's': signal_count = std::atoi(optarg); break;
      case 'm': samples_per_signal = std::atoi(optarg); break;
      case 'c': filter_cutoff = static_cast<float>(std::atof(optarg)); break;
      case 'b': block_size = std::atoi(optarg); break;
      case 'h': PrintUsage(argv[0]); return EXIT_SUCCESS;
      default: PrintUsage(argv[0]); return EXIT_FAILURE;
    }
  }

  std::cout << "==================================================\n"
            << " Launching Batch Signal Processing Engine\n"
            << "==================================================\n"
            << " Signal Count    : " << signal_count << "\n"
            << " Samples / Signal: " << samples_per_signal << "\n"
            << " Total Elements  : " << (signal_count * samples_per_signal) << "\n"
            << "--------------------------------------------------\n";

  SignalConfig config{signal_count, samples_per_signal, filter_cutoff};
  size_t total_elements = static_cast<size_t>(signal_count) * samples_per_signal;

  std::vector<float> h_input(total_elements);
  std::vector<float> h_output(total_elements);

  for (int i = 0; i < signal_count; ++i) {
    for (int j = 0; j < samples_per_signal; ++j) {
      size_t idx = static_cast<size_t>(i) * samples_per_signal + j;
      h_input[idx] = std::sin(0.05f * j) + 0.3f * std::cos(0.15f * j);
    }
  }

  LaunchSignalProcessingPipeline(h_input.data(), h_output.data(), config, block_size);

  std::ofstream log_file("data/execution_output.log");
  if (log_file.is_open()) {
    log_file << "Signal_ID,Sample_Index,Raw_Value,Processed_Value\n";
    for (int i = 0; i < std::min(signal_count, 5); ++i) {
      for (int j = 0; j < std::min(samples_per_signal, 10); ++j) {
        size_t idx = static_cast<size_t>(i) * samples_per_signal + j;
        log_file << i << "," << j << "," << h_input[idx] << "," << h_output[idx] << "\n";
      }
    }
    log_file.close();
    std::cout << ">>> Status Verification saved to 'data/execution_output.log'\n";
  }

  std::cout << "Processing completed successfully.\n";
  return EXIT_SUCCESS;
}