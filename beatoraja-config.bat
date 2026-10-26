@echo off
setlocal enabledelayedexpansion

pushd "%~dp0"

:: === Settings ===

:: beatoraja 0.8.8+ requires JRE 17+ and JavaFX!
:: Since Java 11, JavaFX is no longer bundled with most JDKs, you need a JRE with JavaFX included (e.g., Liberica JRE Full) or place OpenJFX separately.

:: Set JRE_PATH if you use a portable JRE/JDK (e.g. if you placed Liberica JRE Full 25.0.5.0.3+5 at <beatoraja folder>/jre-25.0.5.0.3-full, "set JRE_PATH=jre-25.0.5.0.3-full")
set "JRE_PATH="

:: Set JAVAFX_PATH if you use a portable JavaFX (e.g. if you placed OpenJFX 27.0.1 at <beatoraja folder>/javafx-sdk-27.0.1, "set JAVAFX_PATH=javafx-sdk-27.0.1")
set "JAVAFX_PATH="

:: beatoraja runtime options
set "JAVA_OPTS=-Djava.library.path=./natives -Xms1g -Xmx4g -XX:+UseZGC"

:: ======

:: Set java PATH
if defined JRE_PATH (
    for %%I in ("%JRE_PATH%") do set "JAVA_HOME=%%~fI"
    if not exist "!JAVA_HOME!\bin\java.exe" (
        echo [beatoraja-config.bat] Error: java.exe not found in specified JRE_PATH: !JRE_PATH!
        pause
        popd
        exit /b 1
    )
    set "PATH=!JAVA_HOME!\bin;!PATH!"
)

:: Check if Java exists
where java >nul 2>nul
if errorlevel 1 (
    echo [beatoraja-config.bat] Error: Java not found. Please install JRE 17+ or set JRE_PATH in beatoraja-config.bat.
    pause
    popd
    exit /b 1
)

:: Check Java version and location
set "JAVA_VERSION="
set "JAVA_SPEC_VERSION="
set "JAVA_RUNTIME_HOME="
for /f "tokens=1,* delims== " %%a in ('java -XshowSettings:properties -version 2^>^&1') do (
    if "%%a"=="java.version" set "JAVA_VERSION=%%b"
    if "%%a"=="java.specification.version" set "JAVA_SPEC_VERSION=%%b"
    if "%%a"=="java.home" set "JAVA_RUNTIME_HOME=%%b"
)
if not defined JAVA_VERSION set "JAVA_VERSION=Unknown"
if not defined JAVA_SPEC_VERSION set "JAVA_SPEC_VERSION=0"
if not defined JAVA_RUNTIME_HOME set "JAVA_RUNTIME_HOME=unknown"

set "JAVA_MAJOR_VERSION=!JAVA_SPEC_VERSION!"
if "!JAVA_MAJOR_VERSION:~0,2!"=="1." set "JAVA_MAJOR_VERSION=!JAVA_MAJOR_VERSION:~2!"

if !JAVA_MAJOR_VERSION! lss 17 (
    echo [beatoraja-config.bat] Error: beatoraja requires Java 17 or higher. Detected version: !JAVA_VERSION!
    pause
    popd
    exit /b 1
)

if defined JRE_PATH (
    echo [beatoraja-config.bat] Using Java from JRE_PATH: !JAVA_RUNTIME_HOME! ^(version: !JAVA_VERSION!^)
) else (
    echo [beatoraja-config.bat] Using system Java: !JAVA_RUNTIME_HOME! ^(version: !JAVA_VERSION!^)
)

:: Set JavaFX PATH to JDK_JAVA_OPTIONS if defined
if defined JAVAFX_PATH (
    for %%I in ("%JAVAFX_PATH%") do set "RESOLVED_JAVAFX=%%~fI"
    if not exist "!RESOLVED_JAVAFX!\lib" (
        echo [beatoraja-config.bat] Error: JAVAFX_PATH\lib not found: !JAVAFX_PATH!
        pause
        popd
        exit /b 1
    )
    rem The IR worker (0.8.9+) runs as a separate process and does not inherit command-line options, so JavaFX must be passed via JDK_JAVA_OPTIONS.
    set "JDK_JAVA_OPTIONS=!JDK_JAVA_OPTIONS! --module-path "!RESOLVED_JAVAFX!\lib" --add-modules=javafx.controls,javafx.fxml"
)

:: Check if JavaFX exists
java --describe-module javafx.controls >nul 2>nul
if not errorlevel 1 goto fxok
if defined JAVAFX_PATH if exist "!RESOLVED_JAVAFX!\lib\javafx.controls.jar" goto fxmismatch
echo [beatoraja-config.bat] Error: JavaFX not found. Use a JRE with JavaFX included ^(e.g., Liberica JRE Full^) or place OpenJFX and set JAVAFX_PATH in beatoraja-config.bat.
pause
popd
exit /b 1

:fxmismatch
set "FX_VERSION=(unknown version)"
for /f "tokens=1,* delims==" %%a in ('findstr /b /l /c:"javafx.version=" "!RESOLVED_JAVAFX!\lib\javafx.properties" 2^>nul') do set "FX_VERSION=%%b"
echo [beatoraja-config.bat] Error: JavaFX !FX_VERSION! was found in JAVAFX_PATH, but Java !JAVA_MAJOR_VERSION! could not load it.
echo   The JavaFX SDK is probably too new for your Java. Use JavaFX 21 ^(works with Java 17+^) or a newer Java.
pause
popd
exit /b 1

:fxok

if defined JAVAFX_PATH (
    echo [beatoraja-config.bat] Using JavaFX from JAVAFX_PATH: !RESOLVED_JAVAFX! ^(version: !FX_VERSION!^)
) else (
    echo [beatoraja-config.bat] Using JavaFX included in Java runtime
)

echo [beatoraja-config.bat] Starting beatoraja

:: Run beatoraja
set "JDK_JAVA_OPTIONS=!JDK_JAVA_OPTIONS! -Dfile.encoding=UTF-8"
java %JAVA_OPTS% -cp "beatoraja.jar;ir/*" bms.player.beatoraja.MainLoader
if errorlevel 1 pause
popd
endlocal