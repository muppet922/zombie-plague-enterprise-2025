/* AMX Mod X
*	[ZPE] Gamemode nemesis.
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

#define PLUGIN "gamemode nemesis"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <zpe_class_nemesis>

#define ZPE_SETTINGS_FILE "ZPE/gamemode/zpe_nemesis.ini"

new Array:g_aSound_Nemesis;

new g_pCvar_Nemesis_Chance;
new g_pCvar_Nemesis_Min_Players;
new g_pCvar_Nemesis_Sounds;
new g_pCvar_Nemesis_Allow_Respawn;

new g_pCvar_Notice_Nemesis_Show_Hud;

new g_pCvar_Message_Notice_Nemesis_Converted;
new g_pCvar_Message_Notice_Nemesis_R;
new g_pCvar_Message_Notice_Nemesis_G;
new g_pCvar_Message_Notice_Nemesis_B;
new g_pCvar_Message_Notice_Nemesis_X;
new g_pCvar_Message_Notice_Nemesis_Y;
new g_pCvar_Message_Notice_Nemesis_Effects;
new g_pCvar_Message_Notice_Nemesis_Fxtime;
new g_pCvar_Message_Notice_Nemesis_Holdtime;
new g_pCvar_Message_Notice_Nemesis_Fadeintime;
new g_pCvar_Message_Notice_Nemesis_Fadeouttime;
new g_pCvar_Message_Notice_Nemesis_Channel;

new g_pCvar_All_Messages_Are_Converted;

new g_iTarget_Player;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Nemesis_Chance = register_cvar("zpe_nemesis_chance", "20");
	g_pCvar_Nemesis_Min_Players = register_cvar("zpe_nemesis_min_players", "0");
	g_pCvar_Nemesis_Sounds = register_cvar("zpe_nemesis_sounds", "1");
	g_pCvar_Nemesis_Allow_Respawn = register_cvar("zpe_nemesis_allow_respawn", "0");

	g_pCvar_Notice_Nemesis_Show_Hud = register_cvar("zpe_notice_nemesis_show_hud", "1");

	g_pCvar_Message_Notice_Nemesis_Converted = register_cvar("zpe_message_notice_nemesis_converted", "0");
	g_pCvar_Message_Notice_Nemesis_R = register_cvar("zpe_message_notice_nemesis_r", "0");
	g_pCvar_Message_Notice_Nemesis_G = register_cvar("zpe_message_notice_nemesis_g", "250");
	g_pCvar_Message_Notice_Nemesis_B = register_cvar("zpe_message_notice_nemesis_b", "0");
	g_pCvar_Message_Notice_Nemesis_X = register_cvar("zpe_message_notice_nemesis_x", "-1.0");
	g_pCvar_Message_Notice_Nemesis_Y = register_cvar("zpe_message_notice_nemesis_y", "0.75");
	g_pCvar_Message_Notice_Nemesis_Effects = register_cvar("zpe_message_notice_nemesis_effects", "0");
	g_pCvar_Message_Notice_Nemesis_Fxtime = register_cvar("zpe_message_notice_nemesis_fxtime", "0.1");
	g_pCvar_Message_Notice_Nemesis_Holdtime = register_cvar("zpe_message_notice_nemesis_holdtime", "1.5");
	g_pCvar_Message_Notice_Nemesis_Fadeintime = register_cvar("zpe_message_notice_nemesis_fadeintime", "2.0");
	g_pCvar_Message_Notice_Nemesis_Fadeouttime = register_cvar("zpe_message_notice_nemesis_fadeouttime", "1.5");
	g_pCvar_Message_Notice_Nemesis_Channel = register_cvar("zpe_message_notice_nemesis_channel", "-1");

	g_pCvar_All_Messages_Are_Converted = register_cvar("zpe_all_messages_are_converted", "0");
}

public plugin_precache()
{
	g_aSound_Nemesis = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "ROUND NEMESIS", g_aSound_Nemesis);
	Precache_Sounds(g_aSound_Nemesis)
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/gamemode/zpe_nemesis.cfg");

	// Register game mode at plugin_cfg (plugin gets paused after this)
	zpe_gamemodes_register("nemesis");
}

// Deathmatch module's player respawn forward
public zpe_fw_deathmatch_respawn_pre(iPlayer)
{
	// Respawning allowed?
	if (!get_pcvar_num(g_pCvar_Nemesis_Allow_Respawn))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_core_spawn_post(iPlayer)
{
	zpe_core_respawn_as_zombie(iPlayer, false);
}

public zpe_fw_gamemodes_choose_pre(iGame_Mode_ID, iSkipchecks)
{
	if (!iSkipchecks)
	{
		// Random chance
		if (!CHANCE(get_pcvar_num(g_pCvar_Nemesis_Chance)))
		{
			return PLUGIN_HANDLED;
		}

		// Min players
		if (Get_Alive_Count() < get_pcvar_num(g_pCvar_Nemesis_Min_Players))
		{
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_gamemodes_choose_post(iGame_Mode_ID, iTarget_Player)
{
	g_iTarget_Player = (iTarget_Player == RANDOM_TARGET_PLAYER) ? Get_Random_Alive_Player() : iTarget_Player;
}

public zpe_fw_gamemodes_start()
{
	zpe_class_nemesis_set(g_iTarget_Player);

	for (new i = 1; i <= MaxClients; i++)
	{
		// Not alive
		if (!is_user_alive(i)) // Use bit - invalid player
		{
			continue;
		}

		if (zpe_class_nemesis_get(i))
		{
			continue;
		}

		rg_set_user_team(i, TEAM_CT);
	}

	if (get_pcvar_num(g_pCvar_Nemesis_Sounds))
	{
		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSound_Nemesis, RANDOM(ArraySize(g_aSound_Nemesis)), szSound, charsmax(szSound));
		Play_Sound_To_Clients(szSound);
	}

	if (get_pcvar_num(g_pCvar_Notice_Nemesis_Show_Hud))
	{
		new szPlayer_Name[32];

		GET_USER_NAME(g_iTarget_Player, szPlayer_Name, charsmax(szPlayer_Name));

		if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Notice_Nemesis_Converted))
		{
			set_hudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Nemesis_R),
				get_pcvar_num(g_pCvar_Message_Notice_Nemesis_G),
				get_pcvar_num(g_pCvar_Message_Notice_Nemesis_B),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_X),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Nemesis_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_Fadeouttime),
				get_pcvar_num(g_pCvar_Message_Notice_Nemesis_Channel)
			);

			show_hudmessage(0, "%L", LANG_PLAYER, "NOTICE_NEMESIS", szPlayer_Name);
		}

		else
		{
			set_dhudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Nemesis_R),
				get_pcvar_num(g_pCvar_Message_Notice_Nemesis_G),
				get_pcvar_num(g_pCvar_Message_Notice_Nemesis_B),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_X),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Nemesis_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Nemesis_Fadeouttime)
			);

			show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_NEMESIS", szPlayer_Name);
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