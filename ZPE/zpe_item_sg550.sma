/* AMX Mod X
*	[ZPE] Item SG550 Auto-Sniper.
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

#define PLUGIN "item sg550"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <zpe_kernel>
#include <zpe_items>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

#define ITEM_SG550_NAME "SG550 Auto-Sniper"
#define ITEM_SG550_COST 12

new g_Item_ID;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_Item_ID = zpe_items_register(ITEM_SG550_NAME, ITEM_SG550_COST);
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

	if (zpe_class_survivor_get(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	if (zpe_class_sniper_get(iPlayer))
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

	rg_set_user_bpammo(iPlayer, WEAPON_SG550, 200);

	rg_give_item(iPlayer, "weapon_sg550");
}