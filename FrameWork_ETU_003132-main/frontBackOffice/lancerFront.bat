@echo off
echo Compilation des controllers avec -parameters...

set PROJECT_ROOT=%~dp0
set OUTPUT_DIR=%PROJECT_ROOT%WEB-INF\classes
set LIB_DIR=%PROJECT_ROOT%WEB-INF\lib
set SERVLET_JAR=C:\xampp\tomcat\lib\servlet-api.jar
set JSP_JAR=C:\xampp\tomcat\lib\jsp-api.jar
set POSTGRES_JAR=%LIB_DIR%\postgresql-42.7.8.jar
set CLASSPATH=%LIB_DIR%\clustering_framework.jar;%OUTPUT_DIR%;%SERVLET_JAR%;%JSP_JAR%;%POSTGRES_JAR%

echo Classpath: %CLASSPATH%

cd /d %PROJECT_ROOT%

echo.
echo === Etape 1: Compilation des models ===
javac -parameters -d "%OUTPUT_DIR%" -cp "%CLASSPATH%" WEB-INF\models\*.java

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors de la compilation des models
    pause
    exit /b 1
)

echo === Etape 2: Compilation des controllers ===
javac -parameters -d "%OUTPUT_DIR%" -cp "%CLASSPATH%" WEB-INF\controllers\*.java

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors de la compilation des controllers
    pause
    exit /b 1
)

echo === Etape 3: Creation du fichier WAR ===
set WAR_NAME=reservation.war
set TOMCAT_WEBAPPS=C:\xampp\tomcat\webapps

jar cvf "%WAR_NAME%" -C . WEB-INF

if %ERRORLEVEL% NEQ 0 (
    echo ERREUR lors de la creation du WAR
    pause
    exit /b 1
)

echo === Etape 4: Deploiement dans Tomcat ===
if not exist "%TOMCAT_WEBAPPS%" (
    echo ERREUR: Repertoire Tomcat webapps introuvable: %TOMCAT_WEBAPPS%
    pause
    exit /b 1
)

copy /Y "%WAR_NAME%" "%TOMCAT_WEBAPPS%\"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ===================================
    echo Compilation et deploiement reussis!
    echo WAR genere: %WAR_NAME%
    echo Deploye dans: %TOMCAT_WEBAPPS%\%WAR_NAME%
    echo.
    echo Acces: http://localhost:8080/reservation/reservation/form
    echo ===================================
) else (
    echo.
    echo ERREUR DE DEPLOIEMENT
)

pause