/* AMX Mod X
*	[ZPE] Class Sounds.
*	Author: C&K Corporation.
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

#define PLUGIN "class sounds"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <amx_settings_api>
#include <zpe_class_zombie>
#include <zpe_class_human>
#include <zpe_sounds_api>

#define ZPE_CLASS_ZOMBIE_SETTINGS_PATH "ZPE/classes/zombie"
#define ZPE_CLASS_HUMAN_SETTINGS_PATH "ZPE/classes/human"

new const g_szSound_Section_Name[] = "Sounds";

new const g_szZombie_Sound_Types[_:ZOMBIE_SOUNDS][] =
{
	"DIE",
	"FALL",
	"PAIN",
	"MISS SLASH",
	"HIT SOLID",
	"HIT NORMAL",
	"HIT STAB",
	"INFECT",
	"IDLE",
	"FLAME"
};

new const g_szHuman_Sound_Types[_:HUMAN_SOUNDS][] =
{
	"DIE",
	"FALL",
	"PAIN",
	"MISS SLASH",
	"HIT SOLID",
	"HIT NORMAL",
	"HIT STAB",
	"IDLE"
};

new Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUNDS];
new Array:g_aDefault_Human_Sounds[_:HUMAN_SOUNDS];

Init_Defualut_Zombie_Sounds()
{
	for (new i = 0; i < _:ZOMBIE_SOUNDS; i++)
	{
		g_aDefault_Zombie_Sounds[i] = ArrayCreate(128, 1);
	}

	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_DIE], "zombie_plague_enterprise/zombie_sounds/zombie_die0.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_DIE], "zombie_plague_enterprise/zombie_sounds/zombie_die1.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_DIE], "zombie_plague_enterprise/zombie_sounds/zombie_die2.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_FALL], "zombie_plague_enterprise/zombie_sounds/zombie_fall0.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_PAIN], "zombie_plague_enterprise/zombie_sounds/zombie_pain0.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_PAIN], "zombie_plague_enterprise/zombie_sounds/zombie_pain1.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_MISS_SLASH], "zombie_plague_enterprise/zombie_sounds/zombie_miss_slash0.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_MISS_SLASH], "zombie_plague_enterprise/zombie_sounds/zombie_miss_slash1.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_HIT_SOLID], "zombie_plague_enterprise/zombie_sounds/zombie_hit_solid0.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_HIT_SOLID], "zombie_plague_enterprise/zombie_sounds/zombie_hit_solid1.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_HIT_SOLID], "zombie_plague_enterprise/zombie_sounds/zombie_hit_solid2.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_HIT_SOLID], "zombie_plague_enterprise/zombie_sounds/zombie_hit_solid3.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_HIT_SOLID], "zombie_plague_enterprise/zombie_sounds/zombie_hit_solid4.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_HIT_SOLID], "zombie_plague_enterprise/zombie_sounds/zombie_hit_solid5.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_HIT_NORMAL], "zombie_plague_enterprise/zombie_sounds/zombie_hit_normal0.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_HIT_NORMAL], "zombie_plague_enterprise/zombie_sounds/zombie_hit_normal1.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_HIT_STAB], "zombie_plague_enterprise/zombie_sounds/zombie_hit_stab0.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_INFECT], "zombie_plague_enterprise/zombie_sounds/zombie_infect0.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_INFECT], "zombie_plague_enterprise/zombie_sounds/zombie_infect1.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_IDLE], "zombie_plague_enterprise/zombie_sounds/zombie_idle0.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_IDLE], "zombie_plague_enterprise/zombie_sounds/zombie_idle1.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_FLAME], "zombie_plague_enterprise/zombie_sounds/zombie_burn0.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_FLAME], "zombie_plague_enterprise/zombie_sounds/zombie_burn1.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_FLAME], "zombie_plague_enterprise/zombie_sounds/zombie_burn2.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_FLAME], "zombie_plague_enterprise/zombie_sounds/zombie_burn3.wav");
	ArrayPushString(Array:g_aDefault_Zombie_Sounds[_:ZOMBIE_SOUND_FLAME], "zombie_plague_enterprise/zombie_sounds/zombie_burn4.wav");
}

Init_Defualut_Human_Sounds()
{
	for (new i = 0; i < _:HUMAN_SOUNDS; i++)
	{
		g_aDefault_Human_Sounds[i] = ArrayCreate(128, 1);
	}

	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_DIE], "player/die1.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_DIE], "player/die2.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_DIE], "player/die3.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_FALL], "player/pl_fallpain1.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_FALL], "player/pl_fallpain2.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_FALL], "player/pl_fallpain3.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_PAIN], "player/pl_pain2.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_PAIN], "player/pl_pain4.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_PAIN], "player/pl_pain5.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_PAIN], "player/pl_pain6.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_PAIN], "player/pl_pain7.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_MISS_SLASH], "weapons/knife_slash1.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_HIT_SOLID], "weapons/knife_hit_solid1.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_HIT_NORMAL], "weapons/knife_hit1.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_HIT_NORMAL], "weapons/knife_hit2.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_HIT_NORMAL], "weapons/knife_hit3.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_HIT_NORMAL], "weapons/knife_hit4.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_HIT_STAB], "weapons/knife_stab.wav");
	ArrayPushString(Array:g_aDefault_Human_Sounds[_:HUMAN_SOUND_IDLE], "hostage/hos1.wav");
}

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
}

public zpe_fw_class_zombie_register_post(iClass_ID)
{
	if (g_aDefault_Zombie_Sounds[0] == Invalid_Array)
	{
		Init_Defualut_Zombie_Sounds();
	}

	new szReal_Name[32];
	zpe_class_zombie_get_real_name(iClass_ID, szReal_Name, charsmax(szReal_Name));

	new szClass_Zombie_Config_Path[64];
	formatex(szClass_Zombie_Config_Path, charsmax(szClass_Zombie_Config_Path), "%s/%s.ini", ZPE_CLASS_ZOMBIE_SETTINGS_PATH, szReal_Name);

	new Array:aSounds = ArrayCreate(128, 1);
	new szSound[128];
	new iArraySize;

	for (new i = 0; i < _:ZOMBIE_SOUNDS; i++)
	{
		amx_load_setting_string_arr(szClass_Zombie_Config_Path, g_szSound_Section_Name, g_szZombie_Sound_Types[i], aSounds);

		iArraySize = ArraySize(aSounds);

		if (iArraySize > 0)
		{
			for (new j = 0; j < iArraySize; j++)
			{
				ArrayGetString(aSounds, j, szSound, charsmax(szSound));
				zpe_class_zombie_register_sound(iClass_ID, ZOMBIE_SOUNDS:i, szSound);
			}

			ArrayClear(aSounds);
		}

		else
		{
			iArraySize = ArraySize(g_aDefault_Zombie_Sounds[i]);

			for (new j = 0; j < iArraySize; j++)
			{
				ArrayGetString(g_aDefault_Zombie_Sounds[i], j, szSound, charsmax(szSound));
				zpe_class_zombie_register_sound(iClass_ID, ZOMBIE_SOUNDS:i, szSound);
			}

			amx_save_setting_string_arr(szClass_Zombie_Config_Path, g_szSound_Section_Name, g_szZombie_Sound_Types[i], g_aDefault_Zombie_Sounds[i]);
		}
	}

	ArrayDestroy(aSounds);
}

public zpe_fw_class_human_register_post(iClass_ID)
{
	if (g_aDefault_Human_Sounds[0] == Invalid_Array)
	{
		Init_Defualut_Human_Sounds();
	}

	new szReal_Name[32];
	zpe_class_human_get_real_name(iClass_ID, szReal_Name, charsmax(szReal_Name));

	new szClass_Human_Config_Path[64];
	formatex(szClass_Human_Config_Path, charsmax(szClass_Human_Config_Path), "%s/%s.ini", ZPE_CLASS_HUMAN_SETTINGS_PATH, szReal_Name);

	new Array:aSounds = ArrayCreate(128, 1);
	new szSound[128];
	new iArraySize;

	for (new i = 0; i < _:HUMAN_SOUNDS; i++)
	{
		amx_load_setting_string_arr(szClass_Human_Config_Path, g_szSound_Section_Name, g_szZombie_Sound_Types[i], aSounds);

		iArraySize = ArraySize(aSounds);

		if (iArraySize > 0)
		{
			for (new j = 0; j < iArraySize; j++)
			{
				ArrayGetString(aSounds, j, szSound, charsmax(szSound));
				zpe_class_human_register_sound(iClass_ID, HUMAN_SOUNDS:i, szSound);
			}

			ArrayClear(aSounds);
		}

		else
		{
			iArraySize = ArraySize(g_aDefault_Human_Sounds[i]);

			for (new j = 0; j < iArraySize; j++)
			{
				ArrayGetString(g_aDefault_Human_Sounds[i], j, szSound, charsmax(szSound));
				zpe_class_human_register_sound(iClass_ID, HUMAN_SOUNDS:i, szSound);
			}

			amx_save_setting_string_arr(szClass_Human_Config_Path, g_szSound_Section_Name, g_szHuman_Sound_Types[i], g_aDefault_Human_Sounds[i]);
		}
	}

	ArrayDestroy(aSounds);
}
