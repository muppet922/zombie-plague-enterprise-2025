/* AMX Mod X
*	[ZPE] Gamemode assassin.
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

#define PLUGIN "gamemode assassin"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <amxmisc>
#include <cs_util>
#include <amx_settings_api>
#include <engine>
#include <zpe_gamemodes>
#include <zpe_class_assassin>
#include <zpe_kernel>

#define ZPE_SETTINGS_FILE "ZPE/gamemode/zpe_assassin.ini"

new Array:g_aSounds_Assassin;

new g_pCvar_Assassin_Chance;
new g_pCvar_Assassin_Min_Players;
new g_pCvar_Assassin_Sounds;
new g_pCvar_Assassin_Allow_Respawn;

new g_pCvar_Assassin_Lighting;

new g_pCvar_Notice_Assassin_Show_Hud;

new g_pCvar_Message_Notice_Assassin_Converted;
new g_pCvar_Message_Notice_Assassin_R;
new g_pCvar_Message_Notice_Assassin_G;
new g_pCvar_Message_Notice_Assassin_B;
new g_pCvar_Message_Notice_Assassin_X;
new g_pCvar_Message_Notice_Assassin_Y;
new g_pCvar_Message_Notice_Assassin_Effects;
new g_pCvar_Message_Notice_Assassin_Fxtime;
new g_pCvar_Message_Notice_Assassin_Holdtime;
new g_pCvar_Message_Notice_Assassin_Fadeintime;
new g_pCvar_Message_Notice_Assassin_Fadeouttime;
new g_pCvar_Message_Notice_Assassin_Channel;

new g_pCvar_All_Messages_Are_Converted;

new g_iTarget_Player;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Assassin_Chance = register_cvar("zpe_assassin_chance", "20");
	g_pCvar_Assassin_Min_Players = register_cvar("zpe_assassin_min_players", "0");
	g_pCvar_Assassin_Sounds = register_cvar("zpe_assassin_sounds", "1");
	g_pCvar_Assassin_Allow_Respawn = register_cvar("zpe_assassin_allow_respawn", "0");

	g_pCvar_Assassin_Lighting = register_cvar("zpe_assassin_lighting", "a");

	g_pCvar_Notice_Assassin_Show_Hud = register_cvar("zpe_notice_assassin_show_hud", "1");

	g_pCvar_Message_Notice_Assassin_Converted = register_cvar("zpe_message_notice_assassin_converted", "0");
	g_pCvar_Message_Notice_Assassin_R = register_cvar("zpe_message_notice_assassin_r", "0");
	g_pCvar_Message_Notice_Assassin_G = register_cvar("zpe_message_notice_assassin_g", "250");
	g_pCvar_Message_Notice_Assassin_B = register_cvar("zpe_message_notice_assassin_b", "0");
	g_pCvar_Message_Notice_Assassin_X = register_cvar("zpe_message_notice_assassin_x", "-1.0");
	g_pCvar_Message_Notice_Assassin_Y = register_cvar("zpe_message_notice_assassin_y", "0.75");
	g_pCvar_Message_Notice_Assassin_Effects = register_cvar("zpe_message_notice_assassin_effects", "0");
	g_pCvar_Message_Notice_Assassin_Fxtime = register_cvar("zpe_message_notice_assassin_fxtime", "0.1");
	g_pCvar_Message_Notice_Assassin_Holdtime = register_cvar("zpe_message_notice_assassin_holdtime", "1.5");
	g_pCvar_Message_Notice_Assassin_Fadeintime = register_cvar("zpe_message_notice_assassin_fadeintime", "2.0");
	g_pCvar_Message_Notice_Assassin_Fadeouttime = register_cvar("zpe_message_notice_assassin_fadeouttime", "1.5");
	g_pCvar_Message_Notice_Assassin_Channel = register_cvar("zpe_message_notice_assassin_channel", "-1");

	g_pCvar_All_Messages_Are_Converted = register_cvar("zpe_all_messages_are_converted", "0");
}

public plugin_precache()
{
	g_aSounds_Assassin = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "ROUND ASSASSIN", g_aSounds_Assassin);
	Precache_Sounds(g_aSounds_Assassin);
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/gamemode/zpe_assassin.cfg");

	// Register game mode at plugin_cfg (plugin gets paused after this)
	zpe_gamemodes_register("assassin");
}

// Deathmatch module's player respawn forward
public zpe_fw_deathmatch_respawn_pre(iPlayer)
{
	// Respawning allowed?
	if (!get_pcvar_num(g_pCvar_Assassin_Allow_Respawn))
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
		if (!CHANCE(get_pcvar_num(g_pCvar_Assassin_Chance)))
		{
			return PLUGIN_HANDLED;
		}

		// Min players
		if (Get_Alive_Count() < get_pcvar_num(g_pCvar_Assassin_Min_Players))
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
	zpe_class_assassin_set(g_iTarget_Player);

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_alive(i)) // Use bit - invalid player
		{
			continue;
		}

		if (zpe_class_assassin_get(i))
		{
			continue;
		}

		rg_set_user_team(i, TEAM_CT);
	}

	// Play assassin sound
	if (get_pcvar_num(g_pCvar_Assassin_Sounds))
	{
		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSounds_Assassin, RANDOM(ArraySize(g_aSounds_Assassin)), szSound, charsmax(szSound));
		Play_Sound_To_Clients(szSound);
	}

	if (get_pcvar_num(g_pCvar_Notice_Assassin_Show_Hud))
	{
		new szPlayer_Name[32];

		GET_USER_NAME(g_iTarget_Player, szPlayer_Name, charsmax(szPlayer_Name));

		if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Notice_Assassin_Converted))
		{
			set_hudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Assassin_R),
				get_pcvar_num(g_pCvar_Message_Notice_Assassin_G),
				get_pcvar_num(g_pCvar_Message_Notice_Assassin_B),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_X),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Assassin_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_Fadeouttime),
				get_pcvar_num(g_pCvar_Message_Notice_Assassin_Channel)
			);

			show_hudmessage(0, "%L", LANG_PLAYER, "NOTICE_ASSASSIN", szPlayer_Name);
		}

		else
		{
			set_dhudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Assassin_R),
				get_pcvar_num(g_pCvar_Message_Notice_Assassin_G),
				get_pcvar_num(g_pCvar_Message_Notice_Assassin_B),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_X),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Assassin_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Assassin_Fadeouttime)
			)

			show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_ASSASSIN", szPlayer_Name);
		}
	}

	new szLighting[32];

	get_pcvar_string(g_pCvar_Assassin_Lighting, szLighting, charsmax(szLighting));

	set_lights(szLighting);
}

public zpe_fw_gamemodes_end()
{
	// Execute config file (zpe_settings.cfg)
	server_cmd("exec addons/amxmodx/configs/ZPE/zpe_settings.cfg");
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