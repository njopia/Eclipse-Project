#if defined _st_tank_heal_included
 #endinput
#endif
#define _st_tank_heal_included

// ============================================================================
// HEAL TANK MODULE (HULK TANK)
// Heal Tank abilities and mechanics
// Color: RGB(100, 255, 200) = 100255200
// ============================================================================

/**
 * Heal Tank passive ability
 * Glows green and heals when 3+ survivors nearby
 *
 * @param client    Heal Tank client index
 * @noreturn
 */
stock HulkTankAbility(client)
{
	if (IsTank(client) && GetEntRenderColor(client) == 100255200)
	{
		if (TankAbilityTimer[client] <= 0)
		{
			new count = CountSurvInRange(client, 300);

			if (count >= 3)
			{
				new glowcolor = RGB_TO_INT(0, 255, 0);
				SetEntProp(client, Prop_Send, "m_glowColorOverride", glowcolor);
				SetEntProp(client, Prop_Send, "m_iGlowType", 3);
				SetEntProp(client, Prop_Send, "m_bFlashing", 1);
			}
			else
			{
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
				SetEntProp(client, Prop_Send, "m_iGlowType", 0);
				SetEntProp(client, Prop_Send, "m_bFlashing", 0);
			}
		}
		else
		{
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
			SetEntProp(client, Prop_Send, "m_iGlowType", 0);
			SetEntProp(client, Prop_Send, "m_bFlashing", 0);
		}
	}
}
