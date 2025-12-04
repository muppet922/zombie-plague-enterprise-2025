/* AMX Mod X
*	[ZPE] Rewards Frags HP.
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

#define PLUGIN "rewards frags hp"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <cstrike>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

new g_Message_Score_Info;
new g_Last_Human_Health_Rewarded;
new g_Game_Mode_Started;

new g_pCvar_Frags_Zombie_Killed;
new g_pCvar_Frags_Human_Killed;

new g_pCvar_Frags_Human_Infected;

new g_pCvar_Frags_Nemesis_Ignore;
new g_pCvar_Frags_Assassin_Ignore;
new g_pCvar_Frags_Survivor_Ignore;
new g_pCvar_Frags_Sniper_Ignore;

new g_pCvar_Infection_Health_Bonus;
new g_pCvar_Human_Last_Health_Bonus;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Frags_Zombie_Killed = register_cvar("zpe_frags_zombie_killed", "1");
	g_pCvar_Frags_Human_Killed = register_cvar("zpe_frags_human_killed", "1");

	g_pCvar_Frags_Human_Infected = register_cvar("zpe_frags_human_infected", "1");

	g_pCvar_Frags_Nemesis_Ignore = register_cvar("zpe_frags_nemesis_ignore", "0");
	g_pCvar_Frags_Assassin_Ignore = register_cvar("zpe_frags_assassin_ignore", "0");
	g_pCvar_Frags_Survivor_Ignore = register_cvar("zpe_frags_survivor_ignore", "0");
	g_pCvar_Frags_Sniper_Ignore = register_cvar("zpe_frags_sniper_ignore", "0");

	g_pCvar_Infection_Health_Bonus = register_cvar("zpe_infection_health_bonus", "100.0");
	g_pCvar_Human_Last_Health_Bonus = register_cvar("zpe_human_last_health_bonus", "50.0");

	g_Message_Score_Info = get_user_msgid("ScoreInfo");

	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);
}

public RG_CSGameRules_PlayerKilled_Post(iVictim, iAttacker)
{
	// Killed by a non-player entity or self killed
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Connected, iAttacker))
	{
		return;
	}

	// Nemesis class loaded?
	if (zpe_class_nemesis_get(iAttacker) && get_pcvar_num(g_pCvar_Frags_Nemesis_Ignore))
	{
		// Ignore nemesis frags
		Remove_Frags(iAttacker, iVictim);

		return;
	}

	// Assassin Class loaded?
	if (zpe_class_assassin_get(iAttacker) && get_pcvar_num(g_pCvar_Frags_Assassin_Ignore))
	{
		// Ignore assassin frags
		Remove_Frags(iAttacker, iVictim);

		return;
	}

	// Survivor Class loaded?
	if (zpe_class_survivor_get(iAttacker) && get_pcvar_num(g_pCvar_Frags_Survivor_Ignore))
	{
		// Ignore survivor frags
		Remove_Frags(iAttacker, iVictim);

		return;
	}

	// Sniper Class loaded?
	if (zpe_class_sniper_get(iAttacker) && get_pcvar_num(g_pCvar_Frags_Sniper_Ignore))
	{
		// Ignore sniper frags
		Remove_Frags(iAttacker, iVictim);

		return;
	}

	// Human killed zombie, add up the extra frags for kill
	if (!zpe_core_is_zombie(iAttacker) && get_pcvar_num(g_pCvar_Frags_Zombie_Killed) > 1)
	{
		Update_Frags(iAttacker, iVictim, get_pcvar_num(g_pCvar_Frags_Zombie_Killed) - 1, 0, 0);
	}

	// Zombie killed human, add up the extra frags for kill
	if (zpe_core_is_zombie(iAttacker) && get_pcvar_num(g_pCvar_Frags_Human_Killed) > 1)
	{
		Update_Frags(iAttacker, iVictim, get_pcvar_num(g_pCvar_Frags_Human_Killed) - 1, 0, 0);
	}
}

public zpe_fw_core_infect_post(iPlayer, iAttacker)
{
	if (BIT_VALID(g_iBit_Connected, iAttacker) && iAttacker != iPlayer)
	{
		// Reward frags, deaths
		Update_Frags(iAttacker, iPlayer, get_pcvar_num(g_pCvar_Frags_Human_Infected), 1, 1);

		// Reward health
		if (BIT_VALID(g_iBit_Alive, iAttacker))
		{
			SET_USER_HEALTH(iAttacker, Float:GET_USER_HEALTH(iAttacker)) + get_pcvar_float(g_pCvar_Infection_Health_Bonus);
		}
	}
}

public zpe_fw_gamemodes_start()
{
	g_Game_Mode_Started = true;
	g_Last_Human_Health_Rewarded = false;
}

public zpe_fw_gamemodes_end()
{
	g_Game_Mode_Started = false;
}

public zpe_fw_core_last_human(iPlayer)
{
	if (g_Game_Mode_Started && !g_Last_Human_Health_Rewarded)
	{
		SET_USER_HEALTH(iPlayer, Float:GET_USER_HEALTH(iPlayer)) + get_pcvar_float(g_pCvar_Human_Last_Health_Bonus);

		g_Last_Human_Health_Rewarded = true;
	}
}

// Update player frags and deaths
Update_Frags(iAttacker, iVictim, iFrags, iDeaths, iScoreboard)
{
	// Set attacker frags
	set_entvar(iAttacker, var_frags, get_entvar(iAttacker, var_frags) + float(iFrags));

	// Set victim deaths
	cs_set_user_deaths(iVictim, cs_get_user_deaths(iVictim) + iDeaths);

	// Update scoreboard with attacker and victim info
	if (iScoreboard)
	{
		message_begin(MSG_BROADCAST, g_Message_Score_Info);
		write_byte(iAttacker); // player
		write_short(get_entvar(iAttacker, var_frags)); // frags
		write_short(cs_get_user_deaths(iAttacker)); // deaths
		write_short(0); // class?
		write_short(_:cs_get_user_team(iAttacker)); // team
		message_end();

		message_begin(MSG_BROADCAST, g_Message_Score_Info);
		write_byte(iVictim); // player
		write_short(get_entvar(iVictim, var_frags)); // frags
		write_short(cs_get_user_deaths(iVictim)); // deaths
		write_short(0); // class?
		write_short(_:cs_get_user_team(iVictim)); // team
		message_end();
	}
}

// Remove player frags (when nemesis/assassin/survivor/sniper ignore_frags cvar is enabled)
Remove_Frags(iAttacker, iVictim)
{
	// Remove attacker frags
	set_entvar(iAttacker, var_frags, get_entvar(iAttacker, var_frags) - 1.0);

	// Remove victim deaths
	cs_set_user_deaths(iVictim, cs_get_user_deaths(iVictim) - 1);
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
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