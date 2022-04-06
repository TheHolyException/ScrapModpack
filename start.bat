@Echo off
:loop
cls
rem java -jar ScrapInstaller.jar
java -jar ScrapInstaller.jar -instDir="I:\SteamLibrary\steamapps\common\Scrap Mechanic" -alwaysConfirm
pause
goto loop