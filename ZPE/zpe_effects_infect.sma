/* AMX Mod X
*	[ZPE] Effects Infect.
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

#define PLUGIN "effects infect"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <fakemeta>
#include <zpe_kernel>

#define UNIT_SECOND (1 << 12)

// Some constants
#define FFADE_IN 0x0000

new g_pCvar_Infect_Show_Hud;
new g_pCvar_Infect_Show_Notice;

new g_pCvar_Infect_Screen_Fade;
new g_pCvar_Infect_Screen_Fade_R;
new g_pCvar_Infect_Screen_Fade_G;
new g_pCvar_Infect_Screen_Fade_B;

new g_Cvar_Infect_Screen_Shake;
new g_pCvar_Infect_Hud_Icon;
new g_pCvar_Infect_Tracers;
new g_pCvar_Infect_Particles;

new g_pCvar_Infect_Sparkle;
new g_pCvar_Infect_Sparkle_R;
new g_pCvar_Infect_Sparkle_G;
new g_pCvar_Infect_Sparkle_B;

new g_pCvar_Message_Global_Infection_Converted;
new g_pCvar_Message_Global_Infection_R;
new g_pCvar_Message_Global_Infection_G;
new g_pCvar_Message_Global_Infection_B;
new g_pCvar_Message_Global_Infection_X;
new g_pCvar_Message_Global_Infection_Y;
new g_pCvar_Message_Global_Infection_Effects;
new g_pCvar_Message_Global_Infection_Fxtime;
new g_pCvar_Message_Global_Infection_Holdtime;
new g_pCvar_Message_Global_Infection_Fadeintime;
new g_pCvar_Message_Global_Infection_Fadeouttime;
new g_pCvar_Message_Global_Infection_Channel;

new g_pCvar_Message_Infection_Converted;
new g_pCvar_Message_Infection_R;
new g_pCvar_Message_Infection_G;
new g_pCvar_Message_Infection_B;
new g_pCvar_Message_Infection_X;
new g_pCvar_Message_Infection_Y;
new g_pCvar_Message_Infection_Effects;
new g_pCvar_Message_Infection_Fxtime;
new g_pCvar_Message_Infection_Holdtime;
new g_pCvar_Message_Infection_Fadeintime;
new g_pCvar_Message_Infection_Fadeouttime;
new g_pCvar_Message_Infection_Channel;

new g_pCvar_All_Messages_Are_Converted;

new g_Message_Death;
new g_Message_Score_Attrib;

new g_Message_Damage;

new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Infect_Show_Hud = register_cvar("zpe_infect_show_hud", "1");
	g_pCvar_Infect_Show_Notice = register_cvar("zpe_infect_show_notice", "1");

	g_pCvar_Infect_Screen_Fade = register_cvar("zpe_infect_screen_fade", "1");
	g_pCvar_Infect_Screen_Fade_R = register_cvar("zpe_infect_screen_fade_r", "0");
	g_pCvar_Infect_Screen_Fade_G = register_cvar("zpe_infect_screen_fade_g", "150");
	g_pCvar_Infect_Screen_Fade_B = register_cvar("zpe_infect_screen_fade_b", "0");

	g_Cvar_Infect_Screen_Shake = register_cvar("zpe_infect_screen_shake", "1");
	g_pCvar_Infect_Hud_Icon = register_cvar("zpe_infect_hud_icon", "1");
	g_pCvar_Infect_Tracers = register_cvar("zpe_infect_tracers", "1");
	g_pCvar_Infect_Particles = register_cvar("zpe_infect_particles", "1");

	g_pCvar_Infect_Sparkle = register_cvar("zpe_infect_sparkle", "1");
	g_pCvar_Infect_Sparkle_R = register_cvar("zpe_infect_sparkle_r", "0");
	g_pCvar_Infect_Sparkle_G = register_cvar("zpe_infect_sparkle_g", "150");
	g_pCvar_Infect_Sparkle_B = register_cvar("zpe_infect_sparkle_b", "0");

	g_pCvar_Message_Global_Infection_Converted = register_cvar("zpe_message_global_infection_converted", "0");
	g_pCvar_Message_Global_Infection_R = register_cvar("zpe_message_global_infection_r", "0");
	g_pCvar_Message_Global_Infection_G = register_cvar("zpe_message_global_infection_g", "250");
	g_pCvar_Message_Global_Infection_B = register_cvar("zpe_message_global_infection_b", "0");
	g_pCvar_Message_Global_Infection_X = register_cvar("zpe_message_global_infection_x", "-1.0");
	g_pCvar_Message_Global_Infection_Y = register_cvar("zpe_message_global_infection_y", "0.75");
	g_pCvar_Message_Global_Infection_Effects = register_cvar("zpe_message_global_infection_effects", "0");
	g_pCvar_Message_Global_Infection_Fxtime = register_cvar("zpe_message_global_infection_fxtime", "0.1");
	g_pCvar_Message_Global_Infection_Holdtime = register_cvar("zpe_message_global_infection_holdtime", "1.5");
	g_pCvar_Message_Global_Infection_Fadeintime = register_cvar("zpe_message_global_infection_fadeintime", "2.0");
	g_pCvar_Message_Global_Infection_Fadeouttime = register_cvar("zpe_message_global_infection_fadeouttime", "1.5");
	g_pCvar_Message_Global_Infection_Channel = register_cvar("zpe_message_global_infection_channel", "-1");

	g_pCvar_Message_Infection_Converted = register_cvar("zpe_message_infection_converted", "0");
	g_pCvar_Message_Infection_R = register_cvar("zpe_message_infection_r", "0");
	g_pCvar_Message_Infection_G = register_cvar("zpe_message_infection_g", "250");
	g_pCvar_Message_Infection_B = register_cvar("zpe_message_infection_b", "0");
	g_pCvar_Message_Infection_X = register_cvar("zpe_message_infection_x", "-1.0");
	g_pCvar_Message_Infection_Y = register_cvar("zpe_message_infection_y", "0.75");
	g_pCvar_Message_Infection_Effects = register_cvar("zpe_message_infection_effects", "0");
	g_pCvar_Message_Infection_Fxtime = register_cvar("zpe_message_infection_fxtime", "0.1");
	g_pCvar_Message_Infection_Holdtime = register_cvar("zpe_message_infection_holdtime", "1.5");
	g_pCvar_Message_Infection_Fadeintime = register_cvar("zpe_message_infection_fadeintime", "2.0");
	g_pCvar_Message_Infection_Fadeouttime = register_cvar("zpe_message_infection_fadeouttime", "1.5");
	g_pCvar_Message_Infection_Channel = register_cvar("zpe_message_infection_channel", "-1");

	g_pCvar_All_Messages_Are_Converted = register_cvar("zpe_all_messages_are_converted", "0");

	g_Message_Death = get_user_msgid("DeathMsg");
	g_Message_Score_Attrib = get_user_msgid("ScoreAttrib");

	g_Message_Damage = get_user_msgid("Damage");
}

public zpe_fw_core_infect_post(iPlayer, iAttacker)
{
	// Attacker is valid?
	if (BIT_VALID(g_iBit_Connected, iAttacker))
	{
		// Player infected himself
		if (iAttacker == iPlayer)
		{
			// Show infection HUD notice? (except for first zombie)
			if (get_pcvar_num(g_pCvar_Infect_Show_Hud) && !zpe_core_is_first_zombie(iPlayer))
			{
				new szVictim_Name[32];

				GET_USER_NAME(iPlayer, szVictim_Name, charsmax(szVictim_Name));

				if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Global_Infection_Converted))
				{
					set_hudmessage
					(
						get_pcvar_num(g_pCvar_Message_Global_Infection_R),
						get_pcvar_num(g_pCvar_Message_Global_Infection_G),
						get_pcvar_num(g_pCvar_Message_Global_Infection_B),
						get_pcvar_float(g_pCvar_Message_Global_Infection_X),
						get_pcvar_float(g_pCvar_Message_Global_Infection_Y),
						get_pcvar_num(g_pCvar_Message_Global_Infection_Effects),
						get_pcvar_float(g_pCvar_Message_Global_Infection_Fxtime),
						get_pcvar_float(g_pCvar_Message_Global_Infection_Holdtime),
						get_pcvar_float(g_pCvar_Message_Global_Infection_Fadeintime),
						get_pcvar_float(g_pCvar_Message_Global_Infection_Fadeouttime),
						get_pcvar_num(g_pCvar_Message_Global_Infection_Channel)
					);

					show_hudmessage(0, "%L", LANG_PLAYER, "NOTICE_INFECT", szVictim_Name);
				}

				else
				{
					set_dhudmessage
					(
						get_pcvar_num(g_pCvar_Message_Global_Infection_R),
						get_pcvar_num(g_pCvar_Message_Global_Infection_G),
						get_pcvar_num(g_pCvar_Message_Global_Infection_B),
						get_pcvar_float(g_pCvar_Message_Global_Infection_X),
						get_pcvar_float(g_pCvar_Message_Global_Infection_Y),
						get_pcvar_num(g_pCvar_Message_Global_Infection_Effects),
						get_pcvar_float(g_pCvar_Message_Global_Infection_Fxtime),
						get_pcvar_float(g_pCvar_Message_Global_Infection_Holdtime),
						get_pcvar_float(g_pCvar_Message_Global_Infection_Fadeintime),
						get_pcvar_float(g_pCvar_Message_Global_Infection_Fadeouttime)
					);

					show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_INFECT", szVictim_Name);
				}
			}
		}

		else
		{
			// Show infection HUD notice?
			if (get_pcvar_num(g_pCvar_Infect_Show_Hud))
			{
				new szAttacker_Name[32];
				new szVictim_Name[32];

				GET_USER_NAME(iAttacker, szAttacker_Name, charsmax(szAttacker_Name));
				GET_USER_NAME(iPlayer, szVictim_Name, charsmax(szVictim_Name));

				if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Infection_Converted))
				{
					set_hudmessage
					(
						get_pcvar_num(g_pCvar_Message_Infection_R),
						get_pcvar_num(g_pCvar_Message_Infection_G),
						get_pcvar_num(g_pCvar_Message_Infection_B),
						get_pcvar_float(g_pCvar_Message_Infection_X),
						get_pcvar_float(g_pCvar_Message_Infection_Y),
						get_pcvar_num(g_pCvar_Message_Infection_Effects),
						get_pcvar_float(g_pCvar_Message_Infection_Fxtime),
						get_pcvar_float(g_pCvar_Message_Infection_Holdtime),
						get_pcvar_float(g_pCvar_Message_Infection_Fadeintime),
						get_pcvar_float(g_pCvar_Message_Infection_Fadeouttime),
						get_pcvar_num(g_pCvar_Message_Infection_Channel)
					);

					show_hudmessage(0, "%L", LANG_PLAYER, "NOTICE_INFECT2", szVictim_Name, szAttacker_Name);
				}

				else
				{
					set_dhudmessage
					(
						get_pcvar_num(g_pCvar_Message_Infection_R),
						get_pcvar_num(g_pCvar_Message_Infection_G),
						get_pcvar_num(g_pCvar_Message_Infection_B),
						get_pcvar_float(g_pCvar_Message_Infection_X),
						get_pcvar_float(g_pCvar_Message_Infection_Y),
						get_pcvar_num(g_pCvar_Message_Infection_Effects),
						get_pcvar_float(g_pCvar_Message_Infection_Fxtime),
						get_pcvar_float(g_pCvar_Message_Infection_Holdtime),
						get_pcvar_float(g_pCvar_Message_Infection_Fadeintime),
						get_pcvar_float(g_pCvar_Message_Infection_Fadeouttime)
					);

					show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_INFECT2", szVictim_Name, szAttacker_Name);
				}
			}

			// Show infection death notice?
			if (get_pcvar_num(g_pCvar_Infect_Show_Notice))
			{
				// Send death notice and fix the "dead" attrib on scoreboard
				Send_Death_Message(iAttacker, iPlayer);

				Fix_Dead_Attrib(iPlayer);
			}
		}
	}

	// Infection special effects
	Infection_Effects(iPlayer);
}

Infection_Effects(iPlayer)
{
	// Screen fade?
	if (get_pcvar_num(g_pCvar_Infect_Screen_Fade))
	{
		UTIL_ScreenFade(iPlayer, UNIT_SECOND, 0, FFADE_IN, get_pcvar_num(g_pCvar_Infect_Screen_Fade_R), get_pcvar_num(g_pCvar_Infect_Screen_Fade_G), get_pcvar_num(g_pCvar_Infect_Screen_Fade_B), 255, 0);
	}

	// Screen shake?
	if (get_pcvar_num(g_Cvar_Infect_Screen_Shake))
	{
		UTIL_ScreenShake(iPlayer, UNIT_SECOND * 4, UNIT_SECOND * 2, UNIT_SECOND * 10);
	}

	// Infection icon?
	if (get_pcvar_num(g_pCvar_Infect_Hud_Icon))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Message_Damage, _, iPlayer);
		write_byte(0); // damage save
		write_byte(0); // damage take
		write_long(DMG_NERVEGAS); // damage type - DMG_RADIATION
		write_coord(0); // x
		write_coord(0); // y
		write_coord(0); // z
		message_end();
	}

	// Get player's origin
	new iOrigin[3];

	get_user_origin(iPlayer, iOrigin);

	// Tracers?
	if (get_pcvar_num(g_pCvar_Infect_Tracers))
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_IMPLOSION); // TE player
		write_coord(iOrigin[0]); // x
		write_coord(iOrigin[1]); // y
		write_coord(iOrigin[2]); // z
		write_byte(128); // radius
		write_byte(20); // count
		write_byte(3); // duration
		message_end();
	}

	// Particle burst?
	if (get_pcvar_num(g_pCvar_Infect_Particles))
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_PARTICLEBURST); // TE player
		write_coord(iOrigin[0]); // x
		write_coord(iOrigin[1]); // y
		write_coord(iOrigin[2]); // z
		write_short(50); // radius
		write_byte(70); // color
		write_byte(3); // duration (will be randomized a bit)
		message_end();
	}

	// Light sparkle?
	if (get_pcvar_num(g_pCvar_Infect_Sparkle))
	{
		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_DLIGHT); // TE player
		write_coord(iOrigin[0]); // x
		write_coord(iOrigin[1]); // y
		write_coord(iOrigin[2]); // z
		write_byte(20); // radius
		write_byte(get_pcvar_num(g_pCvar_Infect_Sparkle_R)); // r
		write_byte(get_pcvar_num(g_pCvar_Infect_Sparkle_G)); // g
		write_byte(get_pcvar_num(g_pCvar_Infect_Sparkle_B)); // b
		write_byte(2); // life
		write_byte(0); // decay rate
		message_end();
	}
}

// Send Death Message for infections
Send_Death_Message(iAttacker, iVictim)
{
	message_begin(MSG_BROADCAST, g_Message_Death);
	write_byte(iAttacker); // killer
	write_byte(iVictim); // victim
	write_byte(1); // headshot flag
	write_string("infection"); // killer's weapon
	message_end();
}

// Fix dead attrib on scoreboard
Fix_Dead_Attrib(iPlayer)
{
	message_begin(MSG_BROADCAST, g_Message_Score_Attrib);
	write_byte(iPlayer); // player
	write_byte(0); // attrib
	message_end();
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	BIT_SUB(g_iBit_Connected, iPlayer);
}