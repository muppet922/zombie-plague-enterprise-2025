/* AMX Mod X
*	[ZPE] Gameplay fixes.
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

#define PLUGIN "gameplay fixes"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <hamsandwich>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

#define STATIONARY_USING 2

#define CLASSNAME_MAX_LENGTH 32

#define TASK_RESPAWN 100
#define ID_RESPAWN (Task_ID - TASK_RESPAWN)

new Array:g_aGameplay_Entities;

new g_pCvar_Remove_Doors;
new g_pCvar_Block_Pushables;
new g_pCvar_Block_Suicide;
new g_pCvar_Worldspawn_Kill_Respawn;
new g_pCvar_Disable_Minmodels;
new g_pCvar_Keep_HP_On_Disconnect;

new g_unfwSpawn;
new g_Game_Mode_Started;
new g_Round_Ended;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Remove_Doors = register_cvar("zpe_remove_doors", "0");
	g_pCvar_Block_Pushables = register_cvar("zpe_block_pushables", "1");
	g_pCvar_Block_Suicide = register_cvar("zpe_block_suicide", "1");
	g_pCvar_Worldspawn_Kill_Respawn = register_cvar("zpe_worldspawn_kill_respawn", "1");
	g_pCvar_Disable_Minmodels = register_cvar("zpe_disable_minmodels", "1");
	g_pCvar_Keep_HP_On_Disconnect = register_cvar("zpe_keep_hp_on_disconnect", "1");

	register_clcmd("chooseteam", "Client_Command_Changeteam");
	register_clcmd("jointeam", "Client_Command_Changeteam");

	register_forward(FM_ClientKill, "FM_ClientKill_");

	register_event("HLTV", "Event_Round_Start", "a", "1=0", "2=0");

	RegisterHam(Ham_Use, "func_tank", "Ham_Use_");
	RegisterHam(Ham_Use, "func_tankmortar", "Ham_Use_");
	RegisterHam(Ham_Use, "func_tankrocket", "Ham_Use_");
	RegisterHam(Ham_Use, "func_tanklaser", "Ham_Use_");

	RegisterHam(Ham_Use, "func_pushable", "Ham_Use_Pushable_");

	unregister_forward(FM_Spawn, g_unfwSpawn);
}

public plugin_precache()
{
	// Initialize arrays
	g_aGameplay_Entities = ArrayCreate(CLASSNAME_MAX_LENGTH, 1);

	// Load from external file
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Objective Entities", "GAMEPLAY", g_aGameplay_Entities);

	// Prevent gameplay entities from spawning
	g_unfwSpawn = register_forward(FM_Spawn, "FM_Spawn_");
}

public plugin_cfg()
{
	Event_Round_Start();
}

public client_putinserver(iPlayer)
{
	// Disable minmodels for clients to see zombies properly?
	if (get_pcvar_num(g_pCvar_Disable_Minmodels))
	{
		set_task(0.1, "Disable_Minmodels_Task", iPlayer);
	}

	BIT_ADD(g_iBit_Connected, iPlayer);
}

public Disable_Minmodels_Task(iPlayer)
{
	if (BIT_VALID(g_iBit_Connected, iPlayer))
	{
		client_cmd(iPlayer, "cl_minmodels 0");
	}
}

// Team Change Commands
public Client_Command_Changeteam(iPlayer)
{
	// Block suicides by choosing a different team
	if (get_pcvar_num(g_pCvar_Block_Suicide) && g_Game_Mode_Started && BIT_VALID(g_iBit_Alive, iPlayer))
	{
		zpe_client_print_color(iPlayer, print_team_default, "%L", LANG_PLAYER, "CANT_CHANGE_TEAM_COLOR");

		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public Event_Round_Start()
{
	g_Round_Ended = false;

	// Remove doors?
	if (get_pcvar_num(g_pCvar_Remove_Doors))
	{
		set_task(0.1, "Remove_Doors");
	}
}

// Remove Doors Task
public Remove_Doors()
{
	// Remove rotating doors
	new iEntity;

	iEntity = -1;

	while ((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", "func_door_rotating")) != 0)
	{
		engfunc(EngFunc_SetOrigin, iEntity, Float:{8192.0, 8192.0, 8192.0});
	}

	// Remove all doors?
	if (get_pcvar_num(g_pCvar_Remove_Doors) == 2)
	{
		iEntity = -1;

		while ((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", "func_door")) != 0)
		{
			engfunc(EngFunc_SetOrigin, iEntity, Float:{8192.0, 8192.0, 8192.0});
		}
	}
}

// Entity Spawn Forward
public FM_Spawn_(iEntity)
{
	// Invalid entity
	if (!is_entity(iEntity))
	{
		return FMRES_IGNORED;
	}

	// Get classname
	new szClassname[CLASSNAME_MAX_LENGTH];
	get_entvar(iEntity, var_classname, szClassname, charsmax(szClassname));

	new szRemove_Entity_Name[CLASSNAME_MAX_LENGTH];
	new iRemove_Entity_Count = ArraySize(g_aGameplay_Entities);

	// Check whether it needs to be removed
	for (new i = 0; i < iRemove_Entity_Count; i++)
	{
		ArrayGetString(g_aGameplay_Entities, i, szRemove_Entity_Name, charsmax(szRemove_Entity_Name));

		if (equal(szClassname, szRemove_Entity_Name))
		{
			engfunc(EngFunc_RemoveEntity, iEntity);

			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	// Remove respawn task
	remove_task(iPlayer + TASK_RESPAWN);

	// Respawn player if he dies because of a worldspawn kill?
	if (get_pcvar_num(g_pCvar_Worldspawn_Kill_Respawn))
	{
		set_task(1.0, "Respawn_Player_Check_Task", iPlayer + TASK_RESPAWN);
	}

	BIT_ADD(g_iBit_Alive, iPlayer);
}

// Respawn Player Check Task (if killed by worldspawn)
public Respawn_Player_Check_Task(Task_ID)
{
	// Successfully spawned or round ended
	if (BIT_VALID(g_iBit_Alive, ID_RESPAWN) || g_Round_Ended)
	{
		return;
	}

	// Player moved to spectators
	if (CS_GET_USER_TEAM(ID_RESPAWN) == CS_TEAM_SPECTATOR || CS_GET_USER_TEAM(ID_RESPAWN) == CS_TEAM_UNASSIGNED)
	{
		return;
	}

	// If player was being spawned as a zombie, set the flag again
	if (zpe_core_is_zombie(ID_RESPAWN))
	{
		zpe_core_respawn_as_zombie(ID_RESPAWN, true);
	}

	ExecuteHamB(Ham_CS_RoundRespawn, ID_RESPAWN);
}

// Client disconnecting (prevent game commencing bug after last player on a team leaves)
public client_disconnected(iLeaving_Player)
{
	// Remove respawn task on disconnect
	remove_task(iLeaving_Player + TASK_RESPAWN);

	// Player was not alive
	if (BIT_NOT_VALID(g_iBit_Alive, iLeaving_Player))
	{
		return;
	}

	// Last player, dont bother
	if (Get_Alive_Count() == 1)
	{
		return;
	}

	// Prevent empty teams when no game mode is in progress
	if (!g_Game_Mode_Started)
	{
		// Last Terrorist
		if ((CS_GET_USER_TEAM(iLeaving_Player) == CS_TEAM_T) && (Get_AliveT_Count() == 1))
		{
			// Find replacement and move him to Terrorist team
			rg_set_user_team(Get_Random_Alive_Player(iLeaving_Player), TEAM_TERRORIST);
		}

		// Last CT
		else if ((CS_GET_USER_TEAM(iLeaving_Player) == CS_TEAM_CT) && (Get_AliveCT_Count() == 1))
		{
			// Find replacement and move him to CT team
			rg_set_user_team(Get_Random_Alive_Player(iLeaving_Player), TEAM_CT);
		}
	}

	// Prevent no zombies/humans after game mode started
	else
	{
		new iReplaced_Player;

		// Last Zombie
		if (zpe_core_is_zombie(iLeaving_Player) && zpe_core_get_zombie_count() == 1)
		{
			// Only one CT left, don't leave an empty CT team
			if (zpe_core_get_human_count() == 1 && Get_CT_Count() == 1)
			{
				return;
			}

			// Find replacement
			iReplaced_Player = Get_Random_Alive_Player(iLeaving_Player);

			new szPlayer_Name[32];

			GET_USER_NAME(iReplaced_Player, szPlayer_Name, charsmax(szPlayer_Name));

			zpe_client_print_color(0, print_team_default, "%L", LANG_PLAYER, "LAST_ZOMBIE_LEFT_COLOR", szPlayer_Name);

			if (zpe_class_nemesis_get(iLeaving_Player))
			{
				zpe_class_nemesis_set(iReplaced_Player);

				if (get_pcvar_num(g_pCvar_Keep_HP_On_Disconnect))
				{
					SET_USER_HEALTH(iReplaced_Player, Float:GET_USER_HEALTH(iLeaving_Player));
				}
			}

			else if (zpe_class_assassin_get(iLeaving_Player))
			{
				zpe_class_assassin_set(iReplaced_Player);

				if (get_pcvar_num(g_pCvar_Keep_HP_On_Disconnect))
				{
					SET_USER_HEALTH(iReplaced_Player, Float:GET_USER_HEALTH(iLeaving_Player));
				}
			}

			else
			{
				zpe_core_infect(iReplaced_Player, iReplaced_Player);
			}
		}

		// Last Human
		else if (!zpe_core_is_zombie(iLeaving_Player) && zpe_core_get_human_count() == 1)
		{
			// Only one Terrorist left, don't leave an empty Terrorist team
			if (zpe_core_get_zombie_count() == 1 && Get_T_Count() == 1)
			{
				return;
			}

			// Find replacement
			iReplaced_Player = Get_Random_Alive_Player(iLeaving_Player);

			new szPlayer_Name[32];

			GET_USER_NAME(iReplaced_Player, szPlayer_Name, charsmax(szPlayer_Name));

			zpe_client_print_color(0, print_team_default, "%L", LANG_PLAYER, "LAST_HUMAN_LEFT_COLOR", szPlayer_Name);

			if (zpe_class_survivor_get(iLeaving_Player))
			{
				zpe_class_survivor_set(iReplaced_Player);

				if (get_pcvar_num(g_pCvar_Keep_HP_On_Disconnect))
				{
					SET_USER_HEALTH(iReplaced_Player, Float:GET_USER_HEALTH(iLeaving_Player));
				}
			}

			else if (zpe_class_sniper_get(iLeaving_Player))
			{
				zpe_class_sniper_set(iReplaced_Player);

				if (get_pcvar_num(g_pCvar_Keep_HP_On_Disconnect))
				{
					SET_USER_HEALTH(iReplaced_Player, Float:GET_USER_HEALTH(iLeaving_Player));
				}
			}

			else
			{
				zpe_core_cure(iReplaced_Player, iReplaced_Player);
			}
		}
	}

	BIT_SUB(g_iBit_Alive, iLeaving_Player);
	BIT_SUB(g_iBit_Connected, iLeaving_Player);
}

public zpe_fw_gamemodes_start()
{
	g_Game_Mode_Started = true;
}

public zpe_fw_gamemodes_end()
{
	g_Game_Mode_Started = false;
	g_Round_Ended = true;

	// Stop respawning after game mode ends
	for (new i = 1; i <= MaxClients; i++)
	{
		remove_task(i + TASK_RESPAWN);
	}
}

// Ham Use Stationary Gun Forward
public Ham_Use_(iEntity, iCaller, iActivator, iUse_Type)
{
	// Prevent zombies from using stationary guns
	if (iUse_Type == STATIONARY_USING && BIT_VALID(g_iBit_Alive, iCaller) && zpe_core_is_zombie(iCaller))
	{
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

// Ham Use Pushable Forward
public Ham_Use_Pushable_()
{
	// Prevent speed bug with pushables?
	if (get_pcvar_num(g_pCvar_Block_Pushables))
	{
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

// Client Kill Forward
public FM_ClientKill_()
{
	if (get_pcvar_num(g_pCvar_Block_Suicide) && g_Game_Mode_Started)
	{
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

// Get Alive CTs -returns number of CTs alive-
Get_AliveCT_Count()
{
	new iCTs;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Alive, i) && CS_GET_USER_TEAM(i) == CS_TEAM_CT)
		{
			iCTs++;
		}
	}

	return iCTs;
}

// Get Alive Ts -returns number of Ts alive-
Get_AliveT_Count()
{
	new iTs;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Alive, i) && CS_GET_USER_TEAM(i) == CS_TEAM_T)
		{
			iTs++;
		}
	}

	return iTs;
}

// Get CTs -returns number of CTs connected-
Get_CT_Count()
{
	new iCTs;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Connected, i) && CS_GET_USER_TEAM(i) == CS_TEAM_CT)
		{
			iCTs++;
		}
	}

	return iCTs;
}

// Get Ts -returns number of Ts connected-
Get_T_Count()
{
	new iTs;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Connected, i) && CS_GET_USER_TEAM(i) == CS_TEAM_T)
		{
			iTs++;
		}
	}

	return iTs;
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

Get_Random_Alive_Player(const iIgnore_Player = 0)
{
	new iPlayers[32];
	new iCount;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (i == iIgnore_Player)
		{
			continue;
		}

		if (BIT_VALID(g_iBit_Alive, i))
		{
			iPlayers[iCount++] = i;
		}
	}

	return iCount > 0 ? iPlayers[RANDOM(iCount)] : 0;
}