@echo off
title Ferramenta de Suporte Tecnico
color 0A

:: ============================================
:: VERIFICACAO DE ADMINISTRADOR
:: ============================================

net session >nul 2>&1
if %errorLevel% neq 0 (
    cls
    echo ========================================
    echo    FERRAMENTA DE SUPORTE TECNICO
    echo ========================================
    echo.
    echo [ATENCAO] 
    echo.
    echo Esta ferramenta precisa de permissoes de Administrador
    echo para funcionar completamente.
    echo.
    echo Clique em "SIM" na proxima janela para continuar.
    echo.
    echo ========================================
    echo.
    
    :: Relanca como administrador
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: ============================================
:: EXECUCAO DO SCRIPT
:: ============================================

cd /d "%~dp0"
cls

echo ========================================
echo    FERRAMENTA DE SUPORTE TECNICO
echo    Modo Administrador: ATIVADO
echo ========================================
echo.
echo Iniciando a ferramenta...
echo.

powershell.exe -ExecutionPolicy Bypass -NoProfile -File "SupportTool.ps1"

echo.
echo ========================================
echo    FERRAMENTA FINALIZADA
echo ========================================
echo.
echo Pressione qualquer tecla para fechar...
pause >nul
exit