@echo off
setlocal enabledelayedexpansion

set "PLUGIN_DIR=%PREFIX_NSIS%\Plugins\%PLUGIN_SUBDIR%"
if not exist "%PLUGIN_DIR%" mkdir "%PLUGIN_DIR%"

set "API_INC=%NSIS_SRC%\Contrib\ExDLL"
set "API_HDR=%NSIS_SRC%\Source\exehead"
set "PLUGINAPI_FI=/FI%API_INC%\pluginapi.c"
set "INCLUDES=/I"%API_INC%" /I"%API_HDR%""
set "CL_COMMON=/nologo /O1 /GS- /W3 /MT /EHsc /DUNICODE /D_UNICODE /DNSISCALL=__stdcall %INCLUDES%"
set "LINK_COMMON=/NOLOGO /NODEFAULTLIB /OPT:REF /OPT:ICF,9 /ENTRY:DllMain /MACHINE:%LINK_MACHINE% kernel32.lib user32.lib advapi32.lib"
set "UNTGL_CL=/nologo /O1 /GS- /W3 /MT /EHs-c- /DUNICODE /D_UNICODE"
set "UNTGL_LINK=/NOLOGO /NODEFAULTLIB /OPT:REF /OPT:ICF,9 /ENTRY:_DllMainCRTStartup /MACHINE:%LINK_MACHINE% kernel32.lib user32.lib"

if not exist "%SRC_DIR%\plugins\elevate\src\elevate.c" (
    if exist "%SRC_DIR%\plugins\elevate\elevate-1.3.0-redist.7z" (
        7z x -y "%SRC_DIR%\plugins\elevate\elevate-1.3.0-redist.7z" -o"%SRC_DIR%\plugins\elevate"
        if errorlevel 1 exit 1
    )
)
if not exist "%SRC_DIR%\plugins\elevate\src\elevate.c" (
    echo Could not find elevate source under %SRC_DIR%\plugins\elevate\src
    exit 1
)

if /I "%LINK_MACHINE%"=="ARM64" (
    set "ELEVATE_ARCH_DEF=_M_ARM64"
) else if /I "%LINK_MACHINE%"=="AMD64" (
    set "ELEVATE_ARCH_DEF=_M_AMD64"
) else (
    set "ELEVATE_ARCH_DEF=_M_IX86"
)

cd /d "%SRC_DIR%\plugins\BgWorker"
cl %CL_COMMON% /LD BgWorker.cpp /link /NOLOGO /NODEFAULTLIB /OPT:REF /OPT:ICF,9 /ENTRY:_DllMainCRTStartup /MACHINE:%LINK_MACHINE% kernel32.lib user32.lib /OUT:"%PLUGIN_DIR%\BgWorker.dll"
if errorlevel 1 exit 1
del /q *.obj 2>nul

cd /d "%SRC_DIR%\plugins\elevate\src"
rc /nologo /d NDEBUG /d "%ELEVATE_ARCH_DEF%" elevate.rc
if errorlevel 1 exit 1
cl /nologo /O1 /GS- /MT /DUNICODE /D_UNICODE /D_WIN32_WINNT=0x0600 elevate.c elevate.res /link /NOLOGO /RELEASE /OPT:REF /OPT:ICF /SUBSYSTEM:CONSOLE,6.0 /MACHINE:%LINK_MACHINE% kernel32.lib shell32.lib libcmt.lib libucrt.lib libvcruntime.lib /OUT:"%PLUGIN_DIR%\elevate.exe"
if errorlevel 1 exit 1
del /q *.obj *.res 2>nul

cd /d "%SRC_DIR%\plugins\UAC"
rc /nologo /d NDEBUG resource.rc
if errorlevel 1 exit 1
cl /nologo /O1 /GS- /MT /c "%NSIS_SRC%\SCons\Config\memcpy.c"
if errorlevel 1 exit 1
cl %CL_COMMON% /LD uac.cpp RunAs.cpp util.cpp resource.res memcpy.obj /link /NOLOGO /NODEFAULTLIB /OPT:REF /OPT:ICF,9 /ENTRY:_DllMainCRTStartup /MACHINE:%LINK_MACHINE% kernel32.lib user32.lib ole32.lib shell32.lib advapi32.lib /OUT:"%PLUGIN_DIR%\UAC.dll"
if errorlevel 1 exit 1
del /q *.obj *.res 2>nul

cd /d "%SRC_DIR%\plugins\untgz"
cl %UNTGL_CL% /Gs16000 /DNDEBUG /D_WIN32 /DEXEHEAD /DWIN32 /D_WINDOWS /DNSIS_COMPRESS_USE_ZLIB ^
    /I. /Izlib /Ilzma /Ib2 ^
    /LD untgz.cpp filetype.cpp nsisUtils.c miniclib.c untar.c ^
    zlib\adler32.c zlib\crc32.c zlib\gzio.c zlib\inffast.c zlib\inflate.c zlib\inftrees.c zlib\zutil.c ^
    lzma\lzma.c lzma\LzmaDecode.c ^
    bz2\blocksort.c bz2\bzlib.c bz2\crctable.c bz2\decompress.c bz2\huffman.c bz2\randtable.c ^
    untgz.rc ^
    /link %UNTGL_LINK% /OUT:"%PLUGIN_DIR%\untgz.dll"
if errorlevel 1 exit 1
del /q *.obj 2>nul

cd /d "%SRC_DIR%\plugins\UnicodePathTest\Source"
cl %CL_COMMON% %PLUGINAPI_FI% /LD UnicodePathTest.c /link %LINK_COMMON% /OUT:"%PLUGIN_DIR%\UnicodePathTest.dll"
if errorlevel 1 exit 1
del /q *.obj 2>nul

cd /d "%SRC_DIR%\plugins\access-control"
cl %CL_COMMON% %PLUGINAPI_FI% /LD Contrib\AccessControl\AccessControl.cpp Contrib\AccessControl\AccessControl.rc /link %LINK_COMMON% /OUT:"%PLUGIN_DIR%\AccessControl.dll"
if errorlevel 1 exit 1
del /q *.obj 2>nul

exit 0
