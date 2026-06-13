@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_SCRIPT=%SCRIPT_DIR%build-release.ps1"

if not exist "%PS_SCRIPT%" (
    echo ERROR: Could not find %PS_SCRIPT%
    exit /b 1
)

powershell -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
set "EXITCODE=%ERRORLEVEL%"

if not "%EXITCODE%"=="0" (
    echo.
    echo Release script failed with exit code %EXITCODE%.
    exit /b %EXITCODE%
)

echo.
echo Release script completed successfully.
exit /b 0
