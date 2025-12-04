/* AMX Mod X
*	CS MaxSpeed API.
*	Author: WiLS. Edition: C&K Corporation.
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

#define PLUGIN "cs maxspeed api"
#define VERSION "3.1.2.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <ck_cs_maxspeed_api>

new g_Has_Custom_Max_Speed;
new g_Max_Speed_Is_Multiplier;
new g_Freeze_Time;

new Float:g_fCustom_Max_Speed[MAX_PLAYERS + 1];

new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	register_event("HLTV", "Event_Round_Start", "a", "1=0", "2=0");
	register_logevent("Logevent_Round_Start", 2, "1=Round_Start");

	RegisterHookChain(RG_CBasePlayer_ResetMaxSpeed, "RG_CBasePlayer_ResetMaxSpeed_Post", 1);
}

public plugin_cfg()
{
	// Prevents CS from limiting player maxspeeds at 320
	server_cmd("sv_maxspeed 9999");
}

public plugin_natives()
{
	register_library("ck_cs_maxspeed_api");

	register_native("cs_set_player_maxspeed", "native_set_player_maxspeed");
	register_native("cs_reset_player_maxspeed", "native_reset_player_maxspeed");
}

public native_set_player_maxspeed(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", iPlayer);

		return false;
	}

	new Float:fMax_Speed = get_param_f(2);

	if (fMax_Speed < 0.0)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid maxspeed value %.2f", fMax_Speed);

		return false;
	}

	new iMultiplier = get_param(3);

	BIT_ADD(g_Has_Custom_Max_Speed, iPlayer);

	g_fCustom_Max_Speed[iPlayer] = fMax_Speed;

	if (iMultiplier)
	{
		BIT_ADD(g_Max_Speed_Is_Multiplier, iPlayer);
	}

	else
	{
		BIT_SUB(g_Max_Speed_Is_Multiplier, iPlayer);
	}

	rg_reset_maxspeed(iPlayer);

	return true;
}

public native_reset_player_maxspeed(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", iPlayer);

		return false;
	}

	// Player doesn't have custom maxspeed, no need to reset
	if (BIT_NOT_VALID(g_Has_Custom_Max_Speed, iPlayer))
	{
		return true;
	}

	BIT_SUB(g_Has_Custom_Max_Speed, iPlayer);

	rg_reset_maxspeed(iPlayer);

	return true;
}

public Event_Round_Start()
{
	g_Freeze_Time = true;
}

public Logevent_Round_Start()
{
	g_Freeze_Time = false;
}

public RG_CBasePlayer_ResetMaxSpeed_Post(iPlayer)
{
	// is_user_alive is used to prevent the bug that occurs when using the bit sum
	if (g_Freeze_Time || !is_user_alive(iPlayer) || BIT_NOT_VALID(g_Has_Custom_Max_Speed, iPlayer))
	{
		return;
	}

	new Float:fMax_Speed = get_entvar(iPlayer, var_maxspeed);

	if (BIT_VALID(g_Max_Speed_Is_Multiplier, iPlayer))
	{
		set_entvar(iPlayer, var_maxspeed, fMax_Speed * g_fCustom_Max_Speed[iPlayer]);
	}

	else
	{
		set_entvar(iPlayer, var_maxspeed, g_fCustom_Max_Speed[iPlayer]);
	}
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	BIT_SUB(g_Has_Custom_Max_Speed, iPlayer);

	BIT_SUB(g_iBit_Connected, iPlayer);
}