@echo off
rem JIT (SPIR-V) build of the SYCL port's parity tests on Windows, with the Battlemage XMX variant forced on so the
rem kernels under test are the ones the bmg-g21 AOT engine runs.  sycl\tools\win-build-tests.bat [target, default all]
setlocal
call "%~dp0win-env.bat" || exit /b 1
set "TARGET=%~1"
if "%TARGET%"=="" set TARGET=all
set "SRC=%~dp0.."
set "BUILD=%~dp0..\..\build-sycl-jit"
if not exist "%BUILD%\build.ninja" (
  cmake -S "%SRC%" -B "%BUILD%" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icx ^
        -DCMAKE_CXX_FLAGS=-DSTRATA_XMX_SG16=1 || exit /b 1
)
cmake --build "%BUILD%" --target %TARGET% -- -k 0
