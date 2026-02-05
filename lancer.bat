@echo off
echo Compilation du clustering framework avec -parameters...

set PROJECT_ROOT=%~dp0FrameWork_ETU_003132-main\FrameWork_ETU_003132-main
set OUTPUT_DIR=%PROJECT_ROOT%\classes
set CLASSPATH=%PROJECT_ROOT%\lib\*;%PROJECT_ROOT%\servlet.jar
set JAR_NAME=clustering_framework.jar
set JAR_PATH=%PROJECT_ROOT%\lib\%JAR_NAME%

echo Classpath: %CLASSPATH%

cd /d %PROJECT_ROOT%

REM Creer le repertoire de sortie s'il n'existe pas
if not exist "%OUTPUT_DIR%" mkdir "%OUTPUT_DIR%"

echo.
echo === Etape 1: Compilation des annotations ===
javac -parameters -d "%OUTPUT_DIR%" -cp "%CLASSPATH%" annotation\*.java

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors de la compilation des annotations
    pause
    exit /b 1
)

echo === Etape 2: Compilation du modelview ===
javac -parameters -d "%OUTPUT_DIR%" -cp "%CLASSPATH%;%OUTPUT_DIR%" modelview\*.java

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors de la compilation du modelview
    pause
    exit /b 1
)

echo === Etape 3: Compilation des utilitaires ===
javac -parameters -d "%OUTPUT_DIR%" -cp "%CLASSPATH%;%OUTPUT_DIR%" util\*.java

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors de la compilation des utilitaires
    pause
    exit /b 1
)

echo === Etape 4: Compilation du scan ===
javac -parameters -d "%OUTPUT_DIR%" -cp "%CLASSPATH%;%OUTPUT_DIR%" scan\*.java

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors de la compilation du scan
    pause
    exit /b 1
)

echo === Etape 5: Compilation de l'upload ===
javac -parameters -d "%OUTPUT_DIR%" -cp "%CLASSPATH%;%OUTPUT_DIR%" upload\*.java

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors de la compilation de l'upload
    pause
    exit /b 1
)

echo === Etape 6: Compilation du servlet ===
javac -parameters -d "%OUTPUT_DIR%" -cp "%CLASSPATH%;%OUTPUT_DIR%" servlet\*.java

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors de la compilation du servlet
    pause
    exit /b 1
)

echo === Etape 7: Generation du JAR ===
if not exist "%PROJECT_ROOT%\lib" mkdir "%PROJECT_ROOT%\lib"
jar cf "%JAR_PATH%" -C "%OUTPUT_DIR%" .

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===================================
    echo Compilation reussie avec -parameters!
    echo Les noms de parametres sont maintenant preserves.
    echo Classes generees dans: %OUTPUT_DIR%
    echo JAR genere: %JAR_PATH%
    echo ===================================
) else (
    echo.
    echo ERREUR DE GENERATION DU JAR
)

pause