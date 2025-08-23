@echo on

:: This step is required when building from raw source archive
:: make generate --jobs %CPU_COUNT%
:: if errorlevel 1 exit /b 1

set "CUDAARCHS=50-real;60-real;70-real;80-real"

if "%cuda_compiler_version%"=="11.8" (
  set "CUDAARCHS=%CUDAARCHS%;35-real;86-real;90"

) else if "%cuda_compiler_version:~0,3%"=="12." (
  set "CUDAARCHS=%CUDAARCHS%;86-real;90-real;100-real;120"

) else (
  echo Unsupported CUDA version. Please update build.bat
  exit /b 1
)

md build
cd build
if errorlevel 1 exit /b 1

:: Must add --use-local-env to NVCC_FLAGS otherwise NVCC autoconfigs the host
:: compiler to cl.exe instead of the full path. MSVC does not accept a
:: With vs2022, compilation fails if openmp llvm runtime isn't used
cmake %SRC_DIR% ^
  -G "Ninja" ^
  -DCMAKE_WINDOWS_EXPORT_ALL_SYMBOLS:BOOL=ON ^
  -DCMAKE_BUILD_TYPE=Release ^
  -DCMAKE_INSTALL_PREFIX="%LIBRARY_PREFIX%" ^
  -DCMAKE_PREFIX_PATH="%LIBRARY_PREFIX%" ^
  -DMAGMA_ENABLE_CUDA:BOOL=ON ^
  -DUSE_FORTRAN:BOOL=OFF ^
  -DCMAKE_CUDA_FLAGS="--use-local-env -Xfatbin -compress-all" ^
  -DCMAKE_CUDA_SEPARABLE_COMPILATION:BOOL=OFF ^
  -DOpenMP_RUNTIME_MSVC=llvm ^
  %CMAKE_ARGS%
if errorlevel 1 exit /b 1

cmake --build . ^
    --config Release ^
    --parallel %CPU_COUNT% ^
    --target magma magma_sparse ^
    --verbose
if errorlevel 1 exit /b 1

cmake --install .
if errorlevel 1 exit /b 1
