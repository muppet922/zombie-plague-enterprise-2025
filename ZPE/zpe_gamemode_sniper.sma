/* AMX Mod X
*	[ZPE] Gamemode Sniper.
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

#define PLUGIN "gamemode sniper"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <zpe_class_sniper>
#include <zpe_deathmatch>

#define ZPE_SETTINGS_FILE "ZPE/gamemode/zpe_sniper.ini"

new Array:g_aSound_Sniper;

new g_pCvar_Sniper_Chance;
new g_pCvar_Sniper_Min_Players;
new g_pCvar_Sniper_Sounds;
new g_pCvar_Sniper_Allow_Respawn;

new g_pCvar_Notice_Sniper_Show_Hud;

new g_pCvar_Message_Notice_Sniper_Converted;
new g_pCvar_Message_Notice_Sniper_R;
new g_pCvar_Message_Notice_Sniper_G;
new g_pCvar_Message_Notice_Sniper_B;
new g_pCvar_Message_Notice_Sniper_X;
new g_pCvar_Message_Notice_Sniper_Y;
new g_pCvar_Message_Notice_Sniper_Effects;
new g_pCvar_Message_Notice_Sniper_Fxtime;
new g_pCvar_Message_Notice_Sniper_Holdtime;
new g_pCvar_Message_Notice_Sniper_Fadeintime;
new g_pCvar_Message_Notice_Sniper_Fadeouttime;
new g_pCvar_Message_Notice_Sniper_Channel;

new g_pCvar_All_Messages_Are_Converted;

new g_iTarget_Player;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Sniper_Chance = register_cvar("zpe_sniper_chance", "20");
	g_pCvar_Sniper_Min_Players = register_cvar("zpe_sniper_min_players", "0");
	g_pCvar_Sniper_Sounds = register_cvar("zpe_sniper_sounds", "1");
	g_pCvar_Sniper_Allow_Respawn = register_cvar("zpe_sniper_allow_respawn", "0");

	g_pCvar_Notice_Sniper_Show_Hud = register_cvar("zpe_notice_sniper_show_hud", "1");

	g_pCvar_Message_Notice_Sniper_Converted = register_cvar("zpe_message_notice_sniper_converted", "0");
	g_pCvar_Message_Notice_Sniper_R = register_cvar("zpe_message_notice_sniper_r", "0");
	g_pCvar_Message_Notice_Sniper_G = register_cvar("zpe_message_notice_sniper_g", "250");
	g_pCvar_Message_Notice_Sniper_B = register_cvar("zpe_message_notice_sniper_b", "0");
	g_pCvar_Message_Notice_Sniper_X = register_cvar("zpe_message_notice_sniper_x", "-1.0");
	g_pCvar_Message_Notice_Sniper_Y = register_cvar("zpe_message_notice_sniper_y", "0.75");
	g_pCvar_Message_Notice_Sniper_Effects = register_cvar("zpe_message_notice_sniper_effects", "0");
	g_pCvar_Message_Notice_Sniper_Fxtime = register_cvar("zpe_message_notice_sniper_fxtime", "0.1");
	g_pCvar_Message_Notice_Sniper_Holdtime = register_cvar("zpe_message_notice_sniper_holdtime", "1.5");
	g_pCvar_Message_Notice_Sniper_Fadeintime = register_cvar("zpe_message_notice_sniper_fadeintime", "2.0");
	g_pCvar_Message_Notice_Sniper_Fadeouttime = register_cvar("zpe_message_notice_sniper_fadeouttime", "1.5");
	g_pCvar_Message_Notice_Sniper_Channel = register_cvar("zpe_message_notice_sniper_channel", "-1");

	g_pCvar_All_Messages_Are_Converted = register_cvar("zpe_all_messages_are_converted", "0");
}

public plugin_precache()
{
	g_aSound_Sniper = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "ROUND SNIPER", g_aSound_Sniper);
	Precache_Sounds(g_aSound_Sniper);
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/gamemode/zpe_sniper.cfg");

	// Register game mode at plugin_cfg (plugin gets paused after this)
	zpe_gamemodes_register("sniper");
}

// Deathmatch module's player respawn forward
public zpe_fw_deathmatch_respawn_pre(iPlayer)
{
	// Respawning allowed?
	if (!get_pcvar_num(g_pCvar_Sniper_Allow_Respawn))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_core_spawn_post(iPlayer)
{
	// Always respawn as human on sniper rounds
	zpe_core_respawn_as_zombie(iPlayer, false);
}

public zpe_fw_gamemodes_choose_pre(iGame_Mode_ID, iSkipcheck)
{
	if (!iSkipcheck)
	{
		// Random chance
		if (!CHANCE(get_pcvar_num(g_pCvar_Sniper_Chance)))
		{
			return PLUGIN_HANDLED;
		}

		// Min players
		if (Get_Alive_Count() < get_pcvar_num(g_pCvar_Sniper_Min_Players))
		{
			return PLUGIN_HANDLED;
		}
	}

	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zpe_fw_gamemodes_choose_post(iGame_Mode_ID, iTarget_Player)
{
	// Pick player randomly?
	g_iTarget_Player = (iTarget_Player == RANDOM_TARGET_PLAYER) ? Get_Random_Alive_Player() : iTarget_Player;
}

public zpe_fw_gamemodes_start()
{
	// Turn player into sniper
	zpe_class_sniper_set(g_iTarget_Player);

	// Turn the remaining players into zombies
	for (new i = 1; i <= MaxClients; i++)
	{
		// Not alive
		if (!is_user_alive(i)) // Use bit - invalid player
		{
			continue;
		}

		// Sniper or already a zombie
		if (zpe_class_sniper_get(i) || zpe_core_is_zombie(i))
		{
			continue;
		}

		zpe_core_infect(i);
	}

	if (get_pcvar_num(g_pCvar_Sniper_Sounds))
	{
		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSound_Sniper, RANDOM(ArraySize(g_aSound_Sniper)), szSound, charsmax(szSound));
		Play_Sound_To_Clients(szSound);
	}

	if (get_pcvar_num(g_pCvar_Notice_Sniper_Show_Hud))
	{
		new szPlayer_Name[32];

		GET_USER_NAME(g_iTarget_Player, szPlayer_Name, charsmax(szPlayer_Name));

		if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Notice_Sniper_Converted))
		{
			set_hudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Sniper_R),
				get_pcvar_num(g_pCvar_Message_Notice_Sniper_G),
				get_pcvar_num(g_pCvar_Message_Notice_Sniper_B),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_X),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Sniper_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_Fadeouttime),
				get_pcvar_num(g_pCvar_Message_Notice_Sniper_Channel)
			);

			show_hudmessage(0, "%L", LANG_PLAYER, "NOTICE_SNIPER", szPlayer_Name);
		}

		else
		{
			set_dhudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Sniper_R),
				get_pcvar_num(g_pCvar_Message_Notice_Sniper_G),
				get_pcvar_num(g_pCvar_Message_Notice_Sniper_B),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_X),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Sniper_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Sniper_Fadeouttime)
			);

			show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_SNIPER", szPlayer_Name);
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