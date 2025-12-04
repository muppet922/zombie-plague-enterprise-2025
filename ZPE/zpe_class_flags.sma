/* AMX Mod X
*	[ZPE] Class Flags.
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

#include <amxmodx>
#include <amx_settings_api>
#include <zpe_class_zombie>
#include <zpe_class_human>

#define PLUGIN "class flags"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#define ZPE_CLASS_ZOMBIE_SETTINGS_PATH "ZPE/classes/zombie"
#define ZPE_CLASS_HUMAN_SETTINGS_PATH "ZPE/classes/human"

#define ZPE_SETTING_SECTION_NAME "Settings"

new Array:g_aZombie_Flags;
new Array:g_aHuman_Flags;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public zpe_fw_class_zombie_register_post(iClass_ID)
{
	if (g_aZombie_Flags == Invalid_Array)
	{
		g_aZombie_Flags = ArrayCreate(1, 1);
	}

	new szReal_Name[32];
	zpe_class_zombie_get_real_name(iClass_ID, szReal_Name, charsmax(szReal_Name));

	new szClass_Settings_Path[64];
	formatex(szClass_Settings_Path, charsmax(szClass_Settings_Path), "%s/%s.ini", ZPE_CLASS_ZOMBIE_SETTINGS_PATH, szReal_Name);

	new szFlags[32];
	szFlags[0] = 'z';

	if (!amx_load_setting_string(szClass_Settings_Path, ZPE_SETTING_SECTION_NAME, "FLAGS", szFlags, charsmax(szFlags)))
	{
		amx_save_setting_string(szClass_Settings_Path, ZPE_SETTING_SECTION_NAME, "FLAGS", szFlags);
	}

	ArrayPushCell(g_aZombie_Flags, read_flags(szFlags));
}

public zpe_fw_class_zombie_select_pre(iPlayer, iClass_ID)
{
	if (get_user_flags(iPlayer) & ArrayGetCell(g_aZombie_Flags, iClass_ID))
	{
		return ZPE_CLASS_AVAILABLE;
	}

	return ZPE_CLASS_NOT_AVAILABLE;
}

public zpe_fw_class_human_register_post(iClass_ID)
{
	if (g_aHuman_Flags == Invalid_Array)
	{
		g_aHuman_Flags = ArrayCreate(1, 1);
	}

	new szReal_Name[32];
	zpe_class_human_get_real_name(iClass_ID, szReal_Name, charsmax(szReal_Name));

	new szClass_Settings_Path[64];
	formatex(szClass_Settings_Path, charsmax(szClass_Settings_Path), "%s/%s.ini", ZPE_CLASS_HUMAN_SETTINGS_PATH, szReal_Name);

	new szFlags[32];
	szFlags[0] = 'z';

	if (!amx_load_setting_string(szClass_Settings_Path, ZPE_SETTING_SECTION_NAME, "FLAGS", szFlags, charsmax(szFlags)))
	{
		amx_save_setting_string(szClass_Settings_Path, ZPE_SETTING_SECTION_NAME, "FLAGS", szFlags);
	}

	ArrayPushCell(g_aHuman_Flags, read_flags(szFlags));
}

public zpe_fw_class_human_select_pre(iPlayer, iClass_ID)
{
	if (get_user_flags(iPlayer) & ArrayGetCell(g_aHuman_Flags, iClass_ID))
	{
		return ZPE_CLASS_AVAILABLE;
	}

	return ZPE_CLASS_NOT_AVAILABLE;
}