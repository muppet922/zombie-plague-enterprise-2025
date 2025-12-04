/* AMX Mod X
*	[ZPE] Give menus.
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

#define PLUGIN "give menus"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <amxmisc>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

// Buy Menu: Grenades
new const g_Grenades_Items[][] =
{
	"weapon_hegrenade",
	"weapon_flashbang",
	"weapon_smokegrenade"
};

// Primary and secondary weapon names
new const g_Weapon_Names[][] =
{
	"",
	"P228 Compact",
	"",
	"Schmidt Scout",
	"HE Grenade",
	"XM1014 M4",
	"",
	"Ingram MAC-10",
	"Steyr AUG A1",
	"Smoke Grenade",
	"Dual Elite Berettas",
	"FiveseveN",
	"UMP 45",
	"SG-550 Auto-Sniper",
	"IMI Galil",
	"Famas",
	"USP .45 ACP Tactical",
	"Glock 18C",
	"AWP Magnum Sniper",
	"MP5 Navy",
	"M249 Para Machinegun",
	"M3 Super 90",
	"M4A1 Carbine",
	"Schmidt TMP",
	"G3SG1 Auto-Sniper",
	"Flashbang",
	"Desert Eagle .50 AE",
	"SG-552 Commando",
	"AK-47 Kalashnikov",
	"",
	"ES P90"
};

// For weapon give menu handlers
#define WEAPON_START_ID(%0) g_Menu_Data[%0][0]
#define WEAPON_SELECTION(%1,%2) (g_Menu_Data[%1][1] + %2)
#define WEAPON_AUTO_ON(%2) g_Menu_Data[%2][2]
#define WEAPON_AUTO_PRIMARY(%3) g_Menu_Data[%3][3]
#define WEAPON_AUTO_SECONDARY(%4) g_Menu_Data[%4][4]
#define WEAPON_AUTO_GRENADE(%5) g_Menu_Data[%5][5]

#define WEAPON_ITEM_MAX_LENGTH 32

// Menu selections
#define MENU_KEY_AUTO_SELECT 7
#define MENU_KEY_NEXT 8
#define MENU_KEY_EXIT 9

// Menu keys
const KEYSMENU = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_3 | MENU_KEY_4 | MENU_KEY_5 | MENU_KEY_6 | MENU_KEY_7 | MENU_KEY_8 | MENU_KEY_9 | MENU_KEY_0;

new Float:g_fGive_Time_Start[MAX_PLAYERS + 1];

new g_Menu_Data[MAX_PLAYERS + 1][6];

new	Array:g_aPrimary_Items;
new	Array:g_aSecondary_Items;

new g_Can_Give_Primary;
new g_Can_Give_Secondary;
new g_Can_Give_Grenades;

new g_pCvar_Give_Random_Primary;
new g_pCvar_Give_Random_Secondary;
new g_pCvar_Give_Random_Grenades;

new g_pCvar_Give_Custom_Primary;
new g_pCvar_Give_Custom_Secondary;
new g_pCvar_Give_Custom_Grenades;

new g_pCvar_Give_Custom_Time_Primary;
new g_pCvar_Give_Custom_Time_Secondary;
new g_pCvar_Give_Custom_Time_Grenades;

new g_pCvar_Give_All_Grenades;

new g_pCvar_Grenades_Give_Count[3];
new g_pCvar_Grenades_Show_Count[3];
new g_pCvar_Grenades_Show_Count_If_One[3];

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Give_Random_Primary = register_cvar("zpe_give_random_primary", "0");
	g_pCvar_Give_Random_Secondary = register_cvar("zpe_give_random_secondary", "0");
	g_pCvar_Give_Random_Grenades = register_cvar("zpe_give_random_grenades", "0");

	g_pCvar_Give_Custom_Primary = register_cvar("zpe_give_custom_primary", "1");
	g_pCvar_Give_Custom_Secondary = register_cvar("zpe_give_custom_secondary", "1");
	g_pCvar_Give_Custom_Grenades = register_cvar("zpe_give_custom_grenades", "0");

	g_pCvar_Give_Custom_Time_Primary = register_cvar("zpe_give_custom_time_primary", "15.0");
	g_pCvar_Give_Custom_Time_Secondary = register_cvar("zpe_give_custom_time_secondary", "15.0");
	g_pCvar_Give_Custom_Time_Grenades = register_cvar("zpe_give_custom_time_grenades", "15.0");

	g_pCvar_Give_All_Grenades = register_cvar("zpe_give_all_grenades", "1");

	g_pCvar_Grenades_Give_Count[0] = register_cvar("zpe_give_napalm_grenade_count", "2");
	g_pCvar_Grenades_Give_Count[1] = register_cvar("zpe_give_frost_grenade_count", "1");
	g_pCvar_Grenades_Give_Count[2] = register_cvar("zpe_give_flare_grenade_count", "1");

	g_pCvar_Grenades_Show_Count[0] = register_cvar("zpe_napalm_grenade_count_show", "1");
	g_pCvar_Grenades_Show_Count[1] = register_cvar("zpe_frost_grenade_count_show", "1");
	g_pCvar_Grenades_Show_Count[2] = register_cvar("zpe_flare_grenade_count_show", "1");

	g_pCvar_Grenades_Show_Count_If_One[0] = register_cvar("zpe_napalm_grenade_count_show_if_one", "0");
	g_pCvar_Grenades_Show_Count_If_One[1] = register_cvar("zpe_frost_grenade_count_show_if_one", "0");
	g_pCvar_Grenades_Show_Count_If_One[2] = register_cvar("zpe_flare_grenade_count_show_if_one", "0");

	register_clcmd("say /give", "Client_Command_Give");
	register_clcmd("say give", "Client_Command_Give");
	register_clcmd("say /guns", "Client_Command_Give");
	register_clcmd("say guns", "Client_Command_Give");

	// Menus
	register_menu("Give menu primary", KEYSMENU, "Give_Menu_Primary");
	register_menu("Give menu secondary", KEYSMENU, "Give_Menu_Secondary");
	register_menu("Give menu grenades", KEYSMENU, "Give_Menu_Grenades");
}

public plugin_precache()
{
	// Initialize arrays
	g_aPrimary_Items = ArrayCreate(WEAPON_ITEM_MAX_LENGTH, 1);
	g_aSecondary_Items = ArrayCreate(WEAPON_ITEM_MAX_LENGTH, 1);

	// Load from external file
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Give menu weapons", "PRIMARY", g_aPrimary_Items);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Give menu weapons", "SECONDARY", g_aSecondary_Items);
}

public plugin_natives()
{
	register_library("zpe_give_menus");

	register_native("zpe_give_menus_show", "native_give_menus_show");
}

public native_give_menus_show(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (iPlayer > 32 || BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Client_Command_Give(iPlayer);

	return true;
}

public Client_Command_Give(iPlayer)
{
	if (WEAPON_AUTO_ON(iPlayer))
	{
		zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "GIVE_ENABLED_COLOR");

		WEAPON_AUTO_ON(iPlayer) = 0;
	}

	// Player dead or zombie
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer) || zpe_core_is_zombie(iPlayer))
	{
		return;
	}

	Show_Available_Give_Menus(iPlayer);
}

public zpe_fw_core_cure_post(iPlayer)
{
	// Buyzone time starts when player is set to human
	g_fGive_Time_Start[iPlayer] = get_gametime();

	Human_Weapons(iPlayer);
}

public Human_Weapons(iPlayer)
{
	// Player dead or zombie
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer) || zpe_core_is_zombie(iPlayer))
	{
		return;
	}

	// Survivor and Sniper automatically gets his own weapon
	if (zpe_class_survivor_get(iPlayer) || zpe_class_sniper_get(iPlayer))
	{
		BIT_SUB(g_Can_Give_Primary, iPlayer);
		BIT_SUB(g_Can_Give_Secondary, iPlayer);
		BIT_SUB(g_Can_Give_Grenades, iPlayer);

		return;
	}

	// Random weapons settings
	if (get_pcvar_num(g_pCvar_Give_Random_Primary))
	{
		Give_Primary_Weapon(iPlayer, RANDOM(ArraySize(g_aPrimary_Items)));
	}

	if (get_pcvar_num(g_pCvar_Give_Random_Secondary))
	{
		Give_Secondary_Weapon(iPlayer, RANDOM(ArraySize(g_aSecondary_Items)));
	}

	if (get_pcvar_num(g_pCvar_Give_Random_Grenades))
	{
		Give_Random_Grenades(iPlayer);
	}

	// Custom give menus
	if (get_pcvar_num(g_pCvar_Give_Custom_Primary))
	{
		BIT_ADD(g_Can_Give_Primary, iPlayer);

		if (WEAPON_AUTO_ON(iPlayer))
		{
			Give_Primary_Weapon(iPlayer, WEAPON_AUTO_PRIMARY(iPlayer));
		}
	}

	if (get_pcvar_num(g_pCvar_Give_Custom_Secondary))
	{
		BIT_ADD(g_Can_Give_Secondary, iPlayer);

		if (WEAPON_AUTO_ON(iPlayer))
		{
			Give_Secondary_Weapon(iPlayer, WEAPON_AUTO_SECONDARY(iPlayer));
		}
	}

	if (get_pcvar_num(g_pCvar_Give_Custom_Grenades))
	{
		BIT_ADD(g_Can_Give_Grenades, iPlayer);

		if (WEAPON_AUTO_ON(iPlayer))
		{
			Give_Grenades(iPlayer, WEAPON_AUTO_GRENADE(iPlayer));
		}
	}

	// Open available give menus
	Show_Available_Give_Menus(iPlayer);

	// Automatically give all grenades?
	if (get_pcvar_num(g_pCvar_Give_All_Grenades))
	{
		for (new i = 0; i < sizeof g_Grenades_Items; i++)
		{
			if (get_pcvar_num(g_pCvar_Grenades_Give_Count[i]) > 0)
			{
				Give_Grenades(iPlayer, i);
			}
		}
	}
}

// Shows the next available give menu
Show_Available_Give_Menus(iPlayer)
{
	if (BIT_VALID(g_Can_Give_Primary, iPlayer))
	{
		Show_Give_Menu_Primary(iPlayer);
	}

	else if (BIT_VALID(g_Can_Give_Secondary, iPlayer))
	{
		Show_Give_Menu_Secondary(iPlayer);
	}

	else if (BIT_VALID(g_Can_Give_Grenades, iPlayer))
	{
		Show_Give_Menu_Grenades(iPlayer);
	}
}

Show_Give_Menu_Primary(iPlayer)
{
	new iMenu_Time = floatround(g_fGive_Time_Start[iPlayer] + get_pcvar_float(g_pCvar_Give_Custom_Time_Primary) - get_gametime());

	if (iMenu_Time <= 0)
	{
		zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "MENU_GIVE_TIME_EXPIRED_COLOR");

		return;
	}

	static szMenu[512];

	new iWeapon_Count = ArraySize(g_aPrimary_Items);
	new iWeapon_Count_By_Page = min(WEAPON_START_ID(iPlayer) + 7, iWeapon_Count);
	new iLen;

	// Title
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y %L \r [%d - %d] ^n ^n", iPlayer, "MENU_GIVE_PRIMARY_WEAPONS", WEAPON_START_ID(iPlayer) + 1, iWeapon_Count_By_Page);

	new szWeapon_Name[WEAPON_ITEM_MAX_LENGTH];

	// 1-7. Weapon List
	for (new i = WEAPON_START_ID(iPlayer); i < iWeapon_Count_By_Page; i++)
	{
		ArrayGetString(g_aPrimary_Items, i, szWeapon_Name, charsmax(szWeapon_Name));
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\r %d. \w %s ^n", i - WEAPON_START_ID(iPlayer) + 1, g_Weapon_Names[rg_get_weapon_info(szWeapon_Name, WI_ID)]);
	}

	// 8. Auto select
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n \r 8. \w %L \y [%L]", iPlayer, "MENU_AUTO_SELECT", iPlayer, (WEAPON_AUTO_ON(iPlayer)) ? "MENU_AUTO_SELECT_ENABLED" : "MENU_AUTO_SELECT_DISABLED");

	// 9. Next/Back - 0. Exit
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n ^n \r 9. \w %L / %L ^n ^n \r 0. \w %L", iPlayer, "MENU_NEXT", iPlayer, "MENU_BACK", iPlayer, "MENU_EXIT");

	show_menu(iPlayer, KEYSMENU, szMenu, iMenu_Time, "Give menu primary");
}

Show_Give_Menu_Secondary(iPlayer)
{
	new iMenu_Time = floatround(g_fGive_Time_Start[iPlayer] + get_pcvar_float(g_pCvar_Give_Custom_Time_Secondary) - get_gametime());

	if (iMenu_Time <= 0)
	{
		zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "MENU_GIVE_TIME_EXPIRED_COLOR");

		return;
	}

	static szMenu[512];

	new iLen;
	new iWeapon_Count = ArraySize(g_aSecondary_Items);

	// Title
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y %L ^n", iPlayer, "MENU_GIVE_SECONDARY_WEAPONS");

	new szWeapon_Name[WEAPON_ITEM_MAX_LENGTH];

	// 1-6. Weapon list
	for (new i = 0; i < iWeapon_Count; i++)
	{
		ArrayGetString(g_aSecondary_Items, i, szWeapon_Name, charsmax(szWeapon_Name));
		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n \r %d. \w %s", i + 1, g_Weapon_Names[rg_get_weapon_info(szWeapon_Name, WI_ID)]);
	}

	// 8. Auto select
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n ^n \r 8. \w %L \y [%L]", iPlayer, "MENU_AUTO_SELECT", iPlayer, (WEAPON_AUTO_ON(iPlayer)) ? "MENU_AUTO_SELECT_ENABLED" : "MENU_AUTO_SELECT_DISABLED");

	// 0. Exit
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n ^n \r 0. \w %L", iPlayer, "MENU_EXIT");

	show_menu(iPlayer, KEYSMENU, szMenu, iMenu_Time, "Give menu secondary");
}

Show_Give_Menu_Grenades(iPlayer)
{
	new iMenu_Time = floatround(g_fGive_Time_Start[iPlayer] + get_pcvar_float(g_pCvar_Give_Custom_Time_Grenades) - get_gametime());

	if (iMenu_Time <= 0)
	{
		zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "MENU_GIVE_TIME_EXPIRED_COLOR");

		return;
	}

	static szMenu[512];

	new iLen;
	new iGrenade_Count = sizeof g_Grenades_Items;

	// Title
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "\y %L ^n", iPlayer, "MENU_GIVE_GRENADES");

	new szGive_Count[10];
	new iGive_Count;

	// 1-3. Item list
	for (new i = 0; i < iGrenade_Count; i++)
	{
		iGive_Count = get_pcvar_num(g_pCvar_Grenades_Give_Count[i]);

		if (get_pcvar_num(g_pCvar_Grenades_Show_Count[i]))
		{
			if (iGive_Count < 2 && !get_pcvar_num(g_pCvar_Grenades_Show_Count_If_One[i]))
			{
				formatex(szGive_Count, charsmax(szGive_Count), "");
			}

			else
			{
				formatex(szGive_Count, charsmax(szGive_Count), "[%d]", iGive_Count);
			}
		}

		else
		{
			formatex(szGive_Count, charsmax(szGive_Count), "");
		}

		iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n \r %d. %s %s %s",
				i + 1, iGive_Count > 0 ? "\w" : "\d", g_Weapon_Names[rg_get_weapon_info(g_Grenades_Items[i], WI_ID)], szGive_Count);
	}

	// 8. Auto select
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n ^n \r 8. \w %L \y [%L]", iPlayer, "MENU_AUTO_SELECT", iPlayer, (WEAPON_AUTO_ON(iPlayer)) ? "MENU_AUTO_SELECT_ENABLED" : "MENU_AUTO_SELECT_DISABLED");

	// 0. Exit
	iLen += formatex(szMenu[iLen], charsmax(szMenu) - iLen, "^n ^n \r 0. \w %L", iPlayer, "MENU_EXIT");

	show_menu(iPlayer, KEYSMENU, szMenu, iMenu_Time, "Give menu grenades");
}

public Give_Menu_Primary(iPlayer, iKey)
{
	// Player dead or zombie or already bought primary
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer) || zpe_core_is_zombie(iPlayer) || BIT_NOT_VALID(g_Can_Give_Primary, iPlayer))
	{
		return PLUGIN_HANDLED;
	}

	new iWeapon_Count = ArraySize(g_aPrimary_Items);

	// Special keys/weapon list exceeded
	if (iKey >= MENU_KEY_AUTO_SELECT || WEAPON_SELECTION(iPlayer, iKey) >= iWeapon_Count)
	{
		switch (iKey)
		{
			case MENU_KEY_AUTO_SELECT: // Toggle auto select
			{
				WEAPON_AUTO_ON(iPlayer) = 1 - WEAPON_AUTO_ON(iPlayer);
			}

			case MENU_KEY_NEXT: // Next/back
			{
				if (WEAPON_START_ID(iPlayer) + 7 < iWeapon_Count)
				{
					WEAPON_START_ID(iPlayer) += 7;
				}

				else
				{
					WEAPON_START_ID(iPlayer) = 0;
				}
			}

			case MENU_KEY_EXIT: // Exit
			{
				return PLUGIN_HANDLED;
			}
		}

		// Show give menu again
		Show_Give_Menu_Primary(iPlayer);

		return PLUGIN_HANDLED;
	}

	// Store selected weapon id
	WEAPON_AUTO_PRIMARY(iPlayer) = WEAPON_SELECTION(iPlayer, iKey + WEAPON_START_ID(iPlayer));

	// Give primary weapon
	Give_Primary_Weapon(iPlayer, WEAPON_AUTO_PRIMARY(iPlayer));

	// Show next give menu
	Show_Available_Give_Menus(iPlayer);

	return PLUGIN_HANDLED;
}

Give_Primary_Weapon(iPlayer, iSelection)
{
	// Get weapon's player
	new szWeapon_Name[WEAPON_ITEM_MAX_LENGTH];
	ArrayGetString(g_aPrimary_Items, iSelection, szWeapon_Name, charsmax(szWeapon_Name));
	rg_give_item(iPlayer, szWeapon_Name, GT_DROP_AND_REPLACE);

	new WeaponIdType:iWeapon_ID = rg_get_weapon_info(szWeapon_Name, WI_ID);
	rg_set_user_bpammo(iPlayer, iWeapon_ID, rg_get_weapon_info(iWeapon_ID, WI_MAX_ROUNDS));

	// Primary bought
	BIT_SUB(g_Can_Give_Primary, iPlayer);
}

public Give_Menu_Secondary(iPlayer, iKey)
{
	// Player dead or zombie or already bought secondary
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer) || zpe_core_is_zombie(iPlayer) || BIT_NOT_VALID(g_Can_Give_Secondary, iPlayer))
	{
		return PLUGIN_HANDLED;
	}

	// Special keys/weapon list exceeded
	if (iKey >= ArraySize(g_aSecondary_Items))
	{
		// Toggle auto select
		if (iKey == MENU_KEY_AUTO_SELECT)
		{
			WEAPON_AUTO_ON(iPlayer) = 1 - WEAPON_AUTO_ON(iPlayer);
		}

		// Reshow menu unless user exited
		if (iKey != MENU_KEY_EXIT)
		{
			Show_Give_Menu_Secondary(iPlayer);
		}

		return PLUGIN_HANDLED;
	}

	// Store selected weapon id
	WEAPON_AUTO_SECONDARY(iPlayer) = iKey;

	// Give secondary weapon
	Give_Secondary_Weapon(iPlayer, iKey);

	// Show next give menu
	Show_Available_Give_Menus(iPlayer);

	return PLUGIN_HANDLED;
}

Give_Secondary_Weapon(iPlayer, iSelection)
{
	// Get weapon's player
	new szWeapon_Name[WEAPON_ITEM_MAX_LENGTH];
	ArrayGetString(g_aSecondary_Items, iSelection, szWeapon_Name, charsmax(szWeapon_Name));
	rg_give_item(iPlayer, szWeapon_Name, GT_DROP_AND_REPLACE);

	new WeaponIdType:iWeapon_ID = rg_get_weapon_info(szWeapon_Name, WI_ID);
	rg_set_user_bpammo(iPlayer, iWeapon_ID, rg_get_weapon_info(iWeapon_ID, WI_MAX_ROUNDS));

	// Secondary bought
	BIT_SUB(g_Can_Give_Secondary, iPlayer);
}

public Give_Menu_Grenades(iPlayer, iKey)
{
	// Player dead or zombie or already bought grenades
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer) || zpe_core_is_zombie(iPlayer) || BIT_NOT_VALID(g_Can_Give_Grenades, iPlayer))
	{
		return PLUGIN_HANDLED;
	}

	// Special keys/weapon list exceeded
	if (iKey >= sizeof g_Grenades_Items)
	{
		// Toggle auto select
		if (iKey == MENU_KEY_AUTO_SELECT)
		{
			WEAPON_AUTO_ON(iPlayer) = 1 - WEAPON_AUTO_ON(iPlayer);
		}

		// Reshow menu unless user exited
		if (iKey != MENU_KEY_EXIT)
		{
			Show_Give_Menu_Grenades(iPlayer);
		}

		return PLUGIN_HANDLED;
	}

	if (get_pcvar_num(g_pCvar_Grenades_Give_Count[iKey]) < 1)
	{
		Show_Give_Menu_Grenades(iPlayer);

		return PLUGIN_HANDLED;
	}

	// Store selected grenade
	WEAPON_AUTO_GRENADE(iPlayer) = iKey;

	// Give selected grenade
	Give_Grenades(iPlayer, iKey);

	return PLUGIN_HANDLED;
}

Give_Grenades(iPlayer, iSelection)
{
	// Give the new weapon
	rg_give_item(iPlayer, g_Grenades_Items[iSelection]);

	new iGive_Count = get_pcvar_num(g_pCvar_Grenades_Give_Count[iSelection]);

	if (iGive_Count > 1)
	{
		new iWeapon_ID = rg_get_weapon_info(g_Grenades_Items[iSelection], WI_ID);

		rg_set_user_bpammo(iPlayer, WeaponIdType:iWeapon_ID, iGive_Count);
	}

	// Grenades bought
	BIT_SUB(g_Can_Give_Grenades, iPlayer);
}

Give_Random_Grenades(iPlayer)
{
	new iCount_Available;
	new iAvailable[3];

	for (new i = 0; i < sizeof g_Grenades_Items; i++)
	{
		if (get_pcvar_num(g_pCvar_Grenades_Give_Count[i]) > 0)
		{
			iAvailable[iCount_Available] = i;
			iCount_Available++;
		}
	}

	if (iCount_Available > 0)
	{
		Give_Grenades(iPlayer, iAvailable[RANDOM(iCount_Available)]);
	}
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	WEAPON_AUTO_ON(iPlayer) = 0;
	WEAPON_START_ID(iPlayer) = 0;

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