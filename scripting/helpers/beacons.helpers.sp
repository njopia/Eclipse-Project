// ======================================================================
// Reusable beacon/onda expansiva helpers
// ======================================================================

// --- Visuals: Beacon ring model ---
int			 g_iBeaconBeamModel	  = -1;	   // precached in OnMapStart


/**
 * Draws an expanding ring centered at an entity.
 * @param entity     Center entity
 * @param color      RGBA array, e.g. {0,255,0,255}
 * @param start      Starting radius
 * @param end        Final radius
 * @param life       Seconds the ring lives
 * @param width      Ring thickness
 */

void EMS_BeaconRingAtEntity(int entity, const int color[4], float start = 12.0, float end = 280.0, float life = 0.8, float width = 5.0)
{
	if (g_iBeaconBeamModel == -1)
		return;

	float origin[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

	// TE_SetupBeamRingPoint(origin, start, end, modelIndex, haloIndex, startFrame, frameRate, life, width, amplitude, color[4], speed, flags);
	TE_SetupBeamRingPoint(origin, start, end, g_iBeaconBeamModel, 0, 0, 10, life, width, 0.0, color, 0, 0);
	TE_SendToAll();
}
/** Convenience: healing station pulse (verde) */
void EMS_BeaconPulse_Healing(int entity)
{
	int c[4] = { 0, 255, 0, 220 };
	EMS_BeaconRingAtEntity(entity, c, 14.0, 300.0, 1.0, 6.0);
}

/** Convenience: UV Light pulse (violeta) */
void EMS_BeaconPulse_UV(int entity)
{
	int c[4] = { 160, 32, 240, 220 };
	EMS_BeaconRingAtEntity(entity, c, 14.0, 280.0, 0.9, 5.0);
}
