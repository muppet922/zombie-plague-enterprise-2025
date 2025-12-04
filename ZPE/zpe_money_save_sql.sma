/* AMX Mod X
*	[ZPE] Money Save.
*	Author: C&K Corporation.
*
*	https://ckcorp.ru/ - support from the C&K Corporation.
*	https://forum.ckcorp.ru/ - forum support from the C&K Corporation.
*	https://wiki.ckcorp.ru - documentation and other useful information.
*	https://news.ckcorp.ru/ - other info.
*
*	https://git.ckcorp.ru/ck/amxx-modes/zpe - development.
*
*	Support is provided only on the site.
*/

#define PLUGIN "money save"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <sqlx>

new g_iGlobal_Indexes[33];
new g_iLast_Index;

new Handle:g_SQL_Make_Db_Cache;
new Handle:g_SQL_Connect;

new g_pCvar_Database_Host;
new g_pCvar_Database_Name;
new g_pCvar_Database_User;
new g_pCvar_Database_Password;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Database_Host = register_cvar("zpe_database_host", "");
	g_pCvar_Database_Name = register_cvar("zpe_database_name", "");
	g_pCvar_Database_User = register_cvar("zpe_database_user", "");
	g_pCvar_Database_Password = register_cvar("zpe_database_password", "");
}

public plugin_cfg()
{
	new szDatabase_Host[32];
	new szDatabase_Name[32];
	new szDatabase_User[32];
	new szDatabase_Password[32];

	get_pcvar_string(g_pCvar_Database_Host, szDatabase_Host, charsmax(szDatabase_Host));
	get_pcvar_string(g_pCvar_Database_Name, szDatabase_Name, charsmax(szDatabase_Name));
	get_pcvar_string(g_pCvar_Database_User, szDatabase_User, charsmax(szDatabase_User));
	get_pcvar_string(g_pCvar_Database_Password, szDatabase_Password, charsmax(szDatabase_Password));

	g_SQL_Make_Db_Cache = SQL_MakeDbTuple(szDatabase_Host, szDatabase_Name, szDatabase_User, szDatabase_Password);

	new iError;
	new szError[128];

	g_SQL_Connect = SQL_Connect(g_SQL_Make_Db_Cache, iError, szError, charsmax(szError));

	if (g_SQL_Connect != Empty_Handle)
	{
		new Handle:SQL_Query_Check_Db = SQL_PrepareQuery(g_SQL_Connect, "CREATE TABLE IF NOT EXISTS `zpe_money` (Player_ID INT PRIMARY KEY auto_increment, Steam VARCHAR(32), Money INT");

		SQL_Execute(SQL_Query_Check_Db);
		SQL_FreeHandle(SQL_Query_Check_Db);
	}

	else
	{
		new szSQL_Error[64];

		formatex(szSQL_Error, charsmax(szSQL_Error), "SQL FATAL ERROR - %d: %s", iError, szError);

		set_fail_state(szError);
	}

	g_iLast_Index = SQL_Get_Last_Index();
}

public client_putinserver(iPlayer)
{
	new szAuth_ID[32];
	get_user_authid(iPlayer, szAuth_ID, charsmax(szAuth_ID));

	new szQuery[100];
	formatex(szQuery, charsmax(szQuery), "SELECT * FROM `zpe_money` WHERE `Steam` LIKE '%s'", szAuth_ID);

	new iIndex[1];
	iIndex[0] = iPlayer;

	SQL_ThreadQuery(g_SQL_Make_Db_Cache, "SQL_Check_Player", szQuery, iIndex, 1);
}

public SQL_Check_Player(iFail_State, Handle:SQL_Query, szError[], iError, szData[])
{
	new iPlayer = szData[0];

	if (SQL_MoreResults(SQL_Query))
	{
		g_iGlobal_Indexes[iPlayer] = SQL_ReadResult(SQL_Query, 0);

		UTIL_Set_User_Money(iPlayer, SQL_ReadResult(SQL_Query, 2));
	}

	else
	{
		new szAuth_ID[32];

		get_user_authid(iPlayer, szAuth_ID, charsmax(szAuth_ID));

		new Handle:SQL_Query_Add_Data = SQL_PrepareQuery
		(
			g_SQL_Connect,
			"INSERT INTO `zpe_money` VALUES (NULL, '%s', 0)",
			szAuth_ID
		);

		SQL_Execute(SQL_Query_Add_Data);
		SQL_FreeHandle(SQL_Query_Add_Data);

		g_iGlobal_Indexes[iPlayer] = ++g_iLast_Index;
	}
}

public client_disconnected(iPlayer)
{
	new Handle:SQL_Query_Update_Data = SQL_PrepareQuery
	(
		g_SQL_Connect,
		"UPDATE `zpe_money` SET `Money` = %d WHERE `Player_ID` = %d",
		CS_GET_USER_MONEY(iPlayer),
		g_iGlobal_Indexes[iPlayer]
	);

	SQL_Execute(SQL_Query_Update_Data);
	SQL_FreeHandle(SQL_Query_Update_Data);

	g_iGlobal_Indexes[iPlayer] = 0;
}

public plugin_end()
{
	SQL_FreeHandle(g_SQL_Make_Db_Cache);
	SQL_FreeHandle(g_SQL_Connect);
}

stock SQL_Get_Last_Index()
{
	new Handle:SQL_Query_Get_Last_Index = SQL_PrepareQuery(g_SQL_Connect, "SELECT `Player_ID` FROM `zpe_money` ORDER BY `Player_ID` DESC;");

	SQL_Execute(SQL_Query_Get_Last_Index);

	new iLast_Index = SQL_MoreResults(SQL_Query_Get_Last_Index) ? SQL_ReadResult(SQL_Query_Get_Last_Index, 0) : 0;

	SQL_FreeHandle(SQL_Query_Get_Last_Index);

	return iLast_Index;
}