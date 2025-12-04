/* AMX Mod X
*	[ZPE] Kernel Items.
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

#define PLUGIN "kernel items"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_items_const>

#define ZPE_ITEMS_SETTINGS_FOLDER "ZPE/items"
#define ZPE_ITEMS_SETTINGS_SECTION_NAME "Settings"

// For item list menu handlers
#define MENU_PAGE_ITEMS(%0) g_Menu_Data[%0]

new g_Menu_Data[MAX_PLAYERS + 1];

enum TOTAL_FORWARDS
{
	FW_ITEM_SELECT_PRE = 0,
	FW_ITEM_SELECT_POST,
	FW_ITEM_REGISTER_POST
};

new g_Forwards[TOTAL_FORWARDS];
new g_Forward_Result;

// Items data
new Array:g_aItem_Real_Name;
new Array:g_aItem_Name;
new Array:g_aItem_Cost;

new g_Item_Count;

new g_Additional_Menu_Text[32];

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /items", "Client_Command_Items");
	register_clcmd("say items", "Client_Command_Items");

	g_Forwards[FW_ITEM_SELECT_PRE] = CreateMultiForward("zpe_fw_items_select_pre", ET_CONTINUE, FP_CELL, FP_CELL, FP_CELL);
	g_Forwards[FW_ITEM_SELECT_POST] = CreateMultiForward("zpe_fw_items_select_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
	g_Forwards[FW_ITEM_REGISTER_POST] = CreateMultiForward("zpe_fw_items_register_post", ET_IGNORE, FP_CELL);
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/zpe_items.cfg");
}

public plugin_natives()
{
	register_library("zpe_items");

	register_native("zpe_items_register", "native_items_register");
	register_native("zpe_items_get_id", "native_items_get_id");
	register_native("zpe_items_get_name", "native_items_get_name");
	register_native("zpe_items_get_real_name", "native_items_get_real_name");
	register_native("zpe_items_get_cost", "native_items_get_cost");
	register_native("zpe_items_show_menu", "native_items_show_menu");
	register_native("zpe_items_force_buy", "native_items_force_buy");
	register_native("zpe_items_menu_text_add", "native_items_menu_text_add");

	register_native("zpe_items_menu_get_text_add", "native_items_menu_get_text_add");
	register_native("zpe_items_available", "native_items_available");

	register_native("zpe_items_count", "native_items_count");
	register_native("zpe_items_set_cost", "native_items_set_cost");

	// Initialize dynamic arrays
	g_aItem_Real_Name = ArrayCreate(32, 1);
	g_aItem_Name = ArrayCreate(32, 1);
	g_aItem_Cost = ArrayCreate(1, 1);
}

public native_items_register(iPlugin_ID, iNum_Params)
{
	new szItem_Name[32];
	get_string(1, szItem_Name, charsmax(szItem_Name));

	if (strlen(szItem_Name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "Can't register item with an empty name");

		return ZPE_INVALID_ITEM;
	}

	new szOther_Item_Name[32];

	for (new i = 0; i < g_Item_Count; i++)
	{
		ArrayGetString(g_aItem_Real_Name, i, szOther_Item_Name, charsmax(szOther_Item_Name));

		if (equali(szItem_Name, szOther_Item_Name))
		{
			log_error(AMX_ERR_NATIVE, "Item already registered (%s)", szItem_Name);

			return ZPE_INVALID_ITEM;
		}
	}

	new szItem_Settings_Path[64];
	formatex(szItem_Settings_Path, charsmax(szItem_Settings_Path), "%s/%s.ini", ZPE_ITEMS_SETTINGS_FOLDER, szItem_Name);

	new szItem_Settings_Full_Path[128];
	formatex(szItem_Settings_Full_Path, charsmax(szItem_Settings_Full_Path), "addons/amxmodx/configs/%s", szItem_Settings_Path);

	if (!file_exists(szItem_Settings_Full_Path))
	{
		if (!write_file(szItem_Settings_Full_Path, ""))
		{
			log_error(AMX_ERR_NATIVE, "Can't create config for item (%s)", szItem_Name);

			return ZPE_INVALID_ITEM;
		}
	}

	ArrayPushString(g_aItem_Real_Name, szItem_Name);

	// Name
	if (!amx_load_setting_string(szItem_Settings_Path, ZPE_ITEMS_SETTINGS_SECTION_NAME, "NAME", szItem_Name, charsmax(szItem_Name)))
	{
		amx_save_setting_string(szItem_Settings_Path, ZPE_ITEMS_SETTINGS_SECTION_NAME, "NAME", szItem_Name);
	}

	ArrayPushString(g_aItem_Name, szItem_Name);

	new iCost = get_param(2);

	// Cost
	if (!amx_load_setting_int(szItem_Settings_Path, ZPE_ITEMS_SETTINGS_SECTION_NAME, "COST", iCost))
	{
		amx_save_setting_int(szItem_Settings_Path, ZPE_ITEMS_SETTINGS_SECTION_NAME, "COST", iCost);
	}

	ArrayPushCell(g_aItem_Cost, iCost);

	new iItem_ID = g_Item_Count;

	g_Item_Count++;

	ExecuteForward(g_Forwards[FW_ITEM_REGISTER_POST], _, iItem_ID);

	return iItem_ID;
}

public native_items_get_id(iPlugin_ID, iNum_Params)
{
	new szReal_Name[32];

	get_string(1, szReal_Name, charsmax(szReal_Name));

	// Loop through every item
	new szItem_Name[32];

	for (new i = 0; i < g_Item_Count; i++)
	{
		ArrayGetString(g_aItem_Real_Name, i, szItem_Name, charsmax(szItem_Name));

		if (equali(szReal_Name, szItem_Name))
		{
			return i;
		}
	}

	return ZPE_INVALID_ITEM;
}

public native_items_get_name(iPlugin_ID, iNum_Params)
{
	new iItem_ID = get_param(1);

	if (iItem_ID < 0 || iItem_ID >= g_Item_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid item player (%d)", iItem_ID);

		return false;
	}

	new szItem_Name[32];

	ArrayGetString(g_aItem_Name, iItem_ID, szItem_Name, charsmax(szItem_Name));

	new sLen = get_param(3);

	set_string(2, szItem_Name, sLen);

	return true;
}

public native_items_get_real_name(iPlugin_ID, iNum_Params)
{
	new iItem_ID = get_param(1);

	if (iItem_ID < 0 || iItem_ID >= g_Item_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid item player (%d)", iItem_ID);

		return false;
	}

	new szReal_Name[32];

	ArrayGetString(g_aItem_Real_Name, iItem_ID, szReal_Name, charsmax(szReal_Name));

	new sLen = get_param(3);

	set_string(2, szReal_Name, sLen);

	return true;
}

public native_items_get_cost(iPlugin_ID, iNum_Params)
{
	new iItem_ID = get_param(1);

	if (iItem_ID < 0 || iItem_ID >= g_Item_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid item player (%d)", iItem_ID);

		return -1;
	}

	return ArrayGetCell(g_aItem_Cost, iItem_ID);
}

public native_items_show_menu(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Client_Command_Items(iPlayer);

	return true;
}

public native_items_force_buy(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	new iItem_ID = get_param(2);

	if (iItem_ID < 0 || iItem_ID >= g_Item_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid item player (%d)", iItem_ID);

		return false;
	}

	new iIgnore_Cost = get_param(3);

	Buy_Item(iPlayer, iItem_ID, iIgnore_Cost);

	return true;
}

public native_items_menu_text_add(iPlugin_ID, iNum_Params)
{
	static szText[32];

	get_string(1, szText, charsmax(szText));

	format(g_Additional_Menu_Text, charsmax(g_Additional_Menu_Text), "%s %s", g_Additional_Menu_Text, szText);
}

public native_items_menu_get_text_add(iPlugin_ID, iNum_Params)
{
	set_string(1, g_Additional_Menu_Text, charsmax(g_Additional_Menu_Text));
}

public native_items_available(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	new iItem_ID = get_param(2);

	if (iItem_ID < 0 || iItem_ID >= g_Item_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid item (%d)", iItem_ID);

		return false;
	}

	g_Additional_Menu_Text[0] = 0;

	ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_Forward_Result, iPlayer, iItem_ID, 0);

	return g_Forward_Result;
}

public native_items_count()
{
	return g_Item_Count;
}

public native_items_set_cost(iPlugin_ID, iNum_Params)
{
	new iItem_ID = get_param(1);

	if (iItem_ID < 0 || iItem_ID >= g_Item_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid item (%d)", iItem_ID);

		return false;
	}

	new iNew_Cost = get_param(2);

	if (iNew_Cost < 0)
	{
		log_error(AMX_ERR_NATIVE, "Invalid item cost (%d)", iNew_Cost);

		return false;
	}

	ArraySetCell(g_aItem_Cost, iItem_ID, iNew_Cost);

	return true;
}

public Client_Command_Items(iPlayer)
{
	// Player dead
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		return;
	}

	Show_Items_Menu(iPlayer);
}

// Items Menu
Show_Items_Menu(iPlayer)
{
	static szMenu[256];
	static szTrans_Key[64];
	static szItem_Name[32];

	static iCost;

	new iMenu_ID;
	new iItem_Data[2];

	// Title
	formatex(szMenu, charsmax(szMenu), "%L: \r", iPlayer, "MENU_BUY_EXTRA_ITEMS");
	iMenu_ID = menu_create(szMenu, "Menu_Extra_Items");

	// Item List
	for (new i = 0; i < g_Item_Count; i++)
	{
		// Additional text to display
		g_Additional_Menu_Text[0] = 0;

		// Execute item select attempt forward
		ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_Forward_Result, iPlayer, i, 0);

		// Show item to player?
		if (g_Forward_Result >= ZPE_ITEM_DONT_SHOW)
		{
			continue;
		}

		// Add item name and cost
		ArrayGetString(g_aItem_Name, i, szItem_Name, charsmax(szItem_Name));

		iCost = ArrayGetCell(g_aItem_Cost, i);

		// ML support for item mame
		formatex(szTrans_Key, charsmax(szTrans_Key), "ITEM_NAME %s", szItem_Name);

		if (GetLangTransKey(szTrans_Key) != TransKey_Bad)
		{
			formatex(szItem_Name, charsmax(szItem_Name), "%L", iPlayer, szTrans_Key);
		}

		// Item available to player?
		if (g_Forward_Result >= ZPE_ITEM_NOT_AVAILABLE)
		{
			formatex(szMenu, charsmax(szMenu), "\d %s %d %s", szItem_Name, iCost, g_Additional_Menu_Text);
		}

		else
		{
			formatex(szMenu, charsmax(szMenu), "%s \y %d \w %s", szItem_Name, iCost, g_Additional_Menu_Text);
		}

		iItem_Data[0] = i;
		iItem_Data[1] = 0;

		menu_additem(iMenu_ID, szMenu, iItem_Data);
	}

	// No items to display?
	if (menu_items(iMenu_ID) <= 0)
	{
		zpe_client_print_color(iPlayer, print_team_default, "%L", LANG_PLAYER, "NO_EXTRA_ITEMS_COLOR");

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
	MENU_PAGE_ITEMS(iPlayer) = min(MENU_PAGE_ITEMS(iPlayer), menu_pages(iMenu_ID) - 1);

	menu_display(iPlayer, iMenu_ID, MENU_PAGE_ITEMS(iPlayer));
}

// Items Menu
public Menu_Extra_Items(iPlayer, iMenu_ID, iItem)
{
	// Menu was closed
	if (iItem == MENU_EXIT)
	{
		MENU_PAGE_ITEMS(iPlayer) = 0;

		menu_destroy(iMenu_ID);

		return PLUGIN_HANDLED;
	}

	// Remember items menu page
	MENU_PAGE_ITEMS(iPlayer) = iItem / 7;

	// Dead players are not allowed to buy items
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		menu_destroy(iMenu_ID);

		return PLUGIN_HANDLED;
	}

	// Retrieve item player
	new iItem_Data[2];

	new iDummy;
	new iItem_ID;

	menu_item_getinfo(iMenu_ID, iItem, iDummy, iItem_Data, charsmax(iItem_Data), _, _, iDummy);

	iItem_ID = iItem_Data[0];

	// Attempt to buy the item
	Buy_Item(iPlayer, iItem_ID);

	menu_destroy(iMenu_ID);

	return PLUGIN_HANDLED;
}

// Buy Item
Buy_Item(iPlayer, iItem_ID, iIgnore_Cost = 0)
{
	// Execute item select attempt forward
	ExecuteForward(g_Forwards[FW_ITEM_SELECT_PRE], g_Forward_Result, iPlayer, iItem_ID, iIgnore_Cost);

	// Item available to player?
	if (g_Forward_Result >= ZPE_ITEM_NOT_AVAILABLE)
	{
		return;
	}

	// Execute item selected forward
	ExecuteForward(g_Forwards[FW_ITEM_SELECT_POST], g_Forward_Result, iPlayer, iItem_ID, iIgnore_Cost);
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	// Reset remembered menu pages
	MENU_PAGE_ITEMS(iPlayer) = 0;

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