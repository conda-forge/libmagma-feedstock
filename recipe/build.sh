set -exv

# This step is required when building from raw source archive
# make generate --jobs ${CPU_COUNT}

if [[ "$cuda_compiler_version" == "11.2" ]]; then
  echo "This script no longer supports CUDA < 11.8 because of newer CUDA archs."
  exit 1;
fi

# Only about 7 virtual archs can be built 6 hours for CUDA 11

# Duplicate lists because of https://bitbucket.org/icl/magma/pull-requests/32
export CUDA_ARCH_LIST="sm_35,sm_50,sm_60,sm_61,sm_70,sm_75,sm_80"
export CUDAARCHS="35-real;50-real;60-real;61-real;70-real;75-real;80-real;90"

if [[ "$cuda_compiler_version" == "12.0" ]]; then
  export CUDA_ARCH_LIST="sm_50,sm_60,sm_61,sm_70,sm_75,sm_80,sm_86,sm_89,sm_90"
  export CUDAARCHS="50-real;60-real;70-real;75-real;80-real;89-real;90"
fi

if [[ "$target_platform" == "linux-ppc64le" ]]; then
  export CUDA_ARCH_LIST="sm_50,sm_60,sm_61,sm_70,sm_75,sm_80,sm_86,sm_90"
  export CUDAARCHS="50-real;60-real;61-real;70-real;80-real;86-real;90"
  if [[ "$cuda_compiler_version" == "11"* ]]; then
    export CMAKE_ARGS="${CMAKE_ARGS} -DCUDAToolkit_ROOT=/usr/local/cuda/targets/ppc64le-linux"
  fi
fi

# Jetsons are more common for ARM devices, so target those minor versions
if [[ "$target_platform" == "linux-aarch64" ]]; then
  export CUDA_ARCH_LIST="sm_50,sm_53,sm_60,sm_62,sm_70,sm_72,sm_80,sm_87,sm_90"
  export CUDAARCHS="50-real;60-real;62-real;70-real;80-real;87-real;90"
  if [[ "$cuda_compiler_version" == "11"* ]]; then
    export CMAKE_ARGS="${CMAKE_ARGS} -DCUDAToolkit_ROOT=/usr/local/cuda/targets/sbsa-linux"
  fi
fi

# Remove CXX standard flags added by conda-forge. std=c++11 is required to
# compile some .cu files
export CXXFLAGS="${CXXFLAGS//-std=c++17/-std=c++11}"

# Conda-forge nvcc compiler flags environment variable doesn't match CMake environment variable
# Redirect it so that the flags are added to nvcc calls
export CUDAFLAGS="${CUDAFLAGS} ${CUDA_CFLAGS}"

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
