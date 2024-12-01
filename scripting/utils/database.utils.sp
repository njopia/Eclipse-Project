
Handle db;

#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
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