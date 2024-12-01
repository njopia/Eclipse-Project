
Handle db;

#if !defined EMS_MAIN_FILE
	#error Este archivo debe estar dentro de "scripting/modules/" al momento de compilar orquestador principal.
#endif

public bool doSqlConnection(const char[] databaseName)
{
	char Error[256];
	db = SQL_Connect(databaseName, true, Error, sizeof(Error));
	if (db == INVALID_HANDLE)
	{
		PrintToServer("[DB-UTILS] Error en la conexion a la base de datos: %s", databaseName);
        return false;
	}
	else
	{
		PrintToServer("[DB-UTILS] Conexion a la base de datos exitosa: %s", databaseName);
	}
    return true;
}