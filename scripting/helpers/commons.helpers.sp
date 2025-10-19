#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

/**
 * Obtiene el modo de juego actual.
 *
 * @return				El modo de juego actual.
 * 						- `GAMEMODE_UNKNOWN` (0)
 * 						- `GAMEMODE_COOP` (1)
 * 						- `GAMEMODE_VERSUS` (2)
 * 						- `GAMEMODE_SURVIVAL` (4)
 * 						- `GAMEMODE_SCAVENGE` (8)
 */
int CurrentGameMode()
{
	return L4D_GetGameModeType();
}