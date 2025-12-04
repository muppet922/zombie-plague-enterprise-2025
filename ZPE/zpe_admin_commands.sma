/* AMX Mod X
*	[ZPE] Admin Commands.
*	Author: MeRcyLeZZ. Edition: C&K Corporation.
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

#define PLUGIN "admin commands"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <amxmisc>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>
#include <zpe_log>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

#define ACCESS_FLAG_MAX_LENGTH 2

new g_Access_Make_Zombie[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Make_Human[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Make_Nemesis[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Make_Assassin[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Make_Survivor[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Make_Sniper[ACCESS_FLAG_MAX_LENGTH] = "d";

new g_Access_Respawn_Players[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Start_Game_Mode[ACCESS_FLAG_MAX_LENGTH] = "d";

new g_pCvar_Console_Command_Target_Zombie;
new g_pCvar_Console_Command_Target_Human;
new g_pCvar_Console_Command_Target_Nemesis;
new g_pCvar_Console_Command_Target_Assassin;
new g_pCvar_Console_Command_Target_Survivor;
new g_pCvar_Console_Command_Target_Sniper;

new g_pCvar_Console_Command_Target_Respawn_Players;
new g_pCvar_Console_Command_Target_Start_Game_Mode;

new g_pCvar_Message_Information;
new g_pCvar_Management_Admin_Log;

new g_pCvar_Deathmatch;

new g_Game_Mode_Infection_ID;
new g_Game_Mode_Nemesis_ID;
new g_Game_Mode_Assassin_ID;
new g_Game_Mode_Survivor_ID;
new g_Game_Mode_Sniper_ID;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Console_Command_Target_Zombie = register_cvar("zpe_console_command_taget_zombie", "zpe_zombie");
	g_pCvar_Console_Command_Target_Human = register_cvar("zpe_console_command_taget_human", "zpe_human");
	g_pCvar_Console_Command_Target_Nemesis = register_cvar("zpe_console_command_taget_nemesis", "zpe_nemesis");
	g_pCvar_Console_Command_Target_Assassin = register_cvar("zpe_console_command_taget_assassin", "zpe_assassin");
	g_pCvar_Console_Command_Target_Survivor = register_cvar("zpe_console_command_taget_survivor", "zpe_survivor");
	g_pCvar_Console_Command_Target_Sniper = register_cvar("zpe_console_command_taget_sniper", "zpe_sniper");

	g_pCvar_Console_Command_Target_Respawn_Players = register_cvar("zpe_console_command_taget_respawn", "zpe_respawn");
	g_pCvar_Console_Command_Target_Start_Game_Mode = register_cvar("zpe_console_command_taget_start_game_mode", "zpe_start_game_mode");

	g_pCvar_Management_Admin_Log = register_cvar("zpe_management_admin_log", "1");
	g_pCvar_Message_Information = register_cvar("zpe_message_information", "1");

	new szConsole_Command_Target_Zombie[32];
	new szConsole_Command_Target_Human[32];
	new szConsole_Command_Target_Nemesis[32];
	new szConsole_Command_Target_Assassin[32];
	new szConsole_Command_Target_Survivor[32];
	new szConsole_Command_Target_Sniper[32];

	new szConsole_Command_Target_Respawn_Players[32];
	new szConsole_Command_Target_Start_Game_Mode[32];

	get_pcvar_string(g_pCvar_Console_Command_Target_Zombie, szConsole_Command_Target_Zombie, charsmax(szConsole_Command_Target_Zombie));
	get_pcvar_string(g_pCvar_Console_Command_Target_Human, szConsole_Command_Target_Human, charsmax(szConsole_Command_Target_Human));
	get_pcvar_string(g_pCvar_Console_Command_Target_Nemesis, szConsole_Command_Target_Nemesis, charsmax(szConsole_Command_Target_Nemesis));
	get_pcvar_string(g_pCvar_Console_Command_Target_Assassin, szConsole_Command_Target_Assassin, charsmax(szConsole_Command_Target_Assassin));
	get_pcvar_string(g_pCvar_Console_Command_Target_Survivor, szConsole_Command_Target_Survivor, charsmax(szConsole_Command_Target_Survivor));
	get_pcvar_string(g_pCvar_Console_Command_Target_Sniper, szConsole_Command_Target_Sniper, charsmax(szConsole_Command_Target_Sniper));

	get_pcvar_string(g_pCvar_Console_Command_Target_Respawn_Players, szConsole_Command_Target_Respawn_Players, charsmax(szConsole_Command_Target_Respawn_Players));
	get_pcvar_string(g_pCvar_Console_Command_Target_Start_Game_Mode, szConsole_Command_Target_Start_Game_Mode, charsmax(szConsole_Command_Target_Start_Game_Mode));

	// Admin commands
	register_concmd(szConsole_Command_Target_Zombie, "Cmd_Zombie", _, "<target> - Turn someone into a Zombie", 0);
	register_concmd(szConsole_Command_Target_Human, "Cmd_Human", _, "<target> - Turn someone back to Human", 0);
	register_concmd(szConsole_Command_Target_Nemesis, "Cmd_Nemesis", _, "<target> - Turn someone into a Nemesis", 0);
	register_concmd(szConsole_Command_Target_Assassin, "Cmd_Assassin", _, "<target> - Turn someone into a Assassin", 0);
	register_concmd(szConsole_Command_Target_Survivor, "Cmd_Survivor", _, "<target> - Turn someone into a Survivor", 0);
	register_concmd(szConsole_Command_Target_Sniper, "Cmd_Sniper", _, "<target> - Turn someone into a Sniper", 0);

	register_concmd(szConsole_Command_Target_Respawn_Players, "Cmd_Respawn", _, "<target> - Respawn someone", 0);
	register_concmd(szConsole_Command_Target_Start_Game_Mode, "Cmd_Start_Game_Mode", _, "<game mode name> - Start specific game mode", 0);
}

public plugin_precache()
{
	// Load from external file
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE ZOMBIE", g_Access_Make_Zombie, charsmax(g_Access_Make_Zombie))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE HUMAN", g_Access_Make_Human, charsmax(g_Access_Make_Human))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE NEMESIS", g_Access_Make_Nemesis, charsmax(g_Access_Make_Nemesis))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE ASSASSIN", g_Access_Make_Assassin, charsmax(g_Access_Make_Assassin))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE SURVIVOR", g_Access_Make_Survivor, charsmax(g_Access_Make_Survivor))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE SNIPER", g_Access_Make_Sniper, charsmax(g_Access_Make_Sniper))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "RESPAWN PLAYERS", g_Access_Respawn_Players, charsmax(g_Access_Respawn_Players))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "START GAME MODE", g_Access_Start_Game_Mode, charsmax(g_Access_Start_Game_Mode))
}

public plugin_natives()
{
	register_library("zpe_admin_commands");

	register_native("zpe_admin_commands_zombie", "native_admin_commands_zombie");
	register_native("zpe_admin_commands_human", "native_admin_commands_human");
	register_native("zpe_admin_commands_nemesis", "native_admin_commands_nemesis");
	register_native("zpe_admin_commands_assassin", "native_admin_commands_assassin");
	register_native("zpe_admin_commands_survivor", "native_admin_commands_survivor");
	register_native("zpe_admin_commands_sniper", "native_admin_commands_sniper");
	register_native("zpe_admin_commands_respawn", "native_admin_commands_respawn");
	register_native("zpe_admin_commands_start_mode", "native_admin_commands_start_mode");
}

public plugin_cfg()
{
	g_pCvar_Deathmatch = get_cvar_pointer("zpe_deathmatch");

	g_Game_Mode_Infection_ID = zpe_gamemodes_get_id("Infection Mode");
	g_Game_Mode_Nemesis_ID = zpe_gamemodes_get_id("Nemesis Mode");
	g_Game_Mode_Assassin_ID = zpe_gamemodes_get_id("Assassin Mode");
	g_Game_Mode_Survivor_ID = zpe_gamemodes_get_id("Survivor Mode");
	g_Game_Mode_Sniper_ID = zpe_gamemodes_get_id("Sniper Mode");
}

public native_admin_commands_zombie(iPlugin_ID, iNum_Params)
{
	new iID_Admin = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iID_Admin))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iID_Admin);

		return false;
	}

	new iPlayer = get_param(2);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Command_Zombie(iID_Admin, iPlayer);

	return true;
}

public native_admin_commands_human(iPlugin_ID, iNum_Params)
{
	new iID_Admin = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iID_Admin))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iID_Admin);

		return false;
	}

	new iPlayer = get_param(2);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Command_Human(iID_Admin, iPlayer);

	return true;
}

public native_admin_commands_nemesis(iPlugin_ID, iNum_Params)
{
	new iID_Admin = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iID_Admin))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iID_Admin);

		return false;
	}

	new iPlayer = get_param(2);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Command_Nemesis(iID_Admin, iPlayer);

	return true;
}

public native_admin_commands_assassin(iPlugin_ID, iNum_Params)
{
	new iID_Admin = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iID_Admin))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iID_Admin);

		return false;
	}

	new iPlayer = get_param(2);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Command_Assassin(iID_Admin, iPlayer);

	return true;
}

public native_admin_commands_survivor(iPlugin_ID, iNum_Params)
{
	new iID_Admin = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iID_Admin))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iID_Admin);

		return false;
	}

	new iPlayer = get_param(2);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Command_Survivor(iID_Admin, iPlayer);

	return true;
}

public native_admin_commands_sniper(iPlugin_ID, iNum_Params)
{
	new iID_Admin = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iID_Admin))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iID_Admin);

		return false;
	}

	new iPlayer = get_param(2);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Command_Sniper(iID_Admin, iPlayer);

	return true;
}

public native_admin_commands_respawn(iPlugin_ID, iNum_Params)
{
	new iID_Admin = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iID_Admin))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iID_Admin);

		return false;
	}

	new iPlayer = get_param(2);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	// Respawn allowed for player?
	if (!Allowed_Respawn(iPlayer))
	{
		return false;
	}

	Command_Respawn(iID_Admin, iPlayer);

	return true;
}

public native_admin_commands_start_mode(iPlugin_ID, iNum_Params)
{
	new iID_Admin = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iID_Admin))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iID_Admin);

		return false;
	}

	new szGame_Mode[32];
	get_string(2, szGame_Mode, charsmax(szGame_Mode));

	new iGame_Mode_ID = zpe_gamemodes_get_id(szGame_Mode);

	if (iGame_Mode_ID == ZPE_INVALID_GAME_MODE)
	{
		log_error(AMX_ERR_NATIVE, "Invalid game mode name (%s)", szGame_Mode);

		return false;
	}

	Command_Start_Mode(iID_Admin, iGame_Mode_ID);

	return true;
}

// zpe_zombie [target]
public Cmd_Zombie(iID_Admin, iLevel, iCID)
{
	// Check for access flag - Make Zombie
	if (!cmd_access(iID_Admin, read_flags(g_Access_Make_Zombie), iCID, 2))
	{
		return PLUGIN_HANDLED;
	}

	// Retrieve arguments
	new szArg[32];
	new iPlayer;

	read_argv(1, szArg, charsmax(szArg));
	iPlayer = cmd_target(iPlayer, szArg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));

	// Invalid target
	if (!iPlayer)
	{
		return PLUGIN_HANDLED;
	}

	// Target not allowed to be zombie
	if (zpe_core_is_zombie(iPlayer))
	{
		new szPlayer_Name[32];

		GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

		client_print(iID_Admin, print_console, "%L (%s)", iID_Admin, "ALREADY_ZOMBIE", szPlayer_Name);

		return PLUGIN_HANDLED;
	}

	Command_Zombie(iID_Admin, iPlayer);

	return PLUGIN_HANDLED;
}

// zpe_human [target]
public Cmd_Human(iID_Admin, iLevel, iCID)
{
	// Check for access flag - Make Human
	if (!cmd_access(iID_Admin, read_flags(g_Access_Make_Human), iCID, 2))
	{
		return PLUGIN_HANDLED;
	}

	// Retrieve arguments
	new szArg[32];
	new iPlayer;

	read_argv(1, szArg, charsmax(szArg));
	iPlayer = cmd_target(iPlayer, szArg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));

	// Invalid target
	if (!iPlayer)
	{
		return PLUGIN_HANDLED;
	}

	// Target not allowed to be human
	if (!zpe_core_is_zombie(iPlayer))
	{
		new szPlayer_Name[32];

		GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

		client_print(iID_Admin, print_console, "%L (%s)", iID_Admin, "ALREADY_HUMAN", szPlayer_Name);

		return PLUGIN_HANDLED;
	}

	Command_Human(iID_Admin, iPlayer);

	return PLUGIN_HANDLED;
}

// zpe_nemesis [target]
public Cmd_Nemesis(iID_Admin, iLevel, iCID)
{
	// Check for access flag - Make Nemesis
	if (!cmd_access(iID_Admin, read_flags(g_Access_Make_Nemesis), iCID, 2))
	{
		return PLUGIN_HANDLED;
	}

	// Retrieve arguments
	new szArg[32];
	new iPlayer;

	read_argv(1, szArg, charsmax(szArg));
	iPlayer = cmd_target(iPlayer, szArg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));

	// Invalid target
	if (!iPlayer)
	{
		return PLUGIN_HANDLED;
	}

	// Target not allowed to be nemesis
	if (zpe_class_nemesis_get(iPlayer))
	{
		new szPlayer_Name[32];

		GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

		client_print(iID_Admin, print_console, "%L (%s)", iID_Admin, "ALREADY_NEMESIS", szPlayer_Name);

		return PLUGIN_HANDLED;
	}

	Command_Nemesis(iID_Admin, iPlayer);

	return PLUGIN_HANDLED;
}

// zpe_assassin [target]
public Cmd_Assassin(iID_Admin, iLevel, iCID)
{
	// Check for access flag - Make assassin
	if (!cmd_access(iID_Admin, read_flags(g_Access_Make_Assassin), iCID, 2))
	{
		return PLUGIN_HANDLED;
	}

	// Retrieve arguments
	new szArg[32];
	new iPlayer;

	read_argv(1, szArg, charsmax(szArg));
	iPlayer = cmd_target(iPlayer, szArg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));

	// Invalid target
	if (!iPlayer)
	{
		return PLUGIN_HANDLED;
	}

	// Target not allowed to be assassin
	if (zpe_class_assassin_get(iPlayer))
	{
		new szPlayer_Name[32];

		GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

		client_print(iID_Admin, print_console, "%L (%s)", iID_Admin, "ALREADY_ASSASSIN", szPlayer_Name);

		return PLUGIN_HANDLED;
	}

	Command_Assassin(iID_Admin, iPlayer);

	return PLUGIN_HANDLED;
}

// zpe_survivor [target]
public Cmd_Survivor(iID_Admin, iLevel, iCID)
{
	// Check for access flag - Make Survivor
	if (!cmd_access(iID_Admin, read_flags(g_Access_Make_Survivor), iCID, 2))
	{
		return PLUGIN_HANDLED;
	}

	// Retrieve arguments
	new szArg[32];
	new iPlayer;

	read_argv(1, szArg, charsmax(szArg));
	iPlayer = cmd_target(iPlayer, szArg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));

	// Invalid target
	if (!iPlayer)
	{
		return PLUGIN_HANDLED;
	}

	// Target not allowed to be survivor
	if (zpe_class_survivor_get(iPlayer))
	{
		new szPlayer_Name[32];

		GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

		client_print(iID_Admin, print_console, "%L (%s)", iID_Admin, "ALREADY_SURVIVOR", szPlayer_Name);

		return PLUGIN_HANDLED;
	}

	Command_Survivor(iID_Admin, iPlayer);

	return PLUGIN_HANDLED;
}

// zpe_sniper [target]
public Cmd_Sniper(iID_Admin, iLevel, iCID)
{
	// Check for access flag - Make sniper
	if (!cmd_access(iID_Admin, read_flags(g_Access_Make_Sniper), iCID, 2))
	{
		return PLUGIN_HANDLED;
	}

	// Retrieve arguments
	new szArg[32];
	new iPlayer;

	read_argv(1, szArg, charsmax(szArg));
	iPlayer = cmd_target(iPlayer, szArg, (CMDTARGET_ONLY_ALIVE | CMDTARGET_ALLOW_SELF));

	// Invalid target
	if (!iPlayer)
	{
		return PLUGIN_HANDLED;
	}

	// Target not allowed to be sniper
	if (zpe_class_sniper_get(iPlayer))
	{
		new szPlayer_Name[32];

		GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

		client_print(iID_Admin, print_console, "%L (%s)", iID_Admin, "ALREADY_SNIPER", szPlayer_Name);

		return PLUGIN_HANDLED;
	}

	Command_Sniper(iID_Admin, iPlayer);

	return PLUGIN_HANDLED;
}

// zpe_respawn [target]
public Cmd_Respawn(iID_Admin, iLevel, iCID)
{
	// Check for access flag - Respawn
	if (!cmd_access(iID_Admin, read_flags(g_Access_Respawn_Players), iCID, 2))
	{
		return PLUGIN_HANDLED;
	}

	// Retrieve arguments
	new szArg[32];
	new iPlayer;

	read_argv(1, szArg, charsmax(szArg));
	iPlayer = cmd_target(iPlayer, szArg, CMDTARGET_ALLOW_SELF);

	// Invalid target
	if (!iPlayer)
	{
		return PLUGIN_HANDLED;
	}

	// Target not allowed to be respawned
	if (!Allowed_Respawn(iPlayer))
	{
		new szPlayer_Name[32];

		GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

		client_print(iID_Admin, print_console, "%L (%s)", iID_Admin, "CANT_RESPAWN", szPlayer_Name);

		return PLUGIN_HANDLED;
	}

	Command_Respawn(iID_Admin, iPlayer);

	return PLUGIN_HANDLED;
}

// zpe_gamemodes_start [game mode player]
public Cmd_Start_Game_Mode(iID_Admin, iLevel, iCID)
{
	// Check for access flag - Start Game Mode
	if (!cmd_access(iID_Admin, read_flags(g_Access_Start_Game_Mode), iCID, 2))
	{
		return PLUGIN_HANDLED;
	}

	new szGame_Mode[32];
	read_argv(1, szGame_Mode, charsmax(szGame_Mode));

	new iGame_Mode_ID = zpe_gamemodes_get_id(szGame_Mode);

	if (iGame_Mode_ID == ZPE_INVALID_GAME_MODE)
	{
		client_print(iID_Admin, print_console, "%L (%s)", iID_Admin, "INVALID_GAME_MODE", szGame_Mode);

		return PLUGIN_HANDLED;
	}

	Command_Start_Mode(iID_Admin, iGame_Mode_ID);

	return PLUGIN_HANDLED;
}

// Admin Command zpe_zombie
Command_Zombie(iID, iPlayer)
{
	// Prevent infecting last human
	if (zpe_core_is_last_human(iPlayer))
	{
		zpe_client_print_color(iID, print_team_default, "%L", iID, "CMD_CANT_LAST_HUMAN_COLOR");

		return;
	}

	// Check if a game mode is in progress
	if (zpe_gamemodes_get_current() == ZPE_NO_GAME_MODE)
	{
		// Start infection game mode with this target player
		if (!zpe_gamemodes_start(g_Game_Mode_Infection_ID, iPlayer))
		{
			zpe_client_print_color(iID, print_team_default, "%L", iID, "GAME_MODE_CANT_START_COLOR");

			return;
		}
	}

	else
	{
		// Make player infect himself
		zpe_core_infect(iPlayer, iPlayer);
	}

	// Get user names
	new szAdmin_Name[32];
	new szPlayer_Name[32];

	GET_USER_NAME(iID, szAdmin_Name, charsmax(szAdmin_Name));
	GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

	if (get_pcvar_num(g_pCvar_Message_Information))
	{
		zpe_client_print_color(0, print_team_default, "ADMIN %s - %s %L", szAdmin_Name, szPlayer_Name, LANG_PLAYER, "CMD_INFECT_COLOR");
	}

	// Log to Zombie Plague Enterprise log file?
	if (get_pcvar_num(g_pCvar_Management_Admin_Log))
	{
		new szAuth_ID[32];
		new szIP[16];

		get_user_authid(iID, szAuth_ID, charsmax(szAuth_ID));
		get_user_ip(iID, szIP, charsmax(szIP), 1);

		zpe_log("ADMIN %s <%s><%s> - %s %L (Players: %d)", szAdmin_Name, szAuth_ID, szIP, szPlayer_Name, LANG_SERVER, "CMD_INFECT_LOG", Get_Playing_Count());
	}
}

// Admin Command zpe_human
Command_Human(iID, iPlayer)
{
	// Prevent infecting last zombie
	if (zpe_core_is_last_zombie(iPlayer))
	{
		zpe_client_print_color(iID, print_team_default, "%L", iID, "CMD_CANT_LAST_ZOMBIE_COLOR");

		return;
	}

	// No game mode currently in progress
	if (zpe_gamemodes_get_current() == ZPE_NO_GAME_MODE)
	{
		zpe_client_print_color(iID, print_team_default, "%L", iID, "CMD_ONLY_AFTER_GAME_MODE_COLOR");

		return;
	}

	// Make player cure himself
	zpe_core_cure(iPlayer, iPlayer);

	// Get user names
	new szAdmin_Name[32];
	new szPlayer_Name[32];

	GET_USER_NAME(iID, szAdmin_Name, charsmax(szAdmin_Name));
	GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

	if (get_pcvar_num(g_pCvar_Message_Information))
	{
		zpe_client_print_color(0, print_team_default, "ADMIN %s - %s %L", szAdmin_Name, szPlayer_Name, LANG_PLAYER, "CMD_DISINFECT_COLOR");
	}

	// Log to Zombie Plague Enterprise log file?
	if (get_pcvar_num(g_pCvar_Management_Admin_Log))
	{
		new szAuth_ID[32];
		new szIP[16];

		get_user_authid(iID, szAuth_ID, charsmax(szAuth_ID));
		get_user_ip(iID, szIP, charsmax(szIP), 1);

		zpe_log("ADMIN %s <%s><%s> - %s %L (Players: %d)", szAdmin_Name, szAuth_ID, szIP, szPlayer_Name, LANG_SERVER, "CMD_DISINFECT_LOG", Get_Playing_Count());
	}
}

// Admin Command zpe_nemesis
Command_Nemesis(iID, iPlayer)
{
	// Prevent infecting last human
	if (zpe_core_is_last_human(iPlayer))
	{
		zpe_client_print_color(iID, print_team_default, "%L", iID, "CMD_CANT_LAST_HUMAN_COLOR");

		return;
	}

	// Check if a game mode is in progress
	if (zpe_gamemodes_get_current() == ZPE_NO_GAME_MODE)
	{
		// Start nemesis game mode with this target player
		if (!zpe_gamemodes_start(g_Game_Mode_Nemesis_ID, iPlayer))
		{
			zpe_client_print_color(iID, print_team_default, "%L", iID, "GAME_MODE_CANT_START_COLOR");

			return;
		}
	}

	else
	{
		// Make player nemesis
		zpe_class_nemesis_set(iPlayer);
	}

	// Get user names
	new szAdmin_Name[32];
	new szPlayer_Name[32];

	GET_USER_NAME(iID, szAdmin_Name, charsmax(szAdmin_Name));
	GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

	if (get_pcvar_num(g_pCvar_Message_Information))
	{
		zpe_client_print_color(0, print_team_default, "ADMIN %s - %s %L", szAdmin_Name, szPlayer_Name, LANG_PLAYER, "CMD_NEMESIS_COLOR");
	}

	// Log to Zombie Plague Enterprise log file?
	if (get_pcvar_num(g_pCvar_Management_Admin_Log))
	{
		new szAuth_ID[32];
		new szIP[16];

		get_user_authid(iID, szAuth_ID, charsmax(szAuth_ID));
		get_user_ip(iID, szIP, charsmax(szIP), 1);

		zpe_log("ADMIN %s <%s><%s> - %s %L (Players: %d)", szAdmin_Name, szAuth_ID, szIP, szPlayer_Name, LANG_SERVER, "CMD_NEMESIS_LOG", Get_Playing_Count());
	}
}

// Admin Command zpe_assassin
Command_Assassin(iID, iPlayer)
{
	// Prevent infecting last human
	if (zpe_core_is_last_human(iPlayer))
	{
		zpe_client_print_color(iID, print_team_default, "%L", iID, "CMD_CANT_LAST_HUMAN_COLOR");

		return;
	}

	// Check if a game mode is in progress
	if (zpe_gamemodes_get_current() == ZPE_NO_GAME_MODE)
	{
		// Start assassin game mode with this target player
		if (!zpe_gamemodes_start(g_Game_Mode_Assassin_ID, iPlayer))
		{
			zpe_client_print_color(iID, print_team_default, "%L", iID, "GAME_MODE_CANT_START_COLOR");

			return;
		}
	}

	else
	{
		// Make player assassin
		zpe_class_assassin_set(iPlayer);
	}

	// Get user names
	new szAdmin_Name[32];
	new szPlayer_Name[32];

	GET_USER_NAME(iID, szAdmin_Name, charsmax(szAdmin_Name));
	GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

	if (get_pcvar_num(g_pCvar_Message_Information))
	{
		zpe_client_print_color(0, print_team_default, "ADMIN %s - %s %L", szAdmin_Name, szPlayer_Name, LANG_PLAYER, "CMD_ASSASSIN_COLOR");
	}

	// Log to Zombie Plague Enterprise log file?
	if (get_pcvar_num(g_pCvar_Management_Admin_Log))
	{
		new szAuth_ID[32];
		new szIP[16];

		get_user_authid(iID, szAuth_ID, charsmax(szAuth_ID));
		get_user_ip(iID, szIP, charsmax(szIP), 1);

		zpe_log("ADMIN %s <%s><%s> - %s %L (Players: %d)", szAdmin_Name, szAuth_ID, szIP, szPlayer_Name, LANG_SERVER, "CMD_ASSASSIN_LOG", Get_Playing_Count());
	}
}

// Admin Command zpe_survivor
Command_Survivor(iID, iPlayer)
{
	// Prevent infecting last zombie
	if (zpe_core_is_last_zombie(iPlayer))
	{
		zpe_client_print_color(iID, print_team_default, "%L", iID, "CMD_CANT_LAST_ZOMBIE_COLOR");

		return;
	}

	// Check if a game mode is in progress
	if (zpe_gamemodes_get_current() == ZPE_NO_GAME_MODE)
	{
		// Start survivor game mode with this target player
		if (!zpe_gamemodes_start(g_Game_Mode_Survivor_ID, iPlayer))
		{
			zpe_client_print_color(iID, print_team_default, "%L", iID, "GAME_MODE_CANT_START_COLOR");

			return;
		}
	}

	else
	{
		// Make player survivor
		zpe_class_survivor_set(iPlayer);
	}

	// Get user names
	new szAdmin_Name[32];
	new szPlayer_Name[32];

	GET_USER_NAME(iID, szAdmin_Name, charsmax(szAdmin_Name));
	GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

	if (get_pcvar_num(g_pCvar_Message_Information))
	{
		zpe_client_print_color(0, print_team_default, "ADMIN %s - %s %L", szAdmin_Name, szPlayer_Name, LANG_PLAYER, "CMD_SURVIVOR_COLOR");
	}

	// Log to Zombie Plague Enterprise log file?
	if (get_pcvar_num(g_pCvar_Management_Admin_Log))
	{
		new szAuth_ID[32];
		new szIP[16];

		get_user_authid(iID, szAuth_ID, charsmax(szAuth_ID));
		get_user_ip(iID, szIP, charsmax(szIP), 1);

		zpe_log("ADMIN %s <%s><%s> - %s %L (Players: %d)", szAdmin_Name, szAuth_ID, szIP, szPlayer_Name, LANG_SERVER, "CMD_SURVIVOR_LOG", Get_Playing_Count());
	}
}

// Admin Command zpe_sniper
Command_Sniper(iID, iPlayer)
{
	// Prevent infecting last zombie
	if (zpe_core_is_last_zombie(iPlayer))
	{
		zpe_client_print_color(iID, print_team_default, "%L", iID, "CMD_CANT_LAST_ZOMBIE_COLOR");

		return;
	}

	// Check if a game mode is in progress
	if (zpe_gamemodes_get_current() == ZPE_NO_GAME_MODE)
	{
		// Start sniper game mode with this target player
		if (!zpe_gamemodes_start(g_Game_Mode_Sniper_ID, iPlayer))
		{
			zpe_client_print_color(iID, print_team_default, "%L", iID, "GAME_MODE_CANT_START_COLOR");

			return;
		}
	}

	else
	{
		// Make player sniper
		zpe_class_sniper_set(iPlayer);
	}

	// Get user names
	new szAdmin_Name[32];
	new szPlayer_Name[32];

	GET_USER_NAME(iID, szAdmin_Name, charsmax(szAdmin_Name));
	GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

	if (get_pcvar_num(g_pCvar_Message_Information))
	{
		zpe_client_print_color(0, print_team_default, "ADMIN %s - %s %L", szAdmin_Name, szPlayer_Name, LANG_PLAYER, "CMD_SNIPER_COLOR");
	}

	// Log to Zombie Plague Enterprise log file?
	if (get_pcvar_num(g_pCvar_Management_Admin_Log))
	{
		new szAuth_ID[32];
		new szIP[16];

		get_user_authid(iID, szAuth_ID, charsmax(szAuth_ID));
		get_user_ip(iID, szIP, charsmax(szIP), 1);

		zpe_log("ADMIN %s <%s><%s> - %s %L (Players: %d)", szAdmin_Name, szAuth_ID, szIP, szPlayer_Name, LANG_SERVER, "CMD_SNIPER_LOG", Get_Playing_Count());
	}
}

// Admin Command zpe_respawn
Command_Respawn(iID, iPlayer)
{
	// Deathmatch module active?
	if (g_pCvar_Deathmatch)
	{
		// Respawn as zombie?
		if (get_pcvar_num(g_pCvar_Deathmatch) == 2 || (get_pcvar_num(g_pCvar_Deathmatch) == 3 && CHANCE(50)) || (get_pcvar_num(g_pCvar_Deathmatch) == 4 && zpe_core_get_zombie_count() < Get_Alive_Count() / 2))
		{
			// Only allow respawning as zombie after a game mode started
			if (zpe_gamemodes_get_current() != ZPE_NO_GAME_MODE)
			{
				zpe_core_respawn_as_zombie(iPlayer, true);
			}
		}
	}

	// Respawn player!
	Respawn_Player_Manually(iPlayer);

	// Get user names
	new szAdmin_Name[32];
	new szPlayer_Name[32];

	GET_USER_NAME(iID, szAdmin_Name, charsmax(szAdmin_Name));
	GET_USER_NAME(iPlayer, szPlayer_Name, charsmax(szPlayer_Name));

	if (get_pcvar_num(g_pCvar_Message_Information))
	{
		zpe_client_print_color(0, print_team_default, "ADMIN %s - %s %L", szAdmin_Name, szPlayer_Name, LANG_PLAYER, "CMD_RESPAWN_COLOR");
	}

	// Log to Zombie Plague Enterprise log file?
	if (get_pcvar_num(g_pCvar_Management_Admin_Log))
	{
		new szAuth_ID[32];
		new szIP[16];

		get_user_authid(iID, szAuth_ID, charsmax(szAuth_ID));
		get_user_ip(iID, szIP, charsmax(szIP), 1);

		zpe_log("ADMIN %s <%s><%s> - %s %L (Players: %d)", szAdmin_Name, szAuth_ID, szIP, szPlayer_Name, LANG_SERVER, "CMD_RESPAWN_LOG", Get_Playing_Count());
	}
}

// Respawn player manually (called after respawn checks are done)
Respawn_Player_Manually(iPlayer)
{
	// Respawn!
	rg_round_respawn(iPlayer);
}

// Admin Command zpe_start_game_mode
Command_Start_Mode(iPlayer, iGame_Mode_ID)
{
	// Attempt to start game mode
	if (!zpe_gamemodes_start(iGame_Mode_ID))
	{
		zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "GAME_MODE_CANT_START_COLOR");

		return;
	}

	// Get user names
	new szAdmin_Name[32];
	new szMode_name[32];

	GET_USER_NAME(iPlayer, szAdmin_Name, charsmax(szAdmin_Name));
	zpe_gamemodes_get_name(iGame_Mode_ID, szMode_name, charsmax(szMode_name));

	if (get_pcvar_num(g_pCvar_Message_Information))
	{
		zpe_client_print_color(0, print_team_default, "ADMIN %s - %L: %s", szAdmin_Name, LANG_PLAYER, "CMD_START_GAME_MODE_COLOR", szMode_name);
	}

	// Log to Zombie Plague Enterprise log file?
	if (get_pcvar_num(g_pCvar_Management_Admin_Log))
	{
		new szAuth_ID[32];
		new szIP[16];

		get_user_authid(iPlayer, szAuth_ID, charsmax(szAuth_ID));
		get_user_ip(iPlayer, szIP, charsmax(szIP), 1);

		zpe_log("ADMIN %s <%s><%s> - %L: %s (Players: %d)", szAdmin_Name, szAuth_ID, szIP, LANG_SERVER, "CMD_START_GAME_MODE_LOG", szMode_name, Get_Playing_Count());
	}
}

Get_Playing_Count()
{
	new iPlaying;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_NOT_VALID(g_iBit_Connected, i))
		{
			continue;
		}

		if (CS_GET_USER_TEAM(i) != CS_TEAM_SPECTATOR && CS_GET_USER_TEAM(i) != CS_TEAM_UNASSIGNED)
		{
			iPlaying++;
		}
	}

	return iPlaying;
}

Get_Alive_Count()
{
	new iAlive;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Alive, i))
		{
			iAlive++;
		}
	}

	return iAlive;
}

// Checks if a player is allowed to respawn
Allowed_Respawn(iPlayer)
{
	if (BIT_VALID(g_iBit_Alive, iPlayer))
	{
		return false;
	}

	if (CS_GET_USER_TEAM(iPlayer) == CS_TEAM_SPECTATOR || CS_GET_USER_TEAM(iPlayer) == CS_TEAM_UNASSIGNED)
	{
		return false;
	}

	return true;
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
	BIT_SUB(g_iBit_Connected, iPlayer);
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}