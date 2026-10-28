@echo off
rem Windows: the CPU picture reader (strata-vision.exe: llama.cpp's mtmd, tools/vision without CUDA) for the SYCL engine.
rem   sycl\tools\win-build-vision.bat      -> build-vision-cpu-win\bin\strata-vision.exe
rem Needs the llama.cpp checkout the engine build fetched (build the engine first: sycl\tools\win-build.bat).
setlocal
set STRATA_NO_ONEAPI=1
call "%~dp0win-env.bat" || exit /b 1
for %%I in ("%~dp0..\..") do set "SRC=%%~fI"
set "LLAMA=%SRC%\build-sycl-aot\_deps\strata_llamacpp-src"
if not exist "%LLAMA%\tools\mtmd" set "LLAMA=%SRC%\build-sycl-jit\_deps\strata_llamacpp-src"
if not exist "%LLAMA%\tools\mtmd" (echo llama.cpp with tools/mtmd not found under build-sycl-aot or build-sycl-jit - build the engine first & exit /b 1)
set "LLAMA=%LLAMA:\=/%"
set "BUILD=%SRC%\build-vision-cpu-win"
cmake -G Ninja -S "%SRC%\tools\vision" -B "%BUILD%" -DCMAKE_BUILD_TYPE=Release -DLLAMA_DIR="%LLAMA%" ^
  -DSTRATA_VISION_CUDA=OFF -DSTRATA_PORTABLE=OFF -DCMAKE_C_COMPILER=cl -DCMAKE_CXX_COMPILER=cl || exit /b 1
cmake --build "%BUILD%" --target strata-vision || exit /b 1
echo built: %BUILD%\bin\strata-vision.exe
