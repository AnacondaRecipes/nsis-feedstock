@echo off
setlocal

cd /d "%SRC_DIR%\zlib-src"
if errorlevel 1 exit 1

if not exist zdll.lib (
    nmake -f win32\Makefile.msc LOC=-D_CRT_SECURE_NO_DEPRECATE DLL_BLD=1
    if errorlevel 1 exit 1
)

exit 0
