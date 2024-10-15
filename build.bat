echo
echo  DKBros by Jon Wilson (10yard)
echo
echo ----------------------------------------------------------------------------------------------
echo  Build Windows x64 binary 
echo ----------------------------------------------------------------------------------------------

@echo off
rmdir build /s /Q
rmdir dist /s /Q

xcopy wolf256 dist\wolf256 /S /i /Y
rmdir dist\wolf256\cfg /s /Q
rmdir dist\wolf256\inp /s /Q
rmdir dist\wolf256\ui /s /Q
rmdir dist\wolf256\ini /s /Q
rmdir dist\wolf256\snap /s /Q
del dist\wolf256\session\*.* /Q
del dist\wolf256\ui.ini /Q
copy readme.md dist\readme.md /Y

"C:\Program Files\Python37\Scripts\pyinstaller" dkbros.py --onefile --clean --noconsole --icon dkafe.ico
"C:\Program Files (x86)\Windows Kits\10\bin\x86\signtool" sign /tr http://timestamp.digicert.com /n "Open Source Developer" dist\dkbros.exe

rmdir build /s /Q
del *.spec