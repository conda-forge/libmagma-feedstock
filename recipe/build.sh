set -exv

# This step is required when building from raw source archive
# make generate --jobs ${CPU_COUNT}

# Only about 7 virtual archs can be built 6 hours for CUDA 11
# Only about 8 archs fit into the default 2GB address space; could use
# -mcmodel=medium to increase address space

# 11.2 supports archs 3.5 - 8.6
# 11.8 supports archs 3.5 - 9.0
# 12.x supports archs 5.0 - 9.0

# CUDAARCHS set by nvcc compiler package

# Conda-forge nvcc compiler flags environment variable doesn't match CMake environment variable
# Redirect it so that the flags are added to nvcc calls
export CUDAFLAGS="${CUDAFLAGS} ${CUDA_CFLAGS}"

# Compress SASS and PTX in the binary to reduce disk usage
export CUDAFLAGS="${CUDAFLAGS} -Xfatbin -compress-all"

mkdir build
cd build

cmake $SRC_DIR \
  -G "Ninja" \
  -DBUILD_SHARED_LIBS:BOOL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DMAGMA_ENABLE_CUDA:BOOL=ON \
  -DUSE_FORTRAN:BOOL=OFF \
  -DCMAKE_CUDA_SEPARABLE_COMPILATION:BOOL=OFF \
  ${CMAKE_ARGS}

# Explicitly name build targets to avoid building tests
cmake --build . \
    --config Release \
    --parallel ${CPU_COUNT} \
    --target magma magma_sparse \
    --verbose

cmake --install .  --strip
