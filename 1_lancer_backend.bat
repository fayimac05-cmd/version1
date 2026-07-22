@echo off
title ScolarHub - Backend (port 5000)
echo ============================================
echo   ScolarHub - Demarrage du BACKEND (API)
echo   http://localhost:5000
echo ============================================
echo.
cd /d "%~dp0backend"
call npm start
echo.
echo Le backend s'est arrete. Appuyez sur une touche pour fermer.
pause >nul
