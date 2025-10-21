@echo off
echo ========================================
echo Compilacion LIMPIA de ion.sp
echo ========================================
echo.

REM Ir a la carpeta scripting
cd /d "%~dp0scripting"

REM Eliminar .smx viejo si existe
if exist "compiled\ion.smx" (
    echo [1/4] Eliminando ion.smx viejo...
    del /F /Q "compiled\ion.smx"
    echo       ELIMINADO: compiled\ion.smx
) else (
    echo [1/4] No hay ion.smx previo
)
echo.

REM Compilar
echo [2/4] Compilando ion.sp...
echo.
spcomp ..\ion.sp -ocompiled\ion.smx
echo.

REM Verificar que se creo
if exist "compiled\ion.smx" (
    echo [3/4] EXITO: compiled\ion.smx creado
    dir compiled\ion.smx | find "ion.smx"
) else (
    echo [3/4] ERROR: No se creo ion.smx
    pause
    exit /b 1
)
echo.

echo [4/4] Compilacion completada
echo ========================================
echo.
echo SIGUIENTE PASO: Copiar compiled\ion.smx al servidor
echo.
pause
