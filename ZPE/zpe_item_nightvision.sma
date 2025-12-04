/* AMX Mod X
*	[ZPE] Item night vision.
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

#define PLUGIN "item night vision"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <cstrike>
#include <zpe_kernel>
#include <zpe_items>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

#define ITEM_NIGHT_VISION_NAME "Night vision"
#define ITEM_NIGHT_VISION_COST 15

new g_Item_ID;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_Item_ID = zpe_items_register(ITEM_NIGHT_VISION_NAME, ITEM_NIGHT_VISION_COST);
}

public zpe_fw_items_select_pre(iPlayer, iItem_ID)
{
	// This is not our item
	if (iItem_ID != g_Item_ID)
	{
		return ZPE_ITEM_AVAILABLE;
	}

	// Night vision only available to humans
	if (zpe_class_nemesis_get(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	if (zpe_class_assassin_get(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	if (zpe_class_survivor_get(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	if (zpe_class_sniper_get(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	if (zpe_core_is_zombie(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	// Player already has night vision
	if (cs_get_user_nvg(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
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

	// Give player night vision and enable it automatically
	cs_set_user_nvg(iPlayer, 1);

	amxclient_cmd(iPlayer, "nightvision");
}