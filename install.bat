@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "installer_name=%~nx0"

if /i "%~1"=="--help" goto :help
if /i "%~1"=="-h" goto :help
if "%~1"=="/?" goto :help
if "%~1"=="" goto :usage_error
if not "%~2"=="" goto :usage_error

set "package_dir=%~dp0"
set "librenms_dir=%~f1"
if "%librenms_dir:~-1%"=="\" set "librenms_dir=%librenms_dir:~0,-1%"

if not exist "%librenms_dir%\lnms" goto :missing_librenms
if exist "%librenms_dir%\lnms\" goto :missing_librenms

for %%S in (check_file install_file) do (
    for %%F in (
        "resources\definitions\os_detection\sensaphone-web600.yaml"
        "LibreNMS\OS\SensaphoneWeb600.php"
        "html\images\os\sensaphone-web600.svg"
    ) do (
        call :%%S "%%~F"
        if errorlevel 1 exit /b 1
    )
)

echo WEB600 support is installed in "%librenms_dir%".
exit /b 0

:check_file
set "source_file=%package_dir%%~1"
set "destination_file=%librenms_dir%\%~1"
for %%D in ("%destination_file%") do set "destination_dir=%%~dpD"

if not exist "%source_file%" goto :missing_package
if exist "%source_file%\" goto :missing_package
if not exist "%destination_dir%." (
    >&2 echo Missing LibreNMS directory "%destination_dir%".
    exit /b 1
)
if not exist "%destination_file%" exit /b 0
if exist "%destination_file%\" goto :conflict

fc.exe /b "%source_file%" "%destination_file%" >nul 2>&1
if errorlevel 1 goto :conflict
exit /b 0

:install_file
set "source_file=%package_dir%%~1"
set "destination_file=%librenms_dir%\%~1"
for %%D in ("%destination_file%") do set "destination_dir=%%~dpD"

if exist "%destination_file%" (
    call :check_file "%~1"
    if errorlevel 1 exit /b 1
    exit /b 0
)

:choose_stage
set "staged_file=%destination_dir%.web600-install-%RANDOM%-%RANDOM%-%RANDOM%.tmp"
if exist "%staged_file%" goto :choose_stage

copy /b /-y "%source_file%" "%staged_file%" <nul >nul
if errorlevel 1 goto :copy_failed
fc.exe /b "%source_file%" "%staged_file%" >nul 2>&1
if errorlevel 1 goto :copy_failed

rem REN within the destination directory fails if the final name already exists.
ren "%staged_file%" "%~nx1"
if errorlevel 1 goto :copy_failed
echo Installed "%destination_file%".
exit /b 0

:copy_failed
if exist "%staged_file%" del /q "%staged_file%" >nul 2>&1
>&2 echo Could not install "%destination_file%". Check the share and destination permissions.
exit /b 1

:conflict
>&2 echo Existing destination differs or is not a file. Review "%destination_file%" before installing.
exit /b 1

:missing_package
>&2 echo Missing package file "%source_file%".
exit /b 1

:missing_librenms
>&2 echo LibreNMS was not found in "%librenms_dir%". Pass the directory containing lnms.
exit /b 1

:help
echo Usage: %installer_name% LIBRENMS_DIRECTORY
echo Use a local directory, a mapped drive, or a network share containing lnms.
exit /b 0

:usage_error
call :help >&2
exit /b 2
