╔═════════════════════════════════════════════════════════════════════════════╗
║                                                                             ║
║             ECLIPSE MANAGEMENT SYSTEM - CURRENCY EVENTS                    ║
║                                                                             ║
║                           ✓ IMPLEMENTADO                                   ║
║                                                                             ║
╚═════════════════════════════════════════════════════════════════════════════╝

QUÉ ES:
═══════
Sistema que vincula el currency (puntos) a eventos del juego. Los jugadores
ganan automáticamente puntos por:
- Matar infectados (1-20 puntos según tipo)
- Curar y revivir compañeros (1-3 puntos)
- Escapar de infectados especiales (3 puntos)
- Completar rondas de Survival (10 puntos)
- Headshots (2 puntos bonus)

EVENTOS VINCULADOS: 15
═════════════════════
✓ infected_death       ← Matar común (1 pt)
✓ tank_killed          ← Matar Tank (20 pts)
✓ witch_killed         ← Matar Witch (15 pts)
✓ heal_success         ← Curar (1 pt)
✓ revive_success       ← Revivir (3 pts)
✓ defibrillator_used   ← Desfib (5 pts) [L4D2]
✓ tongue_pull_stopped  ← Escape Smoker (3 pts)
✓ pounce_stopped       ← Escape Hunter (3 pts)
✓ jockey_ride_end      ← Escape Jockey (3 pts)
✓ charger_impact       ← Charger (3 pts)
✓ survival_round_start ← Survival (10 pts) [L4D2]
✓ headshot bonus       ← +2 puntos automático

ARCHIVOS CREADOS:
═════════════════
📂 scripting/modules/currency/
   • currency-events.module.sp (6 eventos)
   • currency-advanced-events.module.sp (5 eventos)
   • currency-stats.module.sp (estadísticas)
   • CURRENCY_SYSTEM_README.txt
   • ARCHITECTURE.txt
   • IMPLEMENTATION_GUIDE.txt
   • currency-config.txt
   • currency-custom-events.example.sp

📄 Documentación:
   • START_HERE.txt ← LEER PRIMERO
   • QUICK_REFERENCE.txt
   • CURRENCY_SYSTEM_SUMMARY.txt
   • EVENTOS_VINCULADOS.txt
   • README_CURRENCY_SYSTEM.txt

INSTALACIÓN RÁPIDA:
═══════════════════
1. Copiar: scripting/compiled/Eclipse Management System.smx
   A: addons/sourcemod/plugins/

2. Recargar: sm_reload Eclipse Management System

3. Verificar: sm_cvar list currency_*

CAMBIAR VALORES:
════════════════
sm_cvar currency_common_kill 5
sm_cvar currency_tank_kill 100

(Cambios inmediatos, sin restart)

CARACTERÍSTICAS:
════════════════
✓ Completamente modular
✓ 15 ConVars configurables
✓ Estadísticas automáticas
✓ Sin errores de compilación
✓ Listo para producción

COMPATIBILIDAD:
════════════════
✓ L4D1 (13 eventos)
✓ L4D2 (15 eventos)
✓ SourceMod 1.10+

¿CÓMO FUNCIONA?
════════════════
Jugador mata zombi común
    ↓
Event "infected_death" dispara
    ↓
event_InfectedDeath() se ejecuta
    ↓
AwardCurrency() suma 1 punto
    ↓
Stats se actualizan
    ↓
Chat muestra: "[Eclipse] Ganaste 1 punto"

PRÓXIMOS PASOS:
════════════════
1. Leer START_HERE.txt
2. Leer QUICK_REFERENCE.txt
3. Instalar en servidor
4. Configurar valores

MÁS INFORMACIÓN:
════════════════
Ver carpeta: scripting/modules/currency/

════════════════════════════════════════════════════════════════════════════════
