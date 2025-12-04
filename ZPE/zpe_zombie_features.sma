/* AMX Mod X
*	[ZPE] Zombie Features.
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

#define PLUGIN "zombie features"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

#define CS_DEFAULT_FOV 90

new Array:g_aBleeding_Decals;
new g_iDecal_Count;

new g_Message_Set_Fov;

new g_pCvar_Zombie_Fov;

new g_pCvar_Nemesis_Silent;
new g_pCvar_Assassin_Silent;
new g_pCvar_Zombie_Silent;

new g_pCvar_Nemesis_Bleeding;
new g_pCvar_Assassin_Bleeding;
new g_pCvar_Zombie_Bleeding;

new g_iBit_Alive;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Zombie_Fov = register_cvar("zpe_zombie_fov", "110");

	g_pCvar_Nemesis_Silent = register_cvar("zpe_nemesis_silent", "1");
	g_pCvar_Assassin_Silent = register_cvar("zpe_assassin_silent", "1");
	g_pCvar_Zombie_Silent = register_cvar("zpe_zombie_silent", "1");

	g_pCvar_Nemesis_Bleeding = register_cvar("zpe_nemesis_bleeding", "1");
	g_pCvar_Assassin_Bleeding = register_cvar("zpe_assassin_bleeding", "1");
	g_pCvar_Zombie_Bleeding = register_cvar("zpe_zombie_bleeding", "1");

	g_Message_Set_Fov = get_user_msgid("SetFOV");

	register_message(g_Message_Set_Fov, "Message_Setfov");

	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);
}

public plugin_precache()
{
	// Initialize arrays
	g_aBleeding_Decals = ArrayCreate(1, 1);

	new Array:aDecal_Names = ArrayCreate(32, 1);

	// Load from external file
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Zombie Decals", "DECALS", aDecal_Names);

	new szDecal_Name[32];
	g_iDecal_Count = ArraySize(aDecal_Names);

	for (new i = 0; i < g_iDecal_Count; i++)
	{
		ArrayGetString(aDecal_Names, i, szDecal_Name, charsmax(szDecal_Name));

		ArrayPushCell(g_aBleeding_Decals, engfunc(EngFunc_DecalIndex, szDecal_Name));
	}

	ArrayDestroy(aDecal_Names);
}

public RG_CSGameRules_PlayerKilled_Post(iVictim)
{
	// Remove bleeding task
	remove_task(iVictim);
}

public Message_Setfov(iMessage_ID, iMessage_Dest, iMessage_Entity)
{
	if (BIT_NOT_VALID(g_iBit_Alive, iMessage_Entity) || !zpe_core_is_zombie(iMessage_Entity) || get_msg_arg_int(1) != CS_DEFAULT_FOV)
	{
		return;
	}

	set_msg_arg_int(1, get_msg_argtype(1), get_pcvar_num(g_pCvar_Zombie_Fov));
}

public zpe_fw_core_infect_post(iPlayer)
{
	// Set custom FOV?
	if (get_pcvar_num(g_pCvar_Zombie_Fov) != CS_DEFAULT_FOV && get_pcvar_num(g_pCvar_Zombie_Fov) != 0)
	{
		message_begin(MSG_ONE, g_Message_Set_Fov, _, iPlayer);
		write_byte(get_pcvar_num(g_pCvar_Zombie_Fov)); // angle
		message_end();
	}

	// Remove previous tasks
	remove_task(iPlayer);

	// Nemesis Class loaded?
	if (zpe_class_nemesis_get(iPlayer))
	{
		// Set silent footsteps?
		if (get_pcvar_num(g_pCvar_Nemesis_Silent))
		{
			rg_set_user_footsteps(iPlayer, true);
		}

		// Nemesis bleeding?
		if (get_pcvar_num(g_pCvar_Nemesis_Bleeding) && g_iDecal_Count > 0)
		{
			set_task(0.7, "Zombie_Bleeding", iPlayer, _, _, "b");
		}
	}

	// Assassin Class loaded?
	else if (zpe_class_assassin_get(iPlayer))
	{
		// Set silent footsteps?
		if (get_pcvar_num(g_pCvar_Assassin_Silent))
		{
			rg_set_user_footsteps(iPlayer, true);
		}

		// Assassin bleeding?
		if (get_pcvar_num(g_pCvar_Assassin_Bleeding) && g_iDecal_Count > 0)
		{
			set_task(0.7, "Zombie_Bleeding", iPlayer, _, _, "b");
		}
	}

	else
	{
		// Set silent footsteps?
		if (get_pcvar_num(g_pCvar_Zombie_Silent))
		{
			rg_set_user_footsteps(iPlayer, true);
		}

		// Zombie bleeding?
		if (get_pcvar_num(g_pCvar_Zombie_Bleeding) && g_iDecal_Count > 0)
		{
			set_task(0.7, "Zombie_Bleeding", iPlayer, _, _, "b");
		}
	}
}

public zpe_fw_core_cure_post(iPlayer)
{
	// Restore FOV?
	if (get_pcvar_num(g_pCvar_Zombie_Fov) != CS_DEFAULT_FOV && get_pcvar_num(g_pCvar_Zombie_Fov) != 0)
	{
		message_begin(MSG_ONE, g_Message_Set_Fov, _, iPlayer);
		write_byte(CS_DEFAULT_FOV); // angle
		message_end();
	}

	// Restore normal footsteps?
	if (rg_get_user_footsteps(iPlayer))
	{
		rg_set_user_footsteps(iPlayer, false);
	}

	// Remove bleeding task
	remove_task(iPlayer);
}

// Make zombies leave footsteps and bloodstains on the floor
public Zombie_Bleeding(iPlayer)
{
	// Only bleed when moving on ground
	if (!(get_entvar(iPlayer, var_flags) & FL_ONGROUND) || _fm_get_speed(iPlayer) < 80)
	{
		return;
	}

	// Get user origin
	static Float:fOrigin[3];

	get_entvar(iPlayer, var_origin, fOrigin);

	// If ducking set a little lower
	if (get_entvar(iPlayer, var_bInDuck))
	{
		fOrigin[2] -= 18.0;
	}

	else
	{
		fOrigin[2] -= 36.0;
	}

	// Send the decal message
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_WORLDDECAL); // TE player
	engfunc(EngFunc_WriteCoord, fOrigin[0]); // x
	engfunc(EngFunc_WriteCoord, fOrigin[1]); // y
	engfunc(EngFunc_WriteCoord, fOrigin[2]); // z
	write_byte(ArrayGetCell(g_aBleeding_Decals, RANDOM(g_iDecal_Count))); // decal number
	message_end();
}

public client_disconnected(iPlayer)
{
	// Remove bleeding task
	remove_task(iPlayer);

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