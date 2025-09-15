@echo on

:: This step is required when building from raw source archive
:: make generate --jobs %CPU_COUNT%
:: if errorlevel 1 exit /b 1

:: CUDAARCHS set by nvcc compiler package

md build
cd build
if errorlevel 1 exit /b 1

:: Must add --use-local-env to NVCC_FLAGS otherwise NVCC autoconfigs the host
:: compiler to cl.exe instead of the full path.
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
