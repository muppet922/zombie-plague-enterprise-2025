/* AMX Mod X
*	[ZPE] Objective remover.
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

#define PLUGIN "objective remover"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <fakemeta>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

#define CLASSNAME_MAX_LENGTH 32

new Array:g_aObjective_Entities;

new g_unfwSpawn;
new g_unfwPrecache_Sound;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	unregister_forward(FM_Spawn, g_unfwSpawn);
	unregister_forward(FM_PrecacheSound, g_unfwPrecache_Sound);

	register_forward(FM_EmitSound, "FM_EmitSound_");

	register_message(get_user_msgid("Scenario"), "Message_Scenario");
	register_message(get_user_msgid("HostagePos"), "Message_HostagePos");
}

public plugin_precache()
{
	// Initialize arrays
	g_aObjective_Entities = ArrayCreate(CLASSNAME_MAX_LENGTH, 1);

	// Load from external file
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Objective Entities", "OBJECTIVES", g_aObjective_Entities);

	// Fake hostage (to force round ending)
	new iEntity = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"));

	if (is_entity(iEntity))
	{
		engfunc(EngFunc_SetOrigin, iEntity, Float:{8192.0, 8192.0, 8192.0});

		dllfunc(DLLFunc_Spawn, iEntity);
	}

	// Prevent objective entities from spawning
	g_unfwSpawn = register_forward(FM_Spawn, "FM_Spawn_");

	// Prevent hostage sounds from being precached
	g_unfwPrecache_Sound = register_forward(FM_PrecacheSound, "FM_PrecacheSound_");
}

// Entity Spawn Forward
public FM_Spawn_(iEntity)
{
	// Invalid entity
	if (!is_entity(iEntity))
	{
		return FMRES_IGNORED;
	}

	// Get сlassname
	new szClassname[32];
	get_entvar(iEntity, var_classname, szClassname, charsmax(szClassname));

	new szRemove_Entity_Name[CLASSNAME_MAX_LENGTH];
	new iRemove_Entity_Count = ArraySize(g_aObjective_Entities);

	// Check whether it needs to be removed
	for (new i = 0; i < iRemove_Entity_Count; i++)
	{
		ArrayGetString(g_aObjective_Entities, i, szRemove_Entity_Name, charsmax(szRemove_Entity_Name));

		if (equal(szClassname, szRemove_Entity_Name))
		{
			engfunc(EngFunc_RemoveEntity, iEntity);

			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

// Sound Precache Forward
public FM_PrecacheSound_(const szSound[])
{
	// Block all those unneeded hostage sounds
	if (equal(szSound, "hostage", 7))
	{
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

// Emit Sound Forward
public FM_EmitSound_(iPlayer, iChannel, const szSample[])
{
	// Block all those unneeded hostage sounds
	if (szSample[0] == 'h' && szSample[1] == 'o' && szSample[2] == 's' && szSample[3] == 't' && szSample[4] == 'a' && szSample[5] == 'g' && szSample[6] == 'e')
	{
		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

// Block hostage HUD display
public Message_Scenario()
{
	if (get_msg_args() > 1)
	{
		new szSprite[8];

		get_msg_arg_string(2, szSprite, charsmax(szSprite));

		if (equal(szSprite, "hostage"))
		{
			return PLUGIN_HANDLED;
		}
	}

	return PLUGIN_CONTINUE;
}

// Block hostages from appearing on radar
public Message_HostagePos()
{
	return PLUGIN_HANDLED;
}