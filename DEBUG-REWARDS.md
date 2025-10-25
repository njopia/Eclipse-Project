# Sistema de Debug de Rewards

## Descripción
Menú admin para probar y debuggear rewards pasivos del sistema de leveling sin necesidad de subir de nivel realmente.

## Comandos Disponibles

### Menú Principal
```
sm_rewardsdebug  - Abre el menú de debug de rewards
sm_rdebug        - Alias corto para el menú de debug
```

### Comando de Nivel
```
sm_setlevel <jugador> <nivel>  - Establece el nivel temporal de un jugador
```
**Ejemplos:**
- `sm_setlevel @me 50` - Establece tu nivel a 50
- `sm_setlevel Player1 10` - Establece el nivel de Player1 a 10

## ConVar
```
leveling_debug_enabled "1"  - Habilita/deshabilita el sistema de debug (1 = on, 0 = off)
```

## Características del Menú

### 1. Rewards Pasivos
Lista completa de todos los rewards pasivos ordenados por nivel:
- **Double Jump** (Nivel 1)
- **Acrobatics** (Nivel 2)
- **Health Bonus** (Nivel 3)
- **Medic** (Nivel 4)
- **Pack Rat** (Nivel 6)
- **Desert Cobra** (Nivel 8)
- **Damage Reduction** (Nivel 9)
- **Gene Mutations I** (Nivel 10)
- **Self Revive** (Nivel 11)
- **Sleight of Hand** (Nivel 13)
- **Knife** (Nivel 15)
- **Hard to Kill** (Nivel 17)
- **Arms Dealer** (Nivel 19)
- **Gene Mutations II** (Nivel 20)
- **Surgeon** (Nivel 22)
- **Extreme Conditioning** (Nivel 24)
- **BullsEye** (Nivel 26)
- **Size Matters** (Nivel 29)
- **Gene Mutations III** (Nivel 30)
- **Master at Arms** (Nivel 32)
- **Hardened Stance** (Nivel 35)
- **Critical Hit** (Nivel 38)
- **Gene Mutations IV** (Nivel 40)
- **Commando** (Nivel 41)
- **Second Chance** (Nivel 44)
- **Laser Rounds** (Nivel 47)

### 2. Gestión de Nivel
Opciones rápidas para establecer niveles:
- Nivel 1
- Nivel 10
- Nivel 20
- Nivel 30
- Nivel 40
- Nivel 50
- Nivel personalizado (via comando)
- Reset nivel (eliminar override)

### 3. Acciones por Reward
Para cada reward puedes:
- **Activar este reward** - Activa el reward inmediatamente con mensaje
- **Establecer nivel temporal** - Establece tu nivel al nivel del reward para probarlo

## Uso Típico

### Escenario 1: Probar un reward específico
1. Ejecuta `sm_rdebug`
2. Selecciona "Rewards Pasivos"
3. Encuentra el reward que quieres probar (ej: "Critical Hit (Lvl 38)")
4. Selecciona "Activar este reward"
5. El reward se activa inmediatamente

### Escenario 2: Probar todos los rewards hasta cierto nivel
1. Ejecuta `sm_rdebug`
2. Selecciona "Gestión de Nivel"
3. Selecciona el nivel deseado (ej: "Nivel 40")
4. Todos los rewards hasta nivel 40 se aplicarán automáticamente

### Escenario 3: Establecer nivel personalizado
1. Ejecuta `sm_setlevel @me 25`
2. Ahora tienes todos los rewards del nivel 1 al 25

### Escenario 4: Resetear todo
1. Ejecuta `sm_rdebug`
2. Selecciona "Reset Todo"
3. Todos los overrides se eliminan, vuelves a tu nivel real

## Permisos
Requiere flag de admin ROOT (ADMFLAG_ROOT) para usar los comandos.

## Notas Importantes
- Los niveles establecidos con el sistema de debug son **temporales**
- Se resetean al desconectar/reconectar
- No afectan el nivel real del jugador en la base de datos
- Ideal para testing y debugging en servidor de desarrollo
- **NO usar en producción** - deshabilitar con `leveling_debug_enabled 0`

## Troubleshooting

### El menú no abre
- Verifica que tienes permisos de admin ROOT
- Verifica que `leveling_debug_enabled` está en 1
- Verifica que el plugin está cargado correctamente

### Los rewards no se aplican
- Asegúrate de estar en equipo survivor (team 2)
- Verifica que estás vivo
- Algunos rewards requieren condiciones específicas (ej: estar incapacitado para Desert Cobra)

### El nivel no persiste
- Esto es normal, el sistema de debug usa niveles temporales
- Para nivel persistente, usa el sistema de leveling real

## Integración con Sistema Real
El módulo de debug se integra con el sistema de leveling:
- Si hay un override de debug, se usa ese nivel
- Si no hay override, se usa el nivel real del jugador
- La función `LevelingDebug_GetForcedLevel(client)` retorna el nivel override o -1
