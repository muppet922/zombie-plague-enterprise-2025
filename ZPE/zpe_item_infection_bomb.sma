/* AMX Mod X
*	[ZPE] Item Infection Grenade.
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

#define PLUGIN "grenade infection"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <ck_cs_weap_models_api>
#include <amx_settings_api>
#include <hamsandwich>
#include <zpe_kernel>
#include <zpe_items>
#include <zpe_gamemodes>

#define ZPE_SETTINGS_FILE "ZPE/zpe_items.ini"

#define ITEM_NAME "Infection Grenade"
#define ITEM_COST 15

// HACK: var_ field used to store custom nade types and their values
#define PEV_NADE_TYPE var_flTimeStepSound
#define NADE_TYPE_INFECTION 1111

#define GRENADE_INFECTION_SPRITE_TRAIL "sprites/laserbeam.spr"
#define GRENADE_INFECTION_SPRITE_RING "sprites/shockwave.spr"

new g_V_Model_Grenade_Infection[MODEL_MAX_LENGTH] = "models/zombie_plague_enterprise/v_grenade_infect.mdl"
new g_P_Model_Grenade_Infection[MODEL_MAX_LENGTH] = "models/p_hegrenade.mdl";
new g_W_Model_Grenade_Infection[MODEL_MAX_LENGTH] = "models/w_hegrenade.mdl";

new Array:g_aSound_Grenade_Infection_Explode;
new Array:g_aSound_Grenade_Infection_Player;

new g_Trail_Sprite;
new g_Explode_Sprite;

new g_Item_ID;

new g_Game_Mode_Infection_ID;
new g_Game_Mode_Multi_ID;

new g_Grenade_Infection_Counter;

new g_pCvar_Grenade_Infection_Glow_Rendering_R;
new g_pCvar_Grenade_Infection_Glow_Rendering_G;
new g_pCvar_Grenade_Infection_Glow_Rendering_B;

new g_pCvar_Grenade_Infection_Trail_Rendering_R;
new g_pCvar_Grenade_Infection_Trail_Rendering_G;
new g_pCvar_Grenade_Infection_Trail_Rendering_B;

new g_pCvar_Grenade_Infection_Small_Ring_Rendering_R;
new g_pCvar_Grenade_Infection_Small_Ring_Rendering_G;
new g_pCvar_Grenade_Infection_Small_Ring_Rendering_B;

new g_pCvar_Grenade_Infection_Medium_Ring_Rendering_R;
new g_pCvar_Grenade_Infection_Medium_Ring_Rendering_G;
new g_pCvar_Grenade_Infection_Medium_Ring_Rendering_B;

new g_pCvar_Grenade_Infection_Largest_Ring_Rendering_R;
new g_pCvar_Grenade_Infection_Largest_Ring_Rendering_G;
new g_pCvar_Grenade_Infection_Largest_Ring_Rendering_B;

new Float:g_fGrenade_Radius;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Grenade_Infection_Glow_Rendering_R = register_cvar("zpe_grenade_infection_glow_rendering_r", "0");
	g_pCvar_Grenade_Infection_Glow_Rendering_G = register_cvar("zpe_grenade_infection_glow_rendering_g", "200");
	g_pCvar_Grenade_Infection_Glow_Rendering_B = register_cvar("zpe_grenade_infection_glow_rendering_b", "0");

	g_pCvar_Grenade_Infection_Trail_Rendering_R = register_cvar("zpe_grenade_infection_trail_rendering_r", "0");
	g_pCvar_Grenade_Infection_Trail_Rendering_G = register_cvar("zpe_grenade_infection_trail_rendering_g", "200");
	g_pCvar_Grenade_Infection_Trail_Rendering_B = register_cvar("zpe_grenade_infection_trail_rendering_b", "0");

	g_pCvar_Grenade_Infection_Small_Ring_Rendering_R = register_cvar("zpe_grenade_infection_small_ring_rendering_r", "0");
	g_pCvar_Grenade_Infection_Small_Ring_Rendering_G = register_cvar("zpe_grenade_infection_small_ring_rendering_g", "200");
	g_pCvar_Grenade_Infection_Small_Ring_Rendering_B = register_cvar("zpe_grenade_infection_small_ring_rendering_b", "0");

	g_pCvar_Grenade_Infection_Medium_Ring_Rendering_R = register_cvar("zpe_grenade_infection_medium_ring_rendering_r", "0");
	g_pCvar_Grenade_Infection_Medium_Ring_Rendering_G = register_cvar("zpe_grenade_infection_medium_ring_rendering_g", "200");
	g_pCvar_Grenade_Infection_Medium_Ring_Rendering_B = register_cvar("zpe_grenade_infection_medium_ring_rendering_b", "0");

	g_pCvar_Grenade_Infection_Largest_Ring_Rendering_R = register_cvar("zpe_grenade_infection_largest_ring_rendering_r", "0");
	g_pCvar_Grenade_Infection_Largest_Ring_Rendering_G = register_cvar("zpe_grenade_infection_largest_ring_rendering_g", "200");
	g_pCvar_Grenade_Infection_Largest_Ring_Rendering_B = register_cvar("zpe_grenade_infection_largest_ring_rendering_b", "0");

	bind_pcvar_float(register_cvar("zpe_grenade_infection_explosion_radius", "240"), g_fGrenade_Radius);

	RegisterHam(Ham_Think, "grenade", "Ham_Think_Grenade_");

	register_event("HLTV", "Event_Round_Start", "a", "1=0", "2=0");

	register_forward(FM_SetModel, "FM_SetModel_");

	g_Item_ID = zpe_items_register(ITEM_NAME, ITEM_COST);
}

public plugin_precache()
{
	g_aSound_Grenade_Infection_Explode = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Grenade_Infection_Player = ArrayCreate(SOUND_MAX_LENGTH, 1);

	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "GRENADE INFECTION EXPLODE", g_aSound_Grenade_Infection_Explode);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "GRENADE INFECTION PLAYER", g_aSound_Grenade_Infection_Player);

	Precache_Sounds(g_aSound_Grenade_Infection_Explode);
	Precache_Sounds(g_aSound_Grenade_Infection_Player);

	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "V GRENADE INFECTION", g_V_Model_Grenade_Infection, charsmax(g_V_Model_Grenade_Infection));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "P GRENADE INFECTION", g_P_Model_Grenade_Infection, charsmax(g_P_Model_Grenade_Infection));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "W GRENADE INFECTION", g_W_Model_Grenade_Infection, charsmax(g_W_Model_Grenade_Infection));

	precache_model(g_V_Model_Grenade_Infection);
	precache_model(g_P_Model_Grenade_Infection);
	precache_model(g_W_Model_Grenade_Infection);

	g_Trail_Sprite = precache_model(GRENADE_INFECTION_SPRITE_TRAIL);
	g_Explode_Sprite = precache_model(GRENADE_INFECTION_SPRITE_RING);
}

public plugin_cfg()
{
	g_Game_Mode_Infection_ID = zpe_gamemodes_get_id("Infection Mode");
	g_Game_Mode_Multi_ID = zpe_gamemodes_get_id("Multiple Infection Mode");
}

public Event_Round_Start()
{
	g_Grenade_Infection_Counter = 0;
}

public zpe_fw_items_select_pre(iPlayer, iItem_ID)
{
	// This is not our item
	if (iItem_ID != g_Item_ID)
	{
		return ZPE_ITEM_AVAILABLE;
	}

	// Infection grenade only available during infection modes
	new iCurrent_Mode = zpe_gamemodes_get_current();

	if (iCurrent_Mode != g_Game_Mode_Infection_ID && iCurrent_Mode != g_Game_Mode_Multi_ID)
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	// Infection grenade only available to zombies
	if (!zpe_core_is_zombie(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	return ZPE_ITEM_AVAILABLE;
}

public zpe_fw_items_select_post(iPlayer, iItem_ID)
{
	// This is not our item
	if (iItem_ID != g_Item_ID)
	{
		return;
	}

	// Give infection grenade
	rg_give_item(iPlayer, "weapon_hegrenade");

	g_Grenade_Infection_Counter++;
}

public zpe_fw_core_cure(iPlayer, iAttacker)
{
	// Remove custom grenade model
	cs_reset_player_view_model(iPlayer, CSW_HEGRENADE);
}

public zpe_fw_core_infect_post(iPlayer, iAttacker)
{
	// Set custom grenade model
	cs_set_player_view_model(iPlayer, CSW_HEGRENADE, g_V_Model_Grenade_Infection);
	cs_set_player_weap_model(iPlayer, CSW_HEGRENADE, g_P_Model_Grenade_Infection);
}

// Forward Set Model
public FM_SetModel_(iEntity, const szModel[])
{
	// We don't care
	if (strlen(szModel) < 8)
	{
		return;
	}

	// Narrow down our matches a bit
	if (szModel[7] != 'w' || szModel[8] != '_')
	{
		return;
	}

	// Get damage time of grenade
	static Float:fDamage_Time;

	get_entvar(iEntity, var_dmgtime, fDamage_Time);

	// Grenade not yet thrown
	if (fDamage_Time == 0.0)
	{
		return;
	}

	// Grenade's owner isn't zombie?
	if (!zpe_core_is_zombie(get_entvar(iEntity, var_owner)))
	{
		return;
	}

	// HE Grenade
	if (szModel[9] == 'h' && szModel[10] == 'e')
	{
		// Give it a glow
		rg_set_user_rendering(iEntity, kRenderFxGlowShell, get_pcvar_num(g_pCvar_Grenade_Infection_Glow_Rendering_R), get_pcvar_num(g_pCvar_Grenade_Infection_Glow_Rendering_G), get_pcvar_num(g_pCvar_Grenade_Infection_Glow_Rendering_B), kRenderNormal, 16);

		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW); // TE player
		write_short(iEntity); // entity
		write_short(g_Trail_Sprite); // sprite
		write_byte(10); // life
		write_byte(10); // width
		write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Trail_Rendering_R)); // r
		write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Trail_Rendering_G)); // g
		write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Trail_Rendering_B)); // b
		write_byte(200); // brightness
		message_end();

		engfunc(EngFunc_SetModel, iEntity, g_W_Model_Grenade_Infection);

		// Set grenade type on the thrown grenade entity
		set_entvar(iEntity, PEV_NADE_TYPE, NADE_TYPE_INFECTION);
	}
}

public Ham_Think_Grenade_(iEntity)
{
	// Invalid entity
	if (!is_entity(iEntity))
	{
		return HAM_IGNORED;
	}

	// Get damage time of grenade
	static Float:fDamage_Time;

	get_entvar(iEntity, var_dmgtime, fDamage_Time);

	// Check if it's time to go off
	if (fDamage_Time > get_gametime())
	{
		return HAM_IGNORED;
	}

	// Check if it's one of our custom nades
	switch (get_entvar(iEntity, PEV_NADE_TYPE))
	{
		case NADE_TYPE_INFECTION: // Infection Grenade
		{
			Infection_Explode(iEntity);

			return HAM_SUPERCEDE;
		}
	}

	return HAM_IGNORED;
}

// Infection Grenade Explosion
Infection_Explode(iEntity)
{
	// Round ended
	if (zpe_gamemodes_get_current() == ZPE_NO_GAME_MODE)
	{
		// Get rid of the grenade
		rg_remove_entity(iEntity);

		return;
	}

	// Get origin
	static Float:fOrigin[3];

	get_entvar(iEntity, var_origin, fOrigin);

	// Make the explosion
	Create_Blast(fOrigin);

	// Infection nade explode sound
	new szSound[SOUND_MAX_LENGTH];
	ArrayGetString(g_aSound_Grenade_Infection_Explode, RANDOM(ArraySize(g_aSound_Grenade_Infection_Explode)), szSound, charsmax(szSound));
	emit_sound(iEntity, CHAN_WEAPON, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

	// Get attacker
	new iAttacker = get_entvar(iEntity, var_owner);

	// Infection grenade owner disconnected or not zombie anymore?
	if (BIT_NOT_VALID(g_iBit_Connected, iAttacker) || !zpe_core_is_zombie(iAttacker))
	{
		// Get rid of the grenade
		rg_remove_entity(iEntity);

		return;
	}

	// Collisions
	new iVictim = -1;

	while ((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, fOrigin, g_fGrenade_Radius)) != 0)
	{
		// Only effect alive humans
		if (iVictim <= MaxClients && BIT_VALID(g_iBit_Alive, iVictim) && !zpe_core_is_zombie(iVictim))
		{
			// Last human is killed
			if (zpe_core_get_human_count() == 1)
			{
				ExecuteHamB(Ham_Killed, iVictim, iAttacker, 0);

				break;
			}

			// Turn into zombie
			zpe_core_infect(iVictim, iAttacker);

			// Victim's sound
			ArrayGetString(g_aSound_Grenade_Infection_Player, RANDOM(ArraySize(g_aSound_Grenade_Infection_Player)), szSound, charsmax(szSound));
			emit_sound(iVictim, CHAN_VOICE, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
		}
	}

	// Get rid of the grenade
	rg_remove_entity(iEntity);
}

// Infection Grenade: Green Blast
Create_Blast(const Float:fOrigin[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_BEAMCYLINDER); // TE player
	engfunc(EngFunc_WriteCoord, fOrigin[0]); // x
	engfunc(EngFunc_WriteCoord, fOrigin[1]); // y
	engfunc(EngFunc_WriteCoord, fOrigin[2]); // z
	engfunc(EngFunc_WriteCoord, fOrigin[0]); // x axis
	engfunc(EngFunc_WriteCoord, fOrigin[1]); // y axis
	engfunc(EngFunc_WriteCoord, fOrigin[2] + 385.0); // z axis
	write_short(g_Explode_Sprite); // sprite
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Small_Ring_Rendering_R)); // red
	write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Small_Ring_Rendering_G)); // green
	write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Small_Ring_Rendering_B)); // blue
	write_byte(200); // brightness
	write_byte(0); // speed
	message_end();

	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_BEAMCYLINDER); // TE player
	engfunc(EngFunc_WriteCoord, fOrigin[0]); // x
	engfunc(EngFunc_WriteCoord, fOrigin[1]); // y
	engfunc(EngFunc_WriteCoord, fOrigin[2]); // z
	engfunc(EngFunc_WriteCoord, fOrigin[0]); // x axis
	engfunc(EngFunc_WriteCoord, fOrigin[1]); // y axis
	engfunc(EngFunc_WriteCoord, fOrigin[2] + 470.0); // z axis
	write_short(g_Explode_Sprite); // sprite
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Medium_Ring_Rendering_R)); // red
	write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Medium_Ring_Rendering_G)); // green
	write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Medium_Ring_Rendering_B)); // blue
	write_byte(200); // brightness
	write_byte(0); // speed
	message_end();

	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_BEAMCYLINDER); // TE player
	engfunc(EngFunc_WriteCoord, fOrigin[0]); // x
	engfunc(EngFunc_WriteCoord, fOrigin[1]); // y
	engfunc(EngFunc_WriteCoord, fOrigin[2]); // z
	engfunc(EngFunc_WriteCoord, fOrigin[0]); // x axis
	engfunc(EngFunc_WriteCoord, fOrigin[1]); // y axis
	engfunc(EngFunc_WriteCoord, fOrigin[2] + 555.0); // z axis
	write_short(g_Explode_Sprite); // sprite
	write_byte(0); // startframe
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Largest_Ring_Rendering_R)); // red
	write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Largest_Ring_Rendering_G)); // green
	write_byte(get_pcvar_num(g_pCvar_Grenade_Infection_Largest_Ring_Rendering_B)); // blue
	write_byte(200); // brightness
	write_byte(0); // speed
	message_end();
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
	BIT_SUB(g_iBit_Connected, iPlayer);
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}