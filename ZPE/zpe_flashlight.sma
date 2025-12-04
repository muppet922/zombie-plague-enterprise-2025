/* AMX Mod X
*	[ZPE] Flashlight.
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

#define PLUGIN "flashlight"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <fakemeta>
#include <xs>
#include <zpe_kernel>

#define TASK_FLASHLIGHT 100
#define TASK_CHARGE 200

#define ID_FLASHLIGHT (iTask_ID - TASK_FLASHLIGHT)
#define ID_CHARGE (iTask_ID - TASK_CHARGE)

#define IMPULSE_FLASHLIGHT 100

new Float:g_fFlashlight_Last_Time[33];

new Array:g_aSound_Flashlight;

new g_Message_Flashlight;
new g_Message_FlashBat;

new g_Flashlight_Active;
new g_Flashlight_Charge[33];

new g_pCvar_Flashlight_Starting_Charge;
new g_pCvar_Flashlight_Custom;
new g_pCvar_Flashlight_Radius;
new g_pCvar_Flashlight_Distance;
new g_pCvar_Flashlight_Show_All;
new g_pCvar_Flashlight_Drain_Rate;
new g_pCvar_Flashlight_Charge_Rate;
new g_pCvar_Flashlight_Color_R;
new g_pCvar_Flashlight_Color_G;
new g_pCvar_Flashlight_Color_B;
new g_pCvar_Flashlight_Life;
new g_pCvar_Flashlight_Decay_Rate;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Flashlight_Starting_Charge = register_cvar("zpe_flashlight_starting_charge", "100");
	g_pCvar_Flashlight_Custom = register_cvar("zpe_flashlight_custom", "0");
	g_pCvar_Flashlight_Radius = register_cvar("zpe_flashlight_radius", "10");
	g_pCvar_Flashlight_Distance = register_cvar("zpe_flashlight_distance", "1000");
	g_pCvar_Flashlight_Show_All = register_cvar("zpe_flashlight_show_all", "1");
	g_pCvar_Flashlight_Drain_Rate = register_cvar("zpe_flashlight_drain_rate", "1");
	g_pCvar_Flashlight_Charge_Rate = register_cvar("zpe_flashlight_charge_rate", "5");
	g_pCvar_Flashlight_Color_R = register_cvar("zpe_flashlight_color_r", "100");
	g_pCvar_Flashlight_Color_G = register_cvar("zpe_flashlight_color_g", "100");
	g_pCvar_Flashlight_Color_B = register_cvar("zpe_flashlight_color_b", "100");
	g_pCvar_Flashlight_Life = register_cvar("zpe_flashlight_life", "3");
	g_pCvar_Flashlight_Decay_Rate = register_cvar("zpe_flashlight_decay_rate", "0");

	register_forward(FM_CmdStart, "FM_CmdStart_Post", 1);

	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);

	g_Message_Flashlight = get_user_msgid("Flashlight");
	g_Message_FlashBat = get_user_msgid("FlashBat");
}

public plugin_precache()
{
	g_aSound_Flashlight = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "FLASHLIGHT", g_aSound_Flashlight);
	Precache_Sounds(g_aSound_Flashlight);
}

public plugin_natives()
{
	register_library("zpe_flashlight");

	register_native("zpe_flashlight_get_charge", "native_flashlight_get_charge");
	register_native("zpe_flashlight_set_charge", "native_flashlight_set_charge");
}

public native_flashlight_get_charge(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return -1;
	}

	// Custom flashlight not enabled
	if (!get_pcvar_num(g_pCvar_Flashlight_Custom))
	{
		return -1;
	}

	return g_Flashlight_Charge[iPlayer];
}

public native_flashlight_set_charge(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	// Custom flashlight not enabled
	if (!get_pcvar_num(g_pCvar_Flashlight_Custom))
	{
		return false;
	}

	new iCharge = get_param(2);

	g_Flashlight_Charge[iPlayer] = clamp(iCharge, 0, 100);

	// Set the flashlight charge task to update batteries
	remove_task(iPlayer + TASK_CHARGE);

	set_task(1.0, "Flashlight_Charge_Task", iPlayer + TASK_CHARGE, _, _, "b");

	return true;
}

public plugin_cfg()
{
	// Enables flashlight
	server_cmd("mp_flashlight 1");
}

// Forward CmdStart // TODO: Optimize CmdStart -> register_impulse
public FM_CmdStart_Post(iPlayer, iHandle)
{
	// Not alive
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		return;
	}

	// Check if it's a flashlight impulse
	if (get_uc(iHandle, UC_Impulse) != IMPULSE_FLASHLIGHT)
	{
		return;
	}

	// Flashlight is being turned off
	if (get_entvar(iPlayer, var_effects) & EF_DIMLIGHT)
	{
		return;
	}

	if (zpe_core_is_zombie(iPlayer))
	{
		// Block it!
		set_uc(iHandle, UC_Impulse, 0);
	}

	else if (get_pcvar_num(g_pCvar_Flashlight_Custom))
	{
		// Block it!
		set_uc(iHandle, UC_Impulse, 0);

		// Should human's custom flashlight be turned on?
		if (g_Flashlight_Charge[iPlayer] > 2 && get_gametime() - g_fFlashlight_Last_Time[iPlayer] > 1.2)
		{
			// Prevent calling flashlight too quickly (bugfix)
			g_fFlashlight_Last_Time[iPlayer] = get_gametime();

			// Toggle custom flashlight
			if (BIT_VALID(g_Flashlight_Active, iPlayer))
			{
				// Remove flashlight task
				remove_task(iPlayer + TASK_FLASHLIGHT);

				BIT_SUB(g_Flashlight_Active, iPlayer);
			}

			else
			{
				// Set the custom flashlight task
				set_task(0.1, "Custom_Flashlight_Task", iPlayer + TASK_FLASHLIGHT, _, _, "b");

				BIT_ADD(g_Flashlight_Active, iPlayer);
			}

			// Set the flashlight charge task
			remove_task(iPlayer + TASK_CHARGE);

			set_task(1.0, "Flashlight_Charge_Task", iPlayer + TASK_CHARGE, _, _, "b");

			// Play flashlight toggle sound
			new szSound[SOUND_MAX_LENGTH];
			ArrayGetString(g_aSound_Flashlight, RANDOM(ArraySize(g_aSound_Flashlight)), szSound, charsmax(szSound));
			emit_sound(iPlayer, CHAN_WEAPON, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

			// Update flashlight status on HUD
			message_begin(MSG_ONE, g_Message_Flashlight, _, iPlayer);
			write_byte(BIT_VALID(g_Flashlight_Active, iPlayer)); // toggle
			write_byte(g_Flashlight_Charge[iPlayer]); // batteries
			message_end();
		}
	}
}

public RG_CSGameRules_PlayerKilled_Post(iVictim)
{
	// Reset flashlight flags
	BIT_SUB(g_Flashlight_Active, iVictim);

	remove_task(iVictim + TASK_FLASHLIGHT);
	remove_task(iVictim + TASK_CHARGE);
}

public zpe_fw_core_infect_post(iPlayer)
{
	// Turn off zombies flashlight
	Turn_Off_Flashlight(iPlayer);
}

public zpe_fw_core_cure_post(iPlayer)
{
	// Turn off humans flashlight (prevents double flashlight bug/exploit after respawn)
	Turn_Off_Flashlight(iPlayer);
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	// Reset flashlight flags
	BIT_SUB(g_Flashlight_Active, iPlayer);

	remove_task(iPlayer + TASK_FLASHLIGHT);
	remove_task(iPlayer + TASK_CHARGE);

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

// Turn off flashlight and restore batteries
Turn_Off_Flashlight(iPlayer)
{
	// Restore batteries to starting charge
	if (get_pcvar_num(g_pCvar_Flashlight_Custom))
	{
		g_Flashlight_Charge[iPlayer] = get_pcvar_num(g_pCvar_Flashlight_Starting_Charge);
	}

	// Check if flashlight is on
	if (get_entvar(iPlayer, var_effects) & EF_DIMLIGHT)
	{
		// Turn it off
		set_entvar(iPlayer, var_impulse, IMPULSE_FLASHLIGHT);
	}

	else
	{
		// Clear any stored flashlight impulse (bugfix)
		set_entvar(iPlayer, var_impulse, 0);

		// Update flashlight HUD
		message_begin(MSG_ONE, g_Message_Flashlight, _, iPlayer);
		write_byte(0); // toggle
		write_byte(get_pcvar_num(g_pCvar_Flashlight_Starting_Charge)); // batteries
		message_end();
	}

	// Turn it off
	BIT_SUB(g_Flashlight_Active, iPlayer);

	// Remove previous tasks
	remove_task(iPlayer + TASK_CHARGE);
	remove_task(iPlayer + TASK_FLASHLIGHT);
}

// Custom Flashlight Task
public Custom_Flashlight_Task(iTask_ID)
{
	// Get player and aiming origins
	static Float:fOrigin[3];
	new Float:fDest_Origin[3];

	get_entvar(ID_FLASHLIGHT, var_origin, fOrigin);

	UTIL_fm_get_aim_origin(ID_FLASHLIGHT, fDest_Origin);

	// Max distance check
	if (get_distance_f(fOrigin, fDest_Origin) > get_pcvar_float(g_pCvar_Flashlight_Distance))
	{
		return;
	}

	// Send to all players?
	if (get_pcvar_num(g_pCvar_Flashlight_Show_All))
	{
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fDest_Origin, 0);
	}

	else
	{
		message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, ID_FLASHLIGHT);
	}

	// Flashlight
	write_byte(TE_DLIGHT); // TE player
	engfunc(EngFunc_WriteCoord, fDest_Origin[0]); // x
	engfunc(EngFunc_WriteCoord, fDest_Origin[1]); // y
	engfunc(EngFunc_WriteCoord, fDest_Origin[2]); // z
	write_byte(get_pcvar_num(g_pCvar_Flashlight_Radius)); // radius
	write_byte(get_pcvar_num(g_pCvar_Flashlight_Color_R)); // r
	write_byte(get_pcvar_num(g_pCvar_Flashlight_Color_G)); // g
	write_byte(get_pcvar_num(g_pCvar_Flashlight_Color_B)); // b
	write_byte(get_pcvar_num(g_pCvar_Flashlight_Life)); // life
	write_byte(get_pcvar_num(g_pCvar_Flashlight_Decay_Rate)); // decay rate
	message_end();
}

// Flashlight charge task
public Flashlight_Charge_Task(iTask_ID)
{
	// Drain or charge?
	if (BIT_VALID(g_Flashlight_Active, ID_CHARGE))
	{
		g_Flashlight_Charge[ID_CHARGE] = max(g_Flashlight_Charge[ID_CHARGE] - get_pcvar_num(g_pCvar_Flashlight_Drain_Rate), 0);
	}

	else
	{
		g_Flashlight_Charge[ID_CHARGE] = min(g_Flashlight_Charge[ID_CHARGE] + get_pcvar_num(g_pCvar_Flashlight_Charge_Rate), 100);
	}

	// Batteries fully charged
	if (g_Flashlight_Charge[ID_CHARGE] == 100)
	{
		// Update flashlight batteries on HUD
		message_begin(MSG_ONE, g_Message_FlashBat, _, ID_CHARGE);
		write_byte(100); // batteries
		message_end();

		// Task not needed anymore
		remove_task(iTask_ID);

		return;
	}

	// Batteries depleted
	if (g_Flashlight_Charge[ID_CHARGE] == 0)
	{
		// Turn it off
		BIT_SUB(g_Flashlight_Active, ID_CHARGE);

		// Remove flashlight task for this player
		remove_task(ID_CHARGE + TASK_FLASHLIGHT);

		// Play flashlight toggle sound
		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSound_Flashlight, RANDOM(ArraySize(g_aSound_Flashlight)), szSound, charsmax(szSound));
		emit_sound(ID_CHARGE, CHAN_WEAPON, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

		// Update flashlight status on HUD
		message_begin(MSG_ONE, g_Message_Flashlight, _, ID_CHARGE);
		write_byte(0); // toggle
		write_byte(0); // batteries
		message_end();

		return;
	}

	// Update flashlight batteries on HUD
	message_begin(MSG_ONE_UNRELIABLE, g_Message_FlashBat, _, ID_CHARGE);
	write_byte(g_Flashlight_Charge[ID_CHARGE]); // batteries
	message_end();
}