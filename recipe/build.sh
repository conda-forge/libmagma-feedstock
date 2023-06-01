set -exv

# This step is required when building from raw source archive
make generate --jobs ${CPU_COUNT}

# Duplicate lists because of https://bitbucket.org/icl/magma/pull-requests/32
export CUDA_ARCH_LIST="sm_35,sm_50,sm_60,sm_70,sm_75,sm_80"
export CUDAARCHS="35-virtual;50-virtual;60-virtual;70-virtual;75-virtual;80-virtual"

# Only build the lowest non-deprecated arch to minimize build time
if [[ "$target_platform" == "linux-ppc64le" || "$target_platform" == "linux-aarch64" ]]; then
  export CUDA_ARCH_LIST="sm_60;sm_80"
  export CUDAARCHS="60-virtual;80-virtual"
fi

# Only build the lowest non-deprecated arch to minimize build time
if [[ "$cuda_compiler_version" == "12.0" ]]; then
  export CUDA_ARCH_LIST="sm_50,sm_60,sm_70,sm_75,sm_80,sm_89"
  export CUDAARCHS="50-virtual;60-virtual;70-virtual;75-virtual;80-virtual;89-virtual"
fi

# Remove CXX standard flags added by conda-forge. std=c++11 is required to
# compile some .cu files
CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"

# Conda-forge nvcc compiler flags environment variable doesn't match CMake environment variable
# Redirect it so that the flags are added to nvcc calls
CUDAFLAGS="${CUDAFLAGS} ${CUDA_CFLAGS}"

mkdir build
cd build

cmake $SRC_DIR \
  -G "Ninja" \
  -DBUILD_SHARED_LIBS:BOOL=ON \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DGPU_TARGET=$CUDA_ARCH_LIST \
  -DMAGMA_ENABLE_CUDA:BOOL=ON \
  -DUSE_FORTRAN:BOOL=OFF \
  -DCMAKE_CUDA_SEPARABLE_COMPILATION:BOOL=OFF \
  ${CMAKE_ARGS}

# Explicitly name build targets to avoid building tests
cmake --build . \
    --config Release \
    --parallel ${CPU_COUNT} \
    --target magma \
    --verbose

cmake --install .

rm -rf $PREFIX/include/*
rm $PREFIX/lib/pkgconfig/magma.pc
