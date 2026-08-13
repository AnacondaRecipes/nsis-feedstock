@echo off
setlocal enabledelayedexpansion

set "PREFIX_NSIS=%PREFIX%\NSIS"
set "NSIS_SRC=%SRC_DIR%\src"

if "%ARCH%"=="arm64" (
    set "TARGET_ARCH=arm64"
    set "PLUGIN_SUBDIR=arm64-unicode"
    set "LINK_MACHINE=ARM64"
) else (
    set "TARGET_ARCH=amd64"
    set "PLUGIN_SUBDIR=amd64-unicode"
    set "LINK_MACHINE=AMD64"
)

set "ZLIB_DIR=%LIBRARY_PREFIX%"
if not exist "%LIBRARY_LIB%\zdll.lib" (
    copy "%LIBRARY_LIB%\zlib.lib" "%LIBRARY_LIB%\zdll.lib"
    if errorlevel 1 exit 1
)

if "%nsis_variant%"=="log_enabled" (
    set "NSIS_LOG=yes"
) else (
    set "NSIS_LOG=no"
)

for /f "tokens=1,2,3,4 delims=." %%a in ("%PKG_VERSION%") do (
    set "VER_MAJOR=%%a"
    set "VER_MINOR=%%b"
    set "VER_REVISION=%%c"
    set "VER_BUILD=%%d"
)
if not defined VER_REVISION set "VER_REVISION=0"
if not defined VER_BUILD set "VER_BUILD=0"

cd "%NSIS_SRC%"
scons ^
    TARGET_ARCH=%TARGET_ARCH% ^
    UNICODE=yes ^
    VER_MAJOR=%VER_MAJOR% ^
    VER_MINOR=%VER_MINOR% ^
    VER_REVISION=%VER_REVISION% ^
    VER_BUILD=%VER_BUILD% ^
    ZLIB_W32="%ZLIB_DIR%" ^
    NSIS_CONFIG_LOG=%NSIS_LOG% ^
    SKIPUTILS="NSIS Menu" ^
    DOCTYPES=none ^
    SKIPDOC=all ^
    PREFIX="%PREFIX_NSIS%" ^
    install
if errorlevel 1 exit 1

call "%RECIPE_DIR%\build_third_party_plugins.bat"
if errorlevel 1 exit 1

FOR %%F IN (activate deactivate) DO (
    IF NOT EXIST %PREFIX%\etc\conda\%%F.d MKDIR %PREFIX%\etc\conda\%%F.d||exit 1
    COPY %RECIPE_DIR%\%%F.bat %PREFIX%\etc\conda\%%F.d\%PKG_NAME%_%%F.bat||exit 1
)

exit 0
