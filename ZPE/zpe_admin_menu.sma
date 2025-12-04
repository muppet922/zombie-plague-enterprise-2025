/* AMX Mod X
*	[ZPE] Admin Menu.
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

#define PLUGIN "admin menu"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <amxmisc>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>
#include <zpe_admin_commands>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

// For players/mode list menu handlers
#define PL_ACTION(%0) g_Menu_Data[%0][0]
#define MENU_PAGE_PLAYERS(%1) g_Menu_Data[%1][1]
#define MENU_PAGE_GAME_MODES(%2) g_Menu_Data[%2][2]

// Admin menu actions
enum
{
	ACTION_INFECT_CURE = 0,
	ACTION_MAKE_NEMESIS,
	ACTION_MAKE_ASSASSIN,
	ACTION_MAKE_SURVIVOR,
	ACTION_MAKE_SNIPER,
	ACTION_RESPAWN_PLAYER,
	ACTION_START_GAME_MODE
};

#define ACCESS_FLAG_MAX_LENGTH 2

new g_Access_Make_Zombie[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Make_Human[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Make_Nemesis[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Make_Assassin[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Make_Survivor[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Make_Sniper[ACCESS_FLAG_MAX_LENGTH] = "d";

new g_Access_Respawn_Players[ACCESS_FLAG_MAX_LENGTH] = "d";
new g_Access_Start_Game_Mode[ACCESS_FLAG_MAX_LENGTH] = "d";

new g_Menu_Data[MAX_PLAYERS + 1][3];

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_clcmd("say /adminmenu", "Client_Command_Admin_Menu");
	register_clcmd("say adminmenu", "Client_Command_Admin_Menu");
}

public plugin_precache()
{
	// Load from external file
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE ZOMBIE", g_Access_Make_Zombie, charsmax(g_Access_Make_Zombie))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE HUMAN", g_Access_Make_Human, charsmax(g_Access_Make_Human))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE NEMESIS", g_Access_Make_Nemesis, charsmax(g_Access_Make_Nemesis))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE ASSASSIN", g_Access_Make_Assassin, charsmax(g_Access_Make_Assassin))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE SURVIVOR", g_Access_Make_Survivor, charsmax(g_Access_Make_Survivor))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "MAKE SNIPER", g_Access_Make_Sniper, charsmax(g_Access_Make_Sniper))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "RESPAWN PLAYERS", g_Access_Respawn_Players, charsmax(g_Access_Respawn_Players))
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Access Flags", "START GAME MODE", g_Access_Start_Game_Mode, charsmax(g_Access_Start_Game_Mode))
}

public plugin_natives()
{
	register_library("zpe_admin_menu");

	register_native("zpe_admin_menu_show", "native_admin_menu_show");
}

public native_admin_menu_show(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Show_Menu_Admin(iPlayer);

	return true;
}

public Client_Command_Admin_Menu(iPlayer)
{
	Show_Menu_Admin(iPlayer);
}

// Admin Menu
Show_Menu_Admin(iPlayer)
{
	static szMenu[512];

	formatex(szMenu, charsmax(szMenu), "\y %L:", iPlayer, "MENU_ADMIN_TITLE");

	new iMenu = menu_create(szMenu, "Menu_Admin");

	new iUser_Flags = get_user_flags(iPlayer);

	// 1. Infect/Cure command
	if (iUser_Flags & (read_flags(g_Access_Make_Zombie) | read_flags(g_Access_Make_Human)))
	{
		formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_ADMIN_MAKE_ZOMBIE_OR_HUMAN");
		menu_additem(iMenu, szMenu, "1");
	}

	else
	{
		formatex(szMenu, charsmax(szMenu), "\d %L", iPlayer, "MENU_ADMIN_MAKE_ZOMBIE_OR_HUMAN");
		menu_additem(iMenu, szMenu, "1");
	}

	// 2. Nemesis command
	if (iUser_Flags & read_flags(g_Access_Make_Nemesis))
	{
		formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_ADMIN_MAKE_NEMESIS");
		menu_additem(iMenu, szMenu, "2");
	}

	else
	{
		formatex(szMenu, charsmax(szMenu), "\d %L", iPlayer, "MENU_ADMIN_MAKE_NEMESIS");
		menu_additem(iMenu, szMenu, "2");
	}

	// 3. Assassin command
	if (iUser_Flags & read_flags(g_Access_Make_Assassin))
	{
		formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_ADMIN_MAKE_ASSASSIN");
		menu_additem(iMenu, szMenu, "3");
	}

	else
	{
		formatex(szMenu, charsmax(szMenu), "\d %L", iPlayer, "MENU_ADMIN_MAKE_ASSASSIN");
		menu_additem(iMenu, szMenu, "3");
	}

	// 4. Survivor command
	if (iUser_Flags & read_flags(g_Access_Make_Survivor))
	{
		formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_ADMIN_MAKE_SURVIVOR");
		menu_additem(iMenu, szMenu, "4");
	}

	else
	{
		formatex(szMenu, charsmax(szMenu), "\d %L", iPlayer, "MENU_ADMIN_MAKE_SURVIVOR");
		menu_additem(iMenu, szMenu, "4");
	}

	// 5. Sniper command
	if (iUser_Flags & read_flags(g_Access_Make_Sniper))
	{
		formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_ADMIN_MAKE_SNIPER");
		menu_additem(iMenu, szMenu, "5");
	}

	else
	{
		formatex(szMenu, charsmax(szMenu), "\d %L", iPlayer, "MENU_ADMIN_MAKE_SNIPER");
		menu_additem(iMenu, szMenu, "5");
	}

	// 6. Respawn command
	if (iUser_Flags & read_flags(g_Access_Respawn_Players))
	{
		formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_ADMIN_RESPAWN");
		menu_additem(iMenu, szMenu, "6");
	}

	else
	{
		formatex(szMenu, charsmax(szMenu), "\d %L", iPlayer, "MENU_ADMIN_RESPAWN");
		menu_additem(iMenu, szMenu, "6");
	}

	// 7. Start game mode command
	if (iUser_Flags & read_flags(g_Access_Start_Game_Mode))
	{
		formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_ADMIN_START_GAME_MODE");
		menu_additem(iMenu, szMenu, "7");
	}

	else
	{
		formatex(szMenu, charsmax(szMenu), "\d %L", iPlayer, "MENU_ADMIN_START_GAME_MODE");
		menu_additem(iMenu, szMenu, "7");
	}

	// Back - Next - Exit
	formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_BACK");
	menu_setprop(iMenu, MPROP_BACKNAME, szMenu);

	formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_NEXT");
	menu_setprop(iMenu, MPROP_NEXTNAME, szMenu);

	formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_EXIT");
	menu_setprop(iMenu, MPROP_EXITNAME, szMenu);

	menu_display(iPlayer, iMenu, 0);
}

// Admin Menu
public Menu_Admin(iPlayer, iMenu, iItem)
{
	new szData[512];
	new szName[512];

	new iAccess;
	new iCallback;

	menu_item_getinfo(iMenu, iItem, iAccess, szData, charsmax(szData), szName, charsmax(szName), iCallback);

	new iKey = str_to_num(szData);

	new iUser_Flags = get_user_flags(iPlayer);

	switch (iKey)
	{
		case 1: // Infect/Cure command
		{
			if (iUser_Flags & (read_flags(g_Access_Make_Zombie) | read_flags(g_Access_Make_Human)))
			{
				// Show players list for admin to pick a target
				PL_ACTION(iPlayer) = ACTION_INFECT_CURE;

				Show_Menu_Player_List(iPlayer);
			}

			else
			{
				zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_ACCESS_COLOR");

				Show_Menu_Admin(iPlayer);
			}
		}

		case 2: // Nemesis command
		{
			if (iUser_Flags & read_flags(g_Access_Make_Nemesis))
			{
				// Show players list for admin to pick a target
				PL_ACTION(iPlayer) = ACTION_MAKE_NEMESIS;

				Show_Menu_Player_List(iPlayer);
			}

			else
			{
				zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_ACCESS_COLOR");

				Show_Menu_Admin(iPlayer);
			}
		}

		case 3: // Assassin command
		{
			if (iUser_Flags & read_flags(g_Access_Make_Assassin))
			{
				// Show players list for admin to pick a target
				PL_ACTION(iPlayer) = ACTION_MAKE_ASSASSIN;

				Show_Menu_Player_List(iPlayer);
			}

			else
			{
				zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_ACCESS_COLOR");

				Show_Menu_Admin(iPlayer);
			}
		}

		case 4: // Survivor command
		{
			if (iUser_Flags & read_flags(g_Access_Make_Survivor))
			{
				// Show players list for admin to pick a target
				PL_ACTION(iPlayer) = ACTION_MAKE_SURVIVOR;

				Show_Menu_Player_List(iPlayer);
			}

			else
			{
				zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_ACCESS_COLOR");

				Show_Menu_Admin(iPlayer);
			}
		}

		case 5: // Sniper command
		{
			if (iUser_Flags & read_flags(g_Access_Make_Sniper))
			{
				// Show players list for admin to pick a target
				PL_ACTION(iPlayer) = ACTION_MAKE_SNIPER;

				Show_Menu_Player_List(iPlayer);
			}

			else
			{
				zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_ACCESS_COLOR");

				Show_Menu_Admin(iPlayer);
			}
		}

		case 6: // Respawn command
		{
			if (iUser_Flags & read_flags(g_Access_Respawn_Players))
			{
				// Show players list for admin to pick a target
				PL_ACTION(iPlayer) = ACTION_RESPAWN_PLAYER;

				Show_Menu_Player_List(iPlayer);
			}

			else
			{
				zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_ACCESS_COLOR");

				Show_Menu_Admin(iPlayer);
			}
		}

		case 7: // Start game mode command
		{
			if (iUser_Flags & read_flags(g_Access_Start_Game_Mode))
			{
				Show_Menu_Game_Mode_List(iPlayer);
			}

			else
			{
				zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_ACCESS_COLOR");

				Show_Menu_Admin(iPlayer);
			}
		}
	}

	menu_destroy(iMenu);

	return PLUGIN_HANDLED
}

// Player List Menu
Show_Menu_Player_List(iPlayer)
{
	static szMenu[512];
	static szPlayer_Name[32];

	new iMenu;
	new szBuffer[2];

	// Title
	switch (PL_ACTION(iPlayer))
	{
		case ACTION_INFECT_CURE:
		{
			formatex(szMenu, charsmax(szMenu), "%L \r", iPlayer, "MENU_ADMIN_MAKE_ZOMBIE_OR_HUMAN");
		}

		case ACTION_MAKE_NEMESIS:
		{
			formatex(szMenu, charsmax(szMenu), "%L \r", iPlayer, "MENU_ADMIN_MAKE_NEMESIS");
		}

		case ACTION_MAKE_ASSASSIN:
		{
			formatex(szMenu, charsmax(szMenu), "%L \r", iPlayer, "MENU_ADMIN_MAKE_ASSASSIN");
		}

		case ACTION_MAKE_SURVIVOR:
		{
			formatex(szMenu, charsmax(szMenu), "%L \r", iPlayer, "MENU_ADMIN_MAKE_SURVIVOR");
		}

		case ACTION_MAKE_SNIPER:
		{
			formatex(szMenu, charsmax(szMenu), "%L \r", iPlayer, "MENU_ADMIN_MAKE_SNIPER");
		}

		case ACTION_RESPAWN_PLAYER:
		{
			formatex(szMenu, charsmax(szMenu), "%L \r", iPlayer, "MENU_ADMIN_RESPAWN");
		}
	}

	iMenu = menu_create(szMenu, "Menu_Player_List");

	new iUser_Flags = get_user_flags(iPlayer);

	// Player List
	for (new i = 1; i <= MaxClients; i++)
	{
		// Skip if not connected
		if (BIT_NOT_VALID(g_iBit_Connected, i))
		{
			continue;
		}

		// Get player's name
		GET_USER_NAME(i, szPlayer_Name, charsmax(szPlayer_Name));

		// Format text depending on the action to take
		switch (PL_ACTION(iPlayer))
		{
			case ACTION_INFECT_CURE: // Infect/Cure command
			{
				if (zpe_core_is_zombie(i))
				{
					if (iUser_Flags & read_flags(g_Access_Make_Human) && BIT_VALID(g_iBit_Alive, i))
					{
						formatex(szMenu, charsmax(szMenu), "%s \r [%L]", szPlayer_Name, iPlayer, zpe_class_nemesis_get(i) ? "CLASS_NEMESIS" : zpe_class_assassin_get(i) ? "CLASS_ASSASSIN" : "CLASS_ZOMBIE");
					}

					else
					{
						formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, zpe_class_nemesis_get(i) ? "CLASS_NEMESIS" : zpe_class_assassin_get(i) ? "CLASS_ASSASSIN" : "CLASS_ZOMBIE");
					}
				}

				else
				{
					if (iUser_Flags & read_flags(g_Access_Make_Zombie) && BIT_VALID(g_iBit_Alive, i))
					{
						formatex(szMenu, charsmax(szMenu), "%s \y [%L]", szPlayer_Name, iPlayer, zpe_class_survivor_get(i) ? "CLASS_SURVIVOR" : zpe_class_sniper_get(i) ? "CLASS_SNIPER" : "CLASS_HUMAN");
					}

					else
					{
						formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, zpe_class_survivor_get(i) ? "CLASS_SURVIVOR" : zpe_class_sniper_get(i) ? "CLASS_SNIPER" : "CLASS_HUMAN");
					}
				}
			}

			case ACTION_MAKE_NEMESIS: // Nemesis command
			{
				if (iUser_Flags & read_flags(g_Access_Make_Nemesis) && BIT_VALID(g_iBit_Alive, i) && !zpe_class_nemesis_get(i))
				{
					if (zpe_core_is_zombie(i))
					{
						formatex(szMenu, charsmax(szMenu), "%s \r [%L]", szPlayer_Name, iPlayer, zpe_class_nemesis_get(i) ? "CLASS_NEMESIS" : zpe_class_assassin_get(i) ? "CLASS_ASSASSIN" : "CLASS_ZOMBIE");
					}

					else
					{
						formatex(szMenu, charsmax(szMenu), "%s \y [%L]", szPlayer_Name, iPlayer, zpe_class_survivor_get(i) ? "CLASS_SURVIVOR" : zpe_class_sniper_get(i) ? "CLASS_SNIPER" : "CLASS_HUMAN");
					}
				}

				else
				{
					if (zpe_core_is_zombie(i))
					{
						if (zpe_class_nemesis_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_NEMESIS");
						}

						else if (zpe_class_assassin_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_ASSASSIN");
						}

						else
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_ZOMBIE");
						}
					}

					else
					{
						if (zpe_class_survivor_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_SURVIVOR");
						}

						else if (zpe_class_sniper_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_SNIPER");
						}

						else
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_HUMAN");
						}
					}
				}
			}

			case ACTION_MAKE_ASSASSIN: // Assassin command
			{
				if (iUser_Flags & read_flags(g_Access_Make_Assassin) && BIT_VALID(g_iBit_Alive, i) && !zpe_class_assassin_get(i))
				{
					if (zpe_core_is_zombie(i))
					{
						formatex(szMenu, charsmax(szMenu), "%s \r [%L]", szPlayer_Name, iPlayer, zpe_class_nemesis_get(i) ? "CLASS_NEMESIS" : zpe_class_assassin_get(i) ? "CLASS_ASSASSIN" : "CLASS_ZOMBIE");
					}

					else
					{
						formatex(szMenu, charsmax(szMenu), "%s \y [%L]", szPlayer_Name, iPlayer, zpe_class_survivor_get(i) ? "CLASS_SURVIVOR" : zpe_class_sniper_get(i) ? "CLASS_SNIPER" : "CLASS_HUMAN");
					}
				}

				else
				{
					if (zpe_core_is_zombie(i))
					{
						if (zpe_class_nemesis_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_NEMESIS");
						}

						else if (zpe_class_assassin_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_ASSASSIN");
						}

						else
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_ZOMBIE");
						}
					}

					else
					{
						if (zpe_class_survivor_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_SURVIVOR");
						}

						else if (zpe_class_sniper_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_SNIPER");
						}

						else
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_HUMAN");
						}
					}
				}
			}

			case ACTION_MAKE_SURVIVOR: // Survivor command
			{
				if (iUser_Flags & read_flags(g_Access_Make_Survivor) && BIT_VALID(g_iBit_Alive, i) && !zpe_class_survivor_get(i))
				{
					if (zpe_core_is_zombie(i))
					{
						formatex(szMenu, charsmax(szMenu), "%s \r [%L]", szPlayer_Name, iPlayer, zpe_class_nemesis_get(i) ? "CLASS_NEMESIS" : zpe_class_assassin_get(i) ? "CLASS_ASSASSIN" : "CLASS_ZOMBIE");
					}

					else
					{
						formatex(szMenu, charsmax(szMenu), "%s \y [%L]", szPlayer_Name, iPlayer, zpe_class_survivor_get(i) ? "CLASS_SURVIVOR" : zpe_class_sniper_get(i) ? "CLASS_SNIPER" : "CLASS_HUMAN");
					}
				}

				else
				{
					if (zpe_core_is_zombie(i))
					{
						if (zpe_class_nemesis_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_NEMESIS");
						}

						else if (zpe_class_assassin_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_ASSASSIN");
						}

						else
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_ZOMBIE");
						}
					}

					else
					{
						if (zpe_class_survivor_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_SURVIVOR");
						}

						else if (zpe_class_sniper_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_SNIPER");
						}

						else
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_HUMAN");
						}
					}
				}
			}

			case ACTION_MAKE_SNIPER: // Sniper command
			{
				if (iUser_Flags & read_flags(g_Access_Make_Sniper) && BIT_VALID(g_iBit_Alive, i) && !zpe_class_sniper_get(i))
				{
					if (zpe_core_is_zombie(i))
					{
						formatex(szMenu, charsmax(szMenu), "%s \r [%L]", szPlayer_Name, iPlayer, zpe_class_nemesis_get(i) ? "CLASS_NEMESIS" : zpe_class_assassin_get(i) ? "CLASS_ASSASSIN" : "CLASS_ZOMBIE");
					}

					else
					{
						formatex(szMenu, charsmax(szMenu), "%s \y [%L]", szPlayer_Name, iPlayer, zpe_class_survivor_get(i) ? "CLASS_SURVIVOR" : zpe_class_sniper_get(i) ? "CLASS_SNIPER" : "CLASS_HUMAN");
					}
				}

				else
				{
					if (zpe_core_is_zombie(i))
					{
						if (zpe_class_nemesis_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_NEMESIS");
						}

						else if (zpe_class_assassin_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_ASSASSIN");
						}

						else
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_ZOMBIE");
						}
					}

					else
					{
						if (zpe_class_survivor_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_SURVIVOR");
						}

						else if (zpe_class_sniper_get(i))
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_SNIPER");
						}

						else
						{
							formatex(szMenu, charsmax(szMenu), "\d %s [%L]", szPlayer_Name, iPlayer, "CLASS_HUMAN");
						}
					}
				}
			}

			case ACTION_RESPAWN_PLAYER: // Respawn command
			{
				if (iUser_Flags & read_flags(g_Access_Respawn_Players) && Allowed_Respawn(i))
				{
					formatex(szMenu, charsmax(szMenu), "%s", szPlayer_Name);
				}

				else
				{
					formatex(szMenu, charsmax(szMenu), "\d %s", szPlayer_Name);
				}
			}
		}

		szBuffer[0] = i;
		szBuffer[1] = 0;

		menu_additem(iMenu, szMenu, szBuffer);
	}

	// Back - Next - Exit
	formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_BACK");
	menu_setprop(iMenu, MPROP_BACKNAME, szMenu);

	formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_NEXT");
	menu_setprop(iMenu, MPROP_NEXTNAME, szMenu);

	formatex(szMenu, charsmax(szMenu), "%L", iPlayer, "MENU_EXIT");
	menu_setprop(iMenu, MPROP_EXITNAME, szMenu);

	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_PLAYERS(iPlayer) = min(MENU_PAGE_PLAYERS(iPlayer), menu_pages(iMenu) - 1);

	menu_display(iPlayer, iMenu, MENU_PAGE_PLAYERS(iPlayer));
}

Show_Menu_Game_Mode_List(iPlayer)
{
	new szTitle[128];
	formatex(szTitle, charsmax(szTitle), "%L: \r", iPlayer, "MENU_ADMIN_START_GAME_MODE");

	new iMenu = menu_create(szTitle, "Menu_Game_Mode_List");

	new szGame_Mode_Name[32];
	new szTranskey[64];
	new szItem[128];

	new szItemdata[2];

	new iGame_Mode_Count = zpe_gamemodes_get_count();

	// Item List
	for (new i = 0; i < iGame_Mode_Count; i++)
	{
		zpe_gamemodes_get_name(i, szGame_Mode_Name, charsmax(szGame_Mode_Name));
		strtoupper(szGame_Mode_Name);

		// ML support for mode name
		formatex(szTranskey, charsmax(szTranskey), "GAME_MODE_NAME_%s", szGame_Mode_Name);

		if (GetLangTransKey(szTranskey) != TransKey_Bad)
		{
			formatex(szItem, charsmax(szItem), "%L", iPlayer, szTranskey);
		}

		szItemdata[0] = i;
		szItemdata[1] = '^0';
		menu_additem(iMenu, szItem, szItemdata);
	}

	// No game modes to display?
	if (menu_items(iMenu) <= 0)
	{
		menu_destroy(iMenu);

		return;
	}

	// Back - Next - Exit
	formatex(szItem, charsmax(szItem), "%L", iPlayer, "MENU_BACK");
	menu_setprop(iMenu, MPROP_BACKNAME, szItem);

	formatex(szItem, charsmax(szItem), "%L", iPlayer, "MENU_NEXT");
	menu_setprop(iMenu, MPROP_NEXTNAME, szItem);

	formatex(szItem, charsmax(szItem), "%L", iPlayer, "MENU_EXIT");
	menu_setprop(iMenu, MPROP_EXITNAME, szItem);

	// If remembered page is greater than number of pages, clamp down the value
	MENU_PAGE_GAME_MODES(iPlayer) = min(MENU_PAGE_GAME_MODES(iPlayer), menu_pages(iMenu) - 1);

	menu_display(iPlayer, iMenu, MENU_PAGE_GAME_MODES(iPlayer));
}

// Player List Menu
public Menu_Player_List(iPlayer, iMenu, iItem)
{
	// Menu was closed
	if (iItem == MENU_EXIT)
	{
		MENU_PAGE_PLAYERS(iPlayer) = 0;

		menu_destroy(iMenu);

		Show_Menu_Admin(iPlayer);

		return PLUGIN_HANDLED;
	}

	// Remember players's menu page
	MENU_PAGE_PLAYERS(iPlayer) = iItem / 7;

	// Retrieve players id
	new szBuffer[2];
	new iDummy;

	menu_item_getinfo(iMenu, iItem, iDummy, szBuffer, charsmax(szBuffer), _, _, iDummy);

	new iPlayers;

	iPlayers = szBuffer[0];

	new iUser_Flags = get_user_flags(iPlayer);

	// Make sure it's still connected
	if (BIT_VALID(g_iBit_Connected, iPlayers))
	{
		// Perform the right action if allowed
		switch (PL_ACTION(iPlayer))
		{
			case ACTION_INFECT_CURE: // Infect/Cure command
			{
				if (zpe_core_is_zombie(iPlayers))
				{
					if (iUser_Flags & read_flags(g_Access_Make_Human) && BIT_VALID(g_iBit_Alive, iPlayers))
					{
						zpe_admin_commands_human(iPlayer, iPlayers);
					}

					else
					{
						zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_COLOR");
					}
				}

				else
				{
					if (iUser_Flags & read_flags(g_Access_Make_Zombie) && BIT_VALID(g_iBit_Alive, iPlayers))
					{
						zpe_admin_commands_zombie(iPlayer, iPlayers);
					}

					else
					{
						zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_COLOR");
					}
				}
			}

			case ACTION_MAKE_NEMESIS: // Nemesis command
			{
				if (iUser_Flags & read_flags(g_Access_Make_Nemesis) && BIT_VALID(g_iBit_Alive, iPlayers) && !zpe_class_nemesis_get(iPlayers))
				{
					zpe_admin_commands_nemesis(iPlayer, iPlayers);
				}

				else
				{
					zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_COLOR");
				}
			}

			case ACTION_MAKE_ASSASSIN: // Assassin command
			{
				if (iUser_Flags & read_flags(g_Access_Make_Assassin) && BIT_VALID(g_iBit_Alive, iPlayers) && !zpe_class_assassin_get(iPlayers))
				{
					zpe_admin_commands_assassin(iPlayer, iPlayers);
				}

				else
				{
					zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_COLOR");
				}
			}

			case ACTION_MAKE_SURVIVOR: // Survivor command
			{
				if (iUser_Flags & read_flags(g_Access_Make_Survivor) && BIT_VALID(g_iBit_Alive, iPlayers) && !zpe_class_survivor_get(iPlayers))
				{
					zpe_admin_commands_survivor(iPlayer, iPlayers);
				}

				else
				{
					zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_COLOR");
				}
			}

			case ACTION_MAKE_SNIPER: // Sniper command
			{
				if (iUser_Flags & read_flags(g_Access_Make_Sniper) && BIT_VALID(g_iBit_Alive, iPlayers) && !zpe_class_sniper_get(iPlayers))
				{
					zpe_admin_commands_sniper(iPlayer, iPlayers);
				}

				else
				{
					zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_COLOR");
				}
			}

			case ACTION_RESPAWN_PLAYER: // Respawn command
			{
				if (iUser_Flags & read_flags(g_Access_Respawn_Players) && Allowed_Respawn(iPlayers))
				{
					zpe_admin_commands_respawn(iPlayer, iPlayers);
				}

				else
				{
					zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_COLOR");
				}
			}
		}
	}

	else
	{
		zpe_client_print_color(iPlayer, print_team_default, "%L", iPlayer, "CMD_NOT_COLOR");
	}

	menu_destroy(iMenu);

	Show_Menu_Player_List(iPlayer);

	return PLUGIN_HANDLED;
}

public Menu_Game_Mode_List(iPlayer, iMenu, iItem)
{
	// Menu was closed
	if (iItem == MENU_EXIT)
	{
		MENU_PAGE_GAME_MODES(iPlayer) = 0;

		menu_destroy(iMenu);

		Show_Menu_Admin(iPlayer);

		return PLUGIN_HANDLED;
	}

	// Remember game modes menu page
	MENU_PAGE_GAME_MODES(iPlayer) = iItem / 7;

	// Retrieve game mode player
	new szItemdata[2];
	new iDummy;

	menu_item_getinfo(iMenu, iItem, iDummy, szItemdata, charsmax(szItemdata), _, _, iDummy);

	new iGame_Mode_ID;

	iGame_Mode_ID = szItemdata[0];

	// Attempt to start game mode
	zpe_admin_commands_start_mode(iPlayer, iGame_Mode_ID);

	menu_destroy(iMenu);

	Show_Menu_Game_Mode_List(iPlayer);

	return PLUGIN_HANDLED;
}

// Checks if a players is allowed to respawn
Allowed_Respawn(iPlayer)
{
	if (BIT_VALID(g_iBit_Alive, iPlayer))
	{
		return false;
	}

	if (CS_GET_USER_TEAM(iPlayer) == CS_TEAM_SPECTATOR || CS_GET_USER_TEAM(iPlayer) == CS_TEAM_UNASSIGNED)
	{
		return false;
	}

	return true;
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	// Reset remembered menu pages
	MENU_PAGE_GAME_MODES(iPlayer) = 0;
	MENU_PAGE_PLAYERS(iPlayer) = 0;

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