@echo off
rem Native Windows build of Strata's SYCL (Intel Arc) engine.
rem   sycl\tools\win-build.bat [AOT device, default bmg-g21] [target, default strata]
setlocal
call "%~dp0win-env.bat" || exit /b 1
set "AOT=%~1"
if "%AOT%"=="" set AOT=bmg-g21
set "TARGET=%~2"
if "%TARGET%"=="" set TARGET=strata
set "SRC=%~dp0.."
set "BUILD=%~dp0..\..\build-sycl-aot"
if not exist "%BUILD%\build.ninja" (
  cmake -S "%SRC%" -B "%BUILD%" -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_C_COMPILER=icx -DCMAKE_CXX_COMPILER=icx ^
        -DSTRATA_SYCL_AOT=%AOT% || exit /b 1
)
cmake --build "%BUILD%" --target %TARGET% -- -k 0
