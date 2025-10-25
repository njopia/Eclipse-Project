#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

//==================================================
// === LEVELING REWARDS MODULE ===
// Gestor central de todas las recompensas del sistema
//==================================================

// Incluir la interfaz base
#include "rewards/reward-base.inc"

// Incluir todos los rewards pasivos (ordenados por nivel de desbloqueo)
#include "rewards/passive/double-jump.reward.sp"          // Nivel 1
#include "rewards/passive/acrobatics.reward.sp"           // Nivel 2
#include "rewards/passive/health-bonus.reward.sp"         // Nivel 3
#include "rewards/passive/medic.reward.sp"                // Nivel 4
#include "rewards/passive/pack-rat.reward.sp"             // Nivel 6
#include "rewards/passive/desert-cobra.reward.sp"         // Nivel 8
#include "rewards/passive/damage-reduction.reward.sp"     // Nivel 9
#include "rewards/passive/gene-mutations.reward.sp"       // Niveles 10, 20, 30, 40
#include "rewards/passive/self-revive.reward.sp"          // Nivel 11
#include "rewards/passive/sleight-of-hand.reward.sp"      // Nivel 13
#include "rewards/passive/knife.reward.sp"                // Nivel 15
#include "rewards/passive/hard-to-kill.reward.sp"         // Nivel 17
#include "rewards/passive/arms-dealer.reward.sp"          // Nivel 19
#include "rewards/passive/surgeon.reward.sp"              // Nivel 22
#include "rewards/passive/extreme-conditioning.reward.sp" // Nivel 24
#include "rewards/passive/bulls-eye.reward.sp"            // Nivel 26
#include "rewards/passive/size-matters.reward.sp"         // Nivel 29
#include "rewards/passive/master-at-arms.reward.sp"       // Nivel 32
#include "rewards/passive/hardened-stance.reward.sp"      // Nivel 35
#include "rewards/passive/critical-hit.reward.sp"         // Nivel 38
#include "rewards/passive/commando.reward.sp"             // Nivel 41
#include "rewards/passive/second-chance.reward.sp"        // Nivel 44
#include "rewards/passive/laser-rounds.reward.sp"         // Nivel 47

// TODO: Incluir rewards activos cuando se implementen
// #include "rewards/active/..."

// Incluir módulo de debug
#include "leveling-debug.module.sp"

/**
 * Inicializa el módulo de rewards
 * Debe ser llamado desde OnPluginStart()
 */
public void LevelingRewards_OnPluginStart()
{
	// Inicializar todos los rewards pasivos
	Acrobatics_OnPluginStart();
	HealthBonus_OnPluginStart();
	Medic_OnPluginStart();
	PackRat_OnPluginStart();
	DesertCobra_OnPluginStart();
	GeneMutations_OnPluginStart();
	SelfRevive_OnPluginStart();
	SleightOfHand_OnPluginStart();
	Knife_OnPluginStart();
	HardToKill_OnPluginStart();
	ArmsDealer_OnPluginStart();
	Surgeon_OnPluginStart();
	ExtremeConditioning_OnPluginStart();
	BullsEye_OnPluginStart();
	SizeMatters_OnPluginStart();
	MasterAtArms_OnPluginStart();
	HardenedStance_OnPluginStart();
	CriticalHit_OnPluginStart();
	Commando_OnPluginStart();
	SecondChance_OnPluginStart();
	LaserRounds_OnPluginStart();
	DoubleJump_OnPluginStart();
	DamageReduction_OnPluginStart();

	// Inicializar módulo de debug
	LevelingDebug_OnPluginStart();

	// Registrar hook para cuando el jugador spawn
	HookEvent("player_spawn", Event_PlayerSpawn_Rewards, EventHookMode_Post);
}

/**
 * OnPlayerRunCmd - Se llama cada tick para procesar input del jugador
 * Delega a los rewards que necesiten procesamiento por tick
 */
public Action LevelingRewards_OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	// Delegar a rewards que necesiten procesamiento por tick
	Acrobatics_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);
	ExtremeConditioning_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);
	DoubleJump_OnPlayerRunCmd(client, buttons, impulse, vel, angles, weapon);

	// Otros rewards activos que necesiten procesamiento por tick se agregarían aquí

	return Plugin_Continue;
}

/**
 * Se llama cuando un cliente se conecta
 */
public void LevelingRewards_OnClientConnect(int client)
{
	Acrobatics_OnClientConnect(client);
	HealthBonus_OnClientConnect(client);
	Medic_OnClientConnect(client);
	PackRat_OnClientConnect(client);
	DesertCobra_OnClientConnect(client);
	GeneMutations_OnClientConnect(client);
	SelfRevive_OnClientConnect(client);
	SleightOfHand_OnClientConnect(client);
	Knife_OnClientConnect(client);
	HardToKill_OnClientConnect(client);
	ArmsDealer_OnClientConnect(client);
	Surgeon_OnClientConnect(client);
	ExtremeConditioning_OnClientConnect(client);
	BullsEye_OnClientConnect(client);
	SizeMatters_OnClientConnect(client);
	MasterAtArms_OnClientConnect(client);
	HardenedStance_OnClientConnect(client);
	CriticalHit_OnClientConnect(client);
	Commando_OnClientConnect(client);
	SecondChance_OnClientConnect(client);
	LaserRounds_OnClientConnect(client);
	DoubleJump_OnClientConnect(client);
	DamageReduction_OnClientConnect(client);

	// Debug
	LevelingDebug_OnClientConnect(client);
}

/**
 * Se llama cuando un cliente se desconecta
 */
public void LevelingRewards_OnClientDisconnect(int client)
{
	Acrobatics_OnClientDisconnect(client);
	HealthBonus_OnClientDisconnect(client);
	Medic_OnClientDisconnect(client);
	PackRat_OnClientDisconnect(client);
	DesertCobra_OnClientDisconnect(client);
	GeneMutations_OnClientDisconnect(client);
	SelfRevive_OnClientDisconnect(client);
	SleightOfHand_OnClientDisconnect(client);
	Knife_OnClientDisconnect(client);
	HardToKill_OnClientDisconnect(client);
	ArmsDealer_OnClientDisconnect(client);
	Surgeon_OnClientDisconnect(client);
	ExtremeConditioning_OnClientDisconnect(client);
	BullsEye_OnClientDisconnect(client);
	SizeMatters_OnClientDisconnect(client);
	MasterAtArms_OnClientDisconnect(client);
	HardenedStance_OnClientDisconnect(client);
	CriticalHit_OnClientDisconnect(client);
	Commando_OnClientDisconnect(client);
	SecondChance_OnClientDisconnect(client);
	LaserRounds_OnClientDisconnect(client);
	DoubleJump_OnClientDisconnect(client);
	DamageReduction_OnClientDisconnect(client);

	// Debug
	LevelingDebug_OnClientDisconnect(client);
}

/**
 * Aplica todos los rewards al subir de nivel (con mensajes)
 * @param client - ID del cliente
 * @param level - Nivel alcanzado
 */
public void LevelingRewards_ApplyRewards(int client, int level)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return;

	// Aplicar cada reward (mostrará mensaje si se desbloquea)
	Acrobatics_OnLevelUp(client, level);
	HealthBonus_OnLevelUp(client, level);
	Medic_OnLevelUp(client, level);
	PackRat_OnLevelUp(client, level);
	DesertCobra_OnLevelUp(client, level);
	GeneMutations_OnLevelUp(client, level);
	SelfRevive_OnLevelUp(client, level);
	SleightOfHand_OnLevelUp(client, level);
	Knife_OnLevelUp(client, level);
	HardToKill_OnLevelUp(client, level);
	ArmsDealer_OnLevelUp(client, level);
	Surgeon_OnLevelUp(client, level);
	ExtremeConditioning_OnLevelUp(client, level);
	BullsEye_OnLevelUp(client, level);
	SizeMatters_OnLevelUp(client, level);
	MasterAtArms_OnLevelUp(client, level);
	HardenedStance_OnLevelUp(client, level);
	CriticalHit_OnLevelUp(client, level);
	Commando_OnLevelUp(client, level);
	SecondChance_OnLevelUp(client, level);
	LaserRounds_OnLevelUp(client, level);
	DoubleJump_OnLevelUp(client, level);
	DamageReduction_OnLevelUp(client, level);
}

/**
 * Aplica todos los rewards silenciosamente (sin mensajes - usado en spawn)
 * @param client - ID del cliente
 * @param level - Nivel actual del jugador
 */
public void LevelingRewards_ApplyRewardsSilent(int client, int level)
{
	if (client <= 0 || client > MaxClients || !IsClientInGame(client))
		return;

	// Aplicar cada reward silenciosamente
	Acrobatics_OnPlayerSpawn(client, level);
	HealthBonus_OnPlayerSpawn(client, level);
	Medic_OnPlayerSpawn(client, level);
	PackRat_OnPlayerSpawn(client, level);
	DesertCobra_OnPlayerSpawn(client, level);
	GeneMutations_OnPlayerSpawn(client, level);
	SelfRevive_OnPlayerSpawn(client, level);
	SleightOfHand_OnPlayerSpawn(client, level);
	Knife_OnPlayerSpawn(client, level);
	HardToKill_OnPlayerSpawn(client, level);
	ArmsDealer_OnPlayerSpawn(client, level);
	Surgeon_OnPlayerSpawn(client, level);
	ExtremeConditioning_OnPlayerSpawn(client, level);
	BullsEye_OnPlayerSpawn(client, level);
	SizeMatters_OnPlayerSpawn(client, level);
	MasterAtArms_OnPlayerSpawn(client, level);
	HardenedStance_OnPlayerSpawn(client, level);
	CriticalHit_OnPlayerSpawn(client, level);
	Commando_OnPlayerSpawn(client, level);
	SecondChance_OnPlayerSpawn(client, level);
	LaserRounds_OnPlayerSpawn(client, level);
	DoubleJump_OnPlayerSpawn(client, level);
	DamageReduction_OnPlayerSpawn(client, level);
}

/**
 * Evento: Player Spawn
 * Aplica todos los rewards al aparecer
 */
public Action Event_PlayerSpawn_Rewards(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Continue;

	// Aplicar rewards según nivel (sin mostrar mensajes en spawn)
	int playerLevel = Leveling_GetPlayerLevel(client);
	if (playerLevel > 0)
	{
		LevelingRewards_ApplyRewardsSilent(client, playerLevel);
	}

	// Mostrar UI de nivel/XP
	LevelingUI_ShowOnSpawn(client);

	return Plugin_Continue;
}

/**
 * Verifica si un jugador tiene el doble salto habilitado
 * (Wrapper para mantener compatibilidad con código existente)
 */
public bool LevelingRewards_IsDoubleJumpEnabled(int client)
{
	return DoubleJump_IsEnabled(client);
}
