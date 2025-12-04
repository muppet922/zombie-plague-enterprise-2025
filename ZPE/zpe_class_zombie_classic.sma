/* AMX Mod X
*	[ZPE] Class Zombie Classic.
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

#define PLUGIN "class zombie classic"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <amx_settings_api>
#include <zpe_class_zombie>

#define CLASS_ZOMBIE_CLASSIC_NAME "Classic Zombie"
#define CLASS_ZOMBIE_CLASSIC_INFO "=Balanced="
#define CLASS_ZOMBIE_CLASSIC_HEALTH 1800.0
#define CLASS_ZOMBIE_CLASSIC_ARMOR 0
#define CLASS_ZOMBIE_CLASSIC_SPEED 0.75
#define CLASS_ZOMBIE_CLASSIC_GRAVITY 1.0
#define CLASS_ZOMBIE_CLASSIC_KNOCKBACK 1.0

new const g_Class_Zombie_Classic_Models[][] =
{
	"zombie_source"
};

new const g_Class_Zombie_Classic_Clawmodels[][] =
{
	"models/zombie_plague_enterprise/v_knife_zombie.mdl"
};

new g_Zombie_Class_ID;

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_Zombie_Class_ID = zpe_class_zombie_register
	(
		CLASS_ZOMBIE_CLASSIC_NAME,
		CLASS_ZOMBIE_CLASSIC_INFO,
		CLASS_ZOMBIE_CLASSIC_HEALTH,
		CLASS_ZOMBIE_CLASSIC_ARMOR,
		CLASS_ZOMBIE_CLASSIC_SPEED,
		CLASS_ZOMBIE_CLASSIC_GRAVITY
	);

	zpe_class_zombie_register_kb(g_Zombie_Class_ID, CLASS_ZOMBIE_CLASSIC_KNOCKBACK);

	for (new i = 0; i < sizeof g_Class_Zombie_Classic_Models; i++)
	{
		zpe_class_zombie_register_model(g_Zombie_Class_ID, g_Class_Zombie_Classic_Models[i]);
	}

	for (new i = 0; i < sizeof g_Class_Zombie_Classic_Clawmodels; i++)
	{
		zpe_class_zombie_register_claw(g_Zombie_Class_ID, g_Class_Zombie_Classic_Clawmodels[i]);
	}
}