/* AMX Mod X
*	[ZPE] Kernel gamemodes.
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

#define PLUGIN "kernel gamemodes"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <hamsandwich>
#include <zpe_kernel>
#include <zpe_gamemodes_const>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

#define TASK_GAMEMODE 100

// Some constants
#define DMG_HEGRENADE (1 << 24)

enum _:TOTAL_FORWARDS
{
	FW_GAME_MODE_CHOOSE_PRE = 0,
	FW_GAME_MODE_CHOOSE_POST,
	FW_GAME_MODE_START,
	FW_GAME_MODE_END
};

new g_Forwards[TOTAL_FORWARDS];
new g_Forward_Result;

// Game Modes data
new Array:g_aGame_Mode_Name;
new Array:g_aGame_Mode_File_Name;

new g_Default_Game_Mode = 0; // first game mode is used as default if none specified

new g_Chosen_Game_Mode = ZPE_NO_GAME_MODE;
new g_Current_Game_Mode = ZPE_NO_GAME_MODE;
new g_Last_Game_Mode = ZPE_NO_GAME_MODE;

new g_Game_Mode_Count;

new g_Allow_Infection;

new g_pCvar_Gamemode_Delay;
new g_pCvar_Prevent_Consecutive;

new g_pCvar_Notice_Gamemodes_Start_Show_Hud;

new g_pCvar_Message_Notice_Gamemodes_Start_Converted;
new g_pCvar_Message_Notice_Gamemodes_Start_R;
new g_pCvar_Message_Notice_Gamemodes_Start_G;
new g_pCvar_Message_Notice_Gamemodes_Start_B;
new g_pCvar_Message_Notice_Gamemodes_Start_X;
new g_pCvar_Message_Notice_Gamemodes_Start_Y;
new g_pCvar_Message_Notice_Gamemodes_Start_Effects;
new g_pCvar_Message_Notice_Gamemodes_Start_Fxtime;
new g_pCvar_Message_Notice_Gamemodes_Start_Holdtime;
new g_pCvar_Message_Notice_Gamemodes_Start_Fadeintime;
new g_pCvar_Message_Notice_Gamemodes_Start_Fadeouttime;
new g_pCvar_Message_Notice_Gamemodes_Start_Channel;

new g_pCvar_All_Messages_Are_Converted;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Gamemode_Delay = register_cvar("zpe_gamemode_delay", "10");
	g_pCvar_Prevent_Consecutive = register_cvar("zpe_prevent_consecutive_modes", "1");

	g_pCvar_Notice_Gamemodes_Start_Show_Hud = register_cvar("zpe_notice_gamemodes_start_show_hud", "1");

	g_pCvar_Message_Notice_Gamemodes_Start_Converted = register_cvar("zpe_message_notice_gamemodes_start_converted", "0");
	g_pCvar_Message_Notice_Gamemodes_Start_R = register_cvar("zpe_message_notice_gamemodes_start_r", "0");
	g_pCvar_Message_Notice_Gamemodes_Start_G = register_cvar("zpe_message_notice_gamemodes_start_g", "250");
	g_pCvar_Message_Notice_Gamemodes_Start_B = register_cvar("zpe_message_notice_gamemodes_start_b", "0");
	g_pCvar_Message_Notice_Gamemodes_Start_X = register_cvar("zpe_message_notice_gamemodes_start_x", "-1.0");
	g_pCvar_Message_Notice_Gamemodes_Start_Y = register_cvar("zpe_message_notice_gamemodes_start_y", "0.75");
	g_pCvar_Message_Notice_Gamemodes_Start_Effects = register_cvar("zpe_message_notice_gamemodes_start_effects", "0");
	g_pCvar_Message_Notice_Gamemodes_Start_Fxtime = register_cvar("zpe_message_notice_gamemodes_start_fxtime", "0.1");
	g_pCvar_Message_Notice_Gamemodes_Start_Holdtime = register_cvar("zpe_message_notice_gamemodes_start_holdtime", "1.5");
	g_pCvar_Message_Notice_Gamemodes_Start_Fadeintime = register_cvar("zpe_message_notice_gamemodes_start_fadeintime", "2.0");
	g_pCvar_Message_Notice_Gamemodes_Start_Fadeouttime = register_cvar("zpe_message_notice_gamemodes_start_fadeouttime", "1.5");
	g_pCvar_Message_Notice_Gamemodes_Start_Channel = register_cvar("zpe_message_notice_gamemodes_start_channel", "-1");

	g_pCvar_All_Messages_Are_Converted = register_cvar("zpe_all_messages_are_converted", "0");

	register_event("HLTV", "Event_Round_Start", "a", "1=0", "2=0");
	register_event("TextMsg", "Event_Game_Restart", "a", "2=#Game_will_restart_in");

	register_logevent("Logevent_Round_End", 2, "1=Round_End");

	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);
	RegisterHookChain(RG_CBasePlayer_TraceAttack, "RG_CBasePlayer_TraceAttack_");

	// TODO: Ham -> ReAPI
	RegisterHam(Ham_TakeDamage, "player", "Ham_TakeDamage_Player_");

	register_forward(FM_ClientDisconnect, "FM_ClientDisconnect_Post", 1)

	g_Forwards[FW_GAME_MODE_CHOOSE_PRE] = CreateMultiForward("zpe_fw_gamemodes_choose_pre", ET_CONTINUE, FP_CELL, FP_CELL);
	g_Forwards[FW_GAME_MODE_CHOOSE_POST] = CreateMultiForward("zpe_fw_gamemodes_choose_post", ET_IGNORE, FP_CELL, FP_CELL);
	g_Forwards[FW_GAME_MODE_START] = CreateMultiForward("zpe_fw_gamemodes_start", ET_IGNORE, FP_CELL);
	g_Forwards[FW_GAME_MODE_END] = CreateMultiForward("zpe_fw_gamemodes_end", ET_IGNORE, FP_CELL);
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/gamemode/zpe_gamemode_kernel.cfg");
}

public plugin_natives()
{
	register_library("zpe_gamemodes");

	register_native("zpe_gamemodes_register", "native_gamemodes_register");
	register_native("zpe_gamemodes_set_default", "native_gamemodes_set_default");
	register_native("zpe_gamemodes_get_default", "native_gamemodes_get_default");
	register_native("zpe_gamemodes_get_chosen", "native_gamemodes_get_chosen");
	register_native("zpe_gamemodes_get_current", "native_gamemodes_get_current");
	register_native("zpe_gamemodes_get_id", "native_gamemodes_get_id");
	register_native("zpe_gamemodes_get_name", "native_gamemodes_get_name");
	register_native("zpe_gamemodes_start", "native_gamemodes_start");
	register_native("zpe_gamemodes_get_count", "native_gamemodes_get_count");
	register_native("zpe_gamemodes_set_allow_infect", "native_gamemodes_set_allow_infect");
	register_native("zpe_gamemodes_get_allow_infect", "native_gamemodes_get_allow_infect");

	// Initialize dynamic arrays
	g_aGame_Mode_Name = ArrayCreate(32, 1);
	g_aGame_Mode_File_Name = ArrayCreate(64, 1);
}

public native_gamemodes_register(iPlugin_ID, iNum_Params)
{
	new szGame_Name[32];
	new szFilename[64];

	get_string(1, szGame_Name, charsmax(szGame_Name));
	get_plugin(iPlugin_ID, szFilename, charsmax(szFilename));

	if (strlen(szGame_Name) < 1)
	{
		log_error(AMX_ERR_NATIVE, "Can't register game mode with an empty name");

		return ZPE_INVALID_GAME_MODE;
	}

	new szGamemode_Name[32];

	for (new i = 0; i < g_Game_Mode_Count; i++)
	{
		ArrayGetString(g_aGame_Mode_Name, i, szGamemode_Name, charsmax(szGamemode_Name));

		if (equali(szGame_Name, szGamemode_Name))
		{
			log_error(AMX_ERR_NATIVE, "Game mode already registered (%s)", szGame_Name);

			return ZPE_INVALID_GAME_MODE;
		}
	}

	ArrayPushString(g_aGame_Mode_Name, szGame_Name);
	ArrayPushString(g_aGame_Mode_File_Name, szFilename);

	// Pause game mode plugin after registering
	pause("ac", szFilename);

	g_Game_Mode_Count++;

	return g_Game_Mode_Count - 1;
}

public native_gamemodes_set_default(iPlugin_ID, iNum_Params)
{
	new iGame_Mode_ID = get_param(1);

	if (iGame_Mode_ID < 0 || iGame_Mode_ID >= g_Game_Mode_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid game mode player (%d)", iGame_Mode_ID);

		return false;
	}

	g_Default_Game_Mode = iGame_Mode_ID;

	return true;
}

public native_gamemodes_get_default(iPlugin_ID, iNum_Params)
{
	return g_Default_Game_Mode;
}

public native_gamemodes_get_chosen(iPlugin_ID, iNum_Params)
{
	return g_Chosen_Game_Mode;
}

public native_gamemodes_get_current(iPlugin_ID, iNum_Params)
{
	return g_Current_Game_Mode;
}

public native_gamemodes_get_id(iPlugin_ID, iNum_Params)
{
	new szGame_Name[32];

	get_string(1, szGame_Name, charsmax(szGame_Name));

	// Loop through every game mode
	new szGamemode_Name[32];

	for (new i = 0; i < g_Game_Mode_Count; i++)
	{
		ArrayGetString(g_aGame_Mode_Name, i, szGamemode_Name, charsmax(szGamemode_Name));

		if (equali(szGame_Name, szGamemode_Name))
		{
			return i;
		}
	}

	return ZPE_INVALID_GAME_MODE;
}

public native_gamemodes_get_name(iPlugin_ID, iNum_Params)
{
	new iGame_Mode_ID = get_param(1);

	if (iGame_Mode_ID < 0 || iGame_Mode_ID >= g_Game_Mode_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid game mode player (%d)", iGame_Mode_ID);

		return false;
	}

	new szGame_Name[32];

	ArrayGetString(g_aGame_Mode_Name, iGame_Mode_ID, szGame_Name, charsmax(szGame_Name));

	new sLen = get_param(3);

	set_string(2, szGame_Name, sLen);

	return true;
}

public native_gamemodes_start(iPlugin_ID, iNum_Params)
{
	new iGame_Mode_ID = get_param(1);

	if (iGame_Mode_ID < 0 || iGame_Mode_ID >= g_Game_Mode_Count)
	{
		log_error(AMX_ERR_NATIVE, "Invalid game mode player (%d)", iGame_Mode_ID);

		return false;
	}

	new iTarget_Player = get_param(2);

	if (iTarget_Player != RANDOM_TARGET_PLAYER && BIT_NOT_VALID(g_iBit_Alive, iTarget_Player))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iTarget_Player);

		return false;
	}

	// Game modes can only be started at roundstart
	if (!task_exists(TASK_GAMEMODE))
	{
		return false;
	}

	new iPrevious_Mode;
	new szFilename_Previous[64];

	// Game mode already chosen?
	if (g_Chosen_Game_Mode != ZPE_NO_GAME_MODE)
	{
		// Pause previous game mode before picking a new one
		ArrayGetString(g_aGame_Mode_File_Name, g_Chosen_Game_Mode, szFilename_Previous, charsmax(szFilename_Previous));

		pause("ac", szFilename_Previous);

		iPrevious_Mode = true;
	}

	// Set chosen game mode player
	g_Chosen_Game_Mode = iGame_Mode_ID;

	// Unpause game mode once it's chosen
	new szFilename[64];

	ArrayGetString(g_aGame_Mode_File_Name, g_Chosen_Game_Mode, szFilename, charsmax(szFilename));

	unpause("ac", szFilename);

	// Execute game mode choose attempt forward (skip checks = true)
	ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_Forward_Result, g_Chosen_Game_Mode, true);

	// Game mode can't be started
	if (g_Forward_Result >= PLUGIN_HANDLED)
	{
		// Pause the game mode we were trying to start
		pause("ac", szFilename);

		// Unpause previously chosen game mode
		if (iPrevious_Mode)
		{
			unpause("ac", szFilename_Previous);
		}

		return false;
	}

	// Execute game mode chosen forward
	ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_Forward_Result, g_Chosen_Game_Mode, iTarget_Player);

	// Override task and start game mode manually
	remove_task(TASK_GAMEMODE);

	Start_Game_Mode_Task();

	return true;
}

public native_gamemodes_get_count(iPlugin_ID, iNum_Params)
{
	return g_Game_Mode_Count;
}

public native_gamemodes_set_allow_infect(iPlugin_ID, iNum_Params)
{
	g_Allow_Infection = get_param(1);
}

public native_gamemodes_get_allow_infect(iPlugin_ID, iNum_Params)
{
	return g_Allow_Infection;
}

public Event_Game_Restart()
{
	Logevent_Round_End();
}

public Logevent_Round_End()
{
	ExecuteForward(g_Forwards[FW_GAME_MODE_END], g_Forward_Result, g_Current_Game_Mode);

	if (g_Chosen_Game_Mode != ZPE_NO_GAME_MODE)
	{
		// Pause game mode after its round ends
		new szFilename[64];

		ArrayGetString(g_aGame_Mode_File_Name, g_Chosen_Game_Mode, szFilename, charsmax(szFilename));

		pause("ac", szFilename);
	}

	g_Current_Game_Mode = ZPE_NO_GAME_MODE;
	g_Chosen_Game_Mode = ZPE_NO_GAME_MODE;

	g_Allow_Infection = false;

	// Stop game mode task
	remove_task(TASK_GAMEMODE);

	// Balance the teams
	Balance_Teams();
}

public Event_Round_Start()
{
	// Players respawn as humans when a new round begins
	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_NOT_VALID(g_iBit_Connected, i))
		{
			continue;
		}

		zpe_core_respawn_as_zombie(i, false);
	}

	// No game modes registered?
	if (g_Game_Mode_Count < 1)
	{
		log_error(AMX_ERR_NATIVE, "FAIL! No game modes registered!");

		return;
	}

	// Remove previous tasks
	remove_task(TASK_GAMEMODE);

	// Pick game mode for the current round (delay needed because not all players are alive at this point)
	set_task(0.1, "Choose_Game_Mode", TASK_GAMEMODE);

	// Start game mode task (delay should be greater than choose_game_mode task)
	set_task(0.2 + get_pcvar_float(g_pCvar_Gamemode_Delay), "Start_Game_Mode_Task", TASK_GAMEMODE);

	// Show T-virus HUD notice
	if (get_pcvar_num(g_pCvar_Notice_Gamemodes_Start_Show_Hud))
	{
		if (get_pcvar_num(g_pCvar_All_Messages_Are_Converted) || get_pcvar_num(g_pCvar_Message_Notice_Gamemodes_Start_Converted))
		{
			set_hudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Gamemodes_Start_R),
				get_pcvar_num(g_pCvar_Message_Notice_Gamemodes_Start_G),
				get_pcvar_num(g_pCvar_Message_Notice_Gamemodes_Start_B),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_X),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Gamemodes_Start_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_Fadeouttime),
				get_pcvar_num(g_pCvar_Message_Notice_Gamemodes_Start_Channel)
			);

			show_hudmessage(0, "%L", LANG_PLAYER, "NOTICE_VIRUS_FREE");
		}

		else
		{
			set_dhudmessage
			(
				get_pcvar_num(g_pCvar_Message_Notice_Gamemodes_Start_R),
				get_pcvar_num(g_pCvar_Message_Notice_Gamemodes_Start_G),
				get_pcvar_num(g_pCvar_Message_Notice_Gamemodes_Start_B),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_X),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_Y),
				get_pcvar_num(g_pCvar_Message_Notice_Gamemodes_Start_Effects),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_Fxtime),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_Holdtime),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_Fadeintime),
				get_pcvar_float(g_pCvar_Message_Notice_Gamemodes_Start_Fadeouttime)
			);

			show_dhudmessage(0, "%L", LANG_PLAYER, "NOTICE_VIRUS_FREE");
		}
	}
}

public Choose_Game_Mode()
{
	// No players joined yet
	if (Get_Alive_Count() == 0)
	{
		return;
	}

	new szFilename[64];

	// Try choosing a game mode
	for (new i = g_Default_Game_Mode + 1; /*no condition*/; i++)
	{
		// Start over when we reach the end
		if (i >= g_Game_Mode_Count)
		{
			i = 0;
		}

		// Game mode already chosen?
		if (g_Chosen_Game_Mode != ZPE_NO_GAME_MODE)
		{
			// Pause previous game mode before picking a new one
			ArrayGetString(g_aGame_Mode_File_Name, g_Chosen_Game_Mode, szFilename, charsmax(szFilename));

			pause("ac", szFilename);
		}

		// Set chosen game mode index
		g_Chosen_Game_Mode = i;

		// Unpause game mode once it's chosen
		ArrayGetString(g_aGame_Mode_File_Name, g_Chosen_Game_Mode, szFilename, charsmax(szFilename));

		unpause("ac", szFilename);

		// Starting non-default game mode?
		if (i != g_Default_Game_Mode)
		{
			// Execute game mode choose attempt forward (skip checks = false)
			ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_Forward_Result, g_Chosen_Game_Mode, false);

			// Custom game mode can start?
			if (g_Forward_Result < PLUGIN_HANDLED && (!get_pcvar_num(g_pCvar_Prevent_Consecutive) || g_Last_Game_Mode != i))
			{
				// Execute game mode chosen forward
				ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_Forward_Result, g_Chosen_Game_Mode, RANDOM_TARGET_PLAYER);

				g_Last_Game_Mode = g_Chosen_Game_Mode;

				break;
			}
		}

		else
		{
			// Execute game mode choose attempt forward (skip checks = true)
			ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_PRE], g_Forward_Result, g_Chosen_Game_Mode, true);

			// Default game mode can start?
			if (g_Forward_Result < PLUGIN_HANDLED)
			{
				// Execute game mode chosen forward
				ExecuteForward(g_Forwards[FW_GAME_MODE_CHOOSE_POST], g_Forward_Result, g_Chosen_Game_Mode, RANDOM_TARGET_PLAYER);

				g_Last_Game_Mode = g_Chosen_Game_Mode;

				break;
			}

			else
			{
				remove_task(TASK_GAMEMODE);

				abort(AMX_ERR_GENERAL, "Default game mode can't be started. Check server settings.");

				break;
			}
		}
	}
}

public Start_Game_Mode_Task()
{
	// No game mode was chosen (not enough players)
	if (g_Chosen_Game_Mode == ZPE_NO_GAME_MODE)
	{
		return;
	}

	// Set current game mode
	g_Current_Game_Mode = g_Chosen_Game_Mode;

	// Execute game mode started forward
	ExecuteForward(g_Forwards[FW_GAME_MODE_START], g_Forward_Result, g_Current_Game_Mode);
}

public RG_CSGameRules_PlayerKilled_Post(iPlayer)
{
	// Are there any other players? (if not, round end is automatically triggered after last player dies)
	if (task_exists(TASK_GAMEMODE))
	{
		// Choose game mode again (to check game mode conditions such as min players)
		Choose_Game_Mode();
	}
}

public RG_CBasePlayer_TraceAttack_(iVictim, iAttacker)
{
	// Non-player damage or self damage
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return HC_CONTINUE;
	}

	// Prevent attacks when no game mode is active
	if (g_Current_Game_Mode == ZPE_NO_GAME_MODE)
	{
		return HC_SUPERCEDE;
	}

	// Prevent friendly fire
	if (zpe_core_is_zombie(iAttacker) == zpe_core_is_zombie(iVictim))
	{
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

// Ham Take Damage Forward (needed to block explosion damage too)
public Ham_TakeDamage_Player_(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type)
{
	// Non-player damage or self damage
	if (iVictim == iAttacker || iAttacker > 32 || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return HAM_IGNORED;
	}

	// Prevent attacks when no game mode is active
	if (g_Current_Game_Mode == ZPE_NO_GAME_MODE)
	{
		return HAM_SUPERCEDE;
	}

	// Prevent friendly fire
	if (zpe_core_is_zombie(iAttacker) == zpe_core_is_zombie(iVictim))
	{
		return HAM_SUPERCEDE;
	}

	// Mode allows infection and zombie attacking human...
	if (g_Allow_Infection && zpe_core_is_zombie(iAttacker) && !zpe_core_is_zombie(iVictim))
	{
		// Nemesis shouldn't be infecting
		if (zpe_class_nemesis_get(iAttacker))
		{
			return HAM_IGNORED;
		}

		// Assassin shouldn't be infecting
		if (zpe_class_assassin_get(iAttacker))
		{
			return HAM_IGNORED;
		}

		// Survivor shouldn't be infected
		if (zpe_class_survivor_get(iVictim))
		{
			return HAM_IGNORED;
		}

		// Sniper shouldn't be infected
		if (zpe_class_sniper_get(iVictim))
		{
			return HAM_IGNORED;
		}

		// Prevent infection/damage by HE grenade (bugfix)
		if (iDamage_Type & DMG_HEGRENADE)
		{
			return HAM_SUPERCEDE;
		}

		// Last human is killed to trigger round end
		if (zpe_core_get_human_count() == 1)
		{
			return HAM_IGNORED;
		}

		// Infect only if damage is done to victim
		if (fDamage > 0.0 && GetHamReturnStatus() != HAM_SUPERCEDE)
		{
			// Infect victim!
			zpe_core_infect(iVictim, iAttacker);

			return HAM_SUPERCEDE;
		}
	}

	return HAM_IGNORED;
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
	// Are there any other players? (if not, round end is automatically triggered after last player leaves)
	if (task_exists(TASK_GAMEMODE))
	{
		// Choose game mode again (to check game mode conditions such as min players)
		Choose_Game_Mode();
	}
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}

public zpe_fw_core_infect_post(iPlayer)
{
	if (g_Current_Game_Mode != ZPE_NO_GAME_MODE)
	{
		// Zombies are switched to Terrorist team
		rg_set_user_team(iPlayer, TEAM_TERRORIST);
	}
}

public zpe_fw_core_cure_post(iPlayer)
{
	if (g_Current_Game_Mode != ZPE_NO_GAME_MODE)
	{
		// Humans are switched to CT team
		rg_set_user_team(iPlayer, TEAM_CT);
	}
}

// Balance Teams
Balance_Teams()
{
	// Get amount of users playing
	new iPlayers_Count = Get_Playing_Count();

	// No players, don't bother
	if (iPlayers_Count < 1)
	{
		return;
	}

	// Split players evenly
	new iTerrors;
	new iMax_Terrors = iPlayers_Count / 2;

	// First, set everyone to CT
	for (new i = 1; i <= MaxClients; i++)
	{
		// Skip if not connected
		if (BIT_NOT_VALID(g_iBit_Connected, i))
		{
			continue;
		}

		// Skip if not playing
		if (CS_GET_USER_TEAM(i) == CS_TEAM_SPECTATOR && CS_GET_USER_TEAM(i) == CS_TEAM_UNASSIGNED)
		{
			continue;
		}

		// Set team
		rg_set_user_team(i, TEAM_CT, MODEL_AUTO, false);
	}

	new iPlayer;

	// Then randomly move half of the players to Terrorists
	while (iTerrors < iMax_Terrors)
	{
		// Keep looping through all players
		if (++iPlayer > MaxClients)
		{
			iPlayer = 1;
		}

		// Skip if not connected
		if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
		{
			continue;
		}

		// Skip if not playing or already a Terrorist
		if (CS_GET_USER_TEAM(iPlayer) != CS_TEAM_CT)
		{
			continue;
		}

		// Random chance
		if (CHANCE(50))
		{
			rg_set_user_team(iPlayer, TEAM_TERRORIST, MODEL_AUTO, false);

			iTerrors++;
		}
	}
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

// Get Playing Count -returns number of users playing-
Get_Playing_Count()
{
	new iPlaying;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Alive, i))
		{
			if (CS_GET_USER_TEAM(i) != CS_TEAM_SPECTATOR && CS_GET_USER_TEAM(i) != CS_TEAM_UNASSIGNED)
			{
				iPlaying++;
			}
		}
	}

	return iPlaying;
}