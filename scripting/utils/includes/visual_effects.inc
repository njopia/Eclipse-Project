#if defined _visual_effects_included
	#endinput
#endif
#define _visual_effects_included
/**
 * Aplica un efecto de color (Fade) en la pantalla del jugador.
 *
 * @param client        Índice del cliente.
 * @param duration      Duración total del efecto en milisegundos.
 * @param holdTime      Tiempo que el color se queda fijo antes de desvanecerse.
 * @param flags         Flags del Fade (0x0001: Fade In, 0x0002: Fade Out, 0x0008: Stay Out).
 * @param r             Rojo (0-255).
 * @param g             Verde (0-255).
 * @param b             Azul (0-255).
 * @param a             Alfa/Transparencia (0-255).
 */
// Macros de colores
#define COLOR_RED	   255, 0, 0
#define COLOR_GREEN	   0, 255, 0
#define COLOR_BLUE	   0, 0, 255
#define COLOR_YELLOW   255, 255, 0
#define COLOR_PURPLE   128, 0, 128
#define COLOR_CYAN	   0, 255, 255
#define COLOR_ORANGE   255, 165, 0
#define COLOR_WHITE	   255, 255, 255
#define COLOR_BLACK	   0, 0, 0

// Macros de opacidad
#define ALPHA_SOFT	   50
#define ALPHA_NORMAL   100
#define ALPHA_STRONG   150
#define ALPHA_SOLID	   255

// Flags para el mensaje de red "Fade"
#define FFADE_IN	   0x0001	 // El color aparece (Fade In)
#define FFADE_OUT	   0x0002	 // El color desaparece (Fade Out)
#define FFADE_MODULATE 0x0004	 // Modula el color (en lugar de mezclarlo)
#define FFADE_STAYOUT  0x0008	 // El color se queda fijo (no se desvanece solo)
#define FFADE_PURGE	   0x0010	 // Limpia todos los efectos de fade anteriores
/**
 * Función base para el efecto Fade.
 */
stock void FX_SetFade(int client, int duration, int holdTime, int flags, int r, int g, int b, int a)
{
	if (!IsClientInGame(client)) return;

	int clients[1];
	clients[0]	   = client;

	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1);
	if (message != INVALID_HANDLE)
	{
		// Usamos BfWrite directamente (estándar de SourceMod para L4D2)
		BfWriteShort(message, duration);
		BfWriteShort(message, holdTime);
		BfWriteShort(message, flags);
		BfWriteByte(message, r);
		BfWriteByte(message, g);
		BfWriteByte(message, b);
		BfWriteByte(message, a);
		EndMessage();
	}
}

/**
 * Crea un bloque de color sólido (Activa el feature visual).
 * Usamos una duración mínima (10ms) para que sea instantáneo.
 */
stock void FX_FadeCustom(int client, int r, int g, int b, int alpha)
{
	// Usamos FFADE_STAYOUT para que sea permanente hasta que lo quitemos.
	// Usamos FFADE_PURGE para que limpie cualquier parpadeo previo.
	FX_SetFade(client, 10, 0, FFADE_STAYOUT | FFADE_PURGE, r, g, b, alpha);
}

/**
 * Limpia el efecto visual de la pantalla (Desactiva el feature).
 */
stock void FX_ClearFade(int client)
{
	// Al quitarlo, un desvanecimiento de 500ms (0.5s) queda más natural que un corte brusco.
	FX_SetFade(client, 500, 0, FFADE_PURGE | FFADE_OUT, 0, 0, 0, 0);
}