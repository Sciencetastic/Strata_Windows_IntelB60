@echo off
rem strata-sycl.bat: the Windows twin of strata-sycl.sh - the SYCL-built engine as a drop-in `exe` for serve/server.py
rem (--engine strata). No container: the engine runs natively with the oneAPI runtime from setvars.bat, stdin/stdout
rem attached (the serve protocol is lines on those pipes), stderr to the server's log.
rem   STRATA_SYCL_BIN   the engine binary, relative to the repo (default: build-sycl-aot\strata.exe)
rem   STRATA_ONEAPI     the oneAPI folder (default: %ONEAPI_ROOT%, else C:\Program Files (x86)\Intel\oneAPI)
rem The port's defaults (as strata-sycl.sh's) are set unless the environment says otherwise; a value of 0 is not passed
rem on, because the engine tests these switches by presence: "env": {"STRATA_VERIFY_NO_HOST": "0"} turns one off.
setlocal
set "HERE=%~dp0..\.."
rem a stray quote in PATH breaks setvars.bat ("\... was unexpected at this time")
set PATH=%PATH:"=%
if not defined STRATA_ONEAPI if defined ONEAPI_ROOT set "STRATA_ONEAPI=%ONEAPI_ROOT%"
if not defined STRATA_ONEAPI set "STRATA_ONEAPI=%ProgramFiles(x86)%\Intel\oneAPI"
call "%STRATA_ONEAPI%\setvars.bat" intel64 >nul 2>nul
if not defined STRATA_VERIFY_DEVICE_PLAN set STRATA_VERIFY_DEVICE_PLAN=1
if not defined STRATA_VERIFY_NO_HOST set STRATA_VERIFY_NO_HOST=1
if not defined STRATA_STAGER_THREADS set STRATA_STAGER_THREADS=12
if not defined SYCL_CACHE_PERSISTENT set SYCL_CACHE_PERSISTENT=0
if not defined ZES_ENABLE_SYSMAN set ZES_ENABLE_SYSMAN=1
rem (STRATA_MIRROR_MIB=0 is a value, not a switch: INTEL_ARC.md asks for it on a two-B60 split, so it is passed on)
for %%k in (STRATA_VERIFY_DEVICE_PLAN STRATA_VERIFY_NO_HOST STRATA_STAGE_TRIM) do call :zero_is_unset %%k
if not defined STRATA_SYCL_BIN set "STRATA_SYCL_BIN=build-sycl-aot\strata.exe"
cd /d "%HERE%"
"%HERE%\%STRATA_SYCL_BIN%" %*
exit /b %ERRORLEVEL%

:zero_is_unset
call set "v=%%%1%%"
if "%v%"=="0" set "%1="
exit /b 0
