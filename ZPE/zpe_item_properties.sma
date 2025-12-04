/* AMX Mod X
*	[ZPE] Item Properties.
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

#define PLUGIN "item properties"
#define VERSION "1.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <amx_settings_api>
#include <zpe_items>
#include <zpe_gamemodes>

#define ZPE_ITEMS_SETTINGS_FOLDER "ZPE/items"
#define ZPE_ITEMS_SETTINGS_SECTION_NAME "Settings"

new Array:g_aItem_Original_Cost;

enum RESTRICTION_TYPE
{
	RT_ON_GAMEMODES,
	RT_EXCEPT_GAMEMODES
};

new Array:g_aItem_Restriction_By_Gamemodes;
new Array:g_aItem_Restriction_Type;

new Array:g_aItem_Cost_By_Gamemodes;

new Array:g_aItem_Available;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_aItem_Original_Cost = ArrayCreate(1, 1);

	g_aItem_Restriction_By_Gamemodes = ArrayCreate(1, 1);
	g_aItem_Restriction_Type = ArrayCreate(1, 1);

	g_aItem_Cost_By_Gamemodes = ArrayCreate(1, 1);

	g_aItem_Available = ArrayCreate(1, 1);
}

public zpe_fw_items_register_post(iItem_ID)
{
	ArrayPushCell(g_aItem_Original_Cost, zpe_items_get_cost(iItem_ID));

	new szReal_Name[32];
	zpe_items_get_real_name(iItem_ID, szReal_Name, charsmax(szReal_Name));

	new szItem_Settings_Path[64];
	formatex(szItem_Settings_Path, charsmax(szItem_Settings_Path), "%s/%s.ini", ZPE_ITEMS_SETTINGS_FOLDER, szReal_Name);

	new Array:aGamemodes = ArrayCreate(32, 1);
	new bool:bLoaded = bool:amx_load_setting_string_arr(szItem_Settings_Path, ZPE_ITEMS_SETTINGS_SECTION_NAME, "RESTRICTION BY GAMEMODES", aGamemodes);

	new RESTRICTION_TYPE:type;

	if (ArraySize(aGamemodes) < 2)
	{
		ArrayDestroy(aGamemodes);

		if (!bLoaded)
		{
			amx_save_setting_string(szItem_Settings_Path, ZPE_ITEMS_SETTINGS_SECTION_NAME, "RESTRICTION BY GAMEMODES", "");
		}
	}

	else
	{
		new szRestriction_Type[3];
		ArrayGetString(aGamemodes, 0, szRestriction_Type, charsmax(szRestriction_Type));
		trim(szRestriction_Type);

		switch (szRestriction_Type[0])
		{
			case '+':
			{
				type = RT_ON_GAMEMODES;

				ArrayDeleteItem(aGamemodes, 0);
			}

			case '-':
			{
				type = RT_EXCEPT_GAMEMODES;

				ArrayDeleteItem(aGamemodes, 0);
			}

			default:
			{
				ArrayDestroy(aGamemodes);
			}
		}
	}

	ArrayPushCell(g_aItem_Restriction_By_Gamemodes, aGamemodes);
	ArrayPushCell(g_aItem_Restriction_Type, type);

	new Array:aCost_By_Gamemodes = ArrayCreate(48, 1);
	bLoaded = bool:amx_load_setting_string_arr(szItem_Settings_Path, ZPE_ITEMS_SETTINGS_SECTION_NAME, "COST BY GAMEMODES", aCost_By_Gamemodes);

	new iCount = ArraySize(aCost_By_Gamemodes);

	if (!iCount)
	{
		ArrayPushCell(g_aItem_Cost_By_Gamemodes, Invalid_Trie);

		ArrayDestroy(aCost_By_Gamemodes);

		if (!bLoaded)
		{
			amx_save_setting_string(szItem_Settings_Path, ZPE_ITEMS_SETTINGS_SECTION_NAME, "COST BY GAMEMODES", "");
		}
	}

	else
	{
		new Trie:tCost_By_Gamemodes = TrieCreate();

		new szString[48];
		new szGamemode[32];
		new szCost[16];

		new iPosition;

		for (new i = 0; i < iCount; i++)
		{
			ArrayGetString(aCost_By_Gamemodes, i, szString, charsmax(szString));
			iPosition = strtok2(szString, szGamemode, charsmax(szGamemode), szCost, charsmax(szCost), ':', true);

			if (iPosition != -1)
			{
				TrieSetCell(tCost_By_Gamemodes, szGamemode, str_to_num(szCost));
			}
		}

		ArrayPushCell(g_aItem_Cost_By_Gamemodes, tCost_By_Gamemodes);

		ArrayDestroy(aCost_By_Gamemodes);
	}

	ArrayPushCell(g_aItem_Available, true);
}

public zpe_fw_gamemodes_start(iGamemode_ID)
{
	new szCurrent_Gamemode[32];
	zpe_gamemodes_get_name(iGamemode_ID, szCurrent_Gamemode, charsmax(szCurrent_Gamemode));

	new bool:bItem_Available;

	new Trie:tCost_By_Gamemodes;
	new iNew_Cost;

	new iItem_Count = zpe_items_count();

	for (new i = 0; i < iItem_Count; i++)
	{
		bItem_Available = Is_Item_Available(i, szCurrent_Gamemode);

		if (bItem_Available)
		{
			tCost_By_Gamemodes = ArrayGetCell(g_aItem_Cost_By_Gamemodes, i);

			if (tCost_By_Gamemodes != Invalid_Trie && TrieGetCell(tCost_By_Gamemodes, szCurrent_Gamemode, iNew_Cost))
			{
				zpe_items_set_cost(i, iNew_Cost);
			}
		}

		ArraySetCell(g_aItem_Available, i, bItem_Available);
	}
}

public zpe_fw_gamemodes_end()
{
	new iItem_Count = zpe_items_count();

	for (new i = 0; i < iItem_Count; i++)
	{
		zpe_items_set_cost(i, ArrayGetCell(g_aItem_Original_Cost, i));
		ArraySetCell(g_aItem_Available, i, true);
	}
}

public zpe_fw_items_select_pre(iPlayer, iItem_ID)
{
	return bool:ArrayGetCell(g_aItem_Available, iItem_ID) ? ZPE_ITEM_AVAILABLE : ZPE_ITEM_NOT_AVAILABLE;
}

bool:Is_Item_Available(iItem_ID, szGamemode[])
{
	new Array:aGamemodes = ArrayGetCell(g_aItem_Restriction_By_Gamemodes, iItem_ID);

	if (aGamemodes == Invalid_Array)
	{
		return true;
	}

	new RESTRICTION_TYPE:type = ArrayGetCell(g_aItem_Restriction_Type, iItem_ID);
	new bool:bGamemode_Found = ArrayFindString(aGamemodes, szGamemode) != -1;

	return type == RT_ON_GAMEMODES ? bGamemode_Found : !bGamemode_Found;
}