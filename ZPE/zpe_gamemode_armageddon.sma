/* AMX Mod X
*	[ZPE] Gamemode Armageddon.
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

#define PLUGIN "gamemode armageddon"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_gamemodes>
#include <zpe_class_nemesis>
#include <zpe_class_survivor>
#include <zpe_deathmatch>

#define ZPE_SETTINGS_FILE "ZPE/gamemode/zpe_armageddon.ini"

new Array:g_aSound_Armageddon;

new g_pCvar_Armageddon_Chance;
new g_pCvar_Armageddon_Min_Players;
new g_pCvar_Armageddon_Ratio;
new g_pCvar_Armageddon_Nemesis_HP_Multi;
new g_pCvar_Armageddon_Survivor_HP_Multi;
new g_pCvar_Armageddon_Sounds;
new g_pCvar_Armageddon_Allow_Respawn;

new g_pCvar_Notice_Armageddon_Show_Hud;

new g_pCvar_Message_Notice_Armageddon_Converted;
new g_pCvar_Message_Notice_Armageddon_R;
new g_pCvar_Message_Notice_Armageddon_G;
new g_pCvar_Message_Notice_Armageddon_B;
new g_pCvar_Message_Notice_Armageddon_X;
new g_pCvar_Message_Notice_Armageddon_Y;
new g_pCvar_Message_Notice_Armageddon_Effects;
new g_pCvar_Message_Notice_Armageddon_Fxtime;
new g_pCvar_Message_Notice_Armageddon_Holdtime;
new g_pCvar_Message_Notice_Armageddon_Fadeintime;
new g_pCvar_Message_Notice_Armageddon_Fadeouttime;
new g_pCvar_Message_Notice_Armageddon_Channel;

new g_pCvar_All_Messages_Are_Converted;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Armageddon_Chance = register_cvar("zpe_armageddon_chance", "20");
	g_pCvar_Armageddon_Min_Players = register_cvar("zpe_armageddon_min_players", "0");
	g_pCvar_Armageddon_Ratio = register_cvar("zpe_armageddon_ratio", "0.5");
	g_pCvar_Armageddon_Nemesis_HP_Multi = register_cvar("zpe_armageddon_nemesis_hp_multi", "0.25");
	g_pCvar_Armageddon_Survivor_HP_Multi = register_cvar("zpe_armageddon_survivor_hp_multi", "0.25");
	g_pCvar_Armageddon_Sounds = register_cvar("zpe_armageddon_sounds", "1");
	g_pCvar_Armageddon_Allow_Respawn = register_cvar("zpe_armageddon_allow_respawn", "0");

	g_pCvar_Notice_Armageddon_Show_Hud = register_cvar("zpe_notice_armageddon_show_hud", "1");

	g_pCvar_Message_Notice_Armageddon_Converted = register_cvar("zpe_message_notice_armageddon_converted", "0");
	g_pCvar_Message_Notice_Armageddon_R = register_cvar("zpe_message_notice_armageddon_r", "0");
	g_pCvar_Message_Notice_Armageddon_G = register_cvar("zpe_message_notice_armageddon_g", "250");
	g_pCvar_Message_Notice_Armageddon_B = register_cvar("zpe_message_notice_armageddon_b", "0");
	g_pCvar_Message_Notice_Armageddon_X = register_cvar("zpe_message_notice_armageddon_x", "-1.0");
	g_pCvar_Message_Notice_Armageddon_Y = register_cvar("zpe_message_notice_armageddon_y", "0.75");
	g_pCvar_Message_Notice_Armageddon_Effects = register_cvar("zpe_message_notice_armageddon_effects", "0");
	g_pCvar_Message_Notice_Armageddon_Fxtime = register_cvar("zpe_message_notice_armageddon_fxtime", "0.1");
	g_pCvar_Message_Notice_Armageddon_Holdtime = register_cvar("zpe_message_notice_armageddon_holdtime", "1.5");
	g_pCvar_Message_Notice_Armageddon_Fadeintime = register_cvar("zpe_message_notice_armageddon_fadeintime", "2.0");
	g_pCvar_Message_Notice_Armageddon_Fadeouttime = register_cvar("zpe_message_notice_armageddon_fadeouttime", "1.5");
	g_pCvar_Message_Notice_Armageddon_Channel = register_cvar("zpe_message_notice_armageddon_channel", "-1");

	g_pCvar_All_Messages_Are_Converted = register_cvar("zpe_all_messages_are_converted", "0");
}

public plugin_precache()
{
	g_aSound_Armageddon = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "ROUND ARMAGEDDON", g_aSound_Armageddon);
	Precache_Sounds(g_aSound_Armageddon);
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/gamemode/zpe_armageddon.cfg");

	// Register game mode at plugin_cfg (plugin gets paused after this)
	zpe_gamemodes_register("armageddon");
}

// Deathmatch module's player respawn forward
public zpe_fw_deathmatch_respawn_pre(iPlayer)
{
	// Respawning allowed?
	if (!get_pcvar_num(g_pCvar_Armageddon_Allow_Respawn))
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
		if (!CHANCE(get_pcvar_num(g_pCvar_Armageddon_Chance)))
		{
			return PLUGIN_HANDLED;
		}

		// Min players
		if (Get_Alive_Count() < get_pcvar_num(g_pCvar_Armageddon_Min_Players))
		{
			return PLUGIN_HANDLED;
		}
	}

	// Game mode allowed
	return PLUGIN_CONTINUE;
}

public zpe_fw_gamemodes_start()
{
	// Calculate player counts
	new iPlayer;
	new iAlive_Count = Get_Alive_Count();
	new iSurvivor_Count = floatround(iAlive_Count * get_pcvar_float(g_pCvar_Armageddon_Ratio), floatround_ceil);
	new iNemesis_Count = iAlive_Count - iSurvivor_Count;

	// Turn specified amount of players into Survivors
	new iSurvivors;
	new iMax_Survivors = iSurvivor_Count;

	while (iSurvivors < iMax_Survivors)
	{
		// Choose random guy
		iPlayer = Get_Random_Alive_Player();

		// Already a survivor?
		if (zpe_class_survivor_get(iPlayer))
		{
			continue;
		}

		// If not, turn him into one
		zpe_class_survivor_set(iPlayer);

		iSurvivors++;

		// Apply survivor health multiplier
		SET_USER_HEALTH(iPlayer, Float:GET_USER_HEALTH(iPlayer) * get_pcvar_float(g_pCvar_Armageddon_Survivor_HP_Multi));
	}

	// Turn specified amount of players into Nemesis
	new iNemesis;
	new iMax_Nemesis = iNemesis_Count;

	while (iNemesis < iMax_Nemesis)
	{
		// Choose random guy
		iPlayer = Get_Random_Alive_Player();

		// Already a survivor or nemesis?
		if (zpe_class_survivor_get(iPlayer) || zpe_class_nemesis_get(iPlayer))
		{
			continue;
		}

		// If not, turn him into one
		zpe_class_nemesis_set(iPlayer);

		iNemesis++;

		// Apply nemesis health multiplier
		SET_USER_HEALTH(iPlayer, Float:GET_USER_HEALTH(iPlayer) * get_pcvar_float(g_pCvar_Armageddon_Nemesis_HP_Multi));
	}

	if (get_pcvar_num(g_pCvar_Armageddon_Sounds))
	{
		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSound_Armageddon, RANDOM(ArraySize(g_aSound_Armageddon)), szSound, charsmax(szSound));
		Play_Sound_To_Clients(szSound);
	}

	if (get_pcvar_num(g_pCvar_Notice_Armageddon_Show_Hud))
	{
		if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Notice_Armageddon_Converted))
		{
			set_hudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Armageddon_R),
				get_pcvar_num(g_pCvar_Message_Notice_Armageddon_G),
				get_pcvar_num(g_pCvar_Message_Notice_Armageddon_B),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_X),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Armageddon_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_Fadeouttime),
				get_pcvar_num(g_pCvar_Message_Notice_Armageddon_Channel)
			);

			show_hudmessage(0, "%L", LANG_PLAYER, "NOTICE_ARMAGEDDON");
		}

		else
		{
			set_dhudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Armageddon_R),
				get_pcvar_num(g_pCvar_Message_Notice_Armageddon_G),
				get_pcvar_num(g_pCvar_Message_Notice_Armageddon_B),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_X),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Armageddon_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Armageddon_Fadeouttime)
			);

			show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_ARMAGEDDON");
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