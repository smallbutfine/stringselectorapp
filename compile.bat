@echo off
chcp 65001 >nul
title Lazarus Projekt-Kompilierer

echo ====================================================
echo       LAZARUS AUTOMATISCHER COMPILER-START         
echo ====================================================
echo.

:: 1. Pfad zu lazbuild automatisch ermitteln (Standard-Installationspfade)
set "LAZ_PATH="

if exist "C:\lazarus\lazbuild.exe" (
    set "LAZ_PATH=C:\lazarus\lazbuild.exe"
) else if exist "C:\Program Files\Lazarus\lazbuild.exe" (
    set "LAZ_PATH=C:\Program Files\Lazarus\lazbuild.exe"
) else if exist "C:\Program Files (x86)\Lazarus\lazbuild.exe" (
    set "LAZ_PATH=C:\Program Files (x86)\Lazarus\lazbuild.exe"
)

:: Falls lazbuild im globalen System-PATH liegt, direkt nutzen
where lazbuild >nul 2>nul
if %errorlevel% equ 0 (
    set "LAZ_PATH=lazbuild"
)

:: Sicherheitsprüfung, falls Lazarus nicht gefunden wurde
if "%LAZ_PATH%"=="" (
    color 0C
    echo [FEHLER] 'lazbuild.exe' konnte nicht gefunden werden!
    echo Bitte stellen Sie sicher, dass Lazarus korrekt installiert ist.
    echo.
    goto ENDE
)

:: 2. Kompilierung starten
echo Verwendeter Compiler: %LAZ_PATH%
echo Starte Kompilierung von 'StringSelectorApp.lpi'...
echo ----------------------------------------------------
echo.

"%LAZ_PATH%" StringSelectorApp.lpi

echo.
echo ----------------------------------------------------
if %errorlevel% equ 0 (
    color 0A
    echo [ERFOLG] Die Anwendung wurde fehlerfrei kompiliert!
    echo Sie können die 'StringSelectorApp.exe' jetzt starten.
) else (
    color 0C
    echo [FEHLER] Bei der Kompilierung sind Fehler aufgetreten.
    echo Bitte prüfen Sie die obige Compiler-Ausgabe.
)

:ENDE
echo.
echo ====================================================
echo Drücken Sie eine beliebige Taste, um zu schließen.
pause >nul
