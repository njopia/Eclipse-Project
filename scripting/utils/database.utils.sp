Handle		 g_hDb;				  // Handle global para la conexion a la base de datos
Handle		 g_hDbPlayers;		  // Handle para la base de datos de players/leveling
#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

public bool doSqlConnection(const char[] databaseName)
{
	char Error[256];
	g_hDb = SQL_Connect(databaseName, true, Error, sizeof(Error));
	if (g_hDb == INVALID_HANDLE)
	{
		LogError("[EMS-SQL] Error conectando a '%s': %s", databaseName, Error);
		return false;
	}
	EMS_InitializeDatabaseSchema(view_as<Database>(g_hDb), databaseName);
	return true;
}

public bool doSqlConnectionPlayers(const char[] databaseName)
{
	char Error[256];
	g_hDbPlayers = SQL_Connect(databaseName, true, Error, sizeof(Error));
	if (g_hDbPlayers == INVALID_HANDLE)
	{
		LogError("[EMS-SQL] Error conectando a DB de jugadores '%s': %s", databaseName, Error);
		return false;
	}
	EMS_InitializeDatabaseSchema(view_as<Database>(g_hDbPlayers), databaseName);
	return true;
}
bool checkDBFile(const char[] databaseName)
{
	if (!SQL_CheckConfig(databaseName))
	{
		return false;
	}
	return true;
}
