/* AMX Mod X
*	[ZPE] Knockback.
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

#define PLUGIN "knockback"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <hamsandwich>
#include <xs>
#include <zpe_kernel>
#include <zpe_class_zombie>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

// Knockback Power values for weapons
// Note: negative values will disable knockback power for the weapon
new Float:g_fKnockback_Weapon_Power[] =
{
	-1.0,	// ---
	2.4,	// P228
	-1.0,	// ---
	6.5,	// SCOUT
	-1.0,	// ---
	8.0,	// XM1014
	-1.0,	// ---
	2.3,	// MAC10
	5.0,	// AUG
	-1.0,	// ---
	2.4,	// ELITE
	2.0,	// FIVESEVEN
	2.4,	// UMP45
	5.3,	// SG550
	5.5,	// GALIL
	5.5,	// FAMAS
	2.2,	// USP
	2.0,	// GLOCK18
	10.0,	// AWP
	2.5,	// MP5NAVY
	5.2,	// M249
	8.0,	// M3
	5.0,	// M4A1
	2.4,	// TMP
	6.5,	// G3SG1
	-1.0,	// ---
	5.3,	// DEAGLE
	5.0,	// SG552
	6.0,	// AK47
	-1.0,	// ---
	2.0		// P90
};

// Weapon entity names (uppercase)
new const g_Weapon_Entity_Names_UP[][] =
{
	"", "WEAPON_P228", "", "WEAPON_SCOUT", "WEAPON_HEGRENADE", "WEAPON_XM1014", "WEAPON_C4", "WEAPON_MAC10",
	"WEAPON_AUG", "WEAPON_SMOKEGRENADE", "WEAPON_ELITE", "WEAPON_FIVESEVEN", "WEAPON_UMP45", "WEAPON_SG550",
	"WEAPON_GALIL", "WEAPON_FAMAS", "WEAPON_USP", "WEAPON_GLOCK18", "WEAPON_AWP", "WEAPON_MP5NAVY", "WEAPON_M249",
	"WEAPON_M3", "WEAPON_M4A1", "WEAPON_TMP", "WEAPON_G3SG1", "WEAPON_FLASHBANG", "WEAPON_DEAGLE", "WEAPON_SG552",
	"WEAPON_AK47", "WEAPON_KNIFE", "WEAPON_P90"
};

new g_pCvar_Knockback_Damage;
new g_pCvar_Knockback_Power;
new g_pCvar_Knockback_Obey_Class;

new g_pCvar_Knockback_Zvel;
new g_pCvar_Knockback_Ducking;
new g_pCvar_Knockback_Distance;
new g_pCvar_Knockback_Nemesis;
new g_pCvar_Knockback_Assassin;

new g_iBit_Alive;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Knockback_Damage = register_cvar("zpe_knockback_damage", "1");
	g_pCvar_Knockback_Power = register_cvar("zpe_knockback_power", "1");
	g_pCvar_Knockback_Obey_Class = register_cvar("zpe_knockback_obey_class", "1");
	g_pCvar_Knockback_Zvel = register_cvar("zpe_knockback_zvel", "0");
	g_pCvar_Knockback_Ducking = register_cvar("zpe_knockback_ducking", "0.25");
	g_pCvar_Knockback_Distance = register_cvar("zpe_knockback_distance", "500");

	g_pCvar_Knockback_Nemesis = register_cvar("zpe_knockback_nemesis", "0.25");
	g_pCvar_Knockback_Assassin = register_cvar("zpe_knockback_assassin", "0.25");

	RegisterHam(Ham_TraceAttack, "player", "Ham_TraceAttack_Player_Post", 1);
}

public plugin_precache()
{
	for (new i = 1; i < sizeof g_Weapon_Entity_Names_UP; i++)
	{
		if (g_fKnockback_Weapon_Power[i] == -1.0)
		{
			continue;
		}

		amx_load_setting_float(ZPE_SETTINGS_FILE, "Knockback Power for Weapons", g_Weapon_Entity_Names_UP[i][7], g_fKnockback_Weapon_Power[i]);
	}
}

// Ham Trace Attack Post Forward
public Ham_TraceAttack_Player_Post(iVictim, iAttacker, Float:fDamage, Float:fDirection[3], iTracehandle, iDamage_Type)
{
	// Non-player damage or self damage
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return;
	}

	// Victim isn't zombie or attacker isn't human
	if (!zpe_core_is_zombie(iVictim) || zpe_core_is_zombie(iAttacker))
	{
		return;
	}

	// Not bullet damage
	if (!(iDamage_Type & DMG_BULLET))
	{
		return;
	}

	// Knockback only if damage is done to victim
	if (fDamage <= 0.0 || GetHamReturnStatus() == HAM_SUPERCEDE || get_tr2(iTracehandle, TR_pHit) != iVictim)
	{
		return;
	}

	// Nemesis knockback disabled, nothing else to do here
	if (zpe_class_nemesis_get(iVictim) && get_pcvar_float(g_pCvar_Knockback_Nemesis) == 0.0)
	{
		return;
	}

	// Assassin knockback disabled, nothing else to do here
	if (zpe_class_assassin_get(iVictim) && get_pcvar_float(g_pCvar_Knockback_Assassin) == 0.0)
	{
		return;
	}

	// Get whether the victim is in a crouch state
	new iDucking = get_entvar(iVictim, var_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND);

	// Zombie knockback when ducking disabled
	if (iDucking && get_pcvar_float(g_pCvar_Knockback_Ducking) == 0.0)
	{
		return;
	}

	// Get distance between players
	static iOrigin1[3];
	static iOrigin2[3];

	get_user_origin(iVictim, iOrigin1);
	get_user_origin(iAttacker, iOrigin2);

	// Max distance exceeded
	if (get_distance(iOrigin1, iOrigin2) > get_pcvar_num(g_pCvar_Knockback_Distance))
	{
		return;
	}

	// Get victim's velocity
	static Float:fVelocity[3];

	get_entvar(iVictim, var_velocity, fVelocity);

	// Use damage on knockback calculation
	if (get_pcvar_num(g_pCvar_Knockback_Damage))
	{
		xs_vec_mul_scalar(fDirection, fDamage, fDirection);
	}

	// Get attacker's weapon id
	new iAttacker_Weapon = CS_GET_WEAPON_ID(iAttacker);

	// Use weapon power on knockback calculation
	if (get_pcvar_num(g_pCvar_Knockback_Power) && g_fKnockback_Weapon_Power[iAttacker_Weapon] > 0.0)
	{
		xs_vec_mul_scalar(fDirection, g_fKnockback_Weapon_Power[iAttacker_Weapon], fDirection);
	}

	// Apply ducking knockback multiplier
	if (iDucking)
	{
		xs_vec_mul_scalar(fDirection, get_pcvar_float(g_pCvar_Knockback_Ducking), fDirection);
	}

	// Nemesis Class loaded?
	if (zpe_class_nemesis_get(iVictim))
	{
		// Apply nemesis knockback multiplier
		xs_vec_mul_scalar(fDirection, get_pcvar_float(g_pCvar_Knockback_Nemesis), fDirection);
	}

	// Assassin Class loaded?
	else if (zpe_class_assassin_get(iVictim))
	{
		// Apply assassin knockback multiplier
		xs_vec_mul_scalar(fDirection, get_pcvar_float(g_pCvar_Knockback_Assassin), fDirection);
	}

	else if (get_pcvar_num(g_pCvar_Knockback_Obey_Class))
	{
		// Apply zombie class knockback multiplier
		xs_vec_mul_scalar(fDirection, zpe_class_zombie_get_kb(zpe_class_zombie_get_current(iVictim)), fDirection);
	}

	// Add up the new vector
	xs_vec_add(fVelocity, fDirection, fDirection);

	// Should knockback also affect vertical velocity?
	if (!get_pcvar_num(g_pCvar_Knockback_Zvel))
	{
		fDirection[2] = fVelocity[2];
	}

	// Set the knockback'd victim's velocity
	set_entvar(iVictim, var_velocity, fDirection);
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