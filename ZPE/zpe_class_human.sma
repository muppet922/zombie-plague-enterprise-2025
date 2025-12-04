/* AMX Mod X
*	[ZPE] Class Human.
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

#define PLUGIN "class human"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <ck_cs_maxspeed_api>
#include <ck_cs_weap_models_api>
#include <zpe_kernel>
#include <zpe_class_human_const>

#define HUMANS_DEFAULT_NAME "Human"
#define HUMANS_DEFAULT_DESCRIPTION "Default"
#define HUMANS_DEFAULT_ARMOR 0
#define HUMANS_DEFAULT_HEALTH 100.0
#define HUMANS_DEFAULT_SPEED 1.0
#define HUMANS_DEFAULT_GRAVITY 1.0

#define ZPE_CLASS_HUMAN_SETTINGS_PATH "ZPE/classes/human"

#define ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME "Settings"

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

// For class list menu handlers
#define MENU_PAGE_CLASS(%0) g_Menu_Data[%0]

// Models
new g_V_Models_Human_Knife[MODEL_MAX_LENGTH] = "models/v_knife.mdl";

new g_Menu_Data[MAX_PLAYERS + 1];

new g_Class_Human[MAX_PLAYERS + 1];
new g_Class_Human_Next[MAX_PLAYERS + 1];
new g_Additional_Menu_Text[MAX_PLAYERS + 1];

enum _:TOTAL_FORWARDS
{
	FW_CLASS_SELECT_PRE = 0,
	FW_CLASS_SELECT_POST,
	FW_CLASS_REGISTER_POST
};

new g_Forwards[TOTAL_FORWARDS];
new g_Forward_Result;

new Array:g_aClass_Human_Real_Name;
new Array:g_aClass_Human_Name;
new Array:g_aClass_Human_Description;
new Array:g_aClass_Human_Models_File;
new Array:g_aClass_Human_Models_Handle;
new Array:g_aClass_Human_Health;
new Array:g_aClass_Human_Armor;
new Array:g_aClass_Human_Speed;
new Array:g_aClass_Human_Gravity;

new g_Class_Human_Count;

new g_pCvar_Human_Armor_Type;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Human_Armor_Type = register_cvar("zpe_human_armor_type", "0");

	register_clcmd("say /hclass", "Cmd_Show_Menu_Class_Human");
	register_clcmd("say /class", "Cmd_Show_Menu_Class_Human");

	g_Forwards[FW_CLASS_SELECT_PRE] = CreateMultiForward("zpe_fw_class_human_select_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_CLASS_SELECT_POST] = CreateMultiForward("zpe_fw_class_human_select_post", ET_CONTINUE, FP_CELL, FP_CELL);
}

public plugin_precache()
{
	// Load from external file
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Settings", "VIEW MODEL HUMAN KNIFE", g_V_Models_Human_Knife, charsmax(g_V_Models_Human_Knife));

	// Precache models
	precache_model(g_V_Models_Human_Knife);

	g_Forwards[FW_CLASS_REGISTER_POST] = CreateMultiForward("zpe_fw_class_human_register_post", ET_CONTINUE, FP_CELL);
}

public plugin_cfg()
{
	// No classes loaded, add default human class
	if (g_Class_Human_Count == 0)
	{
		ArrayPushString(g_aClass_Human_Real_Name, HUMANS_DEFAULT_NAME);
		ArrayPushString(g_aClass_Human_Name, HUMANS_DEFAULT_NAME);
		ArrayPushString(g_aClass_Human_Description, HUMANS_DEFAULT_DESCRIPTION);
		ArrayPushCell(g_aClass_Human_Models_File, false);
		ArrayPushCell(g_aClass_Human_Models_Handle, Invalid_Array);
		ArrayPushCell(g_aClass_Human_Health, HUMANS_DEFAULT_HEALTH);
		ArrayPushCell(g_aClass_Human_Armor, HUMANS_DEFAULT_ARMOR);
		ArrayPushCell(g_aClass_Human_Speed, HUMANS_DEFAULT_SPEED);
		ArrayPushCell(g_aClass_Human_Gravity, HUMANS_DEFAULT_GRAVITY);

		g_Class_Human_Count++;
	}
}

public plugin_natives()
{
	register_library("zpe_class_human");

	register_native("zpe_class_human_get_current", "native_class_human_get_current");
	register_native("zpe_class_human_get_next", "native_class_human_get_next");
	register_native("zpe_class_human_set_next", "native_class_human_set_next");
	register_native("zpe_class_human_register", "native_class_human_register");
	register_native("zpe_class_human_get_id", "native_class_human_get_id");
	register_native("zpe_class_human_get_name", "native_class_human_get_name");
	register_native("zpe_class_human_get_description", "native_class_human_get_description");
	register_native("zpe_class_human_get_count", "native_class_human_get_count");
	register_native("zpe_class_human_show_menu", "native_class_human_show_menu");
	register_native("zpe_class_human_menu_text_add", "native_class_human_menu_text_add");
	register_native("zpe_class_human_get_real_name", "native_class_human_get_real_name");
	register_native("zpe_class_human_register_model", "native_class_human_register_model");
	register_native("zpe_class_human_get_max_health", "native_class_human_get_max_health");

	// Initialize dynamic arrays
	g_aClass_Human_Real_Name = ArrayCreate(32, 1);
	g_aClass_Human_Name = ArrayCreate(32, 1);
	g_aClass_Human_Description = ArrayCreate(32, 1);
	g_aClass_Human_Models_File = ArrayCreate(1, 1);
	g_aClass_Human_Models_Handle = ArrayCreate(1, 1);
	g_aClass_Human_Health = ArrayCreate(1, 1);
	g_aClass_Human_Armor = ArrayCreate(1, 1);
	g_aClass_Human_Speed = ArrayCreate(1, 1);
	g_aClass_Human_Gravity = ArrayCreate(1, 1);
}

public Cmd_Show_Menu_Class_Human(iPlayer)
{
	if (!zpe_core_is_zombie(iPlayer))
	{
		Show_Menu_Class_Human(iPlayer);
	}
}

public Show_Menu_Class_Human(iPlayer)
{
	static szMenu[256];
	static szName[64];
	static szDescription[65];
	static szTranskey[128];

	new iMenu_ID;
	new iItemdata[2];

	formatex(szMenu, charsmax(szMenu), "%L \r", iPlayer, "MENU_CLASS_HUMAN");

	iMenu_ID = menu_create(szMenu, "Menu_Class_Human");

	for (new i = 0; i < g_Class_Human_Count; i++)
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

		ArrayGetString(g_aClass_Human_Name, i, szName, charsmax(szName));
		ArrayGetString(g_aClass_Human_Description, i, szDescription, charsmax(szDescription));

		// ML support for class mame + description
		formatex(szTranskey, charsmax(szTranskey), "HUMAN_DESCRIPTION %s", szName);

		if (GetLangTransKey(szTranskey) != TransKey_Bad)
		{
			formatex(szDescription, charsmax(szDescription), "%L", iPlayer, szTranskey);
		}

		formatex(szTranskey, charsmax(szTranskey), "HUMAN_NAME %s", szName);

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
		else if (i == g_Class_Human_Next[iPlayer])
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

public Menu_Class_Human(iPlayer, iMenu_ID, iItem)
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
	g_Class_Human_Next[iPlayer] = iIndex;

	new szName[32];
	new szTranskey[64];

	new Float:fMax_Speed = Float:ArrayGetCell(g_aClass_Human_Speed, g_Class_Human_Next[iPlayer]);

	ArrayGetString(g_aClass_Human_Name, g_Class_Human_Next[iPlayer], szName, charsmax(szName));

	// ML support for class name
	formatex(szTranskey, charsmax(szTranskey), "HUMAN_NAME %s", szName);

	if (GetLangTransKey(szTranskey) != TransKey_Bad)
	{
		formatex(szName, charsmax(szName), "%L", iPlayer, szTranskey);
	}

	// Show selected class human
	zpe_client_print_color(iPlayer, print_team_default, "%L: %s", iPlayer, "HUMAN_SELECT_COLOR", szName);

	zpe_client_print_color
	(
		iPlayer, print_team_default, "%L: %d %L: %d %L: %d %L: %.2fx",
		iPlayer, "HUMAN_ATTRIBUTE_HP_COLOR", floatround(ArrayGetCell(g_aClass_Human_Health, g_Class_Human_Next[iPlayer])),
		iPlayer, "HUMAN_ATTRIBUTE_ARMOR_COLOR", ArrayGetCell(g_aClass_Human_Armor, g_Class_Human_Next[iPlayer]),
		iPlayer, "HUMAN_ATTRIBUTE_SPEED_COLOR", cs_maxspeed_display_value(fMax_Speed),
		iPlayer, "HUMAN_ATTRIBUTE_GRAVITY_COLOR", Float:ArrayGetCell(g_aClass_Human_Gravity, g_Class_Human_Next[iPlayer])
	);

	// Execute class select post forward
	ExecuteForward(g_Forwards[FW_CLASS_SELECT_POST], g_Forward_Result, iPlayer, iIndex);

	menu_destroy(iMenu_ID);

	return PLUGIN_HANDLED;
}

public zpe_fw_core_cure_post(iPlayer)
{
	// Show class human menu if they haven't chosen any (e.g. just connected)
	if (g_Class_Human_Next[iPlayer] == ZPE_INVALID_CLASS_HUMAN)
	{
		if (g_Class_Human_Count > 1)
		{
			Show_Menu_Class_Human(iPlayer);
		}

		else // If only one class is registered, choose it automatically
		{
			g_Class_Human_Next[iPlayer] = 0;
		}
	}

	// Set selected human class. If none selected yet, use the first one
	g_Class_Human[iPlayer] = g_Class_Human_Next[iPlayer];

	if (g_Class_Human[iPlayer] == ZPE_INVALID_CLASS_HUMAN)
	{
		g_Class_Human[iPlayer] = 0;
	}

	// Apply human attributes
	SET_USER_HEALTH(iPlayer, ArrayGetCell(g_aClass_Human_Health, g_Class_Human[iPlayer]));

	if (get_pcvar_num(g_pCvar_Human_Armor_Type))
	{
		rg_set_user_armor(iPlayer, ArrayGetCell(g_aClass_Human_Armor, g_Class_Human[iPlayer]), ARMOR_VESTHELM);
	}

	else
	{
		rg_set_user_armor(iPlayer, ArrayGetCell(g_aClass_Human_Armor, g_Class_Human[iPlayer]), ARMOR_KEVLAR);
	}

	SET_USER_GRAVITY(iPlayer, Float:ArrayGetCell(g_aClass_Human_Gravity, g_Class_Human[iPlayer]));
	cs_set_player_maxspeed_auto(iPlayer, Float:ArrayGetCell(g_aClass_Human_Speed, g_Class_Human[iPlayer]));

	// Apply human player model
	new Array:aClass_Human_Models = ArrayGetCell(g_aClass_Human_Models_Handle, g_Class_Human[iPlayer]);

	if (aClass_Human_Models != Invalid_Array)
	{
		new iIndex = RANDOM(ArraySize(aClass_Human_Models));

		new szPlayer_Model[32];
		ArrayGetString(aClass_Human_Models, iIndex, szPlayer_Model, charsmax(szPlayer_Model));
		rg_set_user_model(iPlayer, szPlayer_Model);
	}

	// Set custom knife model
	cs_set_player_view_model(iPlayer, CSW_KNIFE, g_V_Models_Human_Knife);
}

public zpe_fw_core_infect(iPlayer, iAttacker)
{
	// Remove custom knife model
	cs_reset_player_view_model(iPlayer, CSW_KNIFE);
}

public native_class_human_get_current(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return ZPE_INVALID_CLASS_HUMAN;
	}

	return g_Class_Human[iPlayer];
}

public native_class_human_get_next(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return ZPE_INVALID_CLASS_HUMAN;
	}

	return g_Class_Human_Next[iPlayer];
}

public native_class_human_set_next(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	new iClass_ID = get_param(2);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Human_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class human player (%d)", iClass_ID);

		return false;
	}

	g_Class_Human_Next[iPlayer] = iClass_ID;

	return true;
}

public Float:native_class_human_get_max_health(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Human_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid class human player (%d)", iClass_ID);

		return -1.0;
	}

	return ArrayGetCell(g_aClass_Human_Health, iClass_ID);
}

public native_class_human_register(iPlugin_ID, iNum_Params)
{
	new szName[32];

	get_string(1, szName, charsmax(szName));

	if (strlen(szName) == 0)
	{
		log_error(AMX_ERR_NATIVE, "Can't register human class with an empty name");

		return ZPE_INVALID_CLASS_HUMAN;
	}

	new szClass_Human_Name[32];

	for (new i = 0; i < g_Class_Human_Count; i++)
	{
		ArrayGetString(g_aClass_Human_Real_Name, i, szClass_Human_Name, charsmax(szClass_Human_Name));

		if (equali(szName, szClass_Human_Name))
		{
			log_error(AMX_ERR_NATIVE, "Class human already registered (%s)", szName);

			return ZPE_INVALID_CLASS_HUMAN;
		}
	}

	new szClass_Human_Settings_Full_Path[128];
	formatex(szClass_Human_Settings_Full_Path, charsmax(szClass_Human_Settings_Full_Path), "addons/amxmodx/configs/%s/%s.ini", ZPE_CLASS_HUMAN_SETTINGS_PATH, szName);

	if (!file_exists(szClass_Human_Settings_Full_Path))
	{
		if (!write_file(szClass_Human_Settings_Full_Path, ""))
		{
			log_error(AMX_ERR_NATIVE, "Can't create config for class human (%s)", szName);

			return ZPE_INVALID_CLASS_HUMAN;
		}
	}

	ArrayPushString(g_aClass_Human_Real_Name, szName);

	new szClass_Human_Settings_Path[64];
	formatex(szClass_Human_Settings_Path, charsmax(szClass_Human_Settings_Path), "%s/%s.ini", ZPE_CLASS_HUMAN_SETTINGS_PATH, szName);

	// Name
	if (!amx_load_setting_string(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "NAME", szName, charsmax(szName)))
	{
		amx_save_setting_string(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "NAME", szName);
	}

	ArrayPushString(g_aClass_Human_Name, szName);

	// Description
	new szDescription[32];

	get_string(2, szDescription, charsmax(szDescription));

	if (!amx_load_setting_string(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "INFO", szDescription, charsmax(szDescription)))
	{
		amx_save_setting_string(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "INFO", szDescription);
	}

	ArrayPushString(g_aClass_Human_Description, szDescription);

	// Models
	new Array:aClass_Human_Models = ArrayCreate(32, 1);

	amx_load_setting_string_arr(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "PLAYER MODELS", aClass_Human_Models);

	new iArray_Size = ArraySize(aClass_Human_Models);
	new bool:bHave_Elements = iArray_Size > 0;

	if (bHave_Elements)
	{
		// Precache player models
		new szPlayer_Model[32];
		new szModel_Path[128];

		for (new i = 0; i < iArray_Size; i++)
		{
			ArrayGetString(aClass_Human_Models, i, szPlayer_Model, charsmax(szPlayer_Model));
			formatex(szModel_Path, charsmax(szModel_Path), "models/player/%s/%s.mdl", szPlayer_Model, szPlayer_Model);
			precache_model(szModel_Path);
		}
	}

	else
	{
		ArrayDestroy(aClass_Human_Models);

		amx_save_setting_string(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "PLAYER MODELS", "");
	}

	ArrayPushCell(g_aClass_Human_Models_File, bHave_Elements);
	ArrayPushCell(g_aClass_Human_Models_Handle, aClass_Human_Models);

	// Health
	new Float:fHealth = get_param_f(3);

	if (!amx_load_setting_float(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "HEALTH", fHealth))
	{
		amx_save_setting_float(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "HEALTH", fHealth);
	}

	ArrayPushCell(g_aClass_Human_Health, fHealth);

	// Armor
	new iArmor = get_param(4);

	if (!amx_load_setting_int(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "ARMOR", iArmor))
	{
		amx_save_setting_int(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "ARMOR", iArmor);
	}

	ArrayPushCell(g_aClass_Human_Armor, iArmor);

	// Speed
	new Float:fSpeed = get_param_f(5);

	if (!amx_load_setting_float(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "SPEED", fSpeed))
	{
		amx_save_setting_float(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "SPEED", fSpeed);
	}

	ArrayPushCell(g_aClass_Human_Speed, fSpeed);

	// Gravity
	new Float:fGravity = get_param_f(6);

	if (!amx_load_setting_float(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "GRAVITY", fGravity))
	{
		amx_save_setting_float(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "GRAVITY", fGravity);
	}

	ArrayPushCell(g_aClass_Human_Gravity, fGravity);

	g_Class_Human_Count++;

	ExecuteForward(g_Forwards[FW_CLASS_REGISTER_POST], g_Forward_Result, g_Class_Human_Count - 1);

	return g_Class_Human_Count - 1;
}

public native_class_human_register_model(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Human_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid human class player (%d)", iClass_ID);

		return false;
	}

	// Player models already loaded from file
	if (ArrayGetCell(g_aClass_Human_Models_File, iClass_ID))
	{
		return true;
	}

	new szPlayer_Model[32];
	get_string(2, szPlayer_Model, charsmax(szPlayer_Model));

	new szModel_Path[128];
	formatex(szModel_Path, charsmax(szModel_Path), "models/player/%s/%s.mdl", szPlayer_Model, szPlayer_Model);
	precache_model(szModel_Path);

	new Array:aClass_Human_Models = ArrayGetCell(g_aClass_Human_Models_Handle, iClass_ID);

	// No models registered yet?
	if (aClass_Human_Models == Invalid_Array)
	{
		aClass_Human_Models = ArrayCreate(32, 1);
		ArraySetCell(g_aClass_Human_Models_Handle, iClass_ID, aClass_Human_Models);
	}

	ArrayPushString(aClass_Human_Models, szPlayer_Model);

	// Save models to file
	new szReal_Name[32];

	ArrayGetString(g_aClass_Human_Real_Name, iClass_ID, szReal_Name, charsmax(szReal_Name));

	new szClass_Human_Settings_Path[64];

	formatex(szClass_Human_Settings_Path, charsmax(szClass_Human_Settings_Path), "%s/%s.ini", ZPE_CLASS_HUMAN_SETTINGS_PATH, szReal_Name);

	amx_save_setting_string_arr(szClass_Human_Settings_Path, ZPE_CLASS_HUMAN_SETTINGS_SECTION_NAME, "PLAYER MODELS", aClass_Human_Models);

	return true;
}

public native_class_human_get_id(iPlugin_ID, iNum_Params)
{
	new szReal_Name[32];

	get_string(1, szReal_Name, charsmax(szReal_Name));

	// Loop through every class
	new szClass_Human_Name[32];

	for (new i = 0; i < g_Class_Human_Count; i++)
	{
		ArrayGetString(g_aClass_Human_Real_Name, i, szClass_Human_Name, charsmax(szClass_Human_Name));

		if (equali(szReal_Name, szClass_Human_Name))
		{
			return i;
		}
	}

	return ZPE_INVALID_CLASS_HUMAN;
}

public native_class_human_get_name(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Human_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid human class player (%d)", iClass_ID);

		return false;
	}

	new szName[32];

	ArrayGetString(g_aClass_Human_Name, iClass_ID, szName, charsmax(szName));

	new sLen = get_param(3);

	set_string(2, szName, sLen);

	return true;
}

public native_class_human_get_real_name(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Human_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid human class player (%d)", iClass_ID);

		return false;
	}

	new szReal_Name[32];

	ArrayGetString(g_aClass_Human_Real_Name, iClass_ID, szReal_Name, charsmax(szReal_Name));

	new sLen = get_param(3);

	set_string(2, szReal_Name, sLen);

	return true;
}

public native_class_human_get_description(iPlugin_ID, iNum_Params)
{
	new iClass_ID = get_param(1);

	if (iClass_ID < 0 || iClass_ID >= g_Class_Human_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid human class player (%d)", iClass_ID);

		return false;
	}

	new szDescription[32];

	ArrayGetString(g_aClass_Human_Description, iClass_ID, szDescription, charsmax(szDescription));

	new sLen = get_param(3);

	set_string(2, szDescription, sLen);

	return true;
}

public native_class_human_get_count(iPlugin_ID, iNum_Params)
{
	return g_Class_Human_Count;
}

public native_class_human_show_menu(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Show_Menu_Class_Human(iPlayer);

	return true;
}

public native_class_human_menu_text_add(iPlugin_ID, iNum_Params)
{
	static szText[32];

	get_string(1, szText, charsmax(szText));

	format(g_Additional_Menu_Text, charsmax(g_Additional_Menu_Text), "%s %s", g_Additional_Menu_Text, szText);
}

public client_putinserver(iPlayer)
{
	g_Class_Human[iPlayer] = ZPE_INVALID_CLASS_HUMAN;
	g_Class_Human_Next[iPlayer] = ZPE_INVALID_CLASS_HUMAN;

	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	// Reset remembered menu pages
	MENU_PAGE_CLASS(iPlayer) = 0;

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