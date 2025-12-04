/* AMX Mod X
*	[ZPE] Leap.
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

#define PLUGIN "leap"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <fun>
#include <zpe_kernel>
#include <zpe_gamemodes>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

new Float:g_fLeap_Last_Time[MAX_PLAYERS + 1];

new g_pCvar_Leap_Zombie;
new g_pCvar_Leap_Zombie_Force;
new g_pCvar_Leap_Zombie_Height;
new g_pCvar_Leap_Zombie_Cooldown;

new g_pCvar_Leap_Nemesis;
new g_pCvar_Leap_Nemesis_Force;
new g_pCvar_Leap_Nemesis_Height;
new g_pCvar_Leap_Nemesis_Cooldown;

new g_pCvar_Leap_Assassin;
new g_pCvar_Leap_Assassin_Force;
new g_pCvar_Leap_Assassin_Height;
new g_pCvar_Leap_Assassin_Cooldown;

new g_pCvar_Leap_Survivor;
new g_pCvar_Leap_Survivor_Force;
new g_pCvar_Leap_Survivor_Height;
new g_pCvar_Leap_Survivor_Cooldown;

new g_pCvar_Leap_Sniper;
new g_pCvar_Leap_Sniper_Force;
new g_pCvar_Leap_Sniper_Height;
new g_pCvar_Leap_Sniper_Cooldown;

new g_Game_Mode_Infection_ID;

new g_iBit_Alive;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Leap_Zombie = register_cvar("zpe_leap_zombie", "3"); // 1-all // 2-first only // 3-last only
	g_pCvar_Leap_Zombie_Force = register_cvar("zpe_leap_zombie_force", "500");
	g_pCvar_Leap_Zombie_Height = register_cvar("zpe_leap_zombie_height", "300");
	g_pCvar_Leap_Zombie_Cooldown = register_cvar("zpe_leap_zombie_cooldown", "10.0");

	g_pCvar_Leap_Nemesis = register_cvar("zpe_leap_nemesis", "1");
	g_pCvar_Leap_Nemesis_Force = register_cvar("zpe_leap_nemesis_force", "500");
	g_pCvar_Leap_Nemesis_Height = register_cvar("zpe_leap_nemesis_height", "300");
	g_pCvar_Leap_Nemesis_Cooldown = register_cvar("zpe_leap_nemesis_cooldown", "5.0");

	g_pCvar_Leap_Assassin = register_cvar("zpe_leap_assassin", "1");
	g_pCvar_Leap_Assassin_Force = register_cvar("zpe_leap_assassin_force", "500");
	g_pCvar_Leap_Assassin_Height = register_cvar("zpe_leap_assassin_height", "300");
	g_pCvar_Leap_Assassin_Cooldown = register_cvar("zpe_leap_assassin_cooldown", "5.0");

	g_pCvar_Leap_Survivor = register_cvar("zpe_leap_survivor", "0");
	g_pCvar_Leap_Survivor_Force = register_cvar("zpe_leap_survivor_force", "500");
	g_pCvar_Leap_Survivor_Height = register_cvar("zpe_leap_survivor_height", "300");
	g_pCvar_Leap_Survivor_Cooldown = register_cvar("zpe_leap_survivor_cooldown", "5.0");

	g_pCvar_Leap_Sniper = register_cvar("zpe_leap_sniper", "0");
	g_pCvar_Leap_Sniper_Force = register_cvar("zpe_leap_sniper_force", "500");
	g_pCvar_Leap_Sniper_Height = register_cvar("zpe_leap_sniper_height", "300");
	g_pCvar_Leap_Sniper_Cooldown = register_cvar("zpe_leap_sniper_cooldown", "5.0");
}

public plugin_cfg()
{
	g_Game_Mode_Infection_ID = zpe_gamemodes_get_id("Infection Mode");
}

public fw_button_changed(iPlayer, iPressed, iUnpressed)
{
	// Not alive
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer) || !zpe_core_is_zombie(iPlayer))
	{
		return;
	}

	// Don't allow leap if player is frozen (e.g. freezetime)
	if (get_user_maxspeed(iPlayer) == 1.0)
	{
		return;
	}

	new iForce;
	new Float:fHeight;

	static Float:fCooldown;

	// Nemesis class loaded?
	if (zpe_class_nemesis_get(iPlayer))
	{
		if (!get_pcvar_num(g_pCvar_Leap_Nemesis))
		{
			return;
		}

		iForce = get_pcvar_num(g_pCvar_Leap_Nemesis_Force);
		fHeight = get_pcvar_float(g_pCvar_Leap_Nemesis_Height);
		fCooldown = get_pcvar_float(g_pCvar_Leap_Nemesis_Cooldown);
	}

	// Assassin Class loaded?
	else if (zpe_class_assassin_get(iPlayer))
	{
		// Check if assassin should leap
		if (!get_pcvar_num(g_pCvar_Leap_Assassin))
		{
			return;
		}

		iForce = get_pcvar_num(g_pCvar_Leap_Assassin_Force);
		fHeight = get_pcvar_float(g_pCvar_Leap_Assassin_Height);
		fCooldown = get_pcvar_float(g_pCvar_Leap_Assassin_Cooldown);
	}

	// Survivor Class loaded?
	else if (zpe_class_survivor_get(iPlayer))
	{
		// Check if survivor should leap
		if (!get_pcvar_num(g_pCvar_Leap_Survivor))
		{
			return;
		}

		iForce = get_pcvar_num(g_pCvar_Leap_Survivor_Force);
		fHeight = get_pcvar_float(g_pCvar_Leap_Survivor_Height);
		fCooldown = get_pcvar_float(g_pCvar_Leap_Survivor_Cooldown);
	}

	// Sniper Class loaded?
	else if (zpe_class_sniper_get(iPlayer))
	{
		// Check if sniper should leap
		if (!get_pcvar_num(g_pCvar_Leap_Sniper))
		{
			return;
		}

		iForce =  get_pcvar_num(g_pCvar_Leap_Sniper_Force);
		fHeight = get_pcvar_float(g_pCvar_Leap_Sniper_Height);
		fCooldown = get_pcvar_float(g_pCvar_Leap_Sniper_Cooldown);
	}

	else
	{
		// Check if zombie should leap
		switch (get_pcvar_num(g_pCvar_Leap_Zombie))
		{
			// Disabled
			case 0:
			{
				return;
			}

			// First zombie (only on infection rounds)
			case 2:
			{
				if (!zpe_core_is_first_zombie(iPlayer) || (zpe_gamemodes_get_current() != g_Game_Mode_Infection_ID))
				{
					return;
				}
			}

			// Last zombie
			case 3:
			{
				if (!zpe_core_is_last_zombie(iPlayer))
				{
					return;
				}
			}
		}

		iForce = get_pcvar_num(g_pCvar_Leap_Zombie_Force);
		fHeight = get_pcvar_float(g_pCvar_Leap_Zombie_Height);
		fCooldown = get_pcvar_float(g_pCvar_Leap_Zombie_Cooldown);
	}

	static Float:fCurrent_Time;

	fCurrent_Time = get_gametime();

	// Cooldown not over yet
	if (fCurrent_Time - g_fLeap_Last_Time[iPlayer] < fCooldown)
	{
		return;
	}

	new iCurrent = get_entvar(iPlayer, var_button);

	// Doing a longjump
	if (!(iCurrent & IN_DUCK && iPressed & IN_JUMP))
	{
		return;
	}

	// Not on ground or not enough speed
	if (!(get_entvar(iPlayer, var_flags) & FL_ONGROUND) || _fm_get_speed(iPlayer) < 80)
	{
		return;
	}

	static Float:fVelocity[3];

	// Make velocity vector
	velocity_by_aim(iPlayer, iForce, fVelocity);

	// Set custom height
	fVelocity[2] = fHeight;

	// Apply the new velocity
	set_entvar(iPlayer, var_velocity, fVelocity);

	// Update last leap time
	g_fLeap_Last_Time[iPlayer] = fCurrent_Time;
}

public client_disconnected(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}