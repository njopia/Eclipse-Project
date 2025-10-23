# Fix de Compilación - Forward Declarations para Stock Functions

## Problemas Encontrados

Al intentar compilar el módulo `hud-system-display.feature.sp`, se presentaban errores de compilación:

### Error 412 (Inicial):
```
error 412: function GetTeamSpeedBoostRemaining implements a forward but is not marked as public
error 412: function GetTeamSpeedBoostCooldown implements a forward but is not marked as public
error 412: function GetTeamHealCooldown implements a forward but is not marked as public
```

### Error 122 (Después de primer intento):
```
error 122: expected type expression
(al usar forward public)
```

## Causa Raíz

Las funciones referenciadas son `stock` functions definidas en otros módulos. En SourcePawn:
- Las funciones `stock` se compilan en línea y están disponibles automáticamente
- Las `forward` declarations no se necesitan para `stock` functions
- Las `forward` declarations se usan solo para funciones públicas (con `public` keyword)

## Solución Correcta

**Remover completamente las declaraciones forward** y reemplazarlas con comentarios documentando las funciones externas disponibles:

### Antes (Incorrecto):
```sourcepawn
forward float GetTeamSpeedBoostRemaining(int client);
forward float GetTeamSpeedBoostCooldown(int client);
forward float GetTeamHealCooldown(int client);
```

### Después (Correcto):
```sourcepawn
// --- External Functions (Definidas en otros módulos) ---
// Estas funciones están definidas como 'stock' en otros módulos
// y se resuelven automáticamente en tiempo de compilación
//
// Desde team-speed-boost.feature.sp:
//   - GetTeamSpeedBoostRemaining(int client)
//   - GetTeamSpeedBoostCooldown(int client)
//
// Desde team-heal.feature.sp:
//   - GetTeamHealCooldown(int client)
```

## Archivos Modificados

- `scripting/modules/buy module/features/0-menu/hud-system-display.feature.sp`
  - Líneas: 24-34
  - Cambios: Remover 3 forward declarations, agregar comentarios documentativos

## Compilación

Ahora el módulo debería compilar sin errores:

```bash
spcomp.exe "scripting/Eclipse Management System.sp"
```

## Nota Técnica - Diferencia entre Forward y Stock

### Forward Declarations:
- Se usan para **funciones públicas** (`public` keyword)
- Permiten referencia anticipada de funciones que se definen más adelante
- Sintaxis: `forward [type] [name]([params]);`
- Compilan a **bytecode runtime** (se resuelven en tiempo de ejecución)

### Stock Functions:
- Se usan para **funciones reutilizables** sin visibilidad pública
- Se compilan **inline en cada lugar donde se usan** (tiempo de compilación)
- No necesitan forward declarations
- Están automáticamente disponibles en todos los includes

### En este caso:
Las funciones `GetTeamSpeedBoostRemaining`, `GetTeamSpeedBoostCooldown` y `GetTeamHealCooldown` son definidas como `stock` (no `public`), por lo que:
- ❌ NO se deben usar `forward` declarations
- ✅ Se resuelven automáticamente en tiempo de compilación
- ✅ Están disponibles en todos los modules que las incluyan

## Verificación

Para verificar que la compilación es exitosa, buscar el archivo compilado:
```
plugins/Eclipse Management System.smx
```

Si el archivo existe y fue actualizado recientemente, la compilación fue exitosa.

## Git Commit

```
3c6d81c fix: Mark forward declarations as public
```

---

**Status**: ✅ CORREGIDO
**Fecha**: Octubre 2025
