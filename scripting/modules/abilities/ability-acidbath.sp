//==================================================
// === ACID BATH ABILITY (Level 9) ===
// Makes spitter goo heal you instead of hurt you
// Duration: 60 seconds
// Cooldown: 5 minutes
//==================================================

/**
 * Activa Acid Bath
 */
bool Ability_AcidBath_Activate(int client)
{
	// Pantalla verde (R:0, G:255, B:0, Alfa:100)
	FX_FadeCustom(client, 107, 224, 136, 100);

	PrintToChat(client, "\x04[Acid Bath]\x01 El acido de Spitter ahora te cura!");
	return true;
}

/**
 * Desactiva Acid Bath
 */
void Ability_AcidBath_Deactivate(int client)
{
	FX_ClearFade(client);
	PrintToChat(client, "\x04[Acid Bath]\x01 Acid Bath deactivated");
}

/**
 * Hook de daño para Acid Bath
 */
public Action AcidBath_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (victim <= 0 || victim > MaxClients || !IsClientInGame(victim))
		return Plugin_Continue;

	// Si el jugador tiene Acid Bath activo
	if (!Abilities_IsActive(victim, Ability_AcidBath))
		return Plugin_Continue;

	// Verificar si el daño es de Spitter (ácido)
	// damagetype 1056 es ácido de spitter
	if (damagetype & DMG_RADIATION || damagetype & DMG_ACID)
	{
		// Convertir daño en curación
		int health	   = GetClientHealth(victim);
		int maxHealth  = GetEntProp(victim, Prop_Data, "m_iMaxHealth");
		int healAmount = RoundToFloor(damage);

		if (health + healAmount > maxHealth)
		{
			healAmount = maxHealth - health;
		}

		if (healAmount > 0)
		{
			SetEntityHealth(victim, health + healAmount);
			PrintHintText(victim, "Acid Bath: +%d HP", healAmount);
		}

		// Bloquear el daño original
		damage = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}
