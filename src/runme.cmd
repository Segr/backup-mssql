@echo off

CALL config.cmd

SET "FOLDER_BACKUP=%CD%\BACKUP"

IF "%SQL_SERVER%" NEQ "" (
	SET "FOLDER_TEMP=\\%SQL_SERVER%\C$\Windows\Temp\BackUpTemp"
	SET "FOLDER_TEMP_LOCAL=C:\Windows\Temp\BackUpTemp"
) ELSE (
	SET "FOLDER_TEMP=%CD%\TEMP"
	SET "FOLDER_TEMP_LOCAL=%CD%\TEMP"
)

SET "ADATE=%date:~6,4%-%date:~3,2%-%date:~0,2%"
SET "ATIME=%time:~0,2%-%time:~3,2%"
IF "%time:~0,1%"==" " SET "ATIME=0%time:~1,1%-%time:~3,2%"
SET "AFOLDER=%ADATE% %ATIME%"

IF "%SQL_SERVER_USER%" NEQ "" SET "SQL_SERVER_USER= -u %SQL_SERVER_USER%"
IF "%SQL_SERVER_PASS%" NEQ "" SET "SQL_SERVER_PASS= -p %SQL_SERVER_PASS%"
IF "%SQL_USER%" NEQ "" SET "SQL_USER= -U %SQL_USER%"
IF "%SQL_PASS%" NEQ "" SET "SQL_PASS= -P %SQL_PASS%"

ECHO. > "%CD%\tmplog.txt"
ECHO -------------- %date% %time% -------------- >> "%CD%\tmplog.txt"
ECHO. >> "%CD%\tmplog.txt"

SET LOG=Search PsExec.exe
::
	IF NOT EXIST "%PsExec_PATH%\PsExec.exe" IF EXIST %windir%\system32\PsExec.exe SET "PsExec_PATH=%windir%\system32"
	IF NOT EXIST "%PsExec_PATH%\PsExec.exe" IF EXIST PsExec.exe SET "PsExec_PATH=%~dp0"
	IF NOT EXIST "%PsExec_PATH%\PsExec.exe" IF EXIST PsExec.exe SET "PsExec_PATH=%PsExec_PATH:~0,-1%"
	IF NOT EXIST "%PsExec_PATH%\PsExec.exe" FOR /f "Usebackq Tokens=1 delims=," %%I IN (`DIR %systemdrive%\PsExec.exe /o:-s/s/p/b`) DO SET "PsExec_PATH=%%~dpI"
	SET "LAST_CHAR=%PsExec_PATH:~-1%"
	if "%LAST_CHAR%"=="\" SET "PsExec_PATH=%PsExec_PATH:~0,-1%"
	IF NOT EXIST "%PsExec_PATH%\PsExec.exe" (
		SET LOG=Error: Can't find PsExec.exe.
		GOTO ERROR
	)
::
ECHO %LOG%... Done.
SET LOG=Find PsExec.exe in "%PsExec_PATH%"
ECHO %LOG% >> "%CD%\tmplog.txt"

SET "PsExec="
IF "%SQL_SERVER%" NEQ "" (
	SET "PsExec="%PsExec_PATH%\PsExec.exe"%SQL_SERVER_USER%%SQL_SERVER_PASS% \\%SQL_SERVER% "
)

::
SET LOG=Test "%FOLDER_BACKUP%"
::
	IF NOT EXIST "%FOLDER_BACKUP%" md "%FOLDER_BACKUP%"
	IF NOT EXIST "%FOLDER_BACKUP%" (
		SET LOG=Error: Can't create folder "%FOLDER_BACKUP%".
		GOTO ERROR
	)
	ECHO. > "%FOLDER_BACKUP%\testfile.txt"
	IF NOT EXIST "%FOLDER_BACKUP%\testfile.txt" (
		SET LOG=Error: Can't write to folder "%FOLDER_BACKUP%".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_BACKUP%\testfile.txt" DEL /F /Q "%FOLDER_BACKUP%\testfile.txt"
::
ECHO %LOG%... Done.
SET LOG=Folder "%FOLDER_BACKUP%" exists and open for write.
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Test "%FOLDER_TEMP%"
::
	IF NOT EXIST "%FOLDER_TEMP%" md "%FOLDER_TEMP%"
	IF NOT EXIST "%FOLDER_TEMP%" (
		SET LOG=Error: Can't create folder "%FOLDER_TEMP%".
		GOTO ERROR
	)
	ECHO. > "%FOLDER_TEMP%\testfile.txt"
	IF NOT EXIST "%FOLDER_TEMP%\testfile.txt" (
		SET LOG=Error: Can't write to folder "%FOLDER_TEMP%".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_TEMP%\testfile.txt" DEL /F /Q "%FOLDER_TEMP%\testfile.txt"
::
ECHO %LOG%... Done.
SET LOG=Folder "%FOLDER_TEMP%" exists and open for write.
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Clear "%FOLDER_TEMP%"
::
	IF EXIST "%FOLDER_TEMP%\*.*" DEL /F /Q "%FOLDER_TEMP%\*.*"
::
ECHO %LOG%... Done.
SET LOG=Folder "%FOLDER_TEMP%" clearing.
ECHO %LOG% >> "%CD%\tmplog.txt"

SET LOG=Search %ARC_EXE%
::
	IF "%ARC_FOLDER%" NEQ "" IF EXIST "%programfiles%\%ARC_FOLDER%\%ARC_EXE%" SET "ARC_PATH=%programfiles%\%ARC_FOLDER%"
	IF "%ARC_FOLDER%" NEQ "" IF EXIST "%programfiles(x86)%\%ARC_FOLDER%\%ARC_EXE%" SET "ARC_PATH=%programfiles(x86)%\%ARC_FOLDER%"
	IF NOT EXIST "%ARC_PATH%\%ARC_EXE%" IF EXIST %windir%\system32\%ARC_EXE% SET "ARC_PATH=%windir%\system32"
	IF NOT EXIST "%ARC_PATH%\%ARC_EXE%" IF EXIST %ARC_EXE% SET "ARC_PATH=%~dp0"
	IF NOT EXIST "%ARC_PATH%\%ARC_EXE%" IF EXIST %ARC_EXE% SET "ARC_PATH=%ARC_PATH:~0,-1%"
	IF NOT EXIST "%ARC_PATH%\%ARC_EXE%" FOR /f "Usebackq Tokens=1 delims=," %%I IN (`DIR %systemdrive%\%ARC_EXE% /o:-s/s/p/b`) DO SET "ARC_PATH=%%~dpI"
	SET "LAST_CHAR=%ARC_PATH:~-1%"
	if "%LAST_CHAR%"=="\" SET "ARC_PATH=%ARC_PATH:~0,-1%"
	IF NOT EXIST "%ARC_PATH%\%ARC_EXE%" (
		SET LOG=Error: Can't find %ARC_EXE%.
		GOTO ERROR
	)
::
ECHO %LOG%... Done.
SET LOG=Find %ARC_EXE% in "%ARC_PATH%"
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Create SQL for get DB
::
	ECHO declare @version varchar(14) > "%FOLDER_TEMP%\getnamebases.sql"
	ECHO select @version = cast(serverproperty('ProductVersion') as varchar(14)) >> "%FOLDER_TEMP%\getnamebases.sql"
	ECHO if substring(@version, 1, charindex('.', @version) - 1) ^>= 9 >>"%FOLDER_TEMP%\getnamebases.sql"
	ECHO select name from sys.databases>>"%FOLDER_TEMP%\getnamebases.sql"
	ECHO else select name from sysdatabases>>"%FOLDER_TEMP%\getnamebases.sql"
	IF NOT EXIST "%FOLDER_TEMP%\getnamebases.sql" (
		SET LOG=Error: Can't create "%FOLDER_TEMP%\getnamebases.sql".
		GOTO ERROR
	)
::
ECHO %LOG%... Done.
SET LOG=Create SQL for get DB "%FOLDER_TEMP%\getnamebases.sql"
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Get list of DB to getnamebases.txt
::
	%PsExec% "%SQL_CMD%"%SQL_USER%%SQL_PASS% -i "%FOLDER_TEMP_LOCAL%\getnamebases.sql" > "%FOLDER_TEMP%\getnamebases.txt"
	IF /i %ERRORLEVEL% GEQ 1 (
		SET LOG=Error: Can't connect to SQL.
		GOTO ERROR
	)
	IF NOT EXIST "%FOLDER_TEMP%\getnamebases.txt" (
		SET LOG=Error: Can't create "%FOLDER_TEMP%\getnamebases.txt".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_TEMP%\getnamebases.sql" DEL /F /Q "%FOLDER_TEMP%\getnamebases.sql"
::
ECHO %LOG%... Done.
SET LOG=Get list of DB to "%FOLDER_TEMP%\getnamebases.txt"
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Get list of DB, exclude sys to namebases.txt
::
	FINDSTR /i /v "( %EXCLUDE_DB% -" "%FOLDER_TEMP%\getnamebases.txt" > "%FOLDER_TEMP%\namebases.txt"
	IF NOT EXIST "%FOLDER_TEMP%\namebases.txt" (
		SET LOG=Error: Can't create "%FOLDER_TEMP%\namebases.txt".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_TEMP%\getnamebases.txt" DEL /F /Q "%FOLDER_TEMP%\getnamebases.txt"
::
ECHO %LOG%... Done.
SET LOG=Get list of DB, exclude sys to "%FOLDER_TEMP%\namebases.txt"
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Test "%FOLDER_BACKUP%\%AFOLDER%"
::
	IF NOT EXIST "%FOLDER_BACKUP%\%AFOLDER%" md "%FOLDER_BACKUP%\%AFOLDER%"
	IF NOT EXIST "%FOLDER_BACKUP%\%AFOLDER%" (
		SET LOG=Error: Can't create folder "%FOLDER_BACKUP%\%AFOLDER%".
		GOTO ERROR
	)
	ECHO. > "%FOLDER_BACKUP%\%AFOLDER%\testfile.txt"
	IF NOT EXIST "%FOLDER_BACKUP%\%AFOLDER%\testfile.txt" (
		SET LOG=Error: Can't write to folder "%FOLDER_BACKUP%\%AFOLDER%".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_BACKUP%\%AFOLDER%\testfile.txt" DEL /F /Q "%FOLDER_BACKUP%\%AFOLDER%\testfile.txt"
::
ECHO %LOG%... Done.
SET LOG=Folder "%FOLDER_BACKUP%\%AFOLDER%" exists and open for write.
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Loop namebases.txt
::
	FOR /f "usebackq tokens=1 delims=," %%I in ("%FOLDER_TEMP%\namebases.txt") DO CALL :DBLOOP %%I
	IF EXIST "%FOLDER_TEMP%\namebases.txt" DEL /F /Q "%FOLDER_TEMP%\namebases.txt"
::
ECHO %LOG%... Done.
SET LOG=Done backup DB.
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Delete old files in FOLDER_BACKUP
::
	FORFILES /p "%FOLDER_BACKUP%" /s /d -%COUNT_DAYS% /c "CMD /c DEL /f /a /q @file"
::
ECHO %LOG%... Done.
SET LOG=Delete old files in "%FOLDER_BACKUP%".
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Clear FOLDER_TEMP
::
	IF EXIST "%FOLDER_TEMP%\*.*" DEL /F /Q "%FOLDER_TEMP%\*.*"
	IF EXIST "%FOLDER_TEMP%" RMDIR /Q "%FOLDER_TEMP%"
::
ECHO %LOG%... Done.
SET LOG=Clear and delete "%FOLDER_TEMP%".
ECHO %LOG% >> "%CD%\tmplog.txt"

IF NOT EXIST "%CD%\backuplog.txt" ECHO. > "%CD%\backuplog.txt"
COPY /Y "%CD%\backuplog.txt"+"%CD%\tmplog.txt" "%CD%\backuplog.txt"
IF EXIST "%CD%\tmplog.txt" DEL /F /Q "%CD%\tmplog.txt"

GOTO :EOF

:ERROR
ECHO %LOG%
ECHO %LOG% >> "%CD%\tmplog.txt"

if EXIST "%CD%\%MAIL_EXE%" (
	"%CD%\%MAIL_EXE%" -f %MAIL_FROM% -o message-file=%CD%\tmplog.txt -u subject %MAIL_SUBJECT% -t %MAIL_TO% -s %MAIL_SERVER%
)

IF NOT EXIST "%CD%\backuplog.txt" ECHO. > "%CD%\backuplog.txt"
COPY /Y "%CD%\backuplog.txt"+"%CD%\tmplog.txt" "%CD%\backuplog.txt"
IF EXIST "%CD%\tmplog.txt" DEL /F /Q "%CD%\tmplog.txt"

EXIT
GOTO :EOF

:DBLOOP
IF "%1"=="" GOTO :EOF
IF "%1"==" " GOTO :EOF

SET "ADATE=%date:~6,4%-%date:~3,2%-%date:~0,2%"
SET "ATIME=%time:~0,2%-%time:~3,2%"
IF "%time:~0,1%"==" " SET "ATIME=0%time:~1,1%-%time:~3,2%"
SET "AFILE=%1 (%ADATE% %ATIME%)"

::
SET LOG=Create backup script for "%1"
::
	ECHO declare @pathName nvarchar(512) > "%FOLDER_TEMP%\%1.sql"
	ECHO set @pathName = '%FOLDER_TEMP_LOCAL%\%1.bak' >> "%FOLDER_TEMP%\%1.sql"
	ECHO backup database [%1] to disk = @pathName with noformat, noinit, name = N'db_backup', skip, norewind, nounload, stats = 10 >> "%FOLDER_TEMP%\%1.sql"
	IF NOT EXIST "%FOLDER_TEMP%\%1.sql" (
		SET LOG=Error: Can't create backup script for "%1".
		GOTO ERROR
	)
::
ECHO %LOG%... Done.
SET LOG=Create backup script "%FOLDER_TEMP%\%1.sql"
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Create backup for "%1"
::
	%PsExec% "%SQL_CMD%"%SQL_USER%%SQL_PASS% -i "%FOLDER_TEMP_LOCAL%\%1.sql" > NUL
	IF /i %ERRORLEVEL% GEQ 1 (
		SET LOG=Error: Can't connect to SQL for backup "%1".
		GOTO ERROR
	)
	IF NOT EXIST "%FOLDER_TEMP%\%1.bak" (
		SET LOG=Error: Can't create "%FOLDER_TEMP%\%1.bak".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_TEMP%\%1.sql" DEL /F /Q "%FOLDER_TEMP%\%1.sql"
::
ECHO %LOG%... Done.
SET LOG=Create backup for "%1" to "%FOLDER_TEMP_LOCAL%\%1.bak".
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Copy backup for "%1"
::
	COPY /Y "%FOLDER_TEMP%\%1.bak" "%FOLDER_BACKUP%\%AFOLDER%\%1.bak" > NUL
	IF NOT EXIST "%FOLDER_BACKUP%\%AFOLDER%\%1.bak" (
		SET LOG=Error: Can't copy backup for "%1" to "%FOLDER_BACKUP%\%AFOLDER%".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_TEMP%\%1.bak" DEL /F /Q "%FOLDER_TEMP%\%1.bak"
::
ECHO %LOG%... Done.
SET LOG=Copy backup for "%1" to "%FOLDER_BACKUP%\%AFOLDER%\%1.bak"
ECHO %LOG% >> "%CD%\tmplog.txt"

::
SET LOG=Create archive backup for "%1"
::
	IF EXIST "%FOLDER_BACKUP%\%AFOLDER%\%AFILE%.%ARC_EXT%" DEL /F /Q "%FOLDER_BACKUP%\%AFOLDER%\%AFILE%.%ARC_EXT%"
	
	"%ARC_PATH%\%ARC_EXE%" %ARC_PARM% "%FOLDER_BACKUP%\%AFOLDER%\%AFILE%.%ARC_EXT%" "%FOLDER_BACKUP%\%AFOLDER%\%1.bak" > NUL
	IF NOT EXIST "%FOLDER_BACKUP%\%AFOLDER%\%AFILE%.%ARC_EXT%" (
		SET LOG=Error: Can't create "%FOLDER_BACKUP%\%AFOLDER%\%AFILE%.%ARC_EXT%".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_BACKUP%\%AFOLDER%\%1.bak" DEL /F /Q "%FOLDER_BACKUP%\%AFOLDER%\%1.bak"
::
ECHO %LOG%... Done.
SET LOG=Create archive backup for "%1" to "%FOLDER_BACKUP%\%AFOLDER%\%AFILE%.%ARC_EXT%".
ECHO %LOG% >> "%CD%\tmplog.txt"
