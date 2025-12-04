/* AMX Mod X
*	[ZPE] Class Zombie Rage.
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

#define PLUGIN "class zombie rage"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_class_zombie>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>

#define CLASS_ZOMBIE_RAGE_NAME "Rage Zombie"
#define CLASS_ZOMBIE_RAGE_INFO "HP+ Speed+ Radioactivity++"
#define CLASS_ZOMBIE_RAGE_HEALTH 2250.0
#define CLASS_ZOMBIE_RAGE_ARMOR 0
#define CLASS_ZOMBIE_RAGE_SPEED 0.80
#define CLASS_ZOMBIE_RAGE_GRAVITY 1.0
#define CLASS_ZOMBIE_RAGE_KNOCKBACK 0.5

new const g_Class_Zombie_Rage_Models[][] =
{
	"zombie_source"
};

new const g_Class_Zombie_Rage_Clawmodels[][] =
{
	"models/zombie_plague_enterprise/v_knife_zombie.mdl"
};

new g_pCvar_Class_Zombie_Rage_Aura_R;
new g_pCvar_Class_Zombie_Rage_Aura_G;
new g_pCvar_Class_Zombie_Rage_Aura_B;

new g_Class_Zombie_ID;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Class_Zombie_Rage_Aura_R = register_cvar("zpe_class_zombie_rage_aura_r", "0");
	g_pCvar_Class_Zombie_Rage_Aura_G = register_cvar("zpe_class_zombie_rage_aura_g", "250");
	g_pCvar_Class_Zombie_Rage_Aura_B = register_cvar("zpe_class_zombie_rage_aura_b", "0");
}

public plugin_precache()
{
	g_Class_Zombie_ID = zpe_class_zombie_register
	(
		CLASS_ZOMBIE_RAGE_NAME,
		CLASS_ZOMBIE_RAGE_INFO,
		CLASS_ZOMBIE_RAGE_HEALTH,
		CLASS_ZOMBIE_RAGE_ARMOR,
		CLASS_ZOMBIE_RAGE_SPEED,
		CLASS_ZOMBIE_RAGE_GRAVITY
	);

	zpe_class_zombie_register_kb(g_Class_Zombie_ID, CLASS_ZOMBIE_RAGE_KNOCKBACK);

	for (new i = 0; i < sizeof g_Class_Zombie_Rage_Models; i++)
	{
		zpe_class_zombie_register_model(g_Class_Zombie_ID, g_Class_Zombie_Rage_Models[i]);
	}

	for (new i = 0; i < sizeof g_Class_Zombie_Rage_Clawmodels; i++)
	{
		zpe_class_zombie_register_claw(g_Class_Zombie_ID, g_Class_Zombie_Rage_Clawmodels[i]);
	}
}

public zpe_fw_core_infect_post(iPlayer)
{
	// Rage Zombie glow
	if (zpe_class_zombie_get_current(iPlayer) == g_Class_Zombie_ID)
	{
		// Apply custom glow, unless nemesis and assassin
		if (!zpe_class_nemesis_get(iPlayer) || !zpe_class_assassin_get(iPlayer))
		{
			rg_set_user_rendering(iPlayer, kRenderFxGlowShell, get_pcvar_num(g_pCvar_Class_Zombie_Rage_Aura_R), get_pcvar_num(g_pCvar_Class_Zombie_Rage_Aura_G), get_pcvar_num(g_pCvar_Class_Zombie_Rage_Aura_B), kRenderNormal, 15);
		}
	}
}

public zpe_fw_core_infect(iPlayer)
{
	// Player was using zombie class with custom rendering, restore it to normal
	if (zpe_class_zombie_get_current(iPlayer) == g_Class_Zombie_ID)
	{
		rg_set_user_rendering(iPlayer);
	}
}

public zpe_fw_core_cure(iPlayer)
{
	// Player was using zombie class with custom rendering, restore it to normal
	if (zpe_class_zombie_get_current(iPlayer) == g_Class_Zombie_ID)
	{
		rg_set_user_rendering(iPlayer);
	}
}

public client_disconnected(iPlayer)
{
	// Player was using zombie class with custom rendering, restore it to normal
	if (zpe_class_zombie_get_current(iPlayer) == g_Class_Zombie_ID)
	{
		rg_set_user_rendering(iPlayer);
	}
}