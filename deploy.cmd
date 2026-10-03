@echo off
call "%~dp0kubernates\deploy.cmd" %*
exit /b %errorlevel%
