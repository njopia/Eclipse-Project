#if defined _difficulty_base_included
	#endinput
#endif
#define _difficulty_base_included

#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

// =============================================================================
// FADE FLAGS
// =============================================================================

#if !defined FFADE_IN
	#define FFADE_IN       0x0001
#endif
#if !defined FFADE_OUT
	#define FFADE_OUT      0x0002
#endif
#if !defined FFADE_MODULATE
	#define FFADE_MODULATE 0x0004
#endif
#if !defined FFADE_STAYOUT
	#define FFADE_STAYOUT  0x0008
#endif
#if !defined FFADE_PURGE
	#define FFADE_PURGE    0x0010
#endif

// =============================================================================
// SCREEN FADE
// =============================================================================

stock void DiffBase_DoScreenFadeAll(bool activate, int r, int g, int b, int alpha, int duration)
{
	if (!activate)
	{
		Handle hPurge = StartMessageAll("Fade");
		if (hPurge != null)
		{
			BfWriteShort(hPurge, 0);
			BfWriteShort(hPurge, 0);
			BfWriteShort(hPurge, FFADE_PURGE);
			BfWriteByte(hPurge, 0);
			BfWriteByte(hPurge, 0);
			BfWriteByte(hPurge, 0);
			BfWriteByte(hPurge, 0);
			EndMessage();
		}
	}

	int hold  = activate ? 999999 : 0;
	int flags = activate ? (FFADE_IN | FFADE_STAYOUT) : FFADE_OUT;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;
		_DiffBase_WriteFade(i, r, g, b, alpha, duration, hold, flags);
	}

	if (!activate)
		CreateTimer(float(duration) / 1000.0 + 0.05, _DiffBase_Timer_PurgeFadeOnce, _, TIMER_FLAG_NO_MAPCHANGE);
}

stock void DiffBase_ApplyFadeToClient(int client, int r, int g, int b, int alpha, int duration)
{
	if (!IsClientInGame(client) || IsFakeClient(client)) return;
	_DiffBase_WriteFade(client, r, g, b, alpha, duration, 999999, FFADE_IN | FFADE_STAYOUT);
}

static stock void _DiffBase_WriteFade(int client, int r, int g, int b, int alpha, int duration, int hold, int flags)
{
	Handle hFade = StartMessageOne("Fade", client);
	if (hFade == null) return;
	BfWriteShort(hFade, duration);
	BfWriteShort(hFade, hold);
	BfWriteShort(hFade, flags);
	BfWriteByte(hFade, r);
	BfWriteByte(hFade, g);
	BfWriteByte(hFade, b);
	BfWriteByte(hFade, alpha);
	EndMessage();
}

public Action _DiffBase_Timer_PurgeFadeOnce(Handle t, any data)
{
	Handle h = StartMessageAll("Fade");
	if (h != null)
	{
		BfWriteShort(h, 0);
		BfWriteShort(h, 0);
		BfWriteShort(h, FFADE_PURGE);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		BfWriteByte(h, 0);
		EndMessage();
	}
	return Plugin_Stop;
}

// =============================================================================
// FOG CONTROLLER
// =============================================================================

stock void DiffBase_DisableMapFogControllers(int ownRef)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "env_fog_controller")) != -1)
	{
		if (ownRef != -1 && entity == EntRefToEntIndex(ownRef)) continue;
		AcceptEntityInput(entity, "TurnOff");
	}
}

stock int DiffBase_SpawnFogController(const char[] color, int fogStart, int fogEnd, float density, int ownRef)
{
	DiffBase_DisableMapFogControllers(ownRef);

	int ent = CreateEntityByName("env_fog_controller");
	if (ent == -1) return -1;

	char sDensity[16], sStart[16], sEnd[16];
	FloatToString(density, sDensity, sizeof(sDensity));
	IntToString(fogStart, sStart,   sizeof(sStart));
	IntToString(fogEnd,   sEnd,     sizeof(sEnd));

	DispatchKeyValue(ent, "fogcolor",      color);
	DispatchKeyValue(ent, "fogstart",      sStart);
	DispatchKeyValue(ent, "fogend",        sEnd);
	DispatchKeyValue(ent, "fogmaxdensity", sDensity);
	DispatchKeyValue(ent, "fogenable",     "1");
	DispatchSpawn(ent);
	AcceptEntityInput(ent, "TurnOn");

	return ent;
}

stock void DiffBase_ApplyFogSettings(int ent, const char[] color, int fogStart, int fogEnd, float density)
{
	if (ent == -1 || !IsValidEntity(ent)) return;

	SetVariantString(color);
	AcceptEntityInput(ent, "SetColor");
	SetVariantInt(fogStart);
	AcceptEntityInput(ent, "SetStartDist");
	SetVariantInt(fogEnd);
	AcceptEntityInput(ent, "SetEndDist");
	SetVariantFloat(density);
	AcceptEntityInput(ent, "SetMaxDensity");
	AcceptEntityInput(ent, "TurnOn");
}

stock void DiffBase_EnsureFogController(int& fogRef, const char[] color, int fogStart, int fogEnd, float density)
{
	// Re-disable map fog controllers every tick — the game re-enables them after
	// a few seconds via map entity I/O, causing a smooth transition that wipes our fog.
	DiffBase_DisableMapFogControllers(fogRef);

	int ent = EntRefToEntIndex(fogRef);
	if (ent == -1 || !IsValidEntity(ent))
	{
		ent = DiffBase_SpawnFogController(color, fogStart, fogEnd, density, fogRef);
		fogRef = (ent != -1) ? EntIndexToEntRef(ent) : -1;
	}
	else
	{
		DiffBase_ApplyFogSettings(ent, color, fogStart, fogEnd, density);
	}
}

stock void DiffBase_RemoveFogController(int& fogRef)
{
	int ent = EntRefToEntIndex(fogRef);
	if (ent != -1 && IsValidEntity(ent))
		RemoveEntity(ent);
	fogRef = -1;
}

// =============================================================================
// AMBIENT PARTICLES
// =============================================================================

stock void DiffBase_CreateAmbientParticles(const char[] name, int count, int[] refs, int& total)
{
	total = 0;
	if (!name[0] || count < 1) return;
	if (count > 16) count = 16;

	PrecacheGeneric(name, true);

	for (int i = 0; i < count; i++)
	{
		int ent = CreateEntityByName("info_particle_system");
		if (ent == -1) continue;

		DispatchKeyValue(ent, "effect_name",  name);
		DispatchKeyValue(ent, "start_active", "1");

		float pos[3];
		pos[0] = float(i * 64);
		pos[1] = float((i % 3) * 96);
		pos[2] = 72.0;
		TeleportEntity(ent, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchSpawn(ent);
		ActivateEntity(ent);
		AcceptEntityInput(ent, "Start");

		refs[total++] = EntIndexToEntRef(ent);
	}
}

stock void DiffBase_RemoveAmbientParticles(int[] refs, int& total)
{
	for (int i = 0; i < total; i++)
	{
		int ent = EntRefToEntIndex(refs[i]);
		if (ent != -1 && IsValidEntity(ent))
		{
			AcceptEntityInput(ent, "Stop");
			RemoveEntity(ent);
		}
		refs[i] = -1;
	}
	total = 0;
}

// =============================================================================
// LIGHT STYLE
// =============================================================================

stock void DiffBase_ApplyLightStyle(const char[] ls)
{
	if (ls[0]) SetLightStyle(0, ls);
}

// =============================================================================
// SOUND
// =============================================================================

stock void DiffBase_PlaySoundToAll(const char[] sample)
{
	if (!sample[0]) return;
	PrecacheSound(sample, true);
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			EmitSoundToClient(i, sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_RAIDSIREN, _, 1.0);
}

stock void DiffBase_StopSoundToAll(const char[] sample)
{
	if (!sample[0]) return;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			StopSound(i, SNDCHAN_STATIC, sample);
}

// =============================================================================
// DIRECTOR
// =============================================================================

stock void DiffBase_BackupDirector(
	Handle hCommonLimit, Handle hMobMin, Handle hMobMax, Handle hMegaMob, Handle hDiff,
	int& origCommon, int& origMin, int& origMax, int& origMega,
	char[] origDiff, int diffLen)
{
	if (origCommon  == -1   && hCommonLimit != null) origCommon = GetConVarInt(hCommonLimit);
	if (origMin     == -1   && hMobMin      != null) origMin    = GetConVarInt(hMobMin);
	if (origMax     == -1   && hMobMax      != null) origMax    = GetConVarInt(hMobMax);
	if (origMega    == -1   && hMegaMob     != null) origMega   = GetConVarInt(hMegaMob);
	if (origDiff[0] == '\0' && hDiff        != null) GetConVarString(hDiff, origDiff, diffLen);
}

stock void DiffBase_ApplyDirector(
	Handle hCommonLimit, Handle hMobMin, Handle hMobMax, Handle hMegaMob,
	int common, int min, int max, int mega)
{
	if (hCommonLimit) SetConVarInt(hCommonLimit, common);
	if (hMobMin)      SetConVarInt(hMobMin,      min);
	if (hMobMax)      SetConVarInt(hMobMax,      max);
	if (hMegaMob)     SetConVarInt(hMegaMob,     mega);
}

stock void DiffBase_RestoreDirector(
	Handle hCommonLimit, Handle hMobMin, Handle hMobMax, Handle hMegaMob, Handle hDiff,
	int origCommon, int origMin, int origMax, int origMega, const char[] origDiff)
{
	if (hCommonLimit && origCommon != -1) SetConVarInt(hCommonLimit, origCommon);
	if (hMobMin      && origMin    != -1) SetConVarInt(hMobMin,      origMin);
	if (hMobMax      && origMax    != -1) SetConVarInt(hMobMax,      origMax);
	if (hMegaMob     && origMega   != -1) SetConVarInt(hMegaMob,     origMega);
	if (hDiff && origDiff[0] != '\0')    ServerCommand("z_difficulty %s", origDiff);
}

// =============================================================================
// DAMAGE MULTIPLIER
// =============================================================================

stock Action DiffBase_ApplyDamageMult(
	int victim, int attacker, int inflictor,
	float& damage, bool isActive, float mult, bool debug, const char[] prefix)
{
	if (!isActive)                                       return Plugin_Continue;
	if (!DiffBase_IsValidClient(victim))                 return Plugin_Continue;
	if (GetClientTeam(victim) != 2)                      return Plugin_Continue;
	if (mult <= 1.0)                                     return Plugin_Continue;

	bool fromSpecial = DiffBase_IsValidClient(attacker) && GetClientTeam(attacker) == 3;
	bool fromCommon  = false;

	if (!fromSpecial)
	{
		char cls[32];
		if (IsValidEdict(attacker) && attacker > MaxClients)
			GetEdictClassname(attacker, cls, sizeof(cls));
		else if (IsValidEdict(inflictor) && inflictor > MaxClients)
			GetEdictClassname(inflictor, cls, sizeof(cls));

		fromCommon = StrEqual(cls, "infected", false);
	}

	if (!fromSpecial && !fromCommon) return Plugin_Continue;

	damage *= mult;

	if (debug)
	{
		char name[64];
		GetClientName(victim, name, sizeof(name));
		PrintToChatAll("\x05[%s:DMG]\x01 %s recibio %.1f (x%.2f)", prefix, name, damage, mult);
	}

	return Plugin_Changed;
}

// =============================================================================
// COLOR CORRECTION
// =============================================================================

stock void DiffBase_CreateColorCorrection(
	const char[] fileName, float weight,
	int& colorCorrectionRef, int& fogVolumeRef,
	const char[] ccTargetName)
{
	fogVolumeRef = -1; // fog_volume is a brush entity that cannot be created dynamically

	int colorEnt = CreateEntityByName("color_correction");
	if (colorEnt < 1) return;

	char sWeight[16];
	FloatToString(weight, sWeight, sizeof(sWeight));

	DispatchKeyValue(colorEnt, "targetname",      ccTargetName);
	DispatchKeyValue(colorEnt, "filename",        fileName);
	DispatchKeyValue(colorEnt, "maxweight",       sWeight);
	DispatchKeyValue(colorEnt, "fadeInDuration",  "4");
	DispatchKeyValue(colorEnt, "fadeOutDuration", "4");
	DispatchKeyValue(colorEnt, "maxfalloff",      "-1");
	DispatchKeyValue(colorEnt, "minfalloff",      "-1");
	DispatchSpawn(colorEnt);
	ActivateEntity(colorEnt);
	AcceptEntityInput(colorEnt, "Enable");

	colorCorrectionRef = (colorEnt > 0 && IsValidEntity(colorEnt)) ? EntIndexToEntRef(colorEnt) : -1;
}

stock void DiffBase_RemoveColorCorrection(int& colorCorrectionRef, int& fogVolumeRef)
{
	int ent = EntRefToEntIndex(colorCorrectionRef);
	if (ent != -1 && IsValidEntity(ent)) { AcceptEntityInput(ent, "Disable"); RemoveEntity(ent); }
	colorCorrectionRef = -1;

	ent = EntRefToEntIndex(fogVolumeRef);
	if (ent != -1 && IsValidEntity(ent)) { AcceptEntityInput(ent, "Disable"); RemoveEntity(ent); }
	fogVolumeRef = -1;
}

// Igual que CreateColorCorrection pero solo actua si la entidad ya no existe.
// Llamar desde el fog enforcer timer para mantener el efecto vivo.
stock void DiffBase_EnsureColorCorrection(int& ccRef, const char[] file, float weight, const char[] targetName)
{
	if (!file[0]) return;
	int ent = EntRefToEntIndex(ccRef);
	if (ent != -1 && IsValidEntity(ent)) return;

	int fogVolumeRef = -1;
	DiffBase_CreateColorCorrection(file, weight, ccRef, fogVolumeRef, targetName);
}

// =============================================================================
// TONEMAP CONTROLLER
// =============================================================================

stock void DiffBase_CreateTonemapController(
	float bloomScale, float exposureMin, float exposureMax,
	int& tonemapRef)
{
	int ent = CreateEntityByName("env_tonemap_controller");
	if (ent < 1) { tonemapRef = -1; return; }
	DispatchSpawn(ent);
	ActivateEntity(ent);

	char buf[32];
	FloatToString(bloomScale,   buf, sizeof(buf)); SetVariantString(buf); AcceptEntityInput(ent, "SetBloomScale");
	FloatToString(exposureMin,  buf, sizeof(buf)); SetVariantString(buf); AcceptEntityInput(ent, "SetAutoExposureMin");
	FloatToString(exposureMax,  buf, sizeof(buf)); SetVariantString(buf); AcceptEntityInput(ent, "SetAutoExposureMax");

	tonemapRef = (ent > 0 && IsValidEntity(ent)) ? EntIndexToEntRef(ent) : -1;
}

stock void DiffBase_RemoveTonemapController(int& tonemapRef)
{
	int ent = EntRefToEntIndex(tonemapRef);
	if (ent > 0 && IsValidEntity(ent)) RemoveEntity(ent);
	tonemapRef = -1;
}

// =============================================================================
// UTILITY
// =============================================================================

stock bool DiffBase_IsValidClient(int client)
{
	return client >= 1
		&& client <= MaxClients
		&& IsClientInGame(client)
		&& !IsClientSourceTV(client)
		&& !IsFakeClient(client);
}

stock bool DiffBase_IsFinaleActive()
{
	int ent = -1;
	ent = FindEntityByClassname(ent, "trigger_finale");
	return ent != -1;
}

// Retorna true si el cliente es un survivor en juego
stock bool DiffBase_IsSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

// Retorna el primer survivor vivo, o -1 si no hay ninguno
stock int DiffBase_FindSurvivorTarget()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
			return i;
	return -1;
}

// Distancia al survivor mas cercano desde una posicion dada
stock float DiffBase_GetNearestSurvivorDist(const float pos[3])
{
	float minDist = 99999.0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
		float survivorPos[3];
		GetClientAbsOrigin(i, survivorPos);
		float dist = GetVectorDistance(pos, survivorPos);
		if (dist < minDist) minDist = dist;
	}
	return minDist;
}

// Spawna una witch en una posicion valida del navmesh cerca de un survivor
stock bool DiffBase_SpawnWitch()
{
	int target = DiffBase_FindSurvivorTarget();
	if (target == -1) return false;
	float pos[3], ang[3];
	if (!L4D_GetRandomPZSpawnPosition(target, view_as<int>(L4D2ZombieClass_Witch), 10, pos))
		return false;
	GetClientAbsAngles(target, ang);
	L4D2_SpawnWitch(pos, ang);
	return true;
}

// Elimina witches que estan a mas de maxDist unidades de cualquier survivor
stock void DiffBase_RecycleWitches(float maxDist)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		if (GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll") != 0) continue;
		float witchPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", witchPos);
		if (DiffBase_GetNearestSurvivorDist(witchPos) > maxDist)
			AcceptEntityInput(entity, "Kill");
	}
}

// Enrabia hasta maxCount witches sin target usando vomit jar
stock void DiffBase_EnrageWitches(int maxCount)
{
	int count = 0;
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "witch")) != INVALID_ENT_REFERENCE)
	{
		if (count >= maxCount) break;
		if (GetEntProp(entity, Prop_Data, "m_bClientSideRagdoll") != 0) continue;
		if (GetEntProp(entity, Prop_Send, "m_hOwnerEntity") > 0) continue;
		int target = DiffBase_FindSurvivorTarget();
		if (target == -1) break;
		L4D2_Infected_OnHitByVomitJar(entity, target);
		count++;
	}
}

// Elimina todos los infected comunes activos
stock void DiffBase_RemoveCommonInfected()
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
		AcceptEntityInput(entity, "Kill");
}

// Elimina comunes que estan a mas de maxDist unidades de cualquier survivor
stock void DiffBase_RecycleCommonInfected(float maxDist)
{
	int entity = -1;
	while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
	{
		float pos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
		if (DiffBase_GetNearestSurvivorDist(pos) > maxDist)
			AcceptEntityInput(entity, "Kill");
	}
}

// =============================================================================
// DEBUG
// =============================================================================

bool g_bDiffDebug = false;

// Emite un mensaje de debug a chat, log y consola del servidor.
// Solo actua si g_bDiffDebug == true.
stock void DiffBase_Debug(const char[] tag, const char[] fmt, any ...)
{
	if (!g_bDiffDebug) return;

	char msg[512];
	VFormat(msg, sizeof(msg), fmt, 3);

	char line[576];
	Format(line, sizeof(line), "[DBG/%s] %s", tag, msg);

	PrintToServer("%s", line);
	LogMessage("%s", line);
	PrintToChatAll("\x04[DBG/%s]\x01 %s", tag, msg);
}
