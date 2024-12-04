Handle		 g_hDb;	   // Handle global para la conexión a la base de datos

#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif

public bool doSqlConnection(const char[] databaseName)
{
	char Error[256];
	g_hDb = SQL_Connect(databaseName, true, Error, sizeof(Error));
	if (g_hDb == INVALID_HANDLE)
	{
		return false;
	}
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
