/* AMX Mod X
*	[ZPE] Class Zombie Light.
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

#define PLUGIN "class zombie light"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <amx_settings_api>
#include <zpe_class_zombie>

#define CLASS_ZOMBIE_LIGHT_NAME "Light Zombie"
#define CLASS_ZOMBIE_LIGHT_INFO "HP- Jump+ Knockback+"
#define CLASS_ZOMBIE_LIGHT_HEALTH 1400.0
#define CLASS_ZOMBIE_LIGHT_ARMOR 0
#define CLASS_ZOMBIE_LIGHT_SPEED 0.75
#define CLASS_ZOMBIE_LIGHT_GRAVITY 0.75
#define CLASS_ZOMBIE_LIGHT_KNOCKBACK 1.25

new const g_Class_Zombie_Light_Models[][] =
{
	"zombie_source"
};

new const g_Class_Zombie_Light_Clawmodels[][] =
{
	"models/zombie_plague_enterprise/v_knife_zombie.mdl"
};

new g_Class_Zombie_ID;

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_Class_Zombie_ID = zpe_class_zombie_register
	(
		CLASS_ZOMBIE_LIGHT_NAME,
		CLASS_ZOMBIE_LIGHT_INFO,
		CLASS_ZOMBIE_LIGHT_HEALTH,
		CLASS_ZOMBIE_LIGHT_ARMOR,
		CLASS_ZOMBIE_LIGHT_SPEED,
		CLASS_ZOMBIE_LIGHT_GRAVITY
	);

	zpe_class_zombie_register_kb(g_Class_Zombie_ID, CLASS_ZOMBIE_LIGHT_KNOCKBACK);

	for (new i = 0; i < sizeof g_Class_Zombie_Light_Models; i++)
	{
		zpe_class_zombie_register_model(g_Class_Zombie_ID, g_Class_Zombie_Light_Models[i]);
	}

	for (new i = 0; i < sizeof g_Class_Zombie_Light_Clawmodels; i++)
	{
		zpe_class_zombie_register_claw(g_Class_Zombie_ID, g_Class_Zombie_Light_Clawmodels[i]);
	}
}