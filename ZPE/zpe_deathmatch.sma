/* AMX Mod X
*	[ZPE] Deathmatch.
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

#define PLUGIN "deathmatch"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <zpe_gamemodes>
#include <zpe_kernel>

#define TASK_RESPAWN 100
#define ID_RESPAWN (iTask_ID - TASK_RESPAWN)

// Custom Forwards
enum _:TOTAL_FORWARDS
{
	FW_USER_RESPAWN_PRE = 0
};

new g_Forwards[TOTAL_FORWARDS];
new g_Forward_Result;

new g_Game_Mode_Started;

new g_pCvar_Deathmatch;
new g_pCvar_Respawn_Delay;
new g_pCvar_Respawn_Zombies;
new g_pCvar_Respawn_Humans;
new g_pCvar_Respawn_On_Suicide;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Deathmatch = register_cvar("zpe_deathmatch", "0");
	g_pCvar_Respawn_Delay = register_cvar("zpe_respawn_delay", "5.0");
	g_pCvar_Respawn_Zombies = register_cvar("zpe_respawn_zombies", "1");
	g_pCvar_Respawn_Humans = register_cvar("zpe_respawn_humans", "1");
	g_pCvar_Respawn_On_Suicide = register_cvar("zpe_respawn_on_suicide", "0");

	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);

	g_Forwards[FW_USER_RESPAWN_PRE] = CreateMultiForward("zpe_fw_deathmatch_respawn_pre", ET_CONTINUE, FP_CELL);
}

public RG_CSGameRules_PlayerKilled_Post(iVictim, iAttacker)
{
	// Respawn if deathmatch is enabled
	if (get_pcvar_num(g_pCvar_Deathmatch))
	{
		if (!get_pcvar_num(g_pCvar_Respawn_On_Suicide) && (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Connected, iAttacker)))
		{
			return;
		}

		// Respawn if human/zombie?
		if ((zpe_core_is_zombie(iVictim) && !get_pcvar_num(g_pCvar_Respawn_Zombies)) || (!zpe_core_is_zombie(iVictim) && !get_pcvar_num(g_pCvar_Respawn_Humans)))
		{
			return;
		}

		set_task(get_pcvar_float(g_pCvar_Respawn_Delay), "Respawn_Player_Task", iVictim + TASK_RESPAWN);
	}
}

public Respawn_Player_Task(iTask_ID)
{
	// Already alive or round ended
	if (BIT_VALID(g_iBit_Alive, ID_RESPAWN) || zpe_gamemodes_get_current() == ZPE_NO_GAME_MODE)
	{
		return;
	}

	// Player moved to spectators
	if (CS_GET_USER_TEAM(ID_RESPAWN) == CS_TEAM_SPECTATOR || CS_GET_USER_TEAM(ID_RESPAWN) == CS_TEAM_UNASSIGNED)
	{
		return;
	}

	// Allow other plugins to decide whether player can respawn or not
	ExecuteForward(g_Forwards[FW_USER_RESPAWN_PRE], g_Forward_Result, ID_RESPAWN);

	if (g_Forward_Result >= PLUGIN_HANDLED)
	{
		return;
	}

	// Respawn as zombie?
	if (get_pcvar_num(g_pCvar_Deathmatch) == 2 || (get_pcvar_num(g_pCvar_Deathmatch) == 3 && CHANCE(50)) || (get_pcvar_num(g_pCvar_Deathmatch) == 4 && zpe_core_get_zombie_count() < Get_Alive_Count() / 2))
	{
		// Only allow respawning as zombie after a game mode started
		if (g_Game_Mode_Started)
		{
			zpe_core_respawn_as_zombie(ID_RESPAWN, true);
		}
	}

	Respawn_Player_Manually(ID_RESPAWN);
}

// Respawn Player Manually (called after respawn checks are done)
Respawn_Player_Manually(iPlayer)
{
	// Respawn!
	rg_round_respawn(iPlayer);
}

public zpe_fw_gamemodes_start()
{
	g_Game_Mode_Started = true;
}

public zpe_fw_gamemodes_end()
{
	g_Game_Mode_Started = false;

	for (new i = 1; i <= MaxClients; i++)
	{
		remove_task(i + TASK_RESPAWN);
	}
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	// Remove tasks on disconnect
	remove_task(iPlayer + TASK_RESPAWN);

	BIT_SUB(g_iBit_Alive, iPlayer);
	BIT_SUB(g_iBit_Connected, iPlayer);
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	remove_task(iPlayer + TASK_RESPAWN);

	BIT_ADD(g_iBit_Alive, iPlayer);
}

// Get Alive Count -returns alive players number-
Get_Alive_Count()
{
	new iAlive;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Alive, i))
		{
			iAlive++;
		}
	}

	return iAlive;
}