/* AMX Mod X
*	[ZPE] Effects Lighting.
*	Author: MeRcyLeZZ. Edition: C&K Corporation.
*
*	https://ckcorp.ru/ - support from the C&K Corporation.
*	https://forum.ckcorp.ru/ - forum support from the C&K Corporation.
*	https://wiki.ckcorp.ru - documentation and other useful information.
*	https://news.ckcorp.ru/ - other info.
*
*	https://git.ckcorp.ru/ck/game-dev/amxx-modes/zpe - development.
*
*	Support is provided only on the site.
*/

#define PLUGIN "effects lighting"
#define VERSION "6.5.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <engine>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

#define LIGHTS_MAX_LENGTH 32
#define SKY_NAME_MAX_LENGTH 32
#define SKY_PATH_MAX_LENGTH 64

new Array:g_aLightning_Cycles;
new Array:g_aThunder_Sounds;

new g_szCustom_Sky_Name[SKY_NAME_MAX_LENGTH];
new bool:g_bCustom_Sky_Enable = false;

new g_iLightning_Frame_Index;
new g_iLightning_Frame_Count;
new g_szLightning_Frames[LIGHTS_MAX_LENGTH];

new g_pCvar_Light;
new g_pCvar_Lightning_Interval;
new g_pCvar_Triggered_Lights;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Light = register_cvar("zpe_light", "b");
	hook_cvar_change(g_pCvar_Light, "Change_Cvar_Light");

	g_pCvar_Lightning_Interval = register_cvar("zpe_lightning_interval", "25");
	hook_cvar_change(g_pCvar_Lightning_Interval, "Change_Cvar_Lightning_Interval");

	g_pCvar_Triggered_Lights = register_cvar("zpe_triggered_lights", "1");

	register_event("HLTV", "Event_Round_Start", "a", "1=0", "2=0");

	// Set a random skybox?
	if (g_bCustom_Sky_Enable)
	{
		set_cvar_string("sv_skyname", g_szCustom_Sky_Name);
	}
}

public plugin_precache()
{
	// Load Skies
	amx_load_setting_int(ZPE_SETTINGS_FILE, "Custom Skies", "ENABLE", g_bCustom_Sky_Enable)

	if (g_bCustom_Sky_Enable)
	{
		new Array:aSky_Names = ArrayCreate(SKY_NAME_MAX_LENGTH, 1);
		amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Custom Skies", "SKY NAMES", aSky_Names);
		ArrayGetString(aSky_Names, RANDOM(ArraySize(aSky_Names)), g_szCustom_Sky_Name, charsmax(g_szCustom_Sky_Name));
		ArrayDestroy(aSky_Names);

		new const szSky_Name_Suffixes[][] =
		{
			"bk",
			"dn",
			"ft",
			"lf",
			"rt",
			"up"
		}

		new szSky_Path[SKY_PATH_MAX_LENGTH];

		for (new i = 0; i < sizeof szSky_Name_Suffixes; i++)
		{
			formatex(szSky_Path, charsmax(szSky_Path), "gfx/env/%s%s.tga", g_szCustom_Sky_Name, szSky_Name_Suffixes[i]);
			precache_generic(szSky_Path);
		}
	}

	// Load lightning cycles
	g_aLightning_Cycles = ArrayCreate(LIGHTS_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Lightning Cycle", "FRAMES", g_aLightning_Cycles);

	// Load thunder sounds
	g_aThunder_Sounds = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "THUNDER", g_aThunder_Sounds);
	Precache_Sounds(g_aThunder_Sounds);
}

public plugin_cfg()
{
	// Set lighting style
	new szLight[2];
	get_pcvar_string(g_pCvar_Light, szLight, charsmax(szLight));
	set_lights(szLight);

	// Lightning task
	new iInterval = get_pcvar_num(g_pCvar_Lightning_Interval);

	if (iInterval > 0)
	{
		set_task(float(iInterval), "Task_Lightning");
	}

	// Call roundstart manually
	Event_Round_Start();
}

public Change_Cvar_Light(pCvar, const szOld_Value[], const szNew_Value[])
{
	set_lights(szNew_Value);
}

public Change_Cvar_Lightning_Interval(pCvar, const szOld_Value[], const szNew_Value[])
{
	if (!task_exists())
	{
		new iInterval = str_to_num(szNew_Value);

		if (iInterval > 0)
		{
			set_task(float(iInterval), "Task_Lightning");
		}
	}
}

// Event round start
public Event_Round_Start()
{
	// Remove lights?
	if (!get_pcvar_num(g_pCvar_Triggered_Lights))
	{
		new iEntity = -1;

		while ((iEntity = engfunc(EngFunc_FindEntityByString, iEntity, "classname", "light")) != 0)
		{
			dllfunc(DLLFunc_Use, iEntity, 0); // Turn off the light

			set_entvar(iEntity, var_targetname, 0); // Prevent it from being triggered
		}
	}
}

public Task_Lightning()
{
	new szRandom_Cycle[LIGHTS_MAX_LENGTH];
	ArrayGetString(g_aLightning_Cycles, RANDOM(ArraySize(g_aLightning_Cycles)), szRandom_Cycle, LIGHTS_MAX_LENGTH - 1);
	formatex(g_szLightning_Frames, LIGHTS_MAX_LENGTH - 1, szRandom_Cycle);

	g_iLightning_Frame_Index = 0;
	g_iLightning_Frame_Count = strlen(szRandom_Cycle);

	set_task(0.1, "Task_Lightning_Frame", _, _, _, "b");
}

public Task_Lightning_Frame()
{
	new szFrame[2];
	szFrame[0] = g_szLightning_Frames[g_iLightning_Frame_Index];
	set_lights(szFrame);

	g_iLightning_Frame_Index++;

	if (g_iLightning_Frame_Index >= g_iLightning_Frame_Count)
	{
		remove_task();

		// Restoring base light after lightning
		new szLight[2];
		get_pcvar_string(g_pCvar_Light, szLight, charsmax(szLight));
		set_lights(szLight);

		set_task(random_float(0.5, 2.5), "Task_Thunder")
	}
}

public Task_Thunder()
{
	new szRandom_Sound[SOUND_MAX_LENGTH];
	ArrayGetString(g_aThunder_Sounds, RANDOM(ArraySize(g_aThunder_Sounds)), szRandom_Sound, charsmax(szRandom_Sound));
	Play_Sound_To_Clients(szRandom_Sound);

	// Looping ligntning
	new iInterval = get_pcvar_num(g_pCvar_Lightning_Interval);

	if (iInterval > 0)
	{
		set_task(float(iInterval), "Task_Lightning");
	}
}

// Plays a sound on clients
Play_Sound_To_Clients(const szSound[])
{
	if (equal(szSound[strlen(szSound) - 4], ".mp3"))
	{
		client_cmd(0, "mp3 play ^"sound/%s^"", szSound);
	}

	else
	{
		client_cmd(0, "spk ^"%s^"", szSound);
	}
}