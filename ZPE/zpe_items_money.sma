/* AMX Mod X
*	[ZPE] Items Money.
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

#define PLUGIN "items money"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <zpe_items>

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public zpe_fw_items_select_pre(iPlayer, iItem_ID, iIgnore_Cost)
{
	// Ignore item costs?
	if (iIgnore_Cost)
	{
		return ZPE_ITEM_AVAILABLE;
	}

	// Get current and required money
	new iCurrent_Money = CS_GET_USER_MONEY(iPlayer);
	new iRequired_money = zpe_items_get_cost(iItem_ID);

	// Not enough money
	if (iCurrent_Money < iRequired_money)
	{
		return ZPE_ITEM_NOT_AVAILABLE;
	}

	return ZPE_ITEM_AVAILABLE;
}

public zpe_fw_items_select_post(iPlayer, iItem_ID, iIgnore_Cost)
{
	// Ignore item costs?
	if (iIgnore_Cost)
	{
		return;
	}

	// Get current and required money
	new iCurrent_Money = CS_GET_USER_MONEY(iPlayer);
	new iRequired_money = zpe_items_get_cost(iItem_ID);

	// Deduct item's money after purchase event
	UTIL_Set_User_Money(iPlayer, iCurrent_Money - iRequired_money);
}