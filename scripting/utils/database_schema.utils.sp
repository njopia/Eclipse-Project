#if !defined _EMS_DATABASE_SCHEMA_
#define _EMS_DATABASE_SCHEMA_

/**
 * Ejecuta las consultas CREATE TABLE para asegurar que la base de datos esté lista.
 * 
 * NOTA: Para MySQL, las bases de datos (containers) 'players' y 'admins' 
 * DEBEN ser creadas manualmente antes de iniciar el plugin para evitar el error 1049.
 * Se debe llamar desde el callback de conexión exitosa en database.utils.sp.
 */
stock void EMS_InitializeDatabaseSchema(Database db, const char[] dbName)
{
    if (StrEqual(dbName, PLAYERS_DB_NAME))
    {
        // Tabla para el Sistema de Niveles (player_levels)
        db.Query(SQL_SchemaCallback, 
            "CREATE TABLE IF NOT EXISTS player_levels (" ...
            "steamid VARCHAR(32) PRIMARY KEY, " ...
            "player_name VARCHAR(128), " ...
            "current_level INT DEFAULT 0, " ...
            "current_xp INT DEFAULT 0, " ...
            "total_xp INT DEFAULT 0, " ...
            "shoulder_cannon_auto_equip TINYINT DEFAULT 1, " ...
            "unlocked_bloodmoon TINYINT DEFAULT 0, " ...
            "unlocked_hell TINYINT DEFAULT 0, " ...
            "unlocked_inferno TINYINT DEFAULT 0, " ...
            "unlocked_cow TINYINT DEFAULT 0, " ...
            "last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP)");

        // Tabla para el Scripted HUD (server_hud_messages)
        db.Query(SQL_SchemaCallback, 
            "CREATE TABLE IF NOT EXISTS server_hud_messages (" ...
            "id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT, " ...
            "message VARCHAR(128) NOT NULL, " ...
            "is_active TINYINT(1) NOT NULL DEFAULT 1, " ...
            "PRIMARY KEY (id))");

        // Insertar mensajes por defecto para el HUD si la tabla es nueva
        db.Query(SQL_SchemaCallback, "INSERT IGNORE INTO server_hud_messages (id, message, is_active) VALUES " ...
            "(1, 'Welcome to Eclipse EMS! Type !menu to start.', 1), " ...
            "(2, 'Kill zombies to earn XP and unlock powerful abilities.', 1), " ...
            "(3, 'Need items? Type !buy to open the Shop.', 1), " ...
            "(4, 'Subscribers get double XP on weekends!', 1)");

        PrintToServer("[EMS-SQL] Esquema de base de datos 'players' verificado/creado.");
    }
    else if (StrEqual(dbName, ADMIN_DB_NAME))
    {
        // Tablas estándar de SourceMod Admins
        db.Query(SQL_SchemaCallback, "CREATE TABLE IF NOT EXISTS sm_admins (" ...
            "id int(10) unsigned NOT NULL auto_increment, " ...
            "authtype enum('steam','name','ip') NOT NULL, " ...
            "identity varchar(65) NOT NULL, password varchar(65), " ...
            "flags varchar(30) NOT NULL, name varchar(65) NOT NULL, " ...
            "immunity int(10) unsigned NOT NULL, PRIMARY KEY (id))");

        db.Query(SQL_SchemaCallback, "CREATE TABLE IF NOT EXISTS sm_groups (id int(10) unsigned NOT NULL auto_increment, flags varchar(30) NOT NULL, name varchar(120) NOT NULL, immunity_level int(1) unsigned NOT NULL, PRIMARY KEY (id))");

        db.Query(SQL_SchemaCallback, "CREATE TABLE IF NOT EXISTS sm_group_immunity (group_id int(10) unsigned NOT NULL, other_id int(10) unsigned NOT NULL, PRIMARY KEY (group_id, other_id))");

        db.Query(SQL_SchemaCallback, "CREATE TABLE IF NOT EXISTS sm_group_overrides (group_id int(10) unsigned NOT NULL, type enum('command','group') NOT NULL, name varchar(32) NOT NULL, access enum('allow','deny') NOT NULL, PRIMARY KEY (group_id, type, name))");

        db.Query(SQL_SchemaCallback, "CREATE TABLE IF NOT EXISTS sm_overrides (type enum('command','group') NOT NULL, name varchar(32) NOT NULL, flags varchar(30) NOT NULL, PRIMARY KEY (type,name))");

        db.Query(SQL_SchemaCallback, "CREATE TABLE IF NOT EXISTS sm_admins_groups (admin_id int(10) unsigned NOT NULL, group_id int(10) unsigned NOT NULL, inherit_order int(10) NOT NULL, PRIMARY KEY (admin_id, group_id))");

        db.Query(SQL_SchemaCallback, "CREATE TABLE IF NOT EXISTS sm_config (cfg_key varchar(32) NOT NULL, cfg_value varchar(255) NOT NULL, PRIMARY KEY (cfg_key))");

        // Pequeña pausa para asegurar que sm_config exista antes del INSERT
        CreateTimer(0.1, Timer_InitAdminConfig, db);

        PrintToServer("[EMS-SQL] Esquema de base de datos 'admins' verificado/creado.");
    }
}

public Action Timer_InitAdminConfig(Handle timer, Database db)
{
    if (db != null)
    {
        db.Query(SQL_SchemaCallback, "INSERT INTO sm_config (cfg_key, cfg_value) VALUES ('admin_version', '1.0.0.1409') ON DUPLICATE KEY UPDATE cfg_value = '1.0.0.1409'");
    }
    return Plugin_Stop;
}

public void SQL_SchemaCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0] != '\0')
    {
        LogError("[EMS-SQL] Error inicializando esquema: %s", error);
    }
}
#endif