/* AMX Mod X
*	[ZPE] Team Scoring.
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

#define PLUGIN "team scoring"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <cs_util>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

// Custom sounds
new Array:g_aSound_Win_Zombies;
new Array:g_aSound_Win_Humans;
new Array:g_aSound_Win_No_One;

new g_Hud_Sync;

new g_Score_Humans;
new g_Score_Zombies;

new g_pCvar_Message_Team_Scoring;
new g_pCvar_Message_Team_Scoring_Converted;

new g_pCvar_Message_Win_Humans;
new g_pCvar_Message_Win_Humans_Converted;
new g_pCvar_Message_Win_Humans_R;
new g_pCvar_Message_Win_Humans_G;
new g_pCvar_Message_Win_Humans_B;
new g_pCvar_Message_Win_Humans_X;
new g_pCvar_Message_Win_Humans_Y;
new g_pCvar_Message_Win_Humans_Effects;
new g_pCvar_Message_Win_Humans_Fxtime;
new g_pCvar_Message_Win_Humans_Holdtime;
new g_pCvar_Message_Win_Humans_Fadeintime;
new g_pCvar_Message_Win_Humans_Fadeouttime;
new g_pCvar_Message_Win_Humans_Channel;

new g_pCvar_Message_Win_Zombies;
new g_pCvar_Message_Win_Zombies_Converted;
new g_pCvar_Message_Win_Zombies_R;
new g_pCvar_Message_Win_Zombies_G;
new g_pCvar_Message_Win_Zombies_B;
new g_pCvar_Message_Win_Zombies_X;
new g_pCvar_Message_Win_Zombies_Y;
new g_pCvar_Message_Win_Zombies_Effects;
new g_pCvar_Message_Win_Zombies_Fxtime;
new g_pCvar_Message_Win_Zombies_Holdtime;
new g_pCvar_Message_Win_Zombies_Fadeintime;
new g_pCvar_Message_Win_Zombies_Fadeouttime;
new g_pCvar_Message_Win_Zombies_Channel;

new g_pCvar_Message_Win_No_One;
new g_pCvar_Message_Win_No_One_Converted;
new g_pCvar_Message_Win_No_One_R;
new g_pCvar_Message_Win_No_One_G;
new g_pCvar_Message_Win_No_One_B;
new g_pCvar_Message_Win_No_One_X;
new g_pCvar_Message_Win_No_One_Y;
new g_pCvar_Message_Win_No_One_Effects;
new g_pCvar_Message_Win_No_One_Fxtime;
new g_pCvar_Message_Win_No_One_Holdtime;
new g_pCvar_Message_Win_No_One_Fadeintime;
new g_pCvar_Message_Win_No_One_Fadeouttime;
new g_pCvar_Message_Win_No_One_Channel;

new g_pCvar_All_Messages_Are_Converted;

new g_pCvar_Sounds_Win_Humans;
new g_pCvar_Sounds_Win_Zombies;
new g_pCvar_Sounds_Win_No_One;

new g_Message_Send_Audio;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Message_Team_Scoring = register_cvar("zpe_message_team_scoring", "1");
	g_pCvar_Message_Team_Scoring_Converted = register_cvar("zpe_message_team_scoring_converted", "0");

	g_pCvar_Message_Win_Humans = register_cvar("zpe_message_win_humans", "1");
	g_pCvar_Message_Win_Humans_Converted = register_cvar("zpe_message_win_humans_converted", "1");
	g_pCvar_Message_Win_Humans_R = register_cvar("zpe_message_win_humans_r", "0");
	g_pCvar_Message_Win_Humans_G = register_cvar("zpe_message_win_humans_g", "0");
	g_pCvar_Message_Win_Humans_B = register_cvar("zpe_message_win_humans_b", "200");
	g_pCvar_Message_Win_Humans_X = register_cvar("zpe_message_win_humans_x", "-1.0");
	g_pCvar_Message_Win_Humans_Y = register_cvar("zpe_message_win_humans_y", "0.12");
	g_pCvar_Message_Win_Humans_Effects = register_cvar("zpe_message_win_humans_effects", "0");
	g_pCvar_Message_Win_Humans_Fxtime = register_cvar("zpe_message_win_humans_fxtime", "0.0");
	g_pCvar_Message_Win_Humans_Holdtime = register_cvar("zpe_message_win_humans_holdtime", "3.0");
	g_pCvar_Message_Win_Humans_Fadeintime = register_cvar("zpe_message_win_humans_fadeintime", "2.0");
	g_pCvar_Message_Win_Humans_Fadeouttime = register_cvar("zpe_message_win_humans_fadeouttime", "1.0");
	g_pCvar_Message_Win_Humans_Channel = register_cvar("zpe_message_win_humans_channel", "-1");

	g_pCvar_Message_Win_Zombies = register_cvar("zpe_message_win_zombies", "1");
	g_pCvar_Message_Win_Zombies_Converted = register_cvar("zpe_message_win_zombies_converted", "1");
	g_pCvar_Message_Win_Zombies_R = register_cvar("zpe_message_win_zombies_r", "200");
	g_pCvar_Message_Win_Zombies_G = register_cvar("zpe_message_win_zombies_g", "0");
	g_pCvar_Message_Win_Zombies_B = register_cvar("zpe_message_win_zombies_b", "0");
	g_pCvar_Message_Win_Zombies_X = register_cvar("zpe_message_win_zombies_x", "-1.0");
	g_pCvar_Message_Win_Zombies_Y = register_cvar("zpe_message_win_zombies_y", "0.12");
	g_pCvar_Message_Win_Zombies_Effects = register_cvar("zpe_message_win_zombies_effects", "0");
	g_pCvar_Message_Win_Zombies_Fxtime = register_cvar("zpe_message_win_zombies_fxtime", "0.0");
	g_pCvar_Message_Win_Zombies_Holdtime = register_cvar("zpe_message_win_zombies_holdtime", "3.0");
	g_pCvar_Message_Win_Zombies_Fadeintime = register_cvar("zpe_message_win_zombies_fadeintime", "2.0");
	g_pCvar_Message_Win_Zombies_Fadeouttime = register_cvar("zpe_message_win_zombies_fadeouttime", "1.0");
	g_pCvar_Message_Win_Zombies_Channel = register_cvar("zpe_message_win_zombies_channel", "-1");

	g_pCvar_Message_Win_No_One = register_cvar("zpe_message_win_no_one", "1");
	g_pCvar_Message_Win_No_One_Converted = register_cvar("zpe_message_win_no_one_converted", "1");
	g_pCvar_Message_Win_No_One_R = register_cvar("zpe_message_win_no_one_r", "200");
	g_pCvar_Message_Win_No_One_G = register_cvar("zpe_message_win_no_one_g", "0");
	g_pCvar_Message_Win_No_One_B = register_cvar("zpe_message_win_no_one_b", "0");
	g_pCvar_Message_Win_No_One_X = register_cvar("zpe_message_win_no_one_x", "-1.0");
	g_pCvar_Message_Win_No_One_Y = register_cvar("zpe_message_win_no_one_y", "0.12");
	g_pCvar_Message_Win_No_One_Effects = register_cvar("zpe_message_win_no_one_effects", "0");
	g_pCvar_Message_Win_No_One_Fxtime = register_cvar("zpe_message_win_no_one_fxtime", "0.0");
	g_pCvar_Message_Win_No_One_Holdtime = register_cvar("zpe_message_win_no_one_holdtime", "3.0");
	g_pCvar_Message_Win_No_One_Fadeintime = register_cvar("zpe_message_win_no_one_fadeintime", "2.0");
	g_pCvar_Message_Win_No_One_Fadeouttime = register_cvar("zpe_message_win_no_one_fadeouttime", "1.0");
	g_pCvar_Message_Win_No_One_Channel = register_cvar("zpe_message_win_no_one_channel", "-1");

	g_pCvar_All_Messages_Are_Converted = register_cvar("zpe_all_messages_are_converted", "0");

	g_pCvar_Sounds_Win_Humans = register_cvar("zpe_sounds_win_humans", "1");
	g_pCvar_Sounds_Win_Zombies = register_cvar("zpe_sounds_win_zombies", "1");
	g_pCvar_Sounds_Win_No_One = register_cvar("zpe_sounds_win_no_one", "1");

	// Create the HUD Sync Objects
	g_Hud_Sync = CreateHudSyncObj();

	g_Message_Send_Audio = get_user_msgid("SendAudio")

	register_message(g_Message_Send_Audio, "SendAudio_");
	register_message(get_user_msgid("TextMsg"), "TextMsg_");
	register_message(get_user_msgid("TeamScore"), "TeamScore_");
}

public plugin_precache()
{
	g_aSound_Win_Zombies = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Win_Humans = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Win_No_One = ArrayCreate(SOUND_MAX_LENGTH, 1);

	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "WIN HUMANS", g_aSound_Win_Humans);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "WIN ZOMBIES", g_aSound_Win_Zombies);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "WIN NO ONE", g_aSound_Win_No_One);

	Precache_Sounds(g_aSound_Win_Humans);
	Precache_Sounds(g_aSound_Win_Zombies);
	Precache_Sounds(g_aSound_Win_No_One);
}

// Block some text messages
public TextMsg_()
{
	new szText_Message[22];

	get_msg_arg_string(2, szText_Message, charsmax(szText_Message));

	// Game restarting/game commencing, reset scores
	if (equal(szText_Message, "#Game_will_restart_in") || equal(szText_Message, "#Game_Commencing"))
	{
		g_Score_Humans = 0;
		g_Score_Zombies = 0;

		Message_Round_End();
	}

	// Block round end related messages
	else if (equal(szText_Message, "#Hostages_Not_Rescued") || equal(szText_Message, "#Round_Draw") || equal(szText_Message, "#Terrorists_Win") || equal(szText_Message, "#CTs_Win"))
	{
		Message_Round_End();

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

// Block CS round win audio messages, since we're playing our own instead
public SendAudio_()
{
	new szAudio[17];

	get_msg_arg_string(2, szAudio, charsmax(szAudio));

	if (equal(szAudio[7], "terwin") || equal(szAudio[7], "ctwin") || equal(szAudio[7], "rounddraw"))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

// Send actual team scores (T = zombies // CT = humans)
public TeamScore_()
{
	new szTeam[2];

	get_msg_arg_string(1, szTeam, charsmax(szTeam));

	switch (szTeam[0])
	{
		// CT
		case 'C':
		{
			set_msg_arg_int(2, get_msg_argtype(2), g_Score_Humans);
		}

		// Terrorist
		case 'T':
		{
			set_msg_arg_int(2, get_msg_argtype(2), g_Score_Zombies);
		}
	}
}

Message_Round_End()
{
	// Determine round winner, show HUD notice
	if (!zpe_core_get_zombie_count())
	{
		// Human team wins
		if (get_pcvar_num(g_pCvar_Message_Team_Scoring))
		{
			if (get_pcvar_num(g_pCvar_Message_Win_Humans))
			{
				if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Team_Scoring_Converted) || get_pcvar_num(g_pCvar_Message_Win_Humans_Converted))
				{
					set_hudmessage
					(
						get_pcvar_num(g_pCvar_Message_Win_Humans_R),
						get_pcvar_num(g_pCvar_Message_Win_Humans_G),
						get_pcvar_num(g_pCvar_Message_Win_Humans_B),
						get_pcvar_float(g_pCvar_Message_Win_Humans_X),
						get_pcvar_float(g_pCvar_Message_Win_Humans_Y),
						get_pcvar_num(g_pCvar_Message_Win_Humans_Effects),
						get_pcvar_float(g_pCvar_Message_Win_Humans_Fxtime),
						get_pcvar_float(g_pCvar_Message_Win_Humans_Holdtime),
						get_pcvar_float(g_pCvar_Message_Win_Humans_Fadeintime),
						get_pcvar_float(g_pCvar_Message_Win_Humans_Fadeouttime),
						get_pcvar_num(g_pCvar_Message_Win_Humans_Channel)
					);

					ShowSyncHudMsg(0, g_Hud_Sync, "%L", LANG_PLAYER, "WIN_HUMAN");
				}

				else
				{
					set_dhudmessage
					(
						get_pcvar_num(g_pCvar_Message_Win_Humans_R),
						get_pcvar_num(g_pCvar_Message_Win_Humans_G),
						get_pcvar_num(g_pCvar_Message_Win_Humans_B),
						get_pcvar_float(g_pCvar_Message_Win_Humans_X),
						get_pcvar_float(g_pCvar_Message_Win_Humans_Y),
						get_pcvar_num(g_pCvar_Message_Win_Humans_Effects),
						get_pcvar_float(g_pCvar_Message_Win_Humans_Fxtime),
						get_pcvar_float(g_pCvar_Message_Win_Humans_Holdtime),
						get_pcvar_float(g_pCvar_Message_Win_Humans_Fadeintime),
						get_pcvar_float(g_pCvar_Message_Win_Humans_Fadeouttime)
					);

					show_dhudmessage(0, "%L", LANG_PLAYER, "WIN_HUMAN");
				}
			}
		}

		if (get_pcvar_num(g_pCvar_Sounds_Win_Humans))
		{
			new szSound[SOUND_MAX_LENGTH];
			ArrayGetString(g_aSound_Win_Humans, RANDOM(ArraySize(g_aSound_Win_Humans)), szSound, charsmax(szSound));
			Play_Sound_To_Clients(szSound);
		}

		g_Score_Humans++;
	}

	else if (!zpe_core_get_human_count())
	{
		// Zombie team wins
		if (get_pcvar_num(g_pCvar_Message_Team_Scoring))
		{
			if (get_pcvar_num(g_pCvar_Message_Win_Zombies))
			{
				if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Team_Scoring_Converted) || get_pcvar_num(g_pCvar_Message_Win_Zombies_Converted))
				{
					set_hudmessage
					(
						get_pcvar_num(g_pCvar_Message_Win_Zombies_R),
						get_pcvar_num(g_pCvar_Message_Win_Zombies_G),
						get_pcvar_num(g_pCvar_Message_Win_Zombies_B),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_X),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_Y),
						get_pcvar_num(g_pCvar_Message_Win_Zombies_Effects),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_Fxtime),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_Holdtime),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_Fadeintime),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_Fadeouttime),
						get_pcvar_num(g_pCvar_Message_Win_Zombies_Channel)
					);

					ShowSyncHudMsg(0, g_Hud_Sync, "%L", LANG_PLAYER, "WIN_ZOMBIE");
				}

				else
				{
					set_dhudmessage
					(
						get_pcvar_num(g_pCvar_Message_Win_Zombies_R),
						get_pcvar_num(g_pCvar_Message_Win_Zombies_G),
						get_pcvar_num(g_pCvar_Message_Win_Zombies_B),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_X),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_Y),
						get_pcvar_num(g_pCvar_Message_Win_Zombies_Effects),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_Fxtime),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_Holdtime),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_Fadeintime),
						get_pcvar_float(g_pCvar_Message_Win_Zombies_Fadeouttime)
					);

					show_dhudmessage(0, "%L", LANG_PLAYER, "WIN_ZOMBIE");
				}
			}
		}

		if (get_pcvar_num(g_pCvar_Sounds_Win_Zombies))
		{
			new szSound[SOUND_MAX_LENGTH];
			ArrayGetString(g_aSound_Win_Zombies, RANDOM(ArraySize(g_aSound_Win_Zombies)), szSound, charsmax(szSound));
			Play_Sound_To_Clients(szSound);
		}

		g_Score_Zombies++;
	}

	else
	{
		// No one wins
		if (get_pcvar_num(g_pCvar_Message_Team_Scoring))
		{
			if (get_pcvar_num(g_pCvar_Message_Win_No_One))
			{
				if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Team_Scoring_Converted) || get_pcvar_num(g_pCvar_Message_Win_No_One_Converted))
				{
					set_hudmessage
					(
						get_pcvar_num(g_pCvar_Message_Win_No_One_R),
						get_pcvar_num(g_pCvar_Message_Win_No_One_G),
						get_pcvar_num(g_pCvar_Message_Win_No_One_B),
						get_pcvar_float(g_pCvar_Message_Win_No_One_X),
						get_pcvar_float(g_pCvar_Message_Win_No_One_Y),
						get_pcvar_num(g_pCvar_Message_Win_No_One_Effects),
						get_pcvar_float(g_pCvar_Message_Win_No_One_Fxtime),
						get_pcvar_float(g_pCvar_Message_Win_No_One_Holdtime),
						get_pcvar_float(g_pCvar_Message_Win_No_One_Fadeintime),
						get_pcvar_float(g_pCvar_Message_Win_No_One_Fadeouttime),
						get_pcvar_num(g_pCvar_Message_Win_No_One_Channel)
					);

					ShowSyncHudMsg(0, g_Hud_Sync, "%L", LANG_PLAYER, "WIN_NO_ONE");
				}

				else
				{
					set_dhudmessage
					(
						get_pcvar_num(g_pCvar_Message_Win_No_One_R),
						get_pcvar_num(g_pCvar_Message_Win_No_One_G),
						get_pcvar_num(g_pCvar_Message_Win_No_One_B),
						get_pcvar_float(g_pCvar_Message_Win_No_One_X),
						get_pcvar_float(g_pCvar_Message_Win_No_One_Y),
						get_pcvar_num(g_pCvar_Message_Win_No_One_Effects),
						get_pcvar_float(g_pCvar_Message_Win_No_One_Fxtime),
						get_pcvar_float(g_pCvar_Message_Win_No_One_Holdtime),
						get_pcvar_float(g_pCvar_Message_Win_No_One_Fadeintime),
						get_pcvar_float(g_pCvar_Message_Win_No_One_Fadeouttime)
					);

					show_dhudmessage(0, "%L", LANG_PLAYER, "WIN_NO_ONE");
				}
			}
		}

		if (get_pcvar_num(g_pCvar_Sounds_Win_No_One))
		{
			new szSound[SOUND_MAX_LENGTH];
			ArrayGetString(g_aSound_Win_No_One, RANDOM(ArraySize(g_aSound_Win_No_One)), szSound, charsmax(szSound));
			Play_Sound_To_Clients(szSound);
		}
	}
}

// Plays a sound on clients
Play_Sound_To_Clients(const szSound[])
{
	if (Ends_With(szSound, ".mp3"))
	{
		client_cmd(0, "stopsound; mp3 play ^"sound/%s^"", szSound);
	}

	else
	{
		client_cmd(0, "mp3 stop; stopsound; spk ^"%s^"", szSound);
	}
}