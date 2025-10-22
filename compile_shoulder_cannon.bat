@echo off
echo ========================================
echo Compilacion de shoulder_cannon.sp
echo ========================================
echo.

REM Ir a la carpeta scripting
cd /d "%~dp0scripting"

REM Eliminar .smx viejo si existe
if exist "compiled\shoulder_cannon.smx" (
    echo [1/4] Eliminando shoulder_cannon.smx viejo...
    del /F /Q "compiled\shoulder_cannon.smx"
    echo       ELIMINADO: compiled\shoulder_cannon.smx
) else (
    echo [1/4] No hay shoulder_cannon.smx previo
)
echo.

REM Compilar
echo [2/4] Compilando shoulder_cannon.sp...
echo.
"c:\Users\Socius\Desktop\sourcemod\addons\sourcemod\scripting\spcomp.exe" ..\shoulder_cannon.sp -ocompiled\shoulder_cannon.smx
echo.

REM Verificar que se creo
if exist "compiled\shoulder_cannon.smx" (
    echo [3/4] EXITO: compiled\shoulder_cannon.smx creado
    dir compiled\shoulder_cannon.smx | find "shoulder_cannon.smx"
) else (
    echo [3/4] ERROR: No se creo shoulder_cannon.smx
    pause
    exit /b 1
)
echo.

echo [4/4] Compilacion completada
echo ========================================
echo.
echo SIGUIENTE PASO: Copiar compiled\shoulder_cannon.smx al servidor
echo.
pause
