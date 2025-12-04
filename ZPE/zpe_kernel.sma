/* AMX Mod X
*	[ZPE] Kernel.
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

#define PLUGIN "kernel"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>

// Custom Forwards
enum TOTAL_FORWARDS
{
	FW_USER_INFECT_PRE = 0,
	FW_USER_INFECT,
	FW_USER_INFECT_POST,
	FW_USER_CURE_PRE,
	FW_USER_CURE,
	FW_USER_CURE_POST,
	FW_USER_LAST_ZOMBIE,
	FW_USER_LAST_HUMAN,
	FW_USER_SPAWN_POST,
	FW_USER_BIT_ADD,
	FW_USER_BIT_SUB
};

new g_Last_Zombie_Forward_Called;
new g_Last_Human_Forward_Called;

new g_Respawn_As_Zombie;

new g_Forward;
new g_Forward_Result;
new g_Forwards[TOTAL_FORWARDS];

new g_iBit_Zombie;
new g_iBit_First_Zombie;
new g_iBit_Last_Zombie;
new g_iBit_Last_Human;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_dictionary("zombie_plague_enterprise.txt");

	g_Forward = CreateMultiForward("zpe_fw_class_zombie_bit_change", ET_CONTINUE, FP_CELL);

	g_Forwards[FW_USER_INFECT_PRE] = CreateMultiForward("zpe_fw_core_infect_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_USER_INFECT] = CreateMultiForward("zpe_fw_core_infect", ET_IGNORE, FP_CELL, FP_CELL);
	g_Forwards[FW_USER_INFECT_POST] = CreateMultiForward("zpe_fw_core_infect_post", ET_IGNORE, FP_CELL, FP_CELL);

	g_Forwards[FW_USER_CURE_PRE] = CreateMultiForward("zpe_fw_core_cure_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_USER_CURE] = CreateMultiForward("zpe_fw_core_cure", ET_IGNORE, FP_CELL, FP_CELL);
	g_Forwards[FW_USER_CURE_POST] = CreateMultiForward("zpe_fw_core_cure_post", ET_IGNORE, FP_CELL, FP_CELL);

	g_Forwards[FW_USER_LAST_ZOMBIE] = CreateMultiForward("zpe_fw_core_last_zombie", ET_IGNORE, FP_CELL);
	g_Forwards[FW_USER_LAST_HUMAN] = CreateMultiForward("zpe_fw_core_last_human", ET_IGNORE, FP_CELL);

	g_Forwards[FW_USER_SPAWN_POST] = CreateMultiForward("zpe_fw_core_spawn_post", ET_IGNORE, FP_CELL);

	g_Forwards[FW_USER_BIT_ADD] = CreateMultiForward("zpe_fw_spawn_post_bit_add", ET_IGNORE, FP_CELL);
	g_Forwards[FW_USER_BIT_SUB] = CreateMultiForward("zpe_fw_kill_pre_bit_sub", ET_IGNORE, FP_CELL);

	RegisterHookChain(RG_CSGameRules_PlayerSpawn, "RG_CSGameRules_PlayerSpawn_Post", 1);
	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Pre");
	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);

	register_forward(FM_ClientDisconnect, "FM_ClientDisconnect_Post", 1)
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/zpe_settings.cfg");
}

public plugin_natives()
{
	register_library("zpe_kernel");

	register_native("zpe_core_is_first_zombie", "native_core_is_first_zombie");
	register_native("zpe_core_is_last_zombie", "native_core_is_last_zombie");
	register_native("zpe_core_is_last_human", "native_core_is_last_human");
	register_native("zpe_core_get_zombie_count", "native_core_get_zombie_count");
	register_native("zpe_core_get_human_count", "native_core_get_human_count");
	register_native("zpe_core_infect", "native_core_infect");
	register_native("zpe_core_cure", "native_core_cure");
	register_native("zpe_core_force_infect", "native_core_force_infect");
	register_native("zpe_core_force_cure", "native_core_force_cure");
	register_native("zpe_core_respawn_as_zombie", "native_core_respawn_as_zombie");
}

public RG_CSGameRules_PlayerSpawn_Post(iPlayer)
{
	// Not connected
	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		return HC_CONTINUE;
	}

	BIT_ADD(g_iBit_Alive, iPlayer);

	// ZPE Spawn Forward
	ExecuteForward(g_Forwards[FW_USER_SPAWN_POST], g_Forward_Result, iPlayer);

	ExecuteForward(g_Forwards[FW_USER_BIT_ADD], g_Forward_Result, iPlayer);

	// Set zombie/human attributes upon respawn
	if (BIT_VALID(g_Respawn_As_Zombie, iPlayer))
	{
		Infect_Player(iPlayer, iPlayer);
	}

	else
	{
		Cure_Player(iPlayer);
	}

	// Reset flag afterwards
	BIT_SUB(g_Respawn_As_Zombie, iPlayer);

	return HC_CONTINUE;
}

public RG_CSGameRules_PlayerKilled_Post(iPlayer)
{
	Check_Last_Zombie_And_Human();
}

Infect_Player(iPlayer, iAttacker = 0)
{
	ExecuteForward(g_Forwards[FW_USER_INFECT_PRE], g_Forward_Result, iPlayer, iAttacker);

	// One or more plugins blocked infection
	if (g_Forward_Result >= PLUGIN_HANDLED)
	{
		return;
	}

	ExecuteForward(g_Forwards[FW_USER_INFECT], g_Forward_Result, iPlayer, iAttacker);

	BIT_ADD(g_iBit_Zombie, iPlayer);

	ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Zombie);

	if (Get_Zombie_Count() == 1)
	{
		BIT_ADD(g_iBit_First_Zombie, iPlayer);
	}

	else
	{
		BIT_SUB(g_iBit_First_Zombie, iPlayer);
	}

	ExecuteForward(g_Forwards[FW_USER_INFECT_POST], g_Forward_Result, iPlayer, iAttacker);

	Check_Last_Zombie_And_Human();
}

Cure_Player(iPlayer, iAttacker = 0)
{
	ExecuteForward(g_Forwards[FW_USER_CURE_PRE], g_Forward_Result, iPlayer, iAttacker);

	// One or more plugins blocked cure
	if (g_Forward_Result >= PLUGIN_HANDLED)
	{
		return;
	}

	ExecuteForward(g_Forwards[FW_USER_CURE], g_Forward_Result, iPlayer, iAttacker);

	BIT_SUB(g_iBit_Zombie, iPlayer);

	ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Zombie);

	ExecuteForward(g_Forwards[FW_USER_CURE_POST], g_Forward_Result, iPlayer, iAttacker);

	Check_Last_Zombie_And_Human();
}

// Last Zombie/Human Check
Check_Last_Zombie_And_Human()
{
	new iLast_Zombie_ID;
	new iLast_Human_ID;

	new iZombie_Count = Get_Zombie_Count();
	new iHuman_Count = Get_Human_Count();

	if (iZombie_Count == 1)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			// Last zombie
			if (BIT_VALID(g_iBit_Alive, i) && BIT_VALID(g_iBit_Zombie, i))
			{
				BIT_ADD(g_iBit_Last_Zombie, i);

				iLast_Zombie_ID = i;
			}

			else
			{
				BIT_SUB(g_iBit_Last_Zombie, i);
			}
		}
	}

	else
	{
		g_Last_Zombie_Forward_Called = false;

		g_iBit_Last_Zombie = false;
	}

	// Last zombie forward
	if (iLast_Zombie_ID > 0 && !g_Last_Zombie_Forward_Called)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_ZOMBIE], g_Forward_Result, iLast_Zombie_ID);

		g_Last_Zombie_Forward_Called = true;
	}

	if (iHuman_Count == 1)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			// Last human
			if (BIT_VALID(g_iBit_Alive, i) && BIT_NOT_VALID(g_iBit_Zombie, i))
			{
				BIT_ADD(g_iBit_Last_Human, i);

				iLast_Human_ID = i;
			}

			else
			{
				BIT_SUB(g_iBit_Last_Human, i);
			}
		}
	}

	else
	{
		g_Last_Human_Forward_Called = false;

		g_iBit_Last_Human = false;
	}

	// Last human forward
	if (iLast_Human_ID > 0 && !g_Last_Human_Forward_Called)
	{
		ExecuteForward(g_Forwards[FW_USER_LAST_HUMAN], g_Forward_Result, iLast_Human_ID);

		g_Last_Human_Forward_Called = true;
	}
}

public native_core_is_first_zombie(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return -1;
	}

	return BIT_VALID(g_iBit_First_Zombie, iPlayer);
}

public native_core_is_last_zombie(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (!is_user_connected(iPlayer)) // Use bit = invalid player
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return -1;
	}

	return BIT_VALID(g_iBit_Last_Zombie, iPlayer);
}

public native_core_is_last_human(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return -1;
	}

	return BIT_VALID(g_iBit_Last_Human, iPlayer);
}

public native_core_get_zombie_count(iPlugin_ID, iNum_Params)
{
	return Get_Zombie_Count();
}

public native_core_get_human_count(iPlugin_ID, iNum_Params)
{
	return Get_Human_Count();
}

public native_core_infect(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (!is_user_alive(iPlayer)) // Use bit = invalid player
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	if (BIT_VALID(g_iBit_Zombie, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Player already infected (%d)", iPlayer);

		return false;
	}

	new iAttacker = get_param(2);

	if (iAttacker && !is_user_alive(iAttacker)) // Use bit = invalid player
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iAttacker);

		return false;
	}

	Infect_Player(iPlayer, iAttacker);

	return true;
}

public native_core_cure(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	if (BIT_NOT_VALID(g_iBit_Zombie, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Player not infected (%d)", iPlayer);

		return false;
	}

	new iAttacker = get_param(2);

	if (iAttacker && BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iAttacker);

		return false;
	}

	Cure_Player(iPlayer, iAttacker);

	return true;
}

public native_core_force_infect(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Infect_Player(iPlayer);

	return true;
}

public native_core_force_cure(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	Cure_Player(iPlayer);

	return true;
}

public native_core_respawn_as_zombie(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	new iRespawn_As_Zombie = get_param(2);

	if (iRespawn_As_Zombie)
	{
		BIT_ADD(g_Respawn_As_Zombie, iPlayer);
	}

	else
	{
		BIT_SUB(g_Respawn_As_Zombie, iPlayer);
	}

	return true;
}

// Get Zombie Count -returns alive zombies number-
Get_Zombie_Count()
{
	new iZombies;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Alive, i) && BIT_VALID(g_iBit_Zombie, i))
		{
			iZombies++;
		}
	}

	return iZombies;
}

// Get Human Count -returns alive humans number-
Get_Human_Count()
{
	new iHumans;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Alive, i) && BIT_NOT_VALID(g_iBit_Zombie, i))
		{
			iHumans++;
		}
	}

	return iHumans;
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

public FM_ClientDisconnect_Post(iPlayer)
{
	// Reset flags AFTER disconnect (to allow checking if the player was zombie before disconnecting)
	BIT_SUB(g_iBit_Zombie, iPlayer);

	ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Zombie);

	BIT_SUB(g_Respawn_As_Zombie, iPlayer);

	// This should be called AFTER client disconnects (post forward)
	Check_Last_Zombie_And_Human();
}

public RG_CSGameRules_PlayerKilled_Pre(iPlayer, iAttacker)
{
	BIT_SUB(g_iBit_Alive, iPlayer);

	ExecuteForward(g_Forwards[FW_USER_BIT_SUB], g_Forward_Result, iPlayer);
}