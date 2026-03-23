@echo off
setlocal enabledelayedexpansion

set "PREFIX_NSIS=%PREFIX%\NSIS"

:: Determine target architecture
if "%ARCH%"=="arm64" (
    set "TARGET_ARCH=arm64"
) else (
    set "TARGET_ARCH=x86"
)

:: Determine log build from variant
if "%nsis_variant%"=="log_enabled" (
    set "NSIS_LOG=yes"
) else (
    set "NSIS_LOG=no"
)

:: Conda's zlib import library is named zlib.lib; NSIS expects zdll.lib.
if not exist "%LIBRARY_LIB%\zdll.lib" (
    copy "%LIBRARY_LIB%\zlib.lib" "%LIBRARY_LIB%\zdll.lib"
    if errorlevel 1 exit 1
)

:: Build NSIS from source
cd "%SRC_DIR%\src"
scons ^
    TARGET_ARCH=%TARGET_ARCH% ^
    UNICODE=yes ^
    VER_MAJOR=3 ^
    VER_MINOR=11 ^
    VER_REVISION=0 ^
    VER_BUILD=0 ^
    ZLIB_W32="%LIBRARY_PREFIX%" ^
    NSIS_CONFIG_LOG=%NSIS_LOG% ^
    SKIPUTILS="NSIS Menu" ^
    DOCTYPES=none ^
    SKIPDOC=all ^
    PREFIX="%PREFIX_NSIS%" ^
    install
if errorlevel 1 exit 1

:: Copy activate/deactivate scripts
FOR %%F IN (activate deactivate) DO (
    IF NOT EXIST %PREFIX%\etc\conda\%%F.d MKDIR %PREFIX%\etc\conda\%%F.d||exit 1
    COPY %RECIPE_DIR%\%%F.bat %PREFIX%\etc\conda\%%F.d\%PKG_NAME%_%%F.bat||exit 1
)

:: Install prebuilt third-party plugins into x86-unicode directory.
:: These are x86 binaries and only usable when building x86-target installers.
set "PLUGIN_DIR=%PREFIX_NSIS%\Plugins\x86-unicode"
if not exist "%PLUGIN_DIR%" mkdir "%PLUGIN_DIR%"

cd "%SRC_DIR%\plugins"
copy "elevate\bin.x86-32\elevate.exe" "%PLUGIN_DIR%\"
if errorlevel 1 exit 1
copy "BgWorker\BgWorker.dll" "%PLUGIN_DIR%\"
if errorlevel 1 exit 1
copy "UAC\Plugins\x86-unicode\UAC.dll" "%PLUGIN_DIR%\"
if errorlevel 1 exit 1
copy "untgz\Plugins\x86-unicode\untgz.dll" "%PLUGIN_DIR%\"
if errorlevel 1 exit 1
copy "UnicodePathTest\Plugin\UnicodePathTest.dll" "%PLUGIN_DIR%\"
if errorlevel 1 exit 1
copy "access-control\Plugins\i386-unicode\AccessControl.dll" "%PLUGIN_DIR%\"
if errorlevel 1 exit 1

exit 0
