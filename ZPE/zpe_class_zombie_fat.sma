/* AMX Mod X
*	[ZPE] Class Zombie Fat.
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

#define PLUGIN "class zombie fat"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <amx_settings_api>
#include <zpe_class_zombie>

#define CLASS_ZOMBIE_FAT_NAME "Fat Zombie"
#define CLASS_ZOMBIE_FAT_INFO "HP++ Speed- Knockback--"
#define CLASS_ZOMBIE_FAT_HEALTH 2700.0
#define CLASS_ZOMBIE_FAT_ARMOR 0
#define CLASS_ZOMBIE_FAT_SPEED 0.65
#define CLASS_ZOMBIE_FAT_GRAVITY 1.0
#define CLASS_ZOMBIE_FAT_KNOCKBACK 0.5

new const g_Class_Zombie_Fat_Models[][] =
{
	"zombie_source"
};

new const g_Class_Zombie_Fat_Clawmodels[][] =
{
	"models/zombie_plague_enterprise/v_knife_zombie.mdl"
};

new g_Zombie_Class_ID;

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_Zombie_Class_ID = zpe_class_zombie_register
	(
		CLASS_ZOMBIE_FAT_NAME,
		CLASS_ZOMBIE_FAT_INFO,
		CLASS_ZOMBIE_FAT_HEALTH,
		CLASS_ZOMBIE_FAT_ARMOR,
		CLASS_ZOMBIE_FAT_SPEED,
		CLASS_ZOMBIE_FAT_GRAVITY
	);

	zpe_class_zombie_register_kb(g_Zombie_Class_ID, CLASS_ZOMBIE_FAT_KNOCKBACK);

	for (new i = 0; i < sizeof g_Class_Zombie_Fat_Models; i++)
	{
		zpe_class_zombie_register_model(g_Zombie_Class_ID, g_Class_Zombie_Fat_Models[i]);
	}

	for (new i = 0; i < sizeof g_Class_Zombie_Fat_Clawmodels; i++)
	{
		zpe_class_zombie_register_claw(g_Zombie_Class_ID, g_Class_Zombie_Fat_Clawmodels[i]);
	}
}