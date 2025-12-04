/* AMX Mod X
*	[ZPE] Gamemode swarm.
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

#define PLUGIN "gamemode swarm"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_gamemodes>

#define ZPE_SETTINGS_FILE "ZPE/gamemode/zpe_swarm.ini"

new Array:g_aSound_Swarm;

new g_pCvar_Swarm_Chance;
new g_pCvar_Swarm_Min_Players;
new g_pCvar_Swarm_Sounds;
new g_pCvar_Swarm_Allow_Respawn;

new g_pCvar_Notice_Swarm_Show_Hud;

new g_pCvar_Message_Notice_Swarm_Converted;
new g_pCvar_Message_Notice_Swarm_R;
new g_pCvar_Message_Notice_Swarm_G;
new g_pCvar_Message_Notice_Swarm_B;
new g_pCvar_Message_Notice_Swarm_X;
new g_pCvar_Message_Notice_Swarm_Y;
new g_pCvar_Message_Notice_Swarm_Effects;
new g_pCvar_Message_Notice_Swarm_Fxtime;
new g_pCvar_Message_Notice_Swarm_Holdtime;
new g_pCvar_Message_Notice_Swarm_Fadeintime;
new g_pCvar_Message_Notice_Swarm_Fadeouttime;
new g_pCvar_Message_Notice_Swarm_Channel;

new g_pCvar_All_Messages_Are_Converted;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Swarm_Chance = register_cvar("zpe_swarm_chance", "20");
	g_pCvar_Swarm_Min_Players = register_cvar("zpe_swarm_min_players", "0");
	g_pCvar_Swarm_Sounds = register_cvar("zpe_swarm_sounds", "1");
	g_pCvar_Swarm_Allow_Respawn = register_cvar("zpe_swarm_allow_respawn", "0");

	g_pCvar_Notice_Swarm_Show_Hud = register_cvar("zpe_notice_swarm_show_hud", "1");

	g_pCvar_Message_Notice_Swarm_Converted = register_cvar("zpe_message_notice_swarm_converted", "0");
	g_pCvar_Message_Notice_Swarm_R = register_cvar("zpe_message_notice_swarm_r", "0");
	g_pCvar_Message_Notice_Swarm_G = register_cvar("zpe_message_notice_swarm_g", "250");
	g_pCvar_Message_Notice_Swarm_B = register_cvar("zpe_message_notice_swarm_b", "0");
	g_pCvar_Message_Notice_Swarm_X = register_cvar("zpe_message_notice_swarm_x", "-1.0");
	g_pCvar_Message_Notice_Swarm_Y = register_cvar("zpe_message_notice_swarm_y", "0.75");
	g_pCvar_Message_Notice_Swarm_Effects = register_cvar("zpe_message_notice_swarm_effects", "0");
	g_pCvar_Message_Notice_Swarm_Fxtime = register_cvar("zpe_message_notice_swarm_fxtime", "0.1");
	g_pCvar_Message_Notice_Swarm_Holdtime = register_cvar("zpe_message_notice_swarm_holdtime", "1.5");
	g_pCvar_Message_Notice_Swarm_Fadeintime = register_cvar("zpe_message_notice_swarm_fadeintime", "2.0");
	g_pCvar_Message_Notice_Swarm_Fadeouttime = register_cvar("zpe_message_notice_swarm_fadeouttime", "1.5");
	g_pCvar_Message_Notice_Swarm_Channel = register_cvar("zpe_message_notice_swarm_channel", "-1");

	g_pCvar_All_Messages_Are_Converted = register_cvar("zpe_all_messages_are_converted", "0");
}

public plugin_precache()
{
	g_aSound_Swarm = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "ROUND SWARM", g_aSound_Swarm);
	Precache_Sounds(g_aSound_Swarm);
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/gamemode/zpe_swarm.cfg");

	// Register game mode at plugin_cfg (plugin gets paused after this)
	zpe_gamemodes_register("swarm");
}

// Deathmatch module's player respawn forward
public zpe_fw_deathmatch_respawn_pre(iPlayer)
{
	// Respawning allowed?
	if (!get_pcvar_num(g_pCvar_Swarm_Allow_Respawn))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_gamemodes_choose_pre(iGame_Mode_ID, iSkipchecks)
{
	if (!iSkipchecks)
	{
		// Random chance
		if (!CHANCE(get_pcvar_num(g_pCvar_Swarm_Chance)))
		{
			return PLUGIN_HANDLED;
		}

		// Min players
		if (Get_Alive_Count() < get_pcvar_num(g_pCvar_Swarm_Min_Players))
		{
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_gamemodes_start()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i)) // Use bit - invalid player
		{
			continue;
		}

		if (CS_GET_USER_TEAM(i) != CS_TEAM_T)
		{
			continue;
		}

		zpe_core_infect(i, 0);
	}

	// Play swarm sound
	if (get_pcvar_num(g_pCvar_Swarm_Sounds))
	{
		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSound_Swarm, RANDOM(ArraySize(g_aSound_Swarm)), szSound, charsmax(szSound));
		Play_Sound_To_Clients(szSound);
	}

	if (get_pcvar_num(g_pCvar_Notice_Swarm_Show_Hud))
	{
		if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Notice_Swarm_Converted))
		{
			set_hudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Swarm_R),
				get_pcvar_num(g_pCvar_Message_Notice_Swarm_G),
				get_pcvar_num(g_pCvar_Message_Notice_Swarm_B),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_X),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Swarm_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_Fadeouttime),
				get_pcvar_num(g_pCvar_Message_Notice_Swarm_Channel)
			);

			show_hudmessage(0,  "%L", LANG_PLAYER, "NOTICE_SWARM");
		}

		else
		{
			set_dhudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Swarm_R),
				get_pcvar_num(g_pCvar_Message_Notice_Swarm_G),
				get_pcvar_num(g_pCvar_Message_Notice_Swarm_B),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_X),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Swarm_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Swarm_Fadeouttime)
			);

			show_dhudmessage(0,  "%L", LANG_PLAYER, "NOTICE_SWARM");
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