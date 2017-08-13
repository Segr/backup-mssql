@echo off

CALL config.cmd
SET "FOLDER_BACKUP=%CD%\BACKUP"
SET "FOLDER_TEMP=%CD%\TEMP"
SET "ADATE=%date:~6,4%-%date:~3,2%-%date:~0,2%"
SET "ATIME=%time:~0,2%-%time:~3,2%"
IF "%time:~0,1%"==" " SET "ATIME=0%time:~1,1%-%time:~3,2%"
SET "AFOLDER=%ADATE% %ATIME%"

ECHO -------------- %date% %time% -------------- >> "log.txt"

::
SET LOG=Test "%FOLDER_BACKUP%"
::
	IF NOT EXIST "%FOLDER_BACKUP%" md "%FOLDER_BACKUP%"
	IF NOT EXIST "%FOLDER_BACKUP%" (
		SET LOG=Error: Can't create folder "%FOLDER_BACKUP%".
		GOTO ERROR
	)
	ECHO . > "%FOLDER_BACKUP%\testfile.txt"
	IF NOT EXIST "%FOLDER_BACKUP%\testfile.txt" (
		SET LOG=Error: Can't write to folder "%FOLDER_BACKUP%".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_BACKUP%\testfile.txt" DEL /F /Q "%FOLDER_BACKUP%\testfile.txt"
::
ECHO %LOG%... Done.
ECHO %LOG%... Done. >> "log.txt"

::
SET LOG=Test "%FOLDER_TEMP%"
::
	IF NOT EXIST "%FOLDER_TEMP%" md "%FOLDER_TEMP%"
	IF NOT EXIST "%FOLDER_TEMP%" (
		SET LOG=Error: Can't create folder "%FOLDER_TEMP%".
		GOTO ERROR
	)
	ECHO . > "%FOLDER_TEMP%\testfile.txt"
	IF NOT EXIST "%FOLDER_TEMP%\testfile.txt" (
		SET LOG=Error: Can't write to folder "%FOLDER_TEMP%".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_TEMP%\testfile.txt" DEL /F /Q "%FOLDER_TEMP%\testfile.txt"
::
ECHO %LOG%... Done.
ECHO %LOG%... Done. >> "log.txt"

::
SET LOG=Clear FOLDER_TEMP
::
	IF EXIST "%FOLDER_TEMP%\*.*" DEL /F /Q "%FOLDER_TEMP%\*.*"
::
ECHO %LOG%... Done.
ECHO %LOG%... Done. >> "log.txt"

SET LOG=Search ARC
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
SET LOG=Find ARC in "%ARC_PATH%"
ECHO %LOG%... Done.
ECHO %LOG%... Done. >> "log.txt"

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
ECHO %LOG%... Done. >> "log.txt"

::
SET LOG=Get list of DB to getnamebases.txt
::
	"%SQL_CMD%" -U %SQL_USER% -P %SQL_PASS% -i "%FOLDER_TEMP%\getnamebases.sql" > "%FOLDER_TEMP%\getnamebases.txt"
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
ECHO %LOG%... Done. >> "log.txt"

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
ECHO %LOG%... Done. >> "log.txt"

::
SET LOG=Loop namebases.txt
::
	FOR /f "usebackq tokens=1 delims=," %%I in ("%FOLDER_TEMP%\namebases.txt") DO CALL :DBLOOP %%I
	IF EXIST "%FOLDER_TEMP%\namebases.txt" DEL /F /Q "%FOLDER_TEMP%\namebases.txt"
::
ECHO %LOG%... Done.
ECHO %LOG%... Done. >> "log.txt"

::
SET LOG=Delete old files in FOLDER_BACKUP
::
	FORFILES /p "%FOLDER_BACKUP%" /s /d -%COUNT_DAYS% /c "CMD /c DEL /f /a /q @file"
::
ECHO %LOG%... Done.
ECHO %LOG%... Done. >> "log.txt"

::
SET LOG=Clear FOLDER_TEMP
::
	IF EXIST "%FOLDER_TEMP%\*.*" DEL /F /Q "%FOLDER_TEMP%\*.*"
	IF EXIST "%FOLDER_TEMP%" RMDIR /Q "%FOLDER_TEMP%"
::
ECHO %LOG%... Done.
ECHO %LOG%... Done. >> "log.txt"

GOTO :EOF

:ERROR
ECHO %LOG%
ECHO %LOG% >> "log.txt"
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
	ECHO set @pathName = '%FOLDER_TEMP%\%1.bak' >> "%FOLDER_TEMP%\%1.sql"
	ECHO backup database [%1] to disk = @pathName with noformat, noinit, name = N'db_backup', skip, norewind, nounload, stats = 10 >> "%FOLDER_TEMP%\%1.sql"
	IF NOT EXIST "%FOLDER_TEMP%\%1.sql" (
		SET LOG=Error: Can't create backup script for "%1".
		GOTO ERROR
	)
::
ECHO %LOG%... Done.
ECHO %LOG%... Done. >> "log.txt"
::
SET LOG=Create backup for "%1"
::
	"%SQL_CMD%" -U %SQL_USER% -P %SQL_PASS% -i "%FOLDER_TEMP%\%1.sql" > NUL
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
ECHO %LOG%... Done. >> "log.txt"
IF EXIST "%FOLDER_TEMP%\%1.%ARC_EXT%" DEL /F /Q "%FOLDER_TEMP%\%1.%ARC_EXT%"

::
SET LOG=Create archive backup for "%1"
::
	"%ARC_PATH%\%ARC_EXE%" %ARC_PARM% "%FOLDER_TEMP%\%1.%ARC_EXT%" "%FOLDER_TEMP%\%1.bak" > NUL
	IF NOT EXIST "%FOLDER_TEMP%\%1.%ARC_EXT%" (
		SET LOG=Error: Can't create "%FOLDER_TEMP%\%1.%ARC_EXT%".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_TEMP%\%1.bak" DEL /F /Q "%FOLDER_TEMP%\%1.bak"
::
ECHO %LOG%... Done.
ECHO %LOG%... Done. >> "log.txt"

::
SET LOG=Test "%FOLDER_BACKUP%\%AFOLDER%"
::
	IF NOT EXIST "%FOLDER_BACKUP%\%AFOLDER%" md "%FOLDER_BACKUP%\%AFOLDER%"
	IF NOT EXIST "%FOLDER_BACKUP%\%AFOLDER%" (
		SET LOG=Error: Can't create folder "%FOLDER_BACKUP%\%AFOLDER%".
		GOTO ERROR
	)
	ECHO . > "%FOLDER_BACKUP%\%AFOLDER%\testfile.txt"
	IF NOT EXIST "%FOLDER_BACKUP%\%AFOLDER%\testfile.txt" (
		SET LOG=Error: Can't write to folder "%FOLDER_BACKUP%\%AFOLDER%".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_BACKUP%\%AFOLDER%\testfile.txt" DEL /F /Q "%FOLDER_BACKUP%\%AFOLDER%\testfile.txt"
::
ECHO %LOG%... Done.
ECHO %LOG%... Done. >> "log.txt"

::
SET LOG=Copy archive backup for "%1"
::
	COPY /Y "%FOLDER_TEMP%\%1.%ARC_EXT%" "%FOLDER_BACKUP%\%AFOLDER%\%AFILE%.%ARC_EXT%" > NUL
	IF NOT EXIST "%FOLDER_BACKUP%\%AFOLDER%\%AFILE%.%ARC_EXT%" (
		SET LOG=Error: Can't copy archive backup for "%1" to "%FOLDER_BACKUP%\%AFOLDER%".
		GOTO ERROR
	)
	IF EXIST "%FOLDER_TEMP%\%1.%ARC_EXT%" DEL /F /Q "%FOLDER_TEMP%\%1.%ARC_EXT%"
::
ECHO %LOG%... Done.
SET LOG=Copy archive backup for "%1" to "%FOLDER_BACKUP%\%AFOLDER%"
ECHO %LOG%... Done. >> "log.txt"