/* AMX Mod X
*	[ZPE] Class Human Classic.
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

#define PLUGIN "class human classic"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <zpe_class_human>

#define CLASS_HUMAN_CLASSIC_NAME "Classic Human"
#define CLASS_HUMAN_CLASSIC_INFO "=Balanced="
#define CLASS_HUMAN_CLASSIC_HEALTH 100.0
#define CLASS_HUMAN_CLASSIC_ARMOR 0
#define CLASS_HUMAN_CLASSIC_SPEED 1.0
#define CLASS_HUMAN_CLASSIC_GRAVITY 1.0

new const g_Class_Human_Classic_Deploy_Sounds[][] =
{
	"weapons/knife_deploy1.wav"
};

new const g_Class_Human_Classic_Models[][] =
{
	"arctic",
	"guerilla",
	"leet",
	"terror",
	"gign",
	"gsg9",
	"sas",
	"urban"
};

public plugin_precache()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	new iClass_Human_ID = zpe_class_human_register(CLASS_HUMAN_CLASSIC_NAME, CLASS_HUMAN_CLASSIC_INFO, CLASS_HUMAN_CLASSIC_HEALTH, CLASS_HUMAN_CLASSIC_ARMOR, CLASS_HUMAN_CLASSIC_SPEED, CLASS_HUMAN_CLASSIC_GRAVITY);

	for (new i = 0; i < sizeof g_Class_Human_Classic_Models; i++)
	{
		zpe_class_human_register_model(iClass_Human_ID, g_Class_Human_Classic_Models[i]);
	}

	// Fix bug deploy sound
	for (new i = 0; i < sizeof g_Class_Human_Classic_Deploy_Sounds; i++)
	{
		precache_sound(g_Class_Human_Classic_Deploy_Sounds[i]);
	}
}