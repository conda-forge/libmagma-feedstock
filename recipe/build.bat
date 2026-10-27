@echo on

:: This step is required when building from raw source archive
:: make generate --jobs %CPU_COUNT%
:: if errorlevel 1 exit /b 1

:: CUDAARCHS set by nvcc compiler package

md build
cd build
if errorlevel 1 exit /b 1

:: Must add --use-local-env to CUDAFLAGS otherwise NVCC autoconfigs the host
:: compiler to cl.exe instead of the full path.
set CUDAFLAGS=--use-local-env

:: Suppress MSVC warning C4996 (deprecated declarations) for host code, both
:: directly and when nvcc forwards flags to the host compiler
set CFLAGS=%CFLAGS% /wd4996
set CXXFLAGS=%CXXFLAGS% /wd4996
set CUDAFLAGS=%CUDAFLAGS% -Xcompiler /wd4996

:: Compress SASS and PTX in the binary to reduce disk usage
set CUDAFLAGS=%CUDAFLAGS% -Xfatbin -compress-all

:: Reduce archs to major-only after 75 to reduce binary size. Users can upgrade to CTK 13.0
:: get minor arch specific instructions. AFAICT, magma doesn't have any code paths specific
:: to anthing later than 70 anyways.
if "%cuda_compiler_version:~0,3%"=="12." (
  set "CUDAARCHS=50-real;52-real;60-real;61-real;70-real;75-real;80-real;90a-real;100f-real;120f-real;121-virtual"
)

if "%cuda_compiler_version:~0,3%"=="13." (
  set CUDAFLAGS=%CUDAFLAGS% -Xfatbin -compress-mode=size
)

:: Must set CMAKE_CXX_STANDARD=17 because CCCL from CUDA 13 has dropped C++14
cmake %SRC_DIR% ^
  -G "Ninja" ^
  -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS:BOOL=ON ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
  -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
  -DMAGMA_ENABLE_CUDA:BOOL=ON ^
  -DUSE_FORTRAN:BOOL=OFF ^
  -DCMAKE_CUDA_SEPARABLE_COMPILATION:BOOL=OFF ^
  -DCMAKE_CXX_STANDARD=17 ^
  %CMAKE_ARGS%
if errorlevel 1 exit /b 1

:: Explicitly name build targets to avoid building tests
cmake --build . ^
    --config Release ^
    --parallel %CPU_COUNT% ^
    --target magma magma_sparse ^
    --verbose
if errorlevel 1 exit /b 1

cmake --install .
if errorlevel 1 exit /b 1
