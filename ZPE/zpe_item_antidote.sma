/* AMX Mod X
*	[ZPE] Item Antidote.
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

#define PLUGIN "item antidote"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <zpe_kernel>
#include <zpe_items>
#include <zpe_gamemodes>

#define ITEM_NAME "Antidote"
#define ITEM_COST 15

new g_Item_ID;

new g_Game_Mode_Infection_ID;
new g_Game_Mode_Multi_ID;

new g_pCvar_Deathmatch;
new g_pCvar_Respawn_After_Last_Human;
new g_pCvar_Antidote_Round_Limit;

new g_Antidotes_Taken;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Antidote_Round_Limit = register_cvar("zpe_antidote_round_limit", "3");

	register_event("HLTV", "Event_Round_Start", "a", "1=0", "2=0");

	g_Item_ID = zpe_items_register(ITEM_NAME, ITEM_COST);
}

public plugin_cfg()
{
	g_Game_Mode_Infection_ID = zpe_gamemodes_get_id("Infection Mode");
	g_Game_Mode_Multi_ID = zpe_gamemodes_get_id("Multiple Infection Mode");

	g_pCvar_Deathmatch = get_cvar_pointer("zpe_deathmatch");
	g_pCvar_Respawn_After_Last_Human = get_cvar_pointer("zpe_respawn_after_last_human");
}

public Event_Round_Start()
{
	g_Antidotes_Taken = 0;
}

public zpe_fw_items_select_pre(iPlayer, iItem_ID)
{
	// This is not our item
	if (iItem_ID != g_Item_ID)
	{
		return ZPE_ITEM_AVAILABLE;
	}

	// Antidote only available during infection modes
	new iCurrent_Mode = zpe_gamemodes_get_current();

	if (iCurrent_Mode != g_Game_Mode_Infection_ID && iCurrent_Mode != g_Game_Mode_Multi_ID)
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	// Antidote only available to zombies
	if (!zpe_core_is_zombie(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	// Display remaining item count for this round
	static szText[32];

	formatex(szText, charsmax(szText), "[%d/%d]", g_Antidotes_Taken, get_pcvar_num(g_pCvar_Antidote_Round_Limit));

	zpe_items_menu_text_add(szText);

	// Antidote not available to last zombie
	if (zpe_core_get_zombie_count() == 1)
	{
		return ZPE_ITEM_NOT_AVAILABLE;
	}

	// Deathmatch mode enabled, respawn after last human disabled, and only one human left
	if (g_pCvar_Deathmatch && get_pcvar_num(g_pCvar_Deathmatch) && g_pCvar_Respawn_After_Last_Human && !get_pcvar_num(g_pCvar_Respawn_After_Last_Human) && zpe_core_get_human_count() == 1)
	{
		return ZPE_ITEM_NOT_AVAILABLE;
	}

	// Reached antidote limit for this round
	if (g_Antidotes_Taken >= get_pcvar_num(g_pCvar_Antidote_Round_Limit))
	{
		return ZPE_ITEM_NOT_AVAILABLE;
	}

	return ZPE_ITEM_AVAILABLE;
}

public zpe_fw_items_select_post(iPlayer, iItem_ID)
{
	// This is not our item
	if (iItem_ID != g_Item_ID)
	{
		return;
	}

	// Make player cure himself
	zpe_core_cure(iPlayer, iPlayer);

	g_Antidotes_Taken++;
}