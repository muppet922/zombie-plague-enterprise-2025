/* AMX Mod X
*	[ZPE] Gamemode plague.
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

#define PLUGIN "gamemode plague"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <zpe_class_nemesis>
#include <zpe_class_survivor>

#define ZPE_SETTINGS_INI "ZPE/gamemode/zpe_plague.ini"

new Array:g_aSound_Plague;

new g_pCvar_Plague_Chance;
new g_pCvar_Plague_Min_Players;
new g_pCvar_Plague_Ratio;
new g_pCvar_Plague_Nemesis_Count;
new g_pCvar_Plague_Nemesis_HP_Multi;
new g_pCvar_Plague_Survivor_Count;
new g_pCvar_Plague_Survivor_HP_Multi;
new g_pCvar_Plague_Sounds;
new g_pCvar_Plague_Allow_Respawn;

new g_pCvar_Notice_Plague_Show_Hud;

new g_pCvar_Message_Notice_Plague_Converted;
new g_pCvar_Message_Notice_Plague_R;
new g_pCvar_Message_Notice_Plague_G;
new g_pCvar_Message_Notice_Plague_B;
new g_pCvar_Message_Notice_Plague_X;
new g_pCvar_Message_Notice_Plague_Y;
new g_pCvar_Message_Notice_Plague_Effects;
new g_pCvar_Message_Notice_Plague_Fxtime;
new g_pCvar_Message_Notice_Plague_Holdtime;
new g_pCvar_Message_Notice_Plague_Fadeintime;
new g_pCvar_Message_Notice_Plague_Fadeouttime;
new g_pCvar_Message_Notice_Plague_Channel;

new g_pCvar_All_Messages_Are_Converted;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Plague_Chance = register_cvar("zpe_plague_chance", "20");
	g_pCvar_Plague_Min_Players = register_cvar("zpe_plague_min_players", "0");
	g_pCvar_Plague_Ratio = register_cvar("zpe_plague_ratio", "0.5");
	g_pCvar_Plague_Nemesis_Count = register_cvar("zpe_plague_nemesis_count", "1");
	g_pCvar_Plague_Nemesis_HP_Multi = register_cvar("zpe_plague_nemesis_hp_multi", "0.5");
	g_pCvar_Plague_Survivor_Count = register_cvar("zpe_plague_survivor_count", "1");
	g_pCvar_Plague_Survivor_HP_Multi = register_cvar("zpe_plague_survivor_hp_multi", "0.5");
	g_pCvar_Plague_Sounds = register_cvar("zpe_plague_sounds", "1");
	g_pCvar_Plague_Allow_Respawn = register_cvar("zpe_plague_allow_respawn", "0");

	g_pCvar_Notice_Plague_Show_Hud = register_cvar("zpe_notice_plague_show_hud", "1");

	g_pCvar_Message_Notice_Plague_Converted = register_cvar("zpe_message_notice_plague_converted", "0");
	g_pCvar_Message_Notice_Plague_R = register_cvar("zpe_message_notice_plague_r", "0");
	g_pCvar_Message_Notice_Plague_G = register_cvar("zpe_message_notice_plague_g", "250");
	g_pCvar_Message_Notice_Plague_B = register_cvar("zpe_message_notice_plague_b", "0");
	g_pCvar_Message_Notice_Plague_X = register_cvar("zpe_message_notice_plague_x", "-1.0");
	g_pCvar_Message_Notice_Plague_Y = register_cvar("zpe_message_notice_plague_y", "0.75");
	g_pCvar_Message_Notice_Plague_Effects = register_cvar("zpe_message_notice_plague_effects", "0");
	g_pCvar_Message_Notice_Plague_Fxtime = register_cvar("zpe_message_notice_plague_fxtime", "0.1");
	g_pCvar_Message_Notice_Plague_Holdtime = register_cvar("zpe_message_notice_plague_holdtime", "1.5");
	g_pCvar_Message_Notice_Plague_Fadeintime = register_cvar("zpe_message_notice_plague_fadeintime", "2.0");
	g_pCvar_Message_Notice_Plague_Fadeouttime = register_cvar("zpe_message_notice_plague_fadeouttime", "1.5");
	g_pCvar_Message_Notice_Plague_Channel = register_cvar("zpe_message_notice_plague_channel", "-1");

	g_pCvar_All_Messages_Are_Converted = register_cvar("zpe_all_messages_are_converted", "0");
}

public plugin_precache()
{
	g_aSound_Plague = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_INI, "Sounds", "ROUND PLAGUE", g_aSound_Plague);
	Precache_Sounds(g_aSound_Plague);
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/gamemode/zpe_plague.cfg");

	// Register game mode at plugin_cfg (plugin gets paused after this)
	zpe_gamemodes_register("plague");
}

// Deathmatch module's player respawn forward
public zpe_fw_deathmatch_respawn_pre(iPlayer)
{
	// Respawning allowed?
	if (!get_pcvar_num(g_pCvar_Plague_Allow_Respawn))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_gamemodes_choose_pre(iGame_Mode_ID, iSkipchecks)
{
	new iAlive_Count = Get_Alive_Count();

	if (!iSkipchecks)
	{
		// Random chance
		if (!CHANCE(get_pcvar_num(g_pCvar_Plague_Chance)))
		{
			return PLUGIN_HANDLED;
		}

		// Min players
		if (iAlive_Count < get_pcvar_num(g_pCvar_Plague_Min_Players))
		{
			return PLUGIN_HANDLED;
		}
	}

	// There should be enough players to have the desired amount of nemesis and survivors
	if (iAlive_Count < get_pcvar_num(g_pCvar_Plague_Nemesis_Count) + get_pcvar_num(g_pCvar_Plague_Survivor_Count))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_gamemodes_start()
{
	new iPlayer;
	new iAlive_Count = Get_Alive_Count();
	new iSurvivor_Count = get_pcvar_num(g_pCvar_Plague_Survivor_Count);
	new iNemesis_Count = get_pcvar_num(g_pCvar_Plague_Nemesis_Count);
	new iZombie_Count = floatround((iAlive_Count - (iNemesis_Count + iSurvivor_Count)) * get_pcvar_float(g_pCvar_Plague_Ratio), floatround_ceil);

	new iSurvivors;
	new iMax_Survivors = iSurvivor_Count;

	while (iSurvivors < iMax_Survivors)
	{
		iPlayer = Get_Random_Alive_Player();

		if (zpe_class_survivor_get(iPlayer))
		{
			continue;
		}

		zpe_class_survivor_set(iPlayer);

		iSurvivors++;

		SET_USER_HEALTH(iPlayer, Float:GET_USER_HEALTH(iPlayer) * get_pcvar_float(g_pCvar_Plague_Survivor_HP_Multi));
	}

	new iNemesis;
	new iMax_Nemesis = iNemesis_Count;

	while (iNemesis < iMax_Nemesis)
	{
		iPlayer = Get_Random_Alive_Player();

		if (zpe_class_survivor_get(iPlayer) || zpe_class_nemesis_get(iPlayer))
		{
			continue;
		}

		zpe_class_nemesis_set(iPlayer);

		iNemesis++;

		SET_USER_HEALTH(iPlayer, Float:GET_USER_HEALTH(iPlayer) * get_pcvar_float(g_pCvar_Plague_Nemesis_HP_Multi));
	}

	new iZombies;
	new iMax_Zombies = iZombie_Count;

	while (iZombies < iMax_Zombies)
	{
		iPlayer = Get_Random_Alive_Player();

		if (zpe_class_survivor_get(iPlayer) || zpe_core_is_zombie(iPlayer))
		{
			continue;
		}

		zpe_core_infect(iPlayer, 0);

		iZombies++;
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i)) // Use bit - invalid player
		{
			continue;
		}

		if (zpe_class_survivor_get(i) || zpe_core_is_zombie(i))
		{
			continue;
		}

		rg_set_user_team(i, TEAM_CT);
	}

	if (get_pcvar_num(g_pCvar_Plague_Sounds))
	{
		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSound_Plague, RANDOM(ArraySize(g_aSound_Plague)), szSound, charsmax(szSound));
		Play_Sound_To_Clients(szSound);
	}

	if (get_pcvar_num(g_pCvar_Notice_Plague_Show_Hud))
	{
		if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Notice_Plague_Converted))
		{
			set_hudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Plague_R),
				get_pcvar_num(g_pCvar_Message_Notice_Plague_G),
				get_pcvar_num(g_pCvar_Message_Notice_Plague_B),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_X),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Plague_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_Fadeouttime),
				get_pcvar_num(g_pCvar_Message_Notice_Plague_Channel)
			);

			show_hudmessage(0, "%L", LANG_PLAYER, "NOTICE_PLAGUE");
		}

		else
		{
			set_dhudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Plague_R),
				get_pcvar_num(g_pCvar_Message_Notice_Plague_G),
				get_pcvar_num(g_pCvar_Message_Notice_Plague_B),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_X),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Plague_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Plague_Fadeouttime)
			);

			show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_PLAGUE");
		}
	}
}

// Plays a sound on clients
Play_Sound_To_Clients(const szSound[])
{
	if (equal(szSound[strlen(szSound) - 4], ".mp3"))
	{
		client_cmd(0, "mp3 play ^"sound/%s^"", szSound);
	}

	else
	{
		client_cmd(0, "spk ^"%s^"", szSound);
	}
}

Get_Alive_Count()
{
	new iAlive;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_alive(i)) // Use bit - invalid player
		{
			iAlive++;
		}
	}

	return iAlive;
}

Get_Random_Alive_Player()
{
	new iPlayers[32];
	new iCount;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (is_user_alive(i)) // Use bit - invalid player
		{
			iPlayers[iCount++] = i;
		}
	}

	return iCount > 0 ? iPlayers[RANDOM(iCount)] : -1;
}