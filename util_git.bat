@Echo Off
chcp 65001
SetLocal EnableDelayedExpansion
:: Inquisitor, 2013
:: Использованы следующие материалы:
:: Быстрое получение длины строки: CyberMuesli, http://forum.oszone.net/showpost.php?p=2164186
:: Получение 0x08: jeb, http://www.dostips.com/forum/viewtopic.php?p=6827#p6827
:: Идея передачи нескольких параметров: Diskretor, http://forum.oszone.net/post-2201046-7.html
:: MAIN GOD Dragokas http://www.cyberforum.ru/members/218284.html
:: Main logic with multi folders for git repo when working with addons DOTA2 - Kain(pvpby) owner this repo.  Version 1.0 Test Win7_x64 
cls
::SETTING here NEED change name your addon / тут НАДО изменить имя вашего аддона
set your_addon=SpellLibraryLua
Call :notok 10 || Exit /b
::DOWN DONT CHANGE! / Дальше настройки не трогать!
set reg_path=HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 570
set reg_param=InstallLocation
set git_temp_folder_content=content/
set git_temp_folder_game=game/
set git_folder_content=%git_temp_folder_content%%your_addon%
set git_folder_game=%git_temp_folder_game%%your_addon%

Call :EchoColor 0B "********************>>" 0E "CHECK" 0B "<<********************" /n
Echo.
Call :Reg_Read "%reg_path%" "%reg_param%" Value KeyType || Call :notok 1|| Exit /b

::full path to dota addon / полный путь к аддону в доте
set full_path_content=%Value%/content/dota_addons/%your_addon%
set full_path_game=%Value%/game/dota_addons/%your_addon%
set "full_path_content=%full_path_content:\=/%"
set "full_path_game=%full_path_game:\=/%"
::git path to repo / полный путь к аддону в хранилище git
set git_folder_content=%~dp0%git_folder_content%
set git_folder_game=%~dp0%git_folder_game%
set "git_folder_content=%git_folder_content:\=/%"
set "git_folder_game=%git_folder_game:\=/%"
::temp path for check / временные пути для проверки
set git_temp_folder_content=%~dp0%git_temp_folder_content%
set git_temp_folder_game=%~dp0%git_temp_folder_game%
set "git_temp_folder_content=%git_temp_folder_content:\=/%"
set "git_temp_folder_game=%git_temp_folder_game:\=/%"

If Exist "%full_path_content%\*.*" (
Call :EchoColor 0E "Link folder cont - Ok " 0A "%full_path_content%" /n
) ELSE (
Call :EchoColor 0C "Folder >> " 0E "%full_path_content%" 0C " << not found" /n
Call :notok 2&EXIT /B
)

If Exist "%full_path_game%\*.*" (
Call :EchoColor 0E "Link folder game - Ok " 0A "%full_path_game%" /n
) ELSE (
Call :EchoColor 0C "Folder >> " 0E "%full_path_game%" 0C " << not found" /n
Call :notok 3&EXIT /B
)

If Exist "%git_temp_folder_content%\*.*" (
IF Exist "%git_folder_content%\*.*" (Call :EchoColor 0C "Folder already exists >> " 0E "%git_folder_content%" 0C " << need DELETE" /n
Call :notok 4&EXIT /B
)
Call :EchoColor 0E "GIT folder cont - empty " 0A "%git_temp_folder_content%" /n
) ELSE (
Call :EchoColor 0C "Folder not found >> " 0E "%git_temp_folder_content%" 0C " << need CREATE" /n
Call :notok 5&EXIT /B
)

If Exist "%git_temp_folder_game%\*.*" (
IF Exist "%git_folder_game%\*.*" (Call :EchoColor 0C "Folder already exists >> " 0E "%git_folder_game%" 0C " << need DELETE" /n
Call :notok 6&EXIT /B
)
Call :EchoColor 0E "GIT folder cont - empty " 0A "%git_temp_folder_game%" /n
) ELSE (
Call :EchoColor 0C "Folder not found >> " 0E "%git_temp_folder_game%" 0C " << need CREATE" /n
Call :notok 7&EXIT /B
)
Echo.
Call :EchoColor 0B "******************>>" 0E " START " 0B "<<*******************" /n
Echo.

MKLINK /J "%git_folder_content%" "%full_path_content%" 1>nul 2>nul
if "%errorlevel%"=="0" (
Call :EchoColor 0D "LINK CREATE for >> " 0E "%git_folder_content%" 0D " << READY" /n
) ELSE (
Call :EchoColor 0C "LINK NOT CREATE for >> " 0E "%git_folder_content%" 0C " << FAIL" /n
Call :notok 8&EXIT /B
)
MKLINK /J "%git_folder_game%" "%full_path_game%" 1>nul 2>nul
if "%errorlevel%"=="0" (
Call :EchoColor 0D "LINK CREATE for >> " 0E "%git_folder_game%" 0D " << READY" /n
) ELSE (
Call :EchoColor 0C "LINK NOT CREATE for >> " 0E "%git_folder_game%" 0C " << FAIL" /n
Call :notok 9&EXIT /B
)
Echo.
Call :EchoColor 0B "******************>>" 0E "FINISH OK" 0B "<<*******************" /n

Exit /B

:notok [%~1=Erorrcount]
if "%~1"=="10" (
if "%your_addon%" == "addon" ( Call :EchoColor 0C "please EDIT " 0B "LINE 13" 0C " this file and specify the name of your " 0A "addon" /n 
Call :EchoColor 0C "use EDITOR this file like " 0A "codepage UTF-8 " 0C "notepade++ vscode etc" /n 
) && Exit /b
Exit /b
)
if NOT "%~1"=="0" (
if "%~1"=="1" ( Call :EchoColor 0C "registry reading problems" 0D " contact the autor Kain(pvpby)" /n )
Echo.
Call :EchoColor 0B "******************>>" 0C " ERROR #%1%" 0B " <<*****************" /n
Echo.
)
Exit /B

:Reg_Read
:: %1-вх.Ключ
:: %2-вх.Имя параметра
:: %3-исх.Переменная для хранения значения
:: %4-исх.(опционально)-Переменная для хранения типа параметра 
set "%~3="& if "%~4" neq "" set "%~4="
For /f "delims=" %%a In ('2^>NUL cmd /e:ON /v:ON /c "Reg.exe query "%~1" /v "%~2"^& echo ^!errorlevel^!"') do (
	set "tok_prev=!err!"
	set "err=%%a"
)
if "%err%" neq "0" Exit /B %err%
::Подсчитываем кол-во токенов в имени параметра, если оно состоит из пробелов
set "_param=%~2"
echo %_param% |>nul find " " && (
	set _toks=0
	set "_param="!_param: =" "!""
	for %%a in (%_param%) do set /A _toks+=1
) || set _toks=1
::Пропускаем полученное кол-во токенов при разборе вывода Reg Query
set _k_type=& set _k_value=
:Reg_Read_tok
for /f "tokens=1*" %%a in ("%tok_prev%") do (
	if !_toks! LEQ 0 (
		if not defined _k_type (
			set "_k_type=%%~a"
		) else (
			set "_k_value=!_k_value! %%~a"
		)
	)
	set /A _toks-=1
	set "tok_prev=%%b"
	if "%%b" neq "" goto Reg_Read_tok
)
set "%~3=%_k_value:~1%"& if "%~4" neq "" set "%~4=%_k_type%")
Exit /B 0

:EchoColor [%1=Color %2="Text" %3=/n (CRLF, optional)] (Support multiple arguments at once)
:: Вывод цветного текста. Ограничения - не выводится восклицательный знак, остальные спецсимволы разрешены.
:: Работа с более, чем одним набором параметров
If Not Defined multiple If Not "%~4"=="" (
	Call :EchoWrapper %*
	Set multiple=
	Exit /B
)
SetLocal EnableDelayedExpansion
If Not Defined BkSpace Call :EchoColorInit
:: Экранирование входящего текста от обратных и прямых слэшей, чистка некоторых символов.
Set "$Text=%~2"
Set "$Text=.%BkSpace%!$Text:\=.%BkSpace%\..\%BkSpace%%BkSpace%%BkSpace%!"
Set "$Text=!$Text:/=.%BkSpace%/..\%BkSpace%%BkSpace%%BkSpace%!"
Set "$Text=!$Text:"=\"!"
Set "$Text=!$Text:^^=^!"
:: Если XP, выводим обычный текст.
If "%isXP%"=="true" (
	<nul Set /P "=.!BkSpace!%~2"
	GoTo :unsupported
)
:: Подаем текст на stdout, не создавая временных файлов и используя трюк с путём.
:: В случае неудачи (проблемный\слишком длинный путь?) выводим текст as is, без расцветки.
:: Если результирующая длина строки (плюс уже имеющиеся там символы) превышает ширину консоли, то вывод тоже будет неудачным. Но получить текущую позицию каретки программно нельзя.
PushD "%~dp0"
2>nul FindStr /R /P /A:%~1 "^-" "%$Text%\..\%~nx0" nul
If !ErrorLevel! GTR 0 <nul Set /P "=.!BkSpace!%~2"
PopD
:: Убираем путь, имя файла и дефис с помощью рассчитаного ранее количества символов.
For /L %%A In (1,1,!BkSpaces!) Do <nul Set /P "=!BkSpace!"
:unsupported
:: Выводим CRLF, если указан третий аргумент.
If /I "%~3"=="/n" Echo.
EndLocal
GoTo :EOF

:EchoWrapper
:: Обработка аргументов поочерёдно
SetLocal EnableDelayedExpansion
:NextArg
Set multiple=true
:: Ох уж это удвоение "^" при передаче аргументов...
Set $Text=
Set $Text=%2
Set "$Text=!$Text:^^^^=^!"
If Not "%~3"=="" If /I Not "%~3"=="/n" (
	Shift&Shift
	Call :EchoColor %1 !$Text!
	GoTo :NextArg
) Else (
	Shift&Shift&Shift
	Call :EchoColor %1 !$Text! %3
	GoTo :NextArg
)
If "%~3"=="" Call :EchoColor %1 !$Text!
EndLocal
GoTo :EOF


:EchoColorInit
:: Отрабатывающая при первом запуске родительской функции инициализация нужных переменных
:: Важно! Под XP, в силу реализации тамошнего findstr, 0x08 в путях не работает, заменяясь на точку. Отключаем цветной вывод для XP.
For /F "tokens=2 delims=[]" %%A In ('Ver') Do (For /F "tokens=2,3 delims=. " %%B In ("%%A") Do (If "%%B"=="5" Set isXP=true))
:: Получаем комбинацию "0x08 0x20 0x08" с помощью prompt
For /F "tokens=1 delims=#" %%A In ('"Prompt #$H# & Echo On & For %%B In (1) Do rem"') Do Set "BkSpace=%%A"
:: Рассчитываем требуемое количество символов для подавления всего, кроме выводимого текста
Set ScriptFileName=%~nx0
Call :StrLen ScriptFileName
Set /A "BkSpaces=!strLen!+6"
GoTo :EOF

:StrLen [%1=VarName (not VALUE), ret !strLen!]
:: Получение длины строки
Set StrLen.S=A!%~1!
Set StrLen=0
For /L %%P In (12,-1,0) Do (
	Set /A "StrLen|=1<<%%P"
	For %%I In (!StrLen!) Do If "!StrLen.S:~%%I,1!"=="" Set /A "StrLen&=~1<<%%P"
)
GoTo :EOF

:: Эта строка должна быть последней и не оканчиваться на CRLF.
-