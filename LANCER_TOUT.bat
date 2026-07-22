@echo off
title ScolarHub - Lanceur
echo ============================================
echo   ScolarHub - Lancement complet
echo ============================================
echo.
echo   1) Demarrage du backend (port 5000)...
start "ScolarHub - Backend" cmd /k "cd /d "%~dp0backend" && npm start"

echo   2) Attente de 8 secondes que le backend soit pret...
timeout /t 8 /nobreak >nul

echo   3) Demarrage de l'app Flutter (Chrome)...
start "ScolarHub - App" cmd /k "cd /d "%~dp0" && flutter run -d chrome"

echo.
echo   Termine ! Deux fenetres se sont ouvertes :
echo     - "ScolarHub - Backend"  (le serveur API)
echo     - "ScolarHub - App"      (l'application)
echo.
echo   Fermez ces deux fenetres pour tout arreter.
echo   Cette fenetre-ci peut etre fermee.
echo.
pause
