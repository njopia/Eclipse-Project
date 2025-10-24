/**
 * =============================================================================
 * BUY COST WRAPPER - Centralized Cost Verification for All Buy Features
 * =============================================================================
 *
 * This file provides wrapper functions for all buy features to verify costs
 * before executing. This allows seamless integration with l4d_stats currency
 * system without modifying each individual feature file.
 *
 * Usage: Include this after all feature files are included
 * =============================================================================
 */

#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

// ===== WRAPPER FUNCTIONS FOR COST VERIFICATION =====

/**
 * Wrapper: Buy ConvertHP with cost verification
 */
stock bool BuyCostConvertHP(int client)
{
	int cost = GetConVarInt(cvar_CostConvertHP);
	if (!PurchaseItem(client, cost, "Convert HP"))
		return false;

	ConvertHealth(client);
	return true;
}

/**
 * Wrapper: Buy FireYell with cost verification
 */
stock bool BuyCostFireYell(int client)
{
	int cost = GetConVarInt(cvar_CostFireYell);
	if (!PurchaseItem(client, cost, "Fire Yell"))
		return false;

	FireYell(client);
	return true;
}

/**
 * Wrapper: Buy PowerYell with cost verification
 */
stock bool BuyCostPowerYell(int client)
{
	int cost = GetConVarInt(cvar_CostPowerYell);
	if (!PurchaseItem(client, cost, "Power Yell"))
		return false;

	PowerYell(client);
	return true;
}

/**
 * Wrapper: Buy LeapOfDesperation with cost verification
 */
stock bool BuyCostLeapOfDesperation(int client)
{
	int cost = GetConVarInt(cvar_CostLeap);
	if (!PurchaseItem(client, cost, "Leap of Desperation"))
		return false;

	LeapOfDesperation(client);
	return true;
}

/**
 * Wrapper: Buy SurvivalSpeedBoost with cost verification
 */
stock bool BuyCostSurvSpeedBoost(int client)
{
	int cost = GetConVarInt(cvar_CostSurvSpeed);
	if (!PurchaseItem(client, cost, "Survivor Speed Boost"))
		return false;

	SurvivalSpeedBoost(client);
	return true;
}

/**
 * Wrapper: Buy AmmoPile with cost verification
 */
stock bool BuyCostAmmoPile(int client)
{
	int cost = GetConVarInt(cvar_CostAmmo);
	if (!PurchaseItem(client, cost, "Ammo Pile"))
		return false;

	BuyAmmoPile(client);
	return true;
}

/**
 * Wrapper: Buy UVLight with cost verification
 */
stock bool BuyCostUVLight(int client)
{
	int cost = GetConVarInt(cvar_CostUVLight);
	if (!PurchaseItem(client, cost, "UV Light"))
		return false;

	BuyUVLight(client);
	return true;
}

/**
 * Wrapper: Buy HealingStation with cost verification
 */
stock bool BuyCostHealingStation(int client)
{
	int cost = GetConVarInt(cvar_CostHealingStation);
	if (!PurchaseItem(client, cost, "Healing Station"))
		return false;

	BuyHealingStation(client);
	return true;
}

/**
 * Wrapper: Buy IonCannon with cost verification
 * Note: This is a duplicate for consistency, but ion-cannon already has it
 */
stock bool BuyCostIonCannon(int client)
{
	return BuyIonCannon(client);
}

/**
 * Wrapper: Buy TeamHeal with cost verification
 */
stock bool BuyCostTeamHeal(int client)
{
	int cost = GetConVarInt(cvar_CostTeamHeal);
	if (!PurchaseItem(client, cost, "Team Heal"))
		return false;

	BuyTeamHeal(client);
	return true;
}

/**
 * Wrapper: Buy TeamSpeedBoost with cost verification
 */
stock bool BuyCostTeamSpeedBoost(int client)
{
	int cost = GetConVarInt(cvar_CostTeamSpeedBoost);
	if (!PurchaseItem(client, cost, "Team Speed Boost"))
		return false;

	BuyTeamSpeedBoost(client);
	return true;
}

// =====================================================
// ===== MENU ITEM DISPLAY HELPER WITH COSTS =====
// =====================================================

/**
 * Format menu item to show cost and availability
 */
stock void FormatMenuItemWithCost(char[] buffer, int maxlen, const char[] itemName, int cost, bool canAfford)
{
	if (canAfford)
		Format(buffer, maxlen, "%s [%d pts]", itemName, cost);
	else
		Format(buffer, maxlen, "%s [%d pts - INSUFFICIENT FUNDS]", itemName, cost);
}

// =====================================================
