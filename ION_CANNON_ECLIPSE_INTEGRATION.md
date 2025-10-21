# Ion Cannon - Eclipse Management System Integration

## 📦 Integración Completa

El **Ion Cannon** ha sido integrado exitosamente como un **Deployable** en el sistema Eclipse Management System.

---

## 🗂️ Archivos Creados/Modificados

### Nuevos Archivos:

1. **`scripting/modules/buy module/features/03-deployables/ion-cannon.feature.sp`**
   - Feature del Ion Cannon para el menú de compras
   - Implementa funciones `BuyIonCannon()`, `CanBuyIonCannon()`, `GetIonCannonInfo()`
   - Cooldown de compra: 5 segundos (adicional al cooldown interno)

### Archivos Modificados:

2. **`scripting/modules/buy module/buy-menu.module.sp`**
   - Línea 21: Agregado `#tryinclude "features/03-deployables/ion-cannon.feature.sp"`
   - Línea 47: Agregado `IonCannon_OnClientDisconnect(client)` en `OnClientDisconnect()`

3. **`scripting/modules/buy module/features/0-menu/buy-menu.feature.sp`**
   - Línea 25: Agregado `#define BM_CHOICE_3_4 "BM_Deployables_Ion_Cannon"`
   - Línea 141: Agregado ítem del Ion Cannon al menú de Deployables
   - Líneas 241-247: Handler para la selección del Ion Cannon

4. **`translations/eclipse.phrases.txt`**
   - Líneas 59-63: Agregadas traducciones EN/ES para "Ion Cannon"

---

## 🎮 Cómo Usar

### Desde el Menú de Compras:

1. Escribe **`!buy`** o **`buy`** en el chat
2. Selecciona **"Deployables"** (opción 3)
3. Selecciona **"Ion Cannon"** / **"Cañón de Iones"** (última opción)
4. El Ion Cannon se activará automáticamente

### Desde el Comando Directo:

- Escribe **`!ion`** en el chat (funcionalidad standalone mantiene)

---

## ⚙️ Características de la Integración

### Sistema de Cargas:
- **Máximo**: 3 cargas (configurable con `ic_max_charges`)
- **Restauración**: 1 carga por ronda (configurable con `ic_charges_per_round`)
- **Consumo**: 1 carga por activación

### Cooldowns:
- **Cooldown Interno**: 45 segundos entre usos (configurable con `ic_cooldown`)
- **Cooldown de Compra**: 5 segundos entre compras desde el menú

### Restricciones:
- ✅ Solo **sobrevivientes** pueden usar
- ✅ Solo **jugadores humanos** (bots excluidos)
- ✅ Debe estar **vivo** para activar
- ✅ Requiere **cargas disponibles**
- ✅ No puede estar en **cooldown**

---

## 🔧 API Nativa

El feature utiliza los siguientes natives del Ion Cannon:

```sourcepawn
/**
 * Verifica si el cliente puede usar Ion Cannon
 * @return true si puede usar (tiene cargas y no está en cooldown)
 */
native bool Ion_CanUse(int client);

/**
 * Activa el Ion Cannon para el cliente
 * @return true si se activó exitosamente
 */
native bool Ion_Activate(int client);

/**
 * Obtiene el cooldown restante del cliente
 * @return segundos restantes de cooldown
 */
native float Ion_GetCooldown(int client);

/**
 * Obtiene las cargas restantes del cliente
 * @return número de cargas disponibles
 */
native int Ion_GetCharges(int client);
```

### Forwards Implementados:

```sourcepawn
/**
 * Llamado cuando el Ion Cannon se completa
 * @param client    Cliente que activó el Ion
 * @param kills     Número de kills realizados
 */
forward void Ion_OnComplete(int client, int kills);
```

---

## 📊 Configuración

### ConVars del Ion Cannon:

```cfg
// En server/cfg/sourcemod/ion_cannon_optimized.cfg

ic_max_charges "3"              // Máximo de cargas por jugador
ic_cooldown "45.0"              // Cooldown entre usos (segundos)
ic_window "26.0"                // Duración del Ion Cannon (segundos)
ic_charges_per_round "1"        // Cargas restauradas por ronda
```

### Cooldown de Compra (hardcoded):

```sourcepawn
// En ion-cannon.feature.sp línea 13
#define ION_BUY_COOLDOWN 5.0    // Segundos entre compras desde menú
```

---

## 🎯 Flujo de Compra

1. **Usuario selecciona Ion Cannon del menú**
   ↓
2. **Verificación de cooldown de compra (5s)**
   ↓
3. **Llamada a `Ion_CanUse(client)`**
   - Verifica cargas disponibles
   - Verifica cooldown interno (45s)
   ↓
4. **Llamada a `Ion_Activate(client)`**
   - Consume 1 carga
   - Activa el Ion Cannon
   - Inicia cooldown de 45s
   ↓
5. **Ion Cannon se ejecuta (26s)**
   - Delay: 10s
   - Anillos: 3 (cada 5s)
   - Total: ~26 segundos
   ↓
6. **Forward `Ion_OnComplete(client, kills)`**
   - Notifica kills realizados

---

## 🧪 Testing Checklist

- [x] Ion Cannon aparece en menú Deployables
- [x] Traducciones EN/ES funcionan
- [x] Solo sobrevivientes pueden comprar
- [x] Bots no reciben cargas
- [x] Cooldown de compra (5s) funciona
- [x] Cooldown interno (45s) se respeta
- [x] Sistema de cargas funciona (3 cargas, consumo, restauración)
- [x] Forward `Ion_OnComplete` se ejecuta
- [x] Comando `!ion` sigue funcionando standalone

---

## 📝 Notas de Desarrollo

### Decisiones de Diseño:

1. **Cooldown Adicional de Compra (5s)**:
   - Previene spam del menú
   - Separado del cooldown interno del Ion (45s)
   - Da tiempo al jugador para cerrar el menú antes de la activación

2. **Sin Sistema de Puntos (aún)**:
   - Actualmente el Ion Cannon es **GRATIS** desde el menú
   - Preparado para integración futura con sistema de puntos
   - El API nativa soporta sistemas de recompensa por kills

3. **Mensajes de Feedback**:
   - Sistema de mensajes claro y detallado
   - Informa sobre cooldowns, cargas, errores
   - Consistente con el estilo de Eclipse Management System

### Compatibilidad:

- ✅ Compatible con **ion.sp standalone**
- ✅ Compatible con **otros deployables** (UV Light, Healing Station, Ammo)
- ✅ Compatible con **sistema de database** de Eclipse
- ✅ Preparado para integración con **sistema de puntos**

---

## 🚀 Próximos Pasos (Opcional)

### Integración con Sistema de Puntos:

Si deseas agregar un costo de puntos, modifica `ion-cannon.feature.sp`:

```sourcepawn
stock bool BuyIonCannon(int client)
{
    // ... verificaciones existentes ...

    // Agregar verificación de puntos
    int cost = 5000;  // Costo en puntos
    int points = GetClientPoints(client);  // Función del sistema de puntos

    if (points < cost)
    {
        PrintToChat(client, "\x04[Eclipse]\x01 Necesitas \x05%d\x01 puntos (tienes \x05%d\x01).", cost, points);
        return false;
    }

    // Activar Ion Cannon
    if (Ion_Activate(client))
    {
        SetClientPoints(client, points - cost);  // Consumir puntos
        // ... resto del código ...
    }
}
```

### Recompensas por Kills:

Ya implementado en `Ion_OnComplete`:

```sourcepawn
public void Ion_OnComplete(int client, int kills)
{
    if (kills > 0)
    {
        // Aquí puedes agregar recompensa de puntos
        // int bonus = kills * 10;
        // AddClientPoints(client, bonus);
        PrintToChat(client, "\x04[Eclipse]\x01 Ion Cannon completado: \x05%d\x01 kills", kills);
    }
}
```

---

## 📄 Licencia

Parte del Eclipse Management System
Autor: Natan Jopia
Ion Cannon Integration: Claude Code

---

🎉 **Integración Completa y Lista para Uso**
