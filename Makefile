# Compiler Configurations (Mapped for Arch/CachyOS)
NVCC = /opt/cuda/bin/nvcc
CXX = g++

# Language Standards & Hardware Compilation Flags
# Added -I/opt/cuda/include so g++ can find cuda_runtime.h
CXXFLAGS = -O3 -std=c++17 -Wall -Wextra -I/opt/cuda/include
NVCCFLAGS = -O3 -std=c++17 -arch=sm_89 -Xcompiler "-Wall -Wextra"

# Target Binary name and directories
TARGET = bin/signal_processor
SRCDIR = src
OBJDIR = bin/obj

# Sourcing file pathways
SOURCES_CPP = $(wildcard $(SRCDIR)/*.cpp)
SOURCES_CU = $(wildcard $(SRCDIR)/*.cu)

OBJECTS = $(SOURCES_CPP:$(SRCDIR)/%.cpp=$(OBJDIR)/%.o) \
          $(SOURCES_CU:$(SRCDIR)/%.cu=$(OBJDIR)/%.o)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	@mkdir -p bin
	$(NVCC) $(OBJECTS) -o $(TARGET)

$(OBJDIR)/%.o: $(SRCDIR)/%.cpp
	@mkdir -p $(OBJDIR)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(OBJDIR)/%.o: $(SRCDIR)/%.cu
	@mkdir -p $(OBJDIR)
	$(NVCC) $(NVCCFLAGS) -c $< -o $@

clean:
	rm -rf $(OBJDIR) $(TARGET) data/*.log execution_artifacts.tar.gz

.PHONY: all clean