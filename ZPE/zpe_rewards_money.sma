/* AMX Mod X
*	[ZPE] Rewards Money.
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

#define PLUGIN "rewards money"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

#define NO_DATA -1

new Float:g_fDamage_Dealt_To_Zombies[MAX_PLAYERS + 1];
new Float:g_fDamage_Dealt_To_Humans[MAX_PLAYERS + 1];

new g_Money_At_Round_Start[MAX_PLAYERS + 1] = { NO_DATA, ... };
new g_Money_Rewarded[MAX_PLAYERS + 1] = { NO_DATA, ... };
new g_Money_Before_Kill[MAX_PLAYERS + 1];

new g_Game_Restarting;

new g_Message_Money;
new g_Message_Money_Block_Status;

new g_pCvar_Money_Limit;

new g_pCvar_Money_For_Winner;
new g_pCvar_Money_For_Loser;

new g_pCvar_Money_Damage;
new g_pCvar_Money_Zombie_Damaged_HP;
new g_pCvar_Money_Human_Damaged_HP;

new g_pCvar_Money_Zombie_Killed;
new g_pCvar_Money_Human_Killed;

new g_pCvar_Money_Human_Infected;

new g_pCvar_Money_Nemesis_Ignore;
new g_pCvar_Money_Assassin_Ignore;
new g_pCvar_Money_Survivor_Ignore;
new g_pCvar_Money_Sniper_Ignore;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Money_Limit = register_cvar("zpe_money_limit", "16000");

	g_pCvar_Money_For_Winner = register_cvar("zpe_money_for_winner", "1000");
	g_pCvar_Money_For_Loser = register_cvar("zpe_money_for_loser", "500");

	g_pCvar_Money_Damage = register_cvar("zpe_money_damage", "100");
	g_pCvar_Money_Zombie_Damaged_HP = register_cvar("zpe_money_zombie_damaged_hp", "500.0");
	g_pCvar_Money_Human_Damaged_HP = register_cvar("zpe_money_human_damaged_hp", "250.0");

	g_pCvar_Money_Zombie_Killed = register_cvar("zpe_money_zombie_killed", "200");
	g_pCvar_Money_Human_Killed = register_cvar("zpe_money_human_killed", "200");

	g_pCvar_Money_Human_Infected = register_cvar("zpe_money_human_infected", "200");

	g_pCvar_Money_Nemesis_Ignore = register_cvar("zpe_money_nemesis_ignore", "0");
	g_pCvar_Money_Assassin_Ignore = register_cvar("zpe_money_assassin_ignore", "0");
	g_pCvar_Money_Survivor_Ignore = register_cvar("zpe_money_survivor_ignore", "0");
	g_pCvar_Money_Sniper_Ignore = register_cvar("zpe_money_sniper_ignore", "0");

	register_event("HLTV", "Event_Round_Start", "a", "1=0", "2=0");
	register_event("TextMsg", "Event_Game_Restart", "a", "2=#Game_will_restart_in");
	register_event("TextMsg", "Event_Game_Restart", "a", "2=#Game_Commencing");

	RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_CBasePlayer_TakeDamage_Post", 1);
	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_");
	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);

	g_Message_Money = get_user_msgid("Money");

	register_message(g_Message_Money, "Message_Money");
}

public zpe_fw_core_infect_post(iPlayer, iAttacker)
{
	// Reward money to zombies infecting humans?
	if (BIT_VALID(g_iBit_Connected, iAttacker) && iAttacker != iPlayer && get_pcvar_num(g_pCvar_Money_Human_Infected) > 0)
	{
		UTIL_Set_User_Money(iAttacker, min(CS_GET_USER_MONEY(iAttacker) + get_pcvar_num(g_pCvar_Money_Human_Infected), get_pcvar_num(g_pCvar_Money_Limit)));
	}
}

public RG_CBasePlayer_TakeDamage_Post(iVictim, iInflictor, iAttacker, Float:fDamage)
{
	// Non-player damage or self damage
	if (iVictim == iAttacker || iAttacker > 32 || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return;
	}

	// Ignore money rewards for Nemesis?
	if (zpe_class_nemesis_get(iAttacker) && get_pcvar_num(g_pCvar_Money_Nemesis_Ignore))
	{
		return;
	}

	// Ignore money rewards for Assassin?
	if (zpe_class_assassin_get(iAttacker) && get_pcvar_num(g_pCvar_Money_Assassin_Ignore))
	{
		return;
	}

	// Ignore money rewards for Survivor?
	if (zpe_class_survivor_get(iAttacker) && get_pcvar_num(g_pCvar_Money_Survivor_Ignore))
	{
		return;
	}

	// Ignore money rewards for Sniper?
	if (zpe_class_sniper_get(iAttacker) && get_pcvar_num(g_pCvar_Money_Sniper_Ignore))
	{
		return;
	}

	// Zombie attacking human...
	if (zpe_core_is_zombie(iAttacker) && !zpe_core_is_zombie(iVictim))
	{
		// Reward money to zombies for damaging humans?
		if (get_pcvar_num(g_pCvar_Money_Damage) > 0)
		{
			// Store damage dealt
			g_fDamage_Dealt_To_Humans[iAttacker] += fDamage;

			// Give rewards according to damage dealt
			new iHow_Many_Rewards = floatround(g_fDamage_Dealt_To_Humans[iAttacker] / get_pcvar_float(g_pCvar_Money_Human_Damaged_HP), floatround_floor);

			if (iHow_Many_Rewards > 0)
			{
				UTIL_Set_User_Money(iAttacker, min(CS_GET_USER_MONEY(iAttacker) + (get_pcvar_num(g_pCvar_Money_Damage) * iHow_Many_Rewards), get_pcvar_num(g_pCvar_Money_Limit)));

				g_fDamage_Dealt_To_Humans[iAttacker] -= get_pcvar_float(g_pCvar_Money_Human_Damaged_HP) * iHow_Many_Rewards;
			}
		}
	}

	// Human attacking zombie...
	else if (!zpe_core_is_zombie(iAttacker) && zpe_core_is_zombie(iVictim))
	{
		// Reward money to humans for damaging zombies?
		if (get_pcvar_num(g_pCvar_Money_Damage) > 0)
		{
			// Store damage dealt
			g_fDamage_Dealt_To_Zombies[iAttacker] += fDamage;

			// Give rewards according to damage dealt
			new iHow_Many_Rewards = floatround(g_fDamage_Dealt_To_Zombies[iAttacker] / get_pcvar_float(g_pCvar_Money_Zombie_Damaged_HP), floatround_floor);

			if (iHow_Many_Rewards > 0)
			{
				UTIL_Set_User_Money(iAttacker, min(CS_GET_USER_MONEY(iAttacker) + (get_pcvar_num(g_pCvar_Money_Damage) * iHow_Many_Rewards), get_pcvar_num(g_pCvar_Money_Limit)));

				g_fDamage_Dealt_To_Zombies[iAttacker] -= get_pcvar_float(g_pCvar_Money_Zombie_Damaged_HP) * iHow_Many_Rewards;
			}
		}
	}
}

public RG_CSGameRules_PlayerKilled_(iVictim, iAttacker)
{
	// Non-player kill or self kill
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Connected, iAttacker))
	{
		return;
	}

	// Block CS money message before the kill
	g_Message_Money_Block_Status = get_msg_block(g_Message_Money);

	set_msg_block(g_Message_Money, BLOCK_SET);

	// Save attacker's money before the kill
	g_Money_Before_Kill[iAttacker] = CS_GET_USER_MONEY(iAttacker);
}

public RG_CSGameRules_PlayerKilled_Post(iVictim, iAttacker)
{
	// Non-player kill or self kill
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Connected, iAttacker))
	{
		return;
	}

	// Restore CS money message block status
	set_msg_block(g_Message_Money, g_Message_Money_Block_Status);

	// Ignore money rewards for nemesis?
	if (zpe_class_nemesis_get(iAttacker) && get_pcvar_num(g_pCvar_Money_Nemesis_Ignore))
	{
		UTIL_Set_User_Money(iAttacker, g_Money_Before_Kill[iAttacker]);

		return;
	}

	// Ignore money rewards for assassin?
	if (zpe_class_assassin_get(iAttacker) && get_pcvar_num(g_pCvar_Money_Assassin_Ignore))
	{
		UTIL_Set_User_Money(iAttacker, g_Money_Before_Kill[iAttacker]);

		return;
	}

	// Ignore money rewards for survivor?
	if (zpe_class_survivor_get(iAttacker) && get_pcvar_num(g_pCvar_Money_Survivor_Ignore))
	{
		UTIL_Set_User_Money(iAttacker, g_Money_Before_Kill[iAttacker]);

		return;
	}

	// Ignore money rewards for sniper?
	if (zpe_class_sniper_get(iAttacker) && get_pcvar_num(g_pCvar_Money_Sniper_Ignore))
	{
		UTIL_Set_User_Money(iAttacker, g_Money_Before_Kill[iAttacker]);

		return;
	}

	// Reward money to atacker for the kill
	if (zpe_core_is_zombie(iVictim))
	{
		UTIL_Set_User_Money(iAttacker, min(g_Money_Before_Kill[iAttacker] + get_pcvar_num(g_pCvar_Money_Zombie_Killed), get_pcvar_num(g_pCvar_Money_Limit)));
	}

	else
	{
		UTIL_Set_User_Money(iAttacker, min(g_Money_Before_Kill[iAttacker] + get_pcvar_num(g_pCvar_Money_Human_Killed), get_pcvar_num(g_pCvar_Money_Limit)));
	}
}

public Event_Round_Start()
{
	// Don't reward money after game restart event
	if (g_Game_Restarting)
	{
		g_Game_Restarting = false;

		return;
	}

	// Save player's money at round start, plus our custom money rewards
	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_NOT_VALID(g_iBit_Connected, i) || g_Money_Rewarded[i] == NO_DATA)
		{
			continue;
		}

		g_Money_At_Round_Start[i] = min(CS_GET_USER_MONEY(i) + g_Money_Rewarded[i], get_pcvar_num(g_pCvar_Money_Limit));

		g_Money_Rewarded[i] = NO_DATA;
	}
}

public zpe_fw_gamemodes_end()
{
	// Determine round winner and money rewards
	if (!zpe_core_get_zombie_count())
	{
		// Human team wins
		for (new i = 1; i <= MaxClients; i++)
		{
			if (BIT_NOT_VALID(g_iBit_Connected, i))
			{
				continue;
			}

			if (zpe_core_is_zombie(i))
			{
				g_Money_Rewarded[i] = get_pcvar_num(g_pCvar_Money_For_Loser);
			}

			else
			{
				g_Money_Rewarded[i] = get_pcvar_num(g_pCvar_Money_For_Winner);
			}
		}
	}

	else if (!zpe_core_get_human_count())
	{
		// Zombie team wins
		for (new i = 1; i <= MaxClients; i++)
		{
			if (BIT_NOT_VALID(g_iBit_Connected, i))
			{
				continue;
			}

			if (zpe_core_is_zombie(i))
			{
				g_Money_Rewarded[i] = get_pcvar_num(g_pCvar_Money_For_Winner);
			}

			else
			{
				g_Money_Rewarded[i] = get_pcvar_num(g_pCvar_Money_For_Loser);
			}
		}
	}

	else
	{
		// No one wins
		for (new i = 1; i <= MaxClients; i++)
		{
			if (BIT_NOT_VALID(g_iBit_Connected, i))
			{
				continue;
			}

			g_Money_Rewarded[i] = get_pcvar_num(g_pCvar_Money_For_Loser);
		}
	}
}

public Message_Money(iMessage_ID, iMessage_Dest, iMessage_Entity)
{
	if (BIT_NOT_VALID(g_iBit_Connected, iMessage_Entity))
	{
		return;
	}

	// If arg 2 = 0, this is CS giving round win money or start money
	if (get_msg_arg_int(2) == 0 && g_Money_At_Round_Start[iMessage_Entity] != NO_DATA)
	{
		UTIL_Set_User_Money(iMessage_Entity, g_Money_At_Round_Start[iMessage_Entity]);

		set_msg_arg_int(1, get_msg_argtype(1), g_Money_At_Round_Start[iMessage_Entity]);

		g_Money_At_Round_Start[iMessage_Entity] = NO_DATA;
	}
}

public Event_Game_Restart()
{
	g_Game_Restarting = true;
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	// Clear saved money after disconnecting
	g_Money_At_Round_Start[iPlayer] = NO_DATA;
	g_Money_Rewarded[iPlayer] = NO_DATA;

	// Clear damage after disconnecting
	g_fDamage_Dealt_To_Zombies[iPlayer] = 0.0;
	g_fDamage_Dealt_To_Humans[iPlayer] = 0.0;

	BIT_SUB(g_iBit_Alive, iPlayer);
	BIT_SUB(g_iBit_Connected, iPlayer);
}

public zpe_fw_kill_pre_bit_sub(iVictim)
{
	BIT_SUB(g_iBit_Alive, iVictim);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}