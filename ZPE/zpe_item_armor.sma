/* AMX Mod X
*	[ZPE] Item Armor.
*	Author: C&K Corporation.
*
*	https://ckcorp.ru/ - support from the C&K Corporation.
*	https://forum.ckcorp.ru/ - forum support from the C&K Corporation.
*	https://wiki.ckcorp.ru - documentation and other useful information.
*	https://news.ckcorp.ru/ - other info.
*
*	https://git.ckcorp.ru/ck/game-dev/amxx-modes/zpe - development.
*
*	Support is provided only on the site.
*/

#define PLUGIN "item armor"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_items>

#define ZPE_SETTINGS_FILE "ZPE/zpe_items.ini"

#define ITEM_NAME "Armor"
#define ITEM_COST 5

new Array:g_aSound_Armor_Buy_Item;

new g_pCvar_Armor_Buy_Count;
new g_pCvar_Armor_Buy_Sound;
new g_pCvar_Armor_Buy_Type;

new g_Item_ID;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Armor_Buy_Count = register_cvar("zpe_armor_buy_count", "70");
	g_pCvar_Armor_Buy_Sound = register_cvar("zpe_armor_buy_sound", "1");
	g_pCvar_Armor_Buy_Type = register_cvar("zpe_armor_buy_type", "0");

	g_Item_ID = zpe_items_register(ITEM_NAME, ITEM_COST);
}

public plugin_precache()
{
	g_aSound_Armor_Buy_Item = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "BUY ARMOR", g_aSound_Armor_Buy_Item);
	Precache_Sounds(g_aSound_Armor_Buy_Item);
}

public zpe_fw_items_select_pre(iPlayer, iItem_ID)
{
	// This is not our item
	if (iItem_ID != g_Item_ID)
	{
		return ZPE_ITEM_AVAILABLE;
	}

	if (zpe_core_is_zombie(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	return ZPE_ITEM_AVAILABLE;
}

public zpe_fw_items_select_post(iPlayer, iItem_ID)
{
	if (iItem_ID != g_Item_ID)
	{
		return;
	}

	new iNew_Armor = rg_get_user_armor(iPlayer) + get_pcvar_num(g_pCvar_Armor_Buy_Count);
	rg_set_user_armor(iPlayer, iNew_Armor, get_pcvar_num(g_pCvar_Armor_Buy_Type) ? ARMOR_VESTHELM : ARMOR_KEVLAR);

	if (get_pcvar_num(g_pCvar_Armor_Buy_Sound))
	{
		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSound_Armor_Buy_Item, RANDOM(ArraySize(g_aSound_Armor_Buy_Item)), szSound, charsmax(szSound));
		emit_sound(iPlayer, CHAN_STATIC, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}
}