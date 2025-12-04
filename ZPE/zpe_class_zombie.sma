/* AMX Mod X
*	[ZPE] Class Zombie.
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

#define PLUGIN "class zombie"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <ck_cs_maxspeed_api>
#include <ck_cs_weap_models_api>
#include <ck_cs_weap_restrict_api>
#include <zpe_kernel>
#include <zpe_class_zombie_const>

#define ZPE_CLASS_ZOMBIE_SETTINGS_PATH "ZPE/classes/zombie"

#define ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME "Settings"

// For class list menu handlers
#define MENU_PAGE_CLASS(%0) g_Menu_Data[%0]

#define ZOMBIE_DEFAULT_MODEL "zombie"
#define ZOMBIE_DEFAULT_CLAWS_MODEL "models/zombie_plague_enterprise/v_knife_zombie.mdl"
#define ZOMBIE_DEFAULT_KNOCKBACK 1.0
#define ZOMBIE_DEFAULT_ALLOWED_WEAPON CSW_KNIFE

// Allowed weapons for zombies
const ZOMBIE_ALLOWED_WEAPONS_BITSUM = (1 << CSW_KNIFE) | (1 << CSW_HEGRENADE) | (1 << CSW_FLASHBANG) | (1 << CSW_SMOKEGRENADE) | (1 << CSW_C4);

enum _:TOTAL_FORWARDS
{
	FW_CLASS_SELECT_PRE = 0,
	FW_CLASS_SELECT_POST,
	FW_CLASS_REGISTER_POST
};

new g_Class_Zombie[MAX_PLAYERS + 1];
new g_Class_Zombie_Next[MAX_PLAYERS + 1];

new g_Additional_Menu_Text[MAX_PLAYERS + 1];

new g_Menu_Data[MAX_PLAYERS + 1];

new Array:g_aClass_Zombie_Real_Name;
new Array:g_aClass_Zombie_Name;
new Array:g_aClass_Zombie_Description;
new Array:g_aClass_Zombie_Models_File;
new Array:g_aClass_Zombie_Models_Handle;
new Array:g_aClass_Zombie_Claws_File;
new Array:g_aClass_Zombie_Claws_Handle;
new Array:g_aClass_Zombie_Health;
new Array:g_aClass_Zombie_Armor;
new Array:g_aClass_Zombie_Speed;
new Array:g_aClass_Zombie_Gravity;
new Array:g_aClass_Zombie_Knockback_File;
new Array:g_aClass_Zombie_Knockback;

new g_Forwards[TOTAL_FORWARDS];
new g_Forward_Result;

new g_Class_Zombie_Count;

new g_pCvar_Zombie_Armor_Type;

new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Zombie_Armor_Type = register_cvar("zpe_zombie_armor_type", "0");

	register_clcmd("say /zclass", "Show_Menu_Class_Zombie");
	register_clcmd("say /class", "Show_Class_Menu");

	g_Forwards[FW_CLASS_SELECT_PRE] = CreateMultiForward("zpe_fw_class_zombie_select_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_CLASS_SELECT_POST] = CreateMultiForward("zpe_fw_class_zombie_select_post", ET_CONTINUE, FP_CELL, FP_CELL);
}

public plugin_precache()
{
	new szModel_Path[128];
	formatex(szModel_Path, charsmax(szModel_Path), "models/player/%s/%s.mdl", ZOMBIE_DEFAULT_MODEL, ZOMBIE_DEFAULT_MODEL);
	precache_model(szModel_Path);

	precache_model(ZOMBIE_DEFAULT_CLAWS_MODEL);

	g_Forwards[FW_CLASS_REGISTER_POST] = CreateMultiForward("zpe_fw_class_zombie_register_post", ET_CONTINUE, FP_CELL);
}

public plugin_natives()
{
	register_library("zpe_class_zombie");

	register_native("zpe_class_zombie_get_current", "native_class_zombie_get_current");
	register_native("zpe_class_zombie_get_next", "native_class_zombie_get_next");
	register_native("zpe_class_zombie_set_next", "native_class_zombie_set_next");
	register_native("zpe_class_zombie_register", "native_class_zombie_register");
	register_native("zpe_class_zombie_register_kb", "native_class_zombie_register_kb");
	register_native("zpe_class_zombie_get_id", "native_class_zombie_get_id");
	register_native("zpe_class_zombie_get_name", "native_class_zombie_get_name");
	register_native("zpe_class_zombie_get_description", "native_class_zombie_get_description");
	register_native("zpe_class_zombie_get_kb", "native_class_zombie_get_kb");
	register_native("zpe_class_zombie_get_count", "native_class_zombie_get_count");
	register_native("zpe_class_zombie_show_menu", "native_class_zombie_show_menu");
	register_native("zpe_class_zombie_get_max_health", "native_class_zombie_get_max_health");
	register_native("zpe_class_zombie_register_model", "native_class_zombie_register_model");
	register_native("zpe_class_zombie_register_claw", "native_class_zombie_register_claw");
	register_native("zpe_class_zombie_get_real_name", "native_class_zombie_get_real_name");
	register_native("zpe_class_zombie_menu_text_add", "native_class_zombie_menu_text_add");

	// Initialize dynamic arrays
	g_aClass_Zombie_Real_Name = ArrayCreate(32, 1);
	g_aClass_Zombie_Name = ArrayCreate(32, 1);
	g_aClass_Zombie_Description = ArrayCreate(32, 1);
	g_aClass_Zombie_Models_File = ArrayCreate(1, 1);
	g_aClass_Zombie_Models_Handle = ArrayCreate(1, 1);
	g_aClass_Zombie_Claws_File = ArrayCreate(1, 1);
	g_aClass_Zombie_Claws_Handle = ArrayCreate(1, 1);
	g_aClass_Zombie_Health = ArrayCreate(1, 1);
	g_aClass_Zombie_Armor = ArrayCreate(1, 1);
	g_aClass_Zombie_Speed = ArrayCreate(1, 1);
	g_aClass_Zombie_Gravity = ArrayCreate(1, 1);
	g_aClass_Zombie_Knockback_File = ArrayCreate(1, 1);
	g_aClass_Zombie_Knockback = ArrayCreate(1, 1);
}

public Show_Class_Menu(iPlayer)
{
	if (zpe_core_is_zombie(iPlayer))
	{
		Show_Menu_Class_Zombie(iPlayer);
	}
}

public Show_Menu_Class_Zombie(iPlayer)
{
	static szMenu[128];
	static szName[32];
	static szDescription[32];
	static szTranskey[64];

	new iMenu_ID;
	new iItemdata[2];

	formatex(szMenu, charsmax(szMenu), "%L \r", iPlayer, "MENU_CLASS_ZOMBIE");

	iMenu_ID = menu_create(szMenu, "Menu_Class_Zombie");

	for (new i = 0; i < g_Class_Zombie_Count; i++)
	{
		// Additional text to display
		g_Additional_Menu_Text[0] = 0;

		// Execute class select attempt forward
		ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_Forward_Result, iPlayer, i);

		// Show class to player?
		if (g_Forward_Result >= ZPE_CLASS_DONT_SHOW)
		{
			continue;
		}

		ArrayGetString(g_aClass_Zombie_Name, i, szName, charsmax(szName));
		ArrayGetString(g_aClass_Zombie_Description, i, szDescription, charsmax(szDescription));

		// ML support for class name + description
		formatex(szTranskey, charsmax(szTranskey), "ZOMBIE_DESCRIPTION %s", szName);

		if (GetLangTransKey(szTranskey) != TransKey_Bad)
		{
			formatex(szDescription, charsmax(szDescription), "%L", iPlayer, szTranskey);
		}

		formatex(szTranskey, charsmax(szTranskey), "ZOMBIE_NAME %s", szName);

		if (GetLangTransKey(szTranskey) != TransKey_Bad)
		{
			formatex(szName, charsmax(szName), "%L", iPlayer, szTranskey);
		}

		// Class available to player?
		if (g_Forward_Result >= ZPE_CLASS_NOT_AVAILABLE)
		{
			formatex(szMenu, charsmax(szMenu), "\d %s %s %s", szName, szDescription, g_Additional_Menu_Text);
		}

		// Class is current class?
		else if (i == g_Class_Zombie_Next[iPlayer])
		{
			formatex(szMenu, charsmax(szMenu), "\r %s \y %s \w %s", szName, szDescription, g_Additional_Menu_Text);
		}

		else
		{
			formatex(szMenu, charsmax(szMenu), "%s \y %s \w %s", szName, szDescription, g_Additional_Menu_Text);
		}

		iItemdata[0] = i;
		iItemdata[1] = 0;

		menu_additem(iMenu_ID, szMenu, iItemdata);
	}

	// No classes to display?
	if (menu_items(iMenu_ID) <= 0)
	{
		zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "NO_CLASSES_COLOR");

		menu_destroy(iMenu_ID);

		return;
	}

	// Back - Next - Exit
	formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_BACK");
	menu_setprop(iMenu_ID, MPROP_BACKNAME, szMenu);

	formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_NEXT");
	menu_setprop(iMenu_ID, MPROP_NEXTNAME, szMenu);

	formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_EXIT");
	menu_setprop(iMenu_ID, MPROP_EXITNAME, szMenu);

	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_CLASS(iPlayer) = min(MENU_PAGE_CLASS(iPlayer), menu_pages(iMenu_ID) - 1);

	menu_display(iPlayer, iMenu_ID, MENU_PAGE_CLASS(iPlayer));
}

public Menu_Class_Zombie(iPlayer, iMenu_ID, iItem)
{
	// Menu was closed
	if (iItem == MENU_EXIT)
	{
		MENU_PAGE_CLASS(iPlayer) = 0;

		menu_destroy(iMenu_ID);

		return PLUGIN_HANDLED;
	}

	// Remember class menu page
	MENU_PAGE_CLASS(iPlayer) = iItem / 7;

	// Retrieve class index
	new iItemdata[2];

	new iDummy;
	new iIndex;

	menu_item_getinfo(iMenu_ID, iItem, iDummy, iItemdata, charsmax(iItemdata), _, _, iDummy);

	iIndex = iItemdata[0];

	// Execute class select attempt forward
	ExecuteForward(g_Forwards[FW_CLASS_SELECT_PRE], g_Forward_Result, iPlayer, iIndex);

	// Class available to player?
	if (g_Forward_Result >= ZPE_CLASS_NOT_AVAILABLE)
	{
		menu_destroy(iMenu_ID);

		return PLUGIN_HANDLED;
	}

	// Make selected class next class for player
	g_Class_Zombie_Next[iPlayer] = iIndex;

	new szName[32];
	new szTranskey[64];

	new Float:fMax_Speed = Float:ArrayGetCell(g_aClass_Zombie_Speed, g_Class_Zombie_Next[iPlayer]);

	ArrayGetString(g_aClass_Zombie_Name, g_Class_Zombie_Next[iPlayer], szName, charsmax(szName));

	// ML support for class name
	formatex(szTranskey, charsmax(szTranskey), "ZOMBIE_NAME %s", szName);

	if (GetLangTransKey(szTranskey) != TransKey_Bad)
	{
		formatex(szName, charsmax(szName), "%L", iPlayer, szTranskey);
	}

	// Show selected class zombie
	zpe_client_print_color(iPlayer, print_team_default, "%L: %s", iPlayer, "ZOMBIE_SELECT_COLOR", szName);

	zpe_client_print_color
	(
		iPlayer, print_team_default, "%L: %d %L: %d %L: %d %L: %.2fx %L %.2fx",
		iPlayer, "ZOMBIE_ATTRIBUTE_HP_COLOR", floatround(ArrayGetCell(g_aClass_Zombie_Health, g_Class_Zombie_Next[iPlayer])),
		iPlayer, "ZOMBIE_ATTRIBUTE_ARMOR_COLOR", ArrayGetCell(g_aClass_Zombie_Armor, g_Class_Zombie_Next[iPlayer]),
		iPlayer, "ZOMBIE_ATTRIBUTE_SPEED_COLOR", cs_maxspeed_display_value(fMax_Speed),
		iPlayer, "ZOMBIE_ATTRIBUTE_GRAVITY_COLOR", Float:ArrayGetCell(g_aClass_Zombie_Gravity, g_Class_Zombie_Next[iPlayer]),
		iPlayer, "ZOMBIE_ATTRIBUTE_KNOCKBACK_COLOR", Float:ArrayGetCell(g_aClass_Zombie_Knockback, g_Class_Zombie_Next[iPlayer])
	);

	// Execute class select post forward
	ExecuteForward(g_Forwards[FW_CLASS_SELECT_POST], g_Forward_Result, iPlayer, iIndex);

	menu_destroy(iMenu_ID);

	return PLUGIN_HANDLED;
}

public zpe_fw_core_infect_post(iPlayer)
{
	// Show class zombie menu if they haven't chosen any (e.g. just connected)
	if (g_Class_Zombie_Next[iPlayer] == ZPE_INVALID_CLASS_ZOMBIE)
	{
		Show_Menu_Class_Zombie(iPlayer);
	}

	// Set selected class zombie. If none selected yet, use the first one
	g_Class_Zombie[iPlayer] = g_Class_Zombie_Next[iPlayer];

	if (g_Class_Zombie[iPlayer] == ZPE_INVALID_CLASS_ZOMBIE)
	{
		g_Class_Zombie[iPlayer] = 0;
	}

	// Apply zombie attributes
	SET_USER_HEALTH(iPlayer, ArrayGetCell(g_aClass_Zombie_Health, g_Class_Zombie[iPlayer]));

	if (get_pcvar_num(g_pCvar_Zombie_Armor_Type))
	{
		rg_set_user_armor(iPlayer, ArrayGetCell(g_aClass_Zombie_Armor, g_Class_Zombie[iPlayer]), ARMOR_VESTHELM);
	}

	else
	{
		rg_set_user_armor(iPlayer, ArrayGetCell(g_aClass_Zombie_Armor, g_Class_Zombie[iPlayer]), ARMOR_KEVLAR);
	}

	SET_USER_GRAVITY(iPlayer, Float:ArrayGetCell(g_aClass_Zombie_Gravity, g_Class_Zombie[iPlayer]));
	cs_set_player_maxspeed_auto(iPlayer, Float:ArrayGetCell(g_aClass_Zombie_Speed, g_Class_Zombie[iPlayer]));

	// Apply zombie player model
	new Array:aClass_Models = ArrayGetCell(g_aClass_Zombie_Models_Handle, g_Class_Zombie[iPlayer]);

	if (aClass_Models != Invalid_Array)
	{
		new szPlayer_Model[32];
		ArrayGetString(aClass_Models, RANDOM(ArraySize(aClass_Models)), szPlayer_Model, charsmax(szPlayer_Model));
		rg_set_user_model(iPlayer, szPlayer_Model);
	}

	else
	{
		rg_set_user_model(iPlayer, ZOMBIE_DEFAULT_MODEL);
	}

	// Apply zombie claw model
	new Array:aClass_Claws = ArrayGetCell(g_aClass_Zombie_Claws_Handle, g_Class_Zombie[iPlayer]);

	if (aClass_Claws != Invalid_Array)
	{
		new szClaw_Model[64];
		ArrayGetString(aClass_Claws, RANDOM(ArraySize(aClass_Claws)), szClaw_Model, charsmax(szClaw_Model));
		cs_set_player_view_model(iPlayer, CSW_KNIFE, szClaw_Model);
	}

	else
	{
		cs_set_player_view_model(iPlayer, CSW_KNIFE, ZOMBIE_DEFAULT_CLAWS_MODEL);
	}

	cs_set_player_weap_model(iPlayer, CSW_KNIFE, "");

	// Apply weapon restrictions for zombies
	cs_set_player_weap_restrict(iPlayer, true, ZOMBIE_ALLOWED_WEAPONS_BITSUM, ZOMBIE_DEFAULT_ALLOWED_WEAPON);
}

public zpe_fw_core_cure(iPlayer)
{
	// Remove zombie claw models
	cs_reset_player_view_model(iPlayer, CSW_KNIFE);
	cs_reset_player_weap_model(iPlayer, CSW_KNIFE);

	// Remove zombie weapon restrictions
	cs_set_player_weap_restrict(iPlayer, false);
}

public native_class_zombie_get_current(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (!is_user_connected(iPlayer)) // Use bit = invalid player
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return ZPE_INVALID_CLASS_ZOMBIE;
	}

	return g_Class_Zombie[iPlayer];
}

public native_class_zombie_get_next(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return ZPE_INVALID_CLASS_ZOMBIE;
	}

	return g_Class_Zombie_Next[iPlayer];
}

public native_class_zombie_set_next(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	new iClass_ID = get_param(2);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Zombie_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class zombie player (%d)", iClass_ID);

		return false;
	}

	g_Class_Zombie_Next[iPlayer] = iClass_ID;

	return true;
}

public Float:native_class_zombie_get_max_health(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Zombie_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class zombie player (%d)", iClass_ID);

		return -1.0;
	}

	return ArrayGetCell(g_aClass_Zombie_Health, iClass_ID);
}

public native_class_zombie_register(iPlugin_ID, iNum_Params)
{
	new szName[32];
	get_string(1, szName, charsmax(szName));

	if (strlen(szName) == 0)
	{
		log_error(AMX_ERR_NATIVE, "Can't register class zombie with an empty name");

		return ZPE_INVALID_CLASS_ZOMBIE;
	}

	new szClass_Zombie_Name[32];

	for (new i = 0; i < g_Class_Zombie_Count; i++)
	{
		ArrayGetString(g_aClass_Zombie_Real_Name, i, szClass_Zombie_Name, charsmax(szClass_Zombie_Name));

		if (equali(szName, szClass_Zombie_Name))
		{
			log_error(AMX_ERR_NATIVE, "Class zombie already registered (%s)", szClass_Zombie_Name);

			return ZPE_INVALID_CLASS_ZOMBIE;
		}
	}

	new szClass_Zombie_Settings_Full_Path[128];
	formatex(szClass_Zombie_Settings_Full_Path, charsmax(szClass_Zombie_Settings_Full_Path), "addons/amxmodx/configs/%s/%s.ini", ZPE_CLASS_ZOMBIE_SETTINGS_PATH, szName);

	if (!file_exists(szClass_Zombie_Settings_Full_Path))
	{
		if (!write_file(szClass_Zombie_Settings_Full_Path, ""))
		{
			log_error(AMX_ERR_NATIVE, "Can't create config for class zombie (%s)", szName);

			return ZPE_INVALID_CLASS_ZOMBIE;
		}
	}

	ArrayPushString(g_aClass_Zombie_Real_Name, szName);

	new szClass_Zombie_Settings_Path[64];
	formatex(szClass_Zombie_Settings_Path, charsmax(szClass_Zombie_Settings_Path), "%s/%s.ini", ZPE_CLASS_ZOMBIE_SETTINGS_PATH, szName);

	// Name
	if (!amx_load_setting_string(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "NAME", szName, charsmax(szName)))
	{
		amx_save_setting_string(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "NAME", szName);
	}

	ArrayPushString(g_aClass_Zombie_Name, szName);

	// Description
	new szDescription[32];
	get_string(2, szDescription, charsmax(szDescription));

	if (!amx_load_setting_string(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "INFO", szDescription, charsmax(szDescription)))
	{
		amx_save_setting_string(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "INFO", szDescription);
	}

	ArrayPushString(g_aClass_Zombie_Description, szDescription);

	// Models
	new Array:aClass_Models = ArrayCreate(32, 1);
	amx_load_setting_string_arr(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "PLAYER MODELS", aClass_Models);

	new iArray_Size = ArraySize(aClass_Models);
	new bool:bHave_Elements = iArray_Size > 0;

	if (bHave_Elements)
	{
		new szPlayer_Model[32];
		new szModel_Path[128];

		for (new i = 0; i < iArray_Size; i++)
		{
			ArrayGetString(aClass_Models, i, szPlayer_Model, charsmax(szPlayer_Model));
			formatex(szModel_Path, charsmax(szModel_Path), "models/player/%s/%s.mdl", szPlayer_Model, szPlayer_Model);
			precache_model(szModel_Path);
		}
	}

	else
	{
		ArrayDestroy(aClass_Models);
		amx_save_setting_string(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "PLAYER MODELS", ZOMBIE_DEFAULT_MODEL);
	}

	ArrayPushCell(g_aClass_Zombie_Models_File, bHave_Elements);
	ArrayPushCell(g_aClass_Zombie_Models_Handle, aClass_Models);

	// Claw model
	new Array:aClass_Claws = ArrayCreate(64, 1);
	amx_load_setting_string_arr(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "CLAWS MODEL", aClass_Claws);

	iArray_Size = ArraySize(aClass_Claws);
	bHave_Elements = iArray_Size > 0;

	if (bHave_Elements)
	{
		new szClaw_Model[64];

		for (new i = 0; i < iArray_Size; i++)
		{
			ArrayGetString(aClass_Claws, i, szClaw_Model, charsmax(szClaw_Model));
			precache_model(szClaw_Model);
		}
	}

	else
	{
		ArrayDestroy(aClass_Claws);
		amx_save_setting_string(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "CLAWS MODEL", ZOMBIE_DEFAULT_CLAWS_MODEL);
	}

	ArrayPushCell(g_aClass_Zombie_Claws_File, bHave_Elements)
	ArrayPushCell(g_aClass_Zombie_Claws_Handle, aClass_Claws);

	// Health
	new Float:fHealth = get_param_f(3);

	if (!amx_load_setting_float(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "HEALTH", fHealth))
	{
		amx_save_setting_float(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "HEALTH", fHealth);
	}

	ArrayPushCell(g_aClass_Zombie_Health, fHealth);

	// Armor
	new iArmor = get_param(4);

	if (!amx_load_setting_int(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "ARMOR", iArmor))
	{
		amx_save_setting_int(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "ARMOR", iArmor);
	}

	ArrayPushCell(g_aClass_Zombie_Armor, iArmor);

	// Speed
	new Float:fSpeed = get_param_f(5);

	if (!amx_load_setting_float(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "SPEED", fSpeed))
	{
		amx_save_setting_float(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "SPEED", fSpeed);
	}

	ArrayPushCell(g_aClass_Zombie_Speed, fSpeed);

	// Gravity
	new Float:fGravity = get_param_f(6);

	if (!amx_load_setting_float(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "GRAVITY", fGravity))
	{
		amx_save_setting_float(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "GRAVITY", fGravity);
	}

	ArrayPushCell(g_aClass_Zombie_Gravity, fGravity);

	// Knockback
	new Float:fKnockback = ZOMBIE_DEFAULT_KNOCKBACK;
	new bool:bSetting_Loaded = bool:amx_load_setting_float(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "KNOCKBACK", fKnockback);

	if (!bSetting_Loaded)
	{
		amx_save_setting_float(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "KNOCKBACK", fKnockback);
	}

	ArrayPushCell(g_aClass_Zombie_Knockback_File, bSetting_Loaded);
	ArrayPushCell(g_aClass_Zombie_Knockback, fKnockback);

	g_Class_Zombie_Count++;

	ExecuteForward(g_Forwards[FW_CLASS_REGISTER_POST], g_Forward_Result, g_Class_Zombie_Count - 1);

	return g_Class_Zombie_Count - 1;
}

public native_class_zombie_register_model(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Zombie_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class zombie player (%d)", iClass_ID);

		return false;
	}

	if (ArrayGetCell(g_aClass_Zombie_Models_File, iClass_ID))
	{
		return true;
	}

	new szPlayer_Model[32];
	get_string(2, szPlayer_Model, charsmax(szPlayer_Model));

	new szModel_Path[86];
	formatex(szModel_Path, charsmax(szModel_Path), "models/player/%s/%s.mdl", szPlayer_Model, szPlayer_Model);
	precache_model(szModel_Path);

	new Array:aClass_Models = ArrayGetCell(g_aClass_Zombie_Models_Handle, iClass_ID);

	if (aClass_Models == Invalid_Array)
	{
		aClass_Models = ArrayCreate(32, 1);
		ArraySetCell(g_aClass_Zombie_Models_Handle, iClass_ID, aClass_Models);
	}

	ArrayPushString(aClass_Models, szPlayer_Model);

	// Save models to file
	new szReal_Name[32];
	ArrayGetString(g_aClass_Zombie_Real_Name, iClass_ID, szReal_Name, charsmax(szReal_Name));

	new szClass_Zombie_Settings_Path[64];
	formatex(szClass_Zombie_Settings_Path, charsmax(szClass_Zombie_Settings_Path), "%s/%s.ini", ZPE_CLASS_ZOMBIE_SETTINGS_PATH, szReal_Name);
	amx_save_setting_string_arr(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "PLAYER MODELS", aClass_Models);

	return true;
}

public native_class_zombie_register_claw(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Zombie_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class zombie player (%d)", iClass_ID);

		return false;
	}

	if (ArrayGetCell(g_aClass_Zombie_Claws_File, iClass_ID))
	{
		return true;
	}

	new szClaw_Model[86];
	get_string(2, szClaw_Model, charsmax(szClaw_Model));
	precache_model(szClaw_Model);

	new Array:aClass_Claws = ArrayGetCell(g_aClass_Zombie_Claws_Handle, iClass_ID);

	if (aClass_Claws == Invalid_Array)
	{
		aClass_Claws = ArrayCreate(64, 1);
		ArraySetCell(g_aClass_Zombie_Claws_Handle, iClass_ID, aClass_Claws);
	}

	ArrayPushString(aClass_Claws, szClaw_Model);

	// Save models to file
	new szReal_Name[32];
	ArrayGetString(g_aClass_Zombie_Real_Name, iClass_ID, szReal_Name, charsmax(szReal_Name));

	new szClass_Zombie_Settings_Path[64];
	formatex(szClass_Zombie_Settings_Path, charsmax(szClass_Zombie_Settings_Path), "%s/%s.ini", ZPE_CLASS_ZOMBIE_SETTINGS_PATH, szReal_Name);
	amx_save_setting_string_arr(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "CLAWS MODEL", aClass_Claws);

	return true;
}

public native_class_zombie_register_kb(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Zombie_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class zombie player (%d)", iClass_ID);

		return false;
	}

	if (ArrayGetCell(g_aClass_Zombie_Knockback_File, iClass_ID))
	{
		return true;
	}

	new Float:fKnockback = get_param_f(2);

	// Set class zombie knockback
	ArraySetCell(g_aClass_Zombie_Knockback, iClass_ID, fKnockback);

	// Save to file
	new szReal_Name[32];
	ArrayGetString(g_aClass_Zombie_Real_Name, iClass_ID, szReal_Name, charsmax(szReal_Name));

	new szClass_Zombie_Settings_Path[64];
	formatex(szClass_Zombie_Settings_Path, charsmax(szClass_Zombie_Settings_Path), "%s/%s.ini", ZPE_CLASS_ZOMBIE_SETTINGS_PATH, szReal_Name);
	amx_save_setting_float(szClass_Zombie_Settings_Path, ZPE_CLASS_ZOMBIE_SETTINGS_SECTION_NAME, "KNOCKBACK", fKnockback);

	return true;
}

public native_class_zombie_get_id(iPlugin_ID, iNum_Params)
{
	new szReal_Name[32];
	get_string(1, szReal_Name, charsmax(szReal_Name));

	// Loop through every class
	new szClass_Zombie_Name[32];

	for (new i = 0; i < g_Class_Zombie_Count; i++)
	{
		ArrayGetString(g_aClass_Zombie_Real_Name, i, szClass_Zombie_Name, charsmax(szClass_Zombie_Name));

		if (equali(szReal_Name, szClass_Zombie_Name))
		{
			return i;
		}
	}

	return ZPE_INVALID_CLASS_ZOMBIE;
}

public native_class_zombie_get_name(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Zombie_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class zombie player (%d)", iClass_ID);

		return false;
	}

	new szName[32];
	ArrayGetString(g_aClass_Zombie_Name, iClass_ID, szName, charsmax(szName));

	new sLen = get_param(3);
	set_string(2, szName, sLen);

	return true;
}

public native_class_zombie_get_real_name(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Zombie_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class zombie player (%d)", iClass_ID);

		return false;
	}

	new szReal_Name[32];
	ArrayGetString(g_aClass_Zombie_Real_Name, iClass_ID, szReal_Name, charsmax(szReal_Name));
	set_string(2, szReal_Name, get_param(3));

	return true;
}

public native_class_zombie_get_description(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Zombie_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class zombie player (%d)", iClass_ID);

		return false;
	}

	new szDescription[32];
	ArrayGetString(g_aClass_Zombie_Description, iClass_ID, szDescription, charsmax(szDescription));
	set_string(2, szDescription, get_param(3));

	return true;
}

public Float:native_class_zombie_get_kb(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Zombie_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class zombie player (%d)", iClass_ID);

		return 1.0;
	}

	// Return class zombie knockback
	return ArrayGetCell(g_aClass_Zombie_Knockback, iClass_ID);
}

public native_class_zombie_get_count(iPlugin_ID, iNum_Params)
{
	return g_Class_Zombie_Count;
}

public native_class_zombie_show_menu(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Show_Menu_Class_Zombie(iPlayer);

	return true;
}

public native_class_zombie_menu_text_add(iPlugin_ID, iNum_Params)
{
	static szText[32];
	get_string(1, szText, charsmax(szText));

	format(g_Additional_Menu_Text, charsmax(g_Additional_Menu_Text), "%s %s", g_Additional_Menu_Text, szText);
}

public client_putinserver(iPlayer)
{
	g_Class_Zombie[iPlayer] = ZPE_INVALID_CLASS_ZOMBIE;
	g_Class_Zombie_Next[iPlayer] = ZPE_INVALID_CLASS_ZOMBIE;

	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	// Reset remembered menu pages
	MENU_PAGE_CLASS(iPlayer) = 0;

	BIT_SUB(g_iBit_Connected, iPlayer);
}