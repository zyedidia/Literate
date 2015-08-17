@echo off
SET dir=%~dp0
%dir%..\gen\lua53.exe %dir%lit.lua %dir%..\gen %*
