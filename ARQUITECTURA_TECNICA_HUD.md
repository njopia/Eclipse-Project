# Arquitectura Técnica - Sistema HUD Dinámico

## Diagrama de Flujo

```
┌─────────────────────────────────────────────────────────────────────┐
│                  ECLIPSE MANAGEMENT SYSTEM (Main)                   │
│                    scripting/Eclipse Management System.sp           │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ├─► buyMenuOnPluginStart()
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    BUY MENU MODULE                                   │
│           scripting/modules/buy module/buy-menu.module.sp          │
│                                                                       │
│  - Includes: hud-system-display.feature.sp                          │
│  - Calls: HUDSystemDisplay_OnPluginStart()                          │
└──────────────────┬──────────────────────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────────────────────┐
│              HUD SYSTEM DISPLAY MODULE                               │
│         scripting/.../hud-system-display.feature.sp                │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ HUDSystemDisplay_OnPluginStart()                               │ │
│  │  - Crea Timer_UpdateHUDDisplayValues (intervalo: 0.5s)        │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │ Timer_UpdateHUDDisplayValues (cada 0.5 segundos)              │ │
│  │  ├─► BuildTeamBonusesHUDText()                                │ │
│  │  │    - Lee: GetTeamSpeedBoostRemaining(client)               │ │
│  │  │    - Lee: GetTeamHealCooldown(client)                      │ │
│  │  │    - Escribe: g_sHUD2_CustomText                           │ │
│  │  │                                                              │ │
│  │  └─► BuildDeployablesHUDText()                                │ │
│  │       - Lee: IsUVLightActive(client)                          │ │
│  │       - Lee: GetUVLightRemaining(client)                      │ │
│  │       - Lee: IsHealingStationActive(client)                   │ │
│  │       - Lee: GetHealingStationRemaining(client)               │ │
│  │       - Escribe: g_sHUD3_CustomText                           │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                       │
│  Stock Functions:                                                     │
│  - GetTeamBonusesHUDText(output, size)                              │
│  - GetDeployablesHUDText(output, size)                              │
└─────────────┬──────────────────────────────────────────────────────┘
              │
              │ (Forward declarations)
              │
              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                  L4D2 SCRIPTED HUD PLUGIN                            │
│                    l4d2_scripted_hud.sp                             │
│                                                                       │
│  Timer_UpdateHUD (periódicamente)                                   │
│  └─► UpdateHUD()                                                     │
│      └─► GetHUD_Texts()                                             │
│          ├─► GetHUD2_Text()                                         │
│          │    ├─ #if defined GetTeamBonusesHUDText                 │
│          │    │   └─► GetTeamBonusesHUDText(output, size)          │
│          │    │       (Obtiene datos dinámicos del sistema !buy)    │
│          │    │                                                      │
│          │    └─ else (Fallback)                                    │
│          │       └─► Mostrar información de Tank (original)         │
│          │                                                           │
│          └─► GetHUD3_Text()                                         │
│               ├─ #if defined GetDeployablesHUDText                 │
│               │   └─► GetDeployablesHUDText(output, size)          │
│               │       (Obtiene datos dinámicos de deployables)      │
│               │                                                      │
│               └─ else (Fallback)                                    │
│                  └─► Mostrar información de Survivors (original)    │
│                                                                      │
│  GameRules_SetPropString("m_szScriptedHUDStringSet", g_sHUD_Text)  │
│  └─► Renderiza en la pantalla del cliente                          │
└─────────────────────────────────────────────────────────────────────┘
```

## Flujo de Datos

### Actualización de HUD2 (Team Bonuses)

```
GetGameTime() = 1000.0
│
├─► Team Speed Boost
│   ├─ g_fSpeedBoostEnd[client] = 1300.0
│   ├─ GetTeamSpeedBoostRemaining(client) = 1300.0 - 1000.0 = 300.0
│   └─ Mostrar: "Speed Boost: 5:00"
│
├─► Team Heal
│   ├─ g_fNextTeamHeal[client] = 1025.0
│   ├─ GetTeamHealCooldown(client) = 1025.0 - 1000.0 = 25.0
│   └─ Mostrar: "Team Heal CD: 25s"
│
└─► Buffer
    g_sHUD2_CustomText = "=== TEAM BONUSES ===\nSpeed Boost: 5:00\nTeam Heal CD: 25s\nSurvivors: 4/4"
```

## Estructura de Datos

### Buffers Globales

```sourcepawn
static char g_sHUD2_CustomText[512];  // Texto dinámico para HUD2
static char g_sHUD3_CustomText[512];  // Texto dinámico para HUD3
```

### Definiciones de Control

```sourcepawn
#define HUD_UPDATE_INTERVAL 0.5  // Actualizar cada 0.5 segundos
```

## Mecanismo de Detección (Preprocessor)

### Directiva #if defined

En `l4d2_scripted_hud.sp`:

```sourcepawn
#if defined GetTeamBonusesHUDText
    GetTeamBonusesHUDText(output, size);
    if (output[0] != '\0')
        return;
#endif
```

**Cómo funciona**:
1. Si `hud-system-display.feature.sp` está compilado, se define la función
2. La directiva `#if defined` detecta su existencia en tiempo de compilación
3. Si existe, llama la función; si no, usa el fallback original

**Ventaja**: Completamente opcional y backwards-compatible

## Ciclo de Actualización

```
┌─────────────────────────────────────────────────────────────────┐
│ Frame N (T = 0.0s)                                              │
│                                                                  │
│ 1. Timer_UpdateHUDDisplayValues ejecuta                         │
│    ├─ BuildTeamBonusesHUDText() → g_sHUD2_CustomText           │
│    └─ BuildDeployablesHUDText() → g_sHUD3_CustomText           │
│                                                                  │
│ 2. Timer_UpdateHUD ejecuta (algunos milisegundos después)       │
│    └─ GetHUD2_Text() lee g_sHUD2_CustomText                    │
│       GetHUD3_Text() lee g_sHUD3_CustomText                    │
│                                                                  │
│ 3. GameRules_SetPropString() actualiza el HUD en clientes      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                           ↓
                   (esperar 0.5s)
                           ↓
┌─────────────────────────────────────────────────────────────────┐
│ Frame N+1 (T = 0.5s)                                            │
│                                                                  │
│ 1. Timer_UpdateHUDDisplayValues ejecuta nuevamente              │
│    └─ Ciclo se repite...                                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Manejo de Errores

### Fallbacks

```sourcepawn
// En hud-system-display.feature.sp
if (!IsClientInGame(client))
    continue;  // Saltar cliente inválido

if (speedBoostTime > 0.0)
    // Mostrar tiempo
else
    // Mostrar "READY"
```

### Tolerancia a Fallos

Si una función no existe:
- `GetTeamSpeedBoostRemaining()` → usa valor 0.0
- `GetTeamHealCooldown()` → usa valor 0.0
- `IsUVLightActive()` → usa valor false
- Resultado: No falla la compilación, solo no muestra ese dato

## Renderizado en Pantalla

```
┌─────────────────────────────────────────────────────────────────┐
│  CLIENTE LEFT 4 DEAD 2                                          │
│                                                                  │
│  ┌────────────────────────┐                                    │
│  │ === TEAM BONUSES ===  │  ← HUD2                            │
│  │ Speed Boost: 4:32     │  (posición: 0.01, 0.01)            │
│  │ Team Heal CD: 25s     │                                    │
│  │ Survivors: 4/4        │                                    │
│  └────────────────────────┘                                    │
│                                                                  │
│  ┌────────────────────────┐                                    │
│  │ === DEPLOYABLES ===   │  ← HUD3                            │
│  │ UV Light: 250s        │  (posición: 0.01, 0.12)            │
│  │ Healing Station: 180s │                                    │
│  └────────────────────────┘                                    │
│                                                                  │
│  [Game World]                                                   │
│                                                                  │
│                                                                  │
│                                                                  │
│                                                                  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## Performance

### Overhead Estimado

- **Timer de actualización**: 0.5 segundos
- **Operaciones por frame**:
  - Bucle sobre MaxClients (32): O(n)
  - Llamadas a funciones: O(1)
  - Formateo de strings: O(m) donde m es tamaño de buffer

- **CPU**: < 1% (operaciones muy simples)
- **Memoria**: ~1KB para buffers de HUD

### Optimizaciones

- Solo actualizar cada 0.5s (no cada frame)
- Almacenar en buffers estáticos para reutilización
- Evitar allocaciones dinámicas
- Usar operaciones de string eficientes

## Extensibilidad

### Agregar Nuevo Datos a HUD2

```sourcepawn
static void BuildTeamBonusesHUDText()
{
    // ... código existente ...

    // Nuevo dato
    float newData = GetSomeNewData();
    if (newData > 0.0)
    {
        Format(tempBuffer, sizeof(tempBuffer), "New Data: %.1f\n", newData);
        StrCat(buffer, sizeof(buffer), tempBuffer);
    }
}
```

### Agregar Nueva Función Stock

```sourcepawn
stock void GetNewHUDData(char[] output, int size)
{
    FormatEx(output, size, "Custom Data");
}
```

## Dependencias

### Requeridas
- SourceMod 1.10+
- l4d2_scripted_hud.sp (solo si desea mostrar los HUDs)
- sourcemod incluye (sourcemod.inc, sdktools.inc, etc.)

### Opcionales
- team-speed-boost.feature.sp
- team-heal.feature.sp
- uv-light.feature.sp
- healing-station.feature.sp

(Si no están presentes, simplemente no muestra esos datos)

## Testing Checklist

- [ ] Module compila sin errores
- [ ] HUDSystemDisplay_OnPluginStart() se ejecuta
- [ ] Timer se crea correctamente
- [ ] GetTeamBonusesHUDText() retorna texto válido
- [ ] GetDeployablesHUDText() retorna texto válido
- [ ] l4d2_scripted_hud detecta las funciones (#if defined)
- [ ] HUD2 aparece en pantalla con datos dinámicos
- [ ] HUD3 aparece en pantalla con datos dinámicos
- [ ] Los datos se actualizan en tiempo real
- [ ] No hay errores en sourcemod_errors.log

## Notas de Desarrollo

### Debugging

Para ver los textos generados, agregar a BuildTeamBonusesHUDText():

```sourcepawn
LogToFile(logfilepath, "HUD2 Text: %s", buffer);
```

### Cambios Futuros

1. **Agregar duración activa a Team Heal**: Modificar team-heal.feature.sp para agregar `g_fTeamHealEnd[client]`
2. **Mostrar cooldown en minutos**: Formatear como MM:SS en lugar de solo segundos
3. **Agregar más HUDs**: Usar HUD4 para información adicional
4. **Agregar animaciones**: Usar directivas de movimiento de HUD en l4d2_scripted_hud

## Referencias

- [L4D2 Scripted HUD Wiki](https://developer.valvesoftware.com/wiki/L4D2_EMS/Appendix:_HUD)
- SourceMod Scripting Documentation
- Eclipse Management System Documentación
