@echo off
rem Windows build environment for the SYCL (Intel Arc) engine: MSVC + Intel oneAPI + CMake and Ninja.
rem Called by win-build.bat, win-build-tests.bat and win-build-vision.bat; finds everything itself:
rem   Visual Studio (2022 or 2026, any edition or Build Tools) with the C++ workload - through vswhere
rem   Intel oneAPI - %ONEAPI_ROOT%, else C:\Program Files (x86)\Intel\oneAPI (STRATA_NO_ONEAPI=1 skips it)
rem   CMake and Ninja - on PATH, else the copies that ship with Visual Studio
rem (A path under "Program Files (x86)" must not be expanded inside a ( ) block, its ")" would end the block: the for /f commands get %%VSWHERE%%, which the child shell expands.)
if defined STRATA_WIN_ENV goto :eof
rem a stray quote in PATH (one entry ending in ") breaks vcvars64.bat and setvars.bat with "\... was unexpected at this
rem time": drop the quotes for this window only
set PATH=%PATH:"=%
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" goto no_vswhere
set "VSDIR="
for /f "usebackq delims=" %%i in (`""%%VSWHERE%%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath"`) do set "VSDIR=%%i"
if not defined VSDIR goto no_vs
call "%VSDIR%\VC\Auxiliary\Build\vcvars64.bat" >nul || goto vcvars_failed
if defined STRATA_NO_ONEAPI goto tools
if not defined ONEAPI_ROOT set "ONEAPI_ROOT=%ProgramFiles(x86)%\Intel\oneAPI"
if not exist "%ONEAPI_ROOT%\setvars.bat" goto no_oneapi
call "%ONEAPI_ROOT%\setvars.bat" intel64 >nul || goto setvars_failed
:tools
where cmake >nul 2>nul && where ninja >nul 2>nul && goto done
set "VSCMAKE="
for /f "usebackq delims=" %%i in (`""%%VSWHERE%%" -products * -find "Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe""`) do if not defined VSCMAKE set "VSCMAKE=%%~dpi"
if not defined VSCMAKE goto no_cmake
set "PATH=%VSCMAKE%;%VSCMAKE%..\..\Ninja;%PATH%"
where ninja >nul 2>nul || goto no_cmake
:done
set STRATA_WIN_ENV=1
goto :eof

:no_vswhere
echo vswhere.exe not found: install Visual Studio 2022 or 2026 with "Desktop development with C++".
exit /b 1
:no_vs
echo No Visual Studio with the C++ tools found: add "Desktop development with C++" in the Visual Studio Installer.
exit /b 1
:vcvars_failed
echo vcvars64.bat failed in %VSDIR%
exit /b 1
:no_oneapi
echo Intel oneAPI not found in %ONEAPI_ROOT%: install the DPC++/C++ compiler and oneMKL, or set ONEAPI_ROOT.
exit /b 1
:setvars_failed
echo setvars.bat failed in %ONEAPI_ROOT%
exit /b 1
:no_cmake
echo CMake and Ninja not found: install CMake 3.24+ and Ninja, or the Visual Studio "C++ CMake tools" component.
exit /b 1
