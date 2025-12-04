/* AMX Mod X
*	[ZPE] Class Zombie Leech.
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

#define PLUGIN "class zombie leech"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_class_zombie>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_kernel>

#define CLASS_ZOMBIE_LEECH_NAME "Leech Zombie"
#define CLASS_ZOMBIE_LEECH_INFO "HP- Knockback+ Leech++"
#define CLASS_ZOMBIE_LEECH_HEALTH 1300.0
#define CLASS_ZOMBIE_LEECH_ARMOR 0
#define CLASS_ZOMBIE_LEECH_SPEED 0.75
#define CLASS_ZOMBIE_LEECH_GRAVITY 1.0
#define CLASS_ZOMBIE_LEECH_KNOCKBACK 1.25

new const g_Class_Zombie_Leech_Models[][] =
{
	"zombie_source"
};

new const g_Class_Zombie_Leech_Clawmodels[][] =
{
	"models/zombie_plague_enterprise/v_knife_zombie.mdl"
};

new g_pCvar_Class_Zombie_Leech_HP_Reward;

new g_Class_Zombie_ID;

new g_iBit_Alive;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Class_Zombie_Leech_HP_Reward = register_cvar("zpe_class_zombie_leech_hp_reward", "200.0");

	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);
}

public plugin_precache()
{
	g_Class_Zombie_ID = zpe_class_zombie_register
	(
		CLASS_ZOMBIE_LEECH_NAME,
		CLASS_ZOMBIE_LEECH_INFO,
		CLASS_ZOMBIE_LEECH_HEALTH,
		CLASS_ZOMBIE_LEECH_ARMOR,
		CLASS_ZOMBIE_LEECH_SPEED,
		CLASS_ZOMBIE_LEECH_GRAVITY
	);

	zpe_class_zombie_register_kb(g_Class_Zombie_ID, CLASS_ZOMBIE_LEECH_KNOCKBACK);

	for (new i = 0; i < sizeof g_Class_Zombie_Leech_Models; i++)
	{
		zpe_class_zombie_register_model(g_Class_Zombie_ID, g_Class_Zombie_Leech_Models[i]);
	}

	for (new i = 0; i < sizeof g_Class_Zombie_Leech_Clawmodels; i++)
	{
		zpe_class_zombie_register_claw(g_Class_Zombie_ID, g_Class_Zombie_Leech_Clawmodels[i]);
	}
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/classes/zombie/Leech_Zombie.cfg");
}

public zpe_fw_core_infect_post(iPlayer, iAttacker)
{
	// Infected by a valid attacker?
	if (BIT_VALID(g_iBit_Alive, iAttacker) && iAttacker != iPlayer && zpe_core_is_zombie(iAttacker))
	{
		// Leech Zombie infection hp bonus
		if (zpe_class_zombie_get_current(iAttacker) == g_Class_Zombie_ID)
		{
			SET_USER_HEALTH(iAttacker, Float:GET_USER_HEALTH(iAttacker)) + get_pcvar_float(g_pCvar_Class_Zombie_Leech_HP_Reward);
		}
	}
}

public RG_CSGameRules_PlayerKilled_Post(iVictim, iAttacker)
{
	// Killed by a non-player entity or self killed
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return;
	}

	// Leech Zombie kill hp bonus
	if (zpe_core_is_zombie(iAttacker) && zpe_class_zombie_get_current(iAttacker) == g_Class_Zombie_ID)
	{
		// Unless nemesis and assassin
		if (!zpe_class_nemesis_get(iAttacker) || !zpe_class_assassin_get(iAttacker))
		{
			SET_USER_HEALTH(iAttacker, Float:GET_USER_HEALTH(iAttacker)) + get_pcvar_float(g_pCvar_Class_Zombie_Leech_HP_Reward);
		}
	}
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