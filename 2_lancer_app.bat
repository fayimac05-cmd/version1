@echo off
title ScolarHub - App Flutter (Chrome)
echo ============================================
echo   ScolarHub - Demarrage de l'APP (Flutter)
echo   Ouvre l'application dans Chrome
echo ============================================
echo.
echo   /!\ Assurez-vous que le backend tourne deja
echo       (double-cliquez d'abord 1_lancer_backend.bat)
echo.
cd /d "%~dp0"
call flutter run -d chrome
echo.
echo L'app s'est arretee. Appuyez sur une touche pour fermer.
pause >nul
