# Consolidado de Comandos — Eclipse Management System

Este documento contiene la lista completa de comandos disponibles en el proyecto, extraídos de los módulos de nivel, economía, habilidades y gestión de servidor.

## 1. Comandos de Jugador (Chat Triggers)

| Comando | Descripción | Módulo |
|:---|:---|:---|
| `!menu` | Abre el menú principal de Eclipse. | Main Menu |
| `!buy` | Abre la tienda / menú de compras. | Buy Module |
| `!level` / `!xp` / `!exp` | Muestra el nivel actual, XP y progreso. | Leveling System |
| `!abilities` | Abre el menú de gestión de habilidades activas. | Abilities System |
| `!frags` | Abre el panel de estadísticas de bajas (Frags). | Frags System |
| `!afk` | Mueve al jugador al equipo de Espectadores. | Management |
| `!join` | Intenta unir al jugador al equipo de Supervivientes. | Management |
| `!language` | Permite cambiar el idioma del plugin para el cliente. | Lang Module |
| `!mapvote` | Inicia o abre el menú de votación de mapas. | Map Vote |

## 2. Comandos de Administración

| Comando | Acceso | Descripción |
|:---|:---|:---|
| `sm_reload_hud` | ADMFLAG_ROOT | Recarga los mensajes del HUD desde la base de datos. |
| `sm_currency <player>` | ADMFLAG_ROOT | Consulta el balance de puntos de un jugador. |
| `sm_test_currency` | ADMFLAG_ROOT | Simula un evento para otorgar puntos de prueba. |
| `!givemoney <amount>` | ADMFLAG_BAN | Otorga una cantidad específica de puntos al objetivo. |
| `sm_ems_precache_reload` | ADMFLAG_CONFIG | Recarga todos los recursos precacheados. |

## 3. Comandos de Emergencia y Soporte
Estos comandos están diseñados para solucionar problemas visuales o de red durante la partida.

| Comando | Descripción |
|:---|:---|
| `sm_fix_white_screen` | Solución integral: limpia Fades, Fog Controllers y restaura la iluminación. |
| `sm_clear_fade` | Purga cualquier efecto de color (overlay) persistente en la pantalla. |
| `sm_clear_fog` | Elimina controladores de niebla dinámicos que puedan obstruir la visión. |

---

## Notas Técnicas

- **Persistencia de Currency**: Los puntos ganados mediante comandos o eventos persisten durante la sesión del servidor pero se resetean al desconectar (a menos que se migren a base de datos).
- **Niveles**: El progreso de los comandos `!level` se guarda automáticamente en la base de datos `players`.
- **Traducciones**: Todos los mensajes de respuesta de estos comandos están localizados en `translations/eclipse.phrases.txt`.

---
*Generado automáticamente basado en la inspección del código fuente del proyecto.*