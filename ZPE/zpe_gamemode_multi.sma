/* AMX Mod X
*	[ZPE] Gamemode Multi.
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

#define PLUGIN "gamemode multi"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <zpe_deathmatch>

#define ZPE_SETTINGS_FILE "ZPE/gamemode/zpe_multi.ini"

new Array:g_aSound_Multi;

new g_pCvar_Multi_Chance;
new g_pCvar_Multi_Min_Players;
new g_pCvar_Multi_Min_Zombies;
new g_pCvar_Multi_Ratio;
new g_pCvar_Multi_Sounds;
new g_pCvar_Multi_Allow_Respawn;
new g_pCvar_Multi_Respawn_After_Last_Human;

new g_pCvar_Notice_Multi_Show_Hud;

new g_pCvar_Message_Notice_Multi_Converted;
new g_pCvar_Message_Notice_Multi_R;
new g_pCvar_Message_Notice_Multi_G;
new g_pCvar_Message_Notice_Multi_B;
new g_pCvar_Message_Notice_Multi_X;
new g_pCvar_Message_Notice_Multi_Y;
new g_pCvar_Message_Notice_Multi_Effects;
new g_pCvar_Message_Notice_Multi_Fxtime;
new g_pCvar_Message_Notice_Multi_Holdtime;
new g_pCvar_Message_Notice_Multi_Fadeintime;
new g_pCvar_Message_Notice_Multi_Fadeouttime;
new g_pCvar_Message_Notice_Multi_Channel;

new g_pCvar_All_Messages_Are_Converted;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Multi_Chance = register_cvar("zpe_multi_chance", "20");
	g_pCvar_Multi_Min_Players = register_cvar("zpe_multi_min_players", "0");
	g_pCvar_Multi_Min_Zombies = register_cvar("zpe_multi_min_zombies", "2");
	g_pCvar_Multi_Ratio = register_cvar("zpe_multi_ratio", "0.15");
	g_pCvar_Multi_Sounds = register_cvar("zpe_multi_sounds", "1");
	g_pCvar_Multi_Allow_Respawn = register_cvar("zpe_multi_allow_respawn", "1");
	g_pCvar_Multi_Respawn_After_Last_Human = register_cvar("zpe_multi_respawn_after_last_human", "1");

	g_pCvar_Notice_Multi_Show_Hud = register_cvar("zpe_notice_multi_show_hud", "1");

	g_pCvar_Message_Notice_Multi_Converted = register_cvar("zpe_message_notice_multi_converted", "0");
	g_pCvar_Message_Notice_Multi_R = register_cvar("zpe_message_notice_multi_r", "0");
	g_pCvar_Message_Notice_Multi_G = register_cvar("zpe_message_notice_multi_g", "250");
	g_pCvar_Message_Notice_Multi_B = register_cvar("zpe_message_notice_multi_b", "0");
	g_pCvar_Message_Notice_Multi_X = register_cvar("zpe_message_notice_multi_x", "-1.0");
	g_pCvar_Message_Notice_Multi_Y = register_cvar("zpe_message_notice_multi_y", "0.75");
	g_pCvar_Message_Notice_Multi_Effects = register_cvar("zpe_message_notice_multi_effects", "0");
	g_pCvar_Message_Notice_Multi_Fxtime = register_cvar("zpe_message_notice_multi_fxtime", "0.1");
	g_pCvar_Message_Notice_Multi_Holdtime = register_cvar("zpe_message_notice_multi_holdtime", "1.5");
	g_pCvar_Message_Notice_Multi_Fadeintime = register_cvar("zpe_message_notice_multi_fadeintime", "2.0");
	g_pCvar_Message_Notice_Multi_Fadeouttime = register_cvar("zpe_message_notice_multi_fadeouttime", "1.5");
	g_pCvar_Message_Notice_Multi_Channel = register_cvar("zpe_message_notice_multi_channel", "-1");

	g_pCvar_All_Messages_Are_Converted = register_cvar("zpe_all_messages_are_converted", "0");
}

public plugin_precache()
{
	g_aSound_Multi = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "ROUND MULTI", g_aSound_Multi);
	Precache_Sounds(g_aSound_Multi);
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/gamemode/zpe_multi.cfg");

	// Register game mode at plugin_cfg (plugin gets paused after this)
	zpe_gamemodes_register("multiple_infection");
}

// Deathmatch module's player respawn forward
public zpe_fw_deathmatch_respawn_pre(iPlayer)
{
	// Respawning allowed?
	if (!get_pcvar_num(g_pCvar_Multi_Allow_Respawn))
	{
		return PLUGIN_HANDLED;
	}

	// Respawn if only the last human is left?
	if (!get_pcvar_num(g_pCvar_Multi_Respawn_After_Last_Human) && zpe_core_get_human_count() == 1)
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_gamemodes_choose_pre(iGame_Mode_ID, iSkipchecks)
{
	new iAlive_Count = Get_Alive_Count();

	new Zombie_Count = floatround(iAlive_Count * get_pcvar_float(g_pCvar_Multi_Ratio), floatround_ceil);

	if (!iSkipchecks)
	{
		if (!CHANCE(get_pcvar_num(g_pCvar_Multi_Chance)))
		{
			return PLUGIN_HANDLED;
		}

		// Min players
		if (iAlive_Count < get_pcvar_num(g_pCvar_Multi_Min_Players))
		{
			return PLUGIN_HANDLED;
		}

		// Min zombies
		if (Zombie_Count < get_pcvar_num(g_pCvar_Multi_Min_Zombies))
		{
			return PLUGIN_HANDLED;
		}
	}

	if (Zombie_Count >= iAlive_Count)
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_gamemodes_start()
{
	zpe_gamemodes_set_allow_infect();

	new iZombies;
	new iPlayer;

	new iAlive_Count = Get_Alive_Count();

	new iMax_Zombies = floatround(iAlive_Count * get_pcvar_float(g_pCvar_Multi_Ratio), floatround_ceil);

	while (iZombies < iMax_Zombies)
	{
		iPlayer = Get_Random_Alive_Player();

		if (!is_user_alive(iPlayer)) // Use bit - invalid player
		{
			continue;
		}

		if (zpe_core_is_zombie(iPlayer))
		{
			continue;
		}

		zpe_core_infect(iPlayer, 0);

		iZombies++;
	}

	for (new i = 1; i <= MaxClients; i++)
	{
		// Not alive
		if (!is_user_alive(i)) // Use bit - invalid player
		{
			continue;
		}

		// This is our first zombie
		if (zpe_core_is_zombie(i))
		{
			continue;
		}

		rg_set_user_team(i, TEAM_CT);
	}

	if (get_pcvar_num(g_pCvar_Multi_Sounds))
	{
		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSound_Multi, RANDOM(ArraySize(g_aSound_Multi)), szSound, charsmax(szSound));
		Play_Sound_To_Clients(szSound);
	}

	if (get_pcvar_num(g_pCvar_Notice_Multi_Show_Hud))
	{
		if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Notice_Multi_Converted))
		{
			set_hudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Multi_R),
				get_pcvar_num(g_pCvar_Message_Notice_Multi_G),
				get_pcvar_num(g_pCvar_Message_Notice_Multi_B),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_X),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Multi_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_Fadeouttime),
				get_pcvar_num(g_pCvar_Message_Notice_Multi_Channel)
			);

			show_hudmessage(0, "%L", LANG_PLAYER, "NOTICE_MULTI");
		}

		else
		{
			set_dhudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Multi_R),
				get_pcvar_num(g_pCvar_Message_Notice_Multi_G),
				get_pcvar_num(g_pCvar_Message_Notice_Multi_B),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_X),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Multi_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Multi_Fadeouttime)
			);

			show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_MULTI");
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