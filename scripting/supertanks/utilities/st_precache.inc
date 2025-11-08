#if defined _st_precache_included
 #endinput
#endif
#define _st_precache_included

// ============================================================================
// PRECACHE MODULE
// Handles precaching of models, sounds, and particles
// ============================================================================

/**
 * Precache all resources required by the plugin
 * Called from OnMapStart()
 */
stock ST_Precache_All()
{
	ST_Precache_Particles();
	ST_Precache_Models();
	ST_Precache_Sounds();
	ST_Precache_ModelIndexes();
}

/**
 * Precache all particle effects
 */
stock ST_Precache_Particles()
{
	PrecacheParticle(PARTICLE_LS_BOLT);
	PrecacheParticle(PARTICLE_SMOKE);
	PrecacheParticle(PARTICLE_FIRE);
	PrecacheParticle(PARTICLE_WARP);
	PrecacheParticle(PARTICLE_SPIT);
	PrecacheParticle(PARTICLE_ELEC);
	PrecacheParticle(PARTICLE_BLOOD_EXPLODE);
	PrecacheParticle(PARTICLE_EXPLODE);
	PrecacheParticle(PARTICLE_METEOR);
	PrecacheParticle(PARTICLE_FLARE);
	PrecacheParticle(PARTICLE_DEMON_SMOKE);
	//PrecacheParticle(PARTICLE_DEMON_HEAT); // Commented in original
}

/**
 * Precache all models
 */
stock ST_Precache_Models()
{
	// Survivor models
	CheckModelPreCache(MODEL_NICK);
	CheckModelPreCache(MODEL_ROCHELLE);
	CheckModelPreCache(MODEL_COACH);
	CheckModelPreCache(MODEL_ELLIS);
	CheckModelPreCache(MODEL_BILL);
	CheckModelPreCache(MODEL_ZOEY);
	CheckModelPreCache(MODEL_FRANCIS);
	CheckModelPreCache(MODEL_LOUIS);

	// Tank models
	CheckModelPreCache(MODEL_TANK_DLC3);
	CheckModelPreCache("models/infected/hulk.mdl");

	// Infected models
	CheckModelPreCache("models/infected/witch.mdl");
	CheckModelPreCache("models/infected/witch_bride.mdl");
	CheckModelPreCache("models/infected/boomette.mdl");
	CheckModelPreCache("models/infected/common_male_ceda.mdl");
	CheckModelPreCache("models/infected/common_male_clown.mdl");
	CheckModelPreCache("models/infected/common_male_mud.mdl");
	CheckModelPreCache("models/infected/common_male_roadcrew.mdl");
	CheckModelPreCache("models/infected/common_male_riot.mdl");
	CheckModelPreCache("models/infected/common_male_fallen_survivor.mdl");
	CheckModelPreCache("models/infected/common_male_jimmy.mdl");

	// Weapon view models
	CheckModelPreCache(MODEL_V_FIREAXE);
	CheckModelPreCache(MODEL_V_FRYING_PAN);
	CheckModelPreCache(MODEL_V_MACHETE);
	CheckModelPreCache(MODEL_V_BAT);
	CheckModelPreCache(MODEL_V_CROWBAR);
	CheckModelPreCache(MODEL_V_CRICKET_BAT);
	CheckModelPreCache(MODEL_V_TONFA);
	CheckModelPreCache(MODEL_V_KATANA);
	CheckModelPreCache(MODEL_V_ELECTRIC_GUITAR);
	CheckModelPreCache(MODEL_V_GOLFCLUB);

	// Prop models
	CheckModelPreCache(MODEL_GASCAN);
	CheckModelPreCache(MODEL_PROPANE);
	CheckModelPreCache("models/props_vehicles/tire001c_car.mdl");
	CheckModelPreCache("models/props_unique/airport/atlas_break_ball.mdl");
	CheckModelPreCache("models/props_debris/concrete_chunk01a.mdl");
}

/**
 * Precache all sound files
 */
stock ST_Precache_Sounds()
{
	// Ambient sounds
	CheckSoundPreCache("ambient/ambience/rainscapes/rain/debris_05.wav");
	CheckSoundPreCache("ambient/fire/gascan_ignite1.wav");

	// Energy/electric sounds
	CheckSoundPreCache("ambient/energy/spark5.wav");
	CheckSoundPreCache("ambient/energy/spark6.wav");
	CheckSoundPreCache("ambient/energy/zap5.wav");
	CheckSoundPreCache("ambient/energy/zap6.wav");
	CheckSoundPreCache("ambient/energy/zap7.wav");
	CheckSoundPreCache("ambient/energy/zap8.wav");
	CheckSoundPreCache("ambient/energy/zap9.wav");

	// Infected sounds
	CheckSoundPreCache("npc/infected/action/die/male/death_42.wav");
	CheckSoundPreCache("npc/infected/action/die/male/death_43.wav");
	CheckSoundPreCache("npc/mega_mob/mega_mob_incoming.wav");

	// Special infected sounds
	CheckSoundPreCache("player/charger/hit/charger_smash_02.wav");
	CheckSoundPreCache("player/tank/voice/growl/tank_climb_01.wav");
	CheckSoundPreCache("player/spitter/voice/warn/spitter_spit_02.wav");

	// Explosion sounds
	CheckSoundPreCache("player/boomer/explode/explo_medium_09.wav");
	CheckSoundPreCache("player/boomer/explode/explo_medium_10.wav");
	CheckSoundPreCache("player/boomer/explode/explo_medium_14.wav");

	// UI sounds
	CheckSoundPreCache("ui/beep22.wav");
}

/**
 * Precache model indexes
 * Store commonly used model indexes in global variables
 */
stock ST_Precache_ModelIndexes()
{
	MODEL_DEFIB = PrecacheModel("models/w_models/weapons/w_eq_defibrillator.mdl", true);
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Check and precache a model if not already precached
 * Prints a message to server console when precaching
 *
 * @param Modelfile    Path to model file
 * @noreturn
 */
stock CheckModelPreCache(const String:Modelfile[])
{
	if (!IsModelPrecached(Modelfile))
	{
		PrecacheModel(Modelfile, true);
		PrintToServer("Precaching Model: %s", Modelfile);
	}
}

/**
 * Precache a sound file
 * Prints a message to server console when precaching
 *
 * @param Soundfile    Path to sound file
 * @noreturn
 */
stock CheckSoundPreCache(const String:Soundfile[])
{
	PrecacheSound(Soundfile, true);
	PrintToServer("Precaching Sound: %s", Soundfile);
}

/**
 * Precache a particle effect
 * Creates a temporary particle system entity to force precaching
 *
 * @param ParticleName    Name of the particle effect
 * @noreturn
 */
stock PrecacheParticle(const String:ParticleName[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEntity(particle))
	{
		DispatchKeyValue(particle, "effect_name", ParticleName);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		SetVariantString("OnUser1 !self:Kill::0.1:-1");
		AcceptEntityInput(particle, "AddOutput");
		AcceptEntityInput(particle, "FireUser1");
	}
}
