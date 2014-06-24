@echo off
REM JBoss, the OpenSource webOS
REM
REM Distributable under LGPL license.
REM See terms of license at gnu.org.
REM -------------------------------------------------------------------------
REM  Red Hat JBoss EAP 6 Service Script for Windows
REM    It has to reside in one of:
REM      %JBOSS_HOME%\bin
REM      %JBOSS_HOME%\modules\native\sbin\
REM      %JBOSS_HOME%\modules\system\layers\base\native\sbin\
REM
REM  v6 2013-08-21 added /name /desc
REM                added /serviceuser /servicepass
REM                extended directory checking for versions and locations
REM                extended checking on option usage
REM  v5	2013-06-10 adapted for EAP 6.1.0
REM  v4	2012-10-03 Small changes to properly handles spaces in LogPath, StartPath,
REM                and StopPath (George Rypysc)
REM  v3	2012-09-14 fixed service log path
REM                cmd line options for controller,domain host, loglevel,
REM		   username,password
REM  v2	2012-09-05 NOPAUSE support
REM  v1	2012-08-20 initial edit
REM
REM Author: Tom Fonteyne (unless noted above)
REM ========================================================
setlocal EnableExtensions EnableDelayedExpansion

set "DIRNAME=%~dp0%"
if exist "%DIRNAME%..\jboss-modules.jar" (
  REM we are in JBOSS_HOME/bin
  set "WE=%DIRNAME%..\"
) else if exist "%DIRNAME%..\..\..\jboss-modules.jar" (
  REM we are in sbin in a 6.0.x installation
  set "WE=%DIRNAME%..\..\..\"
) else (
  REM we should be in sbin in 6.1 and up
  set "WE=%DIRNAME%..\..\..\..\..\..\"
)
pushd "%WE%"
set "RESOLVED_JBOSS_HOME=%CD%"
popd
set WE=
set DIRNAME=

if "x%JBOSS_HOME%" == "x" (
  set "JBOSS_HOME=%RESOLVED_JBOSS_HOME%" 
)

pushd "%JBOSS_HOME%"
set "SANITIZED_JBOSS_HOME=%CD%"
popd

rem debug
rem echo "SANITIZED_JBOSS_HOME=%SANITIZED_JBOSS_HOME%"
rem echo "RESOLVED_JBOSS_HOME=%RESOLVED_JBOSS_HOME%"
rem echo "JBOSS_HOME=%JBOSS_HOME%"

if "%RESOLVED_JBOSS_HOME%" NEQ "%SANITIZED_JBOSS_HOME%" (
    echo WARNING JBOSS_HOME may be pointing to a different installation - unpredictable results may occur.
    goto cmdEnd
)
rem Find jboss-modules.jar to check JBOSS_HOME
if not exist "%JBOSS_HOME%\jboss-modules.jar" (
  echo Could not locate "%JBOSS_HOME%\jboss-modules.jar".
  goto cmdEnd
)

set PRUNSRV=
if exist "%JBOSS_HOME%\modules\native\sbin\prunsrv.exe" (
  rem EAP 6.0.0 and 6.0.1
  set PRUNSRV="%JBOSS_HOME%\modules\native\sbin\prunsrv.exe"
) else if exist "%JBOSS_HOME%\modules\system\layers\base\native\sbin\prunsrv.exe" (
  rem EAP 6.1.0 (and up)
  set PRUNSRV="%JBOSS_HOME%\modules\system\layers\base\native\sbin\prunsrv.exe"
) else (
  REM could happen if the user copied the batch file manually
  echo Native package not installed
  goto cmdEnd
)

echo(

rem echo PRUNSRV=%PRUNSRV%

rem defaults
set SHORTNAME=JBossEAP6
set DISPLAYNAME=JBossEAP6
set DESCRIPTION="JBoss Enterprise Application Platform 6"
set CONTROLLER=localhost:9999
set DC_HOST=master
set IS_DOMAIN=false
set LOGLEVEL=INFO
set JBOSSUSER=
set JBOSSPASS=
set SERVICE_USER=
set SERVICE_PASS=

set COMMAND=%1
shift
if /I "%COMMAND%" == "install"   goto cmdInstall
if /I "%COMMAND%" == "uninstall" goto cmdUninstall
if /I "%COMMAND%" == "start"     goto cmdStart
if /I "%COMMAND%" == "stop"      goto cmdStop
if /I "%COMMAND%" == "restart"   goto cmdRestart

echo ERROR: invalid command

:cmdUsage
echo Red Hat JBoss EAP 6 Service Script for Windows
echo Usage:
echo(
echo   service install ^<options^>  , where the options are:
echo(
echo     /controller ^<host:port^>   : The host:port of the management interface
echo                                 default: %CONTROLLER%
echo     /host [^<domainhost^>]      : Indicates that domain mode is to be used with an optional domain controller name
echo                                 default: %DC_HOST%
echo                                 Not specifying /host will install JBoss in standalone mode
echo     /loglevel ^<level^>         : The log level for the service:  Error, Info, Warn or Debug ^(Case insensitive^)
echo                                 default: %LOGLEVEL% 
echo(
echo     /name ^<servicename^>       : The name of the service - should not contain spaces
echo                                 default: %SHORTNAME%
echo     /desc ^<description^>     : The description of the service, use double quotes to allow spaces
echo                                 default: %DESCRIPTION%
echo     /serviceuser ^<username^>   : Specifies the name of the account under which the service should run.
echo                                 Use an account name in the form DomainName\UserName
echo                                 default: not used, the service runs as Local System Account.
echo     /servicepass ^<password^>   : password for /serviceuser
echo(
echo     /jbossuser ^<username^>     : jboss username to use for the shutdown command
echo     /jbosspass ^<password^>     : password for /jbossuser
echo(
echo Other commands:	
echo(	
echo   service uninstall [/name ^<servicename^>]
echo   service start [/name ^<servicename^>]
echo   service stop [/name ^<servicename^>]
echo   service restart [/name ^<servicename^>]
echo(
echo     /name  ^<servicename^>      : The name of the service - should not contain spaces
echo                                 default: %SHORTNAME%
echo(
echo(
goto endBatch

:cmdInstall

:LoopArgs
if "%~1" == "" goto doInstall

if /I "%~1"== "/controller" (
  set CONTROLLER=
  if not "%~2"=="" (  
    set T="%~2"
    if not "!T:~0,1!"=="/" (
      set CONTROLLER="%~2"
    )
  )
  if "!CONTROLLER!" == "" (
    echo ERROR: The management interface should be specified in the format host:port, example:  127.0.0.1:9999
    goto endBatch
  )
  shift
  shift
  goto LoopArgs
)
if /I "%~1"== "/name" (
  set SHORTNAME=
  if not "%~2"=="" (
    set T="%~2"
    if not "!T:~0,1!"=="/" (
      set SHORTNAME="%~2"
      set DISPLAYNAME="%~2"
    )
  )
  if "!SHORTNAME!" == "" (
    echo ERROR: You need to specify a service name
    goto endBatch
  )
  shift
  shift
  goto LoopArgs
)
if /I "%~1"== "/desc" (
  set DESCRIPTION=
  if not "%~2"=="" (
    set T="%~2"
    if not "!T:~0,1!"=="/" (
      set DESCRIPTION="%~2"
    )
  )
  if "!DESCRIPTION!" == "" (
    echo ERROR: You need to specify a description
    goto endBatch
  )
  shift
  shift
  goto LoopArgs
)
if /I "%~1"== "/jbossuser" (
  set JBOSSUSER=
  if not "%~2"=="" (
    set T="%~2"
    if not "!T:~0,1!"=="/" (
      set JBOSSUSER="%~2"
    )
  )
  if "!JBOSSUSER!" == "" (
    echo ERROR: You need to specify a username
    goto endBatch
  )
  shift
  shift
  goto LoopArgs
)
if /I "%~1"== "/jbosspass" (
  set JBOSSPASS=
  if not "%~2"=="" (
    set T="%~2"
    if not "!T:~0,1!"=="/" (
      set JBOSSPASS="%~2"
    )
  )
  if "!JBOSSPASS!" == "" (
    echo ERROR: You need to specify a password for /jbosspass
    goto endBatch
  )
  shift
  shift
  goto LoopArgs
)
if /I "%~1"== "/serviceuser" (
  set SERVICE_USER=
  if not "%~2"=="" (
    set T="%~2"
    if not "!T:~0,1!"=="/" (
      set SERVICE_USER="%~2"
    )
  )
  if "!SERVICE_USER!" == "" (
    echo ERROR: You need to specify a username in the format DOMAIN\USER, or .\USER for the local domain
    goto endBatch
  )
  shift
  shift
  goto LoopArgs
)
if /I "%~1"== "/servicepass" (
  set SERVICE_PASS=
  if not "%~2"=="" (
    set T="%~2"
    if not "!T:~0,1!"=="/" (
      set SERVICE_PASS="%~2"
    )
  )
  if "!SERVICE_PASS!" == "" (
    echo ERROR: You need to specify a password for /servicepass
    goto endBatch
  )
  shift
  shift
  goto LoopArgs
)
if /I "%~1"== "/host" (
  set IS_DOMAIN=true
  if not "%~2"=="" (
    set T="%~2"
    if not "!T:~0,1!"=="/" (
      set DC_HOST="%~2"
      shift
    )
  )
  shift
  goto LoopArgs
)
if /I "%~1"== "/loglevel" (
  if /I not "%~2"=="Error" if /I not "%~2"=="Info" if /I not "%~2"=="Warn" if /I not "%~2"=="Debug" (
    echo ERROR: /loglevel must be set to Error, Info, Warn or Debug ^(Case insensitive^)
    goto endBatch      
  )
  set LOGLEVEL="%~2"
  shift
  shift
  goto LoopArgs
)
echo ERROR: Unrecognised option: %1
echo(
goto cmdUsage

:doInstall
set CREDENTIALS=
if not "%JBOSSUSER%" == "" (
  if "%JBOSSPASS%" == "" (
    echo When specifying a user, you need to specify the password
    goto endBatch
  )
  set CREDENTIALS=--user=%JBOSSUSER% --password=%JBOSSPASS%
)

set RUNAS=
if not "%SERVICE_USER%" == "" (
  if "%SERVICE_PASS%" == "" (
    echo When specifying a user, you need to specify the password
    goto endBatch
  )
  set RUNAS=--ServiceUser %SERVICE_USER% --ServicePassword %SERVICE_PASS%
)

if /I "%IS_DOMAIN%" == "true" (
  set STARTPARAM="/c \"set NOPAUSE=Y ^^^&^^^& domain.bat\""
  set STOPPARAM="/c jboss-cli.bat --controller=%CONTROLLER% --connect %CREDENTIALS% --command=/host=!DC_HOST!:shutdown"
  set LOGPATH=%JBOSS_HOME%\domain\log
) else (
  set STARTPARAM="/c \"set NOPAUSE=Y ^^^&^^^& standalone.bat\""
  set STOPPARAM="/c jboss-cli.bat --controller=%CONTROLLER% --connect %CREDENTIALS% --command=:shutdown"
  set LOGPATH=%JBOSS_HOME%\standalone\log
)

echo(
rem echo SHORTNAME=%SHORTNAME%
rem echo DESCRIPTION=%DESCRIPTION%
rem echo STARTPARAM=%STARTPARAM%
rem echo STOPPARAM=%STOPPARAM%
rem echo LOGLEVEL=%LOGLEVEL%
rem echo CREDENTIALS=%CREDENTIALS%

rem echo on
%PRUNSRV% install %SHORTNAME% %RUNAS% --DisplayName=%DISPLAYNAME% --Description %DESCRIPTION% --LogLevel=%LOGLEVEL% --LogPath="%LOGPATH%" --LogPrefix=service --StdOutput=auto --StdError=auto --StartMode=exe --StartImage=cmd.exe --StartPath="%JBOSS_HOME%\bin" ++StartParams=%STARTPARAM% --StopMode=exe --StopImage=cmd.exe --StopPath="%JBOSS_HOME%\bin"  ++StopParams=%STOPPARAM%
rem @echo off
goto cmdEnd


REM the other commands take a /name parameter - if there is no ^<servicename^> passed as second parameter,
REM we silently ignore this and use the default SHORTNAME

:cmdUninstall
if /I "%~1"=="/name" (
  if not "%~2"=="" (
    set SHORTNAME="%~2"
  )
) 
%PRUNSRV% stop %SHORTNAME%
if "%errorlevel%" == "0" (
  %PRUNSRV% delete %SHORTNAME%
) else (
  echo Unable to stop the service
)
goto cmdEnd

:cmdStart
if /I "%~1"=="/name" (
  if not "%~2"=="" (
    set SHORTNAME="%~2"
  )
)
%PRUNSRV% start %SHORTNAME%
goto cmdEnd

:cmdStop
if /I "%~1"=="/name" (
  if not "%~2"=="" (
    set SHORTNAME="%~2"
  )
)
%PRUNSRV% stop %SHORTNAME%
goto cmdEnd

:cmdRestart
if /I "%~1"=="/name" (
  if not "%~2"=="" (
    set SHORTNAME="%~2"
  )
)
%PRUNSRV% stop %SHORTNAME%
if "%errorlevel%" == "0" (
  %PRUNSRV% start %SHORTNAME%
) else (
  echo Unable to stop the service
)
goto cmdEnd


:cmdEnd
REM if there is a need to add other error messages, make sure to list higher numbers first !
if errorlevel 8 (
  echo ERROR: The service %SHORTNAME% already exists
  goto endBatch
)
if errorlevel 2 (
  echo ERROR: Failed to load service configuration
  goto endBatch
)
if errorlevel 0 (
  goto endBatch
)
echo "Unforseen error=%errorlevel%"

rem nothing below, exit
:endBatch


