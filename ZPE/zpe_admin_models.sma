/* AMX Mod X
*	[ZPE] Admin Models.
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

#define PLUGIN "admin models"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <ck_cs_weap_models_api>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

#define ACCESS_FLAG_MAX_LENGTH 2

// Access flags
new g_Access_Admin_Models_Human_Player[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Admin_Models_Human_Knife[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Admin_Models_Zombie_Player[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Admin_Models_Zombie_Claws[ACCESS_FLAG_MAX_LENGTH] = "d";

// Custom models
new Array:g_aAdmin_Models_Human_Player;
new Array:g_aAdmin_V_Models_Human_Knife;
new Array:g_aAdmin_P_Models_Human_Knife;
new Array:g_aAdmin_Models_Zombie_Player;
new Array:g_aAdmin_Models_Zombie_Claws;

new g_pCvar_Admin_Models_Human_Player;
new g_pCvar_Admin_Models_Human_Knife;
new g_pCvar_Admin_Models_Zombie_Player;
new g_pCvar_Admin_Models_Zombie_Claws;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Admin_Models_Human_Player = register_cvar("zpe_admin_models_human_player", "1");
	g_pCvar_Admin_Models_Human_Knife = register_cvar("zpe_admin_models_human_knife", "1");
	g_pCvar_Admin_Models_Zombie_Player = register_cvar("zpe_admin_models_zombie_player", "1");
	g_pCvar_Admin_Models_Zombie_Claws = register_cvar("zpe_admin_models_zombie_claws", "1");
}

public plugin_precache()
{
	g_aAdmin_Models_Human_Player = ArrayCreate(PLAYER_MODEL_MAX_LENGTH, 1);
	g_aAdmin_V_Models_Human_Knife = ArrayCreate(MODEL_MAX_LENGTH, 1);
	g_aAdmin_P_Models_Human_Knife = ArrayCreate(MODEL_MAX_LENGTH, 1);

	g_aAdmin_Models_Zombie_Player = ArrayCreate(PLAYER_MODEL_MAX_LENGTH, 1);
	g_aAdmin_Models_Zombie_Claws = ArrayCreate(MODEL_MAX_LENGTH, 1);

	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Settings", "ADMIN MODELS HUMAN PLAYER", g_aAdmin_Models_Human_Player);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Settings", "ADMIN VIEW MODELS HUMAN KNIFE", g_aAdmin_V_Models_Human_Knife);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Settings", "ADMIN PLAYER MODELS HUMAN KNIFE", g_aAdmin_P_Models_Human_Knife);

	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Settings", "ADMIN MODELS ZOMBIE PLAYER", g_aAdmin_Models_Zombie_Player);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Settings", "ADMIN MODELS ZOMBIE CLAWS", g_aAdmin_Models_Zombie_Claws);

	Precache_Player_Models(g_aAdmin_Models_Human_Player);
	Precache_Models(g_aAdmin_V_Models_Human_Knife);
	Precache_Models(g_aAdmin_P_Models_Human_Knife);

	Precache_Player_Models(g_aAdmin_Models_Zombie_Player);
	Precache_Models(g_aAdmin_Models_Zombie_Claws);

	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "ADMIN MODELS HUMAN PLAYER", g_Access_Admin_Models_Human_Player, charsmax(g_Access_Admin_Models_Human_Player));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "ADMIN MODELS HUMAN KNIFE", g_Access_Admin_Models_Human_Knife, charsmax(g_Access_Admin_Models_Human_Knife));

	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "ADMIN MODELS ZOMBIE PLAYER", g_Access_Admin_Models_Zombie_Player, charsmax(g_Access_Admin_Models_Zombie_Player));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "ADMIN MODELS ZOMBIE CLAWS", g_Access_Admin_Models_Zombie_Claws, charsmax(g_Access_Admin_Models_Zombie_Claws));
}

public zpe_fw_core_cure_post(iPlayer, iAttacker)
{
	// Skip for Survivor
	if (zpe_class_survivor_get(iPlayer))
	{
		return;
	}

	// Skip for Sniper
	else if (zpe_class_sniper_get(iPlayer))
	{
		return;
	}

	new iUser_Flags = get_user_flags(iPlayer);

	// Apply admin human player model?
	if (get_pcvar_num(g_pCvar_Admin_Models_Human_Player))
	{
		if (iUser_Flags & read_flags(g_Access_Admin_Models_Human_Player))
		{
			new szPlayer_Model[PLAYER_MODEL_MAX_LENGTH];
			ArrayGetString(g_aAdmin_Models_Human_Player, RANDOM(ArraySize(g_aAdmin_Models_Human_Player)), szPlayer_Model, charsmax(szPlayer_Model));

			rg_set_user_model(iPlayer, szPlayer_Model);
		}
	}

	// Apply admin human knife model?
	if (get_pcvar_num(g_pCvar_Admin_Models_Human_Knife))
	{
		if (iUser_Flags & read_flags(g_Access_Admin_Models_Human_Knife))
		{
			new szModel[MODEL_MAX_LENGTH];

			ArrayGetString(g_aAdmin_V_Models_Human_Knife, RANDOM(ArraySize(g_aAdmin_V_Models_Human_Knife)), szModel, charsmax(szModel));
			cs_set_player_view_model(iPlayer, CSW_KNIFE, szModel);

			ArrayGetString(g_aAdmin_P_Models_Human_Knife, RANDOM(ArraySize(g_aAdmin_P_Models_Human_Knife)), szModel, charsmax(szModel));
			cs_set_player_weap_model(iPlayer, CSW_KNIFE, szModel);
		}
	}
}

public zpe_fw_core_infect_post(iPlayer, iAttacker)
{
	// Skip for Nemesis
	if (zpe_class_nemesis_get(iPlayer))
	{
		return;
	}

	// Skip for Assassin
	else if (zpe_class_assassin_get(iPlayer))
	{
		return;
	}

	new iUser_Flags = get_user_flags(iPlayer);

	// Apply admin zombie player model?
	if (get_pcvar_num(g_pCvar_Admin_Models_Zombie_Player))
	{
		if (iUser_Flags & read_flags(g_Access_Admin_Models_Zombie_Player))
		{
			new szPlayer_Model[PLAYER_MODEL_MAX_LENGTH];
			ArrayGetString(g_aAdmin_Models_Zombie_Player, RANDOM(ArraySize(g_aAdmin_Models_Zombie_Player)), szPlayer_Model, charsmax(szPlayer_Model));
			rg_set_user_model(iPlayer, szPlayer_Model);
		}
	}

	// Apply admin zombie claw model?
	if (get_pcvar_num(g_pCvar_Admin_Models_Zombie_Claws))
	{
		if (iUser_Flags & read_flags(g_Access_Admin_Models_Zombie_Claws))
		{
			new szModel[MODEL_MAX_LENGTH];
			ArrayGetString(g_aAdmin_Models_Zombie_Claws, RANDOM(ArraySize(g_aAdmin_Models_Zombie_Claws)), szModel, charsmax(szModel));
			cs_set_player_view_model(iPlayer, CSW_KNIFE, szModel);
		}
	}
}