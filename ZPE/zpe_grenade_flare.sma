/* AMX Mod X
*	[ZPE] Grenade Flare.
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

#define PLUGIN "grenade flare"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <fakemeta>
#include <hamsandwich>
#include <ck_cs_weap_models_api>
#include <zpe_kernel>

#define ZPE_SETTINGS_FILE "ZPE/zpe_items.ini"

// HACK: var_ field used to store custom nade types and their values
#define PEV_NADE_TYPE var_flTimeStepSound
#define NADE_TYPE_FLARE 4444
#define PEV_FLARE_COLOR var_punchangle
#define PEV_FLARE_DURATION var_flSwimTime

#define SPRITE_GRANDE_TRAIL "sprites/laserbeam.spr"

new g_V_Model_Grenade_Flare[MODEL_MAX_LENGTH] = "models/zombie_plague_enterprise/v_grenade_flare.mdl";
new g_P_Model_Grenade_Flare[MODEL_MAX_LENGTH] = "models/p_smokegrenade.mdl";
new g_W_Model_Grenade_Flare[MODEL_MAX_LENGTH] = "models/w_smokegrenade.mdl";

new Array:g_aSound_Grenade_Flare_Explode;

new g_iStatus_Icon;

new g_pCvar_Grenade_Flare_Duration;
new g_pCvar_Grenade_Flare_Radius;
new g_pCvar_Grenade_Flare_Hudicon_Player;

new g_pCvar_Grenade_Flare_Hudicon_Player_Color_R;
new g_pCvar_Grenade_Flare_Hudicon_Player_Color_G;
new g_pCvar_Grenade_Flare_Hudicon_Player_Color_B;

new g_pCvar_Grenade_Flare_Random_Hue_Color;

new g_pCvar_Grenade_Flare_Lighting_Rendering_R;
new g_pCvar_Grenade_Flare_Lighting_Rendering_G;
new g_pCvar_Grenade_Flare_Lighting_Rendering_B;

new g_pCvar_Grenade_Flare_Glow_Rendering_R;
new g_pCvar_Grenade_Flare_Glow_Rendering_G;
new g_pCvar_Grenade_Flare_Glow_Rendering_B;

new g_pCvar_Grenade_Flare_Trail_Rendering_R;
new g_pCvar_Grenade_Flare_Trail_Rendering_G;
new g_pCvar_Grenade_Flare_Trail_Rendering_B;

new g_Trail_Sprite;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Grenade_Flare_Duration = register_cvar("zpe_grenade_flare_duration", "60");
	g_pCvar_Grenade_Flare_Radius = register_cvar("zpe_grenade_flare_radius", "25");
	g_pCvar_Grenade_Flare_Hudicon_Player = register_cvar("zpe_grenade_flare_hudicon_player", "1");

	g_pCvar_Grenade_Flare_Hudicon_Player_Color_R = register_cvar("zpe_grenade_flare_hudicon_player_color_r", "255");
	g_pCvar_Grenade_Flare_Hudicon_Player_Color_G = register_cvar("zpe_grenade_flare_hudicon_player_color_g", "255");
	g_pCvar_Grenade_Flare_Hudicon_Player_Color_B = register_cvar("zpe_grenade_flare_hudicon_player_color_b", "255");

	g_pCvar_Grenade_Flare_Random_Hue_Color = register_cvar("zpe_grenade_flare_random_hue_color", "1");

	g_pCvar_Grenade_Flare_Lighting_Rendering_R = register_cvar("zpe_grenade_flare_lighting_rendering_r", "255");
	g_pCvar_Grenade_Flare_Lighting_Rendering_G = register_cvar("zpe_grenade_flare_lighting_rendering_g", "255");
	g_pCvar_Grenade_Flare_Lighting_Rendering_B = register_cvar("zpe_grenade_flare_lighting_rendering_b", "255");

	g_pCvar_Grenade_Flare_Glow_Rendering_R = register_cvar("zpe_grenade_flare_glow_rendering_r", "255");
	g_pCvar_Grenade_Flare_Glow_Rendering_G = register_cvar("zpe_grenade_flare_glow_rendering_g", "255");
	g_pCvar_Grenade_Flare_Glow_Rendering_B = register_cvar("zpe_grenade_flare_glow_rendering_b", "255");

	g_pCvar_Grenade_Flare_Trail_Rendering_R = register_cvar("zpe_grenade_flare_trail_rendering_r", "255");
	g_pCvar_Grenade_Flare_Trail_Rendering_G = register_cvar("zpe_grenade_flare_trail_rendering_g", "255");
	g_pCvar_Grenade_Flare_Trail_Rendering_B = register_cvar("zpe_grenade_flare_trail_rendering_b", "255");

	RegisterHam(Ham_Think, "grenade", "Ham_Think_Grenade_");

	register_forward(FM_SetModel, "FM_SetModel_");

	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
	register_event("DeathMsg", "Event_DeathMsg", "a");

	g_iStatus_Icon = get_user_msgid("StatusIcon");
}

public plugin_precache()
{
	g_aSound_Grenade_Flare_Explode = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "GRENADE FLARE EXPLODE", g_aSound_Grenade_Flare_Explode);
	Precache_Sounds(g_aSound_Grenade_Flare_Explode);

	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "V GRENADE FLARE", g_V_Model_Grenade_Flare, charsmax(g_V_Model_Grenade_Flare));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "P GRENADE FLARE", g_P_Model_Grenade_Flare, charsmax(g_P_Model_Grenade_Flare));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "W GRENADE FLARE", g_W_Model_Grenade_Flare, charsmax(g_W_Model_Grenade_Flare));

	precache_model(g_V_Model_Grenade_Flare);
	precache_model(g_P_Model_Grenade_Flare);
	precache_model(g_W_Model_Grenade_Flare);

	g_Trail_Sprite = precache_model(SPRITE_GRANDE_TRAIL);
}

public zpe_fw_core_cure_post(iPlayer)
{
	// Set custom grenade model
	cs_set_player_view_model(iPlayer, CSW_SMOKEGRENADE, g_V_Model_Grenade_Flare);
	cs_set_player_weap_model(iPlayer, CSW_SMOKEGRENADE, g_P_Model_Grenade_Flare);
}

public zpe_fw_core_infect(iPlayer)
{
	// Remove custom grenade model
	cs_reset_player_view_model(iPlayer, CSW_SMOKEGRENADE);
}

// Forward Set Model
public FM_SetModel_(iEntity, const sModel[])
{
	// We don't care
	if (strlen(sModel) < 8)
	{
		return FMRES_IGNORED;
	}

	// Narrow down our matches a bit
	if (sModel[7] != 'w' || sModel[8] != '_')
	{
		return FMRES_IGNORED;
	}

	// Get damage time of grenade
	static Float:fDamage_Time;

	get_entvar(iEntity, var_dmgtime, fDamage_Time);

	// Grenade not yet thrown
	if (fDamage_Time == 0.0)
	{
		return FMRES_IGNORED;
	}

	// Grenade's owner is zombie?
	if (zpe_core_is_zombie(get_entvar(iEntity, var_owner)))
	{
		return FMRES_IGNORED;
	}

	// Smoke Grenade
	if (sModel[9] == 's' && sModel[10] == 'm')
	{
		// Give it a glow
		new iRGB[3];

		new bool:bRandom_Hue_Color = bool:get_pcvar_num(g_pCvar_Grenade_Flare_Random_Hue_Color);

		if (bRandom_Hue_Color)
		{
			new iHSV[3];
			iHSV[0] = RANDOM(360);
			iHSV[1] = 100;
			iHSV[2] = 100;
			HSV_To_RGB(iHSV, iRGB);
		}

		else
		{
			iRGB[0] = get_pcvar_num(g_pCvar_Grenade_Flare_Glow_Rendering_R); 
			iRGB[1] = get_pcvar_num(g_pCvar_Grenade_Flare_Glow_Rendering_G); 
			iRGB[2] = get_pcvar_num(g_pCvar_Grenade_Flare_Glow_Rendering_B); 
		}

		rg_set_user_rendering(iEntity, kRenderFxGlowShell, iRGB[0], iRGB[1], iRGB[2], kRenderNormal, 16);

		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW); // TE player
		write_short(iEntity); // entity
		write_short(g_Trail_Sprite); // sprite
		write_byte(10); // life
		write_byte(10); // width

		if (!bRandom_Hue_Color)
		{
			iRGB[0] = get_pcvar_num(g_pCvar_Grenade_Flare_Trail_Rendering_R); 
			iRGB[1] = get_pcvar_num(g_pCvar_Grenade_Flare_Trail_Rendering_G); 
			iRGB[2] = get_pcvar_num(g_pCvar_Grenade_Flare_Trail_Rendering_B); 
		}

		write_byte(iRGB[0]); // r
		write_byte(iRGB[1]); // g
		write_byte(iRGB[2]); // b
		write_byte(200); // brightness
		message_end();

		// Set grenade type on the thrown grenade entity
		set_entvar(iEntity, PEV_NADE_TYPE, NADE_TYPE_FLARE);

		engfunc(EngFunc_SetModel, iEntity, g_W_Model_Grenade_Flare);

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

// Ham Grenade Think Forward
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

	new Float:fCurrent_Time = get_gametime();

	// Check if it's time to go off
	if (fDamage_Time > fCurrent_Time)
	{
		return HAM_IGNORED;
	}

	// Check if it's one of our custom nades
	if (get_entvar(iEntity, PEV_NADE_TYPE) == NADE_TYPE_FLARE)
	{
		// Get its duration
		new iDuration = get_entvar(iEntity, PEV_FLARE_DURATION);

		// Already went off, do lighting loop for the duration of PEV_FLARE_DURATION
		if (iDuration > 0)
		{
			// Check whether this is the last loop
			if (iDuration == 1)
			{
				// Get rid of the flare entity
				rg_remove_entity(iEntity);

				return HAM_SUPERCEDE;
			}

			// Light it up!
			Flare_Lighting(iEntity, iDuration);

			// Set time for next loop
			set_entvar(iEntity, PEV_FLARE_DURATION, --iDuration);
			set_entvar(iEntity, var_dmgtime, fCurrent_Time + 2.0);
		}

		// Light up when it's stopped on ground
		else if ((get_entvar(iEntity, var_flags) & FL_ONGROUND) && _fm_get_speed(iEntity) < 10)
		{
			// Flare sound
			new szSound[SOUND_MAX_LENGTH];
			ArrayGetString(g_aSound_Grenade_Flare_Explode, RANDOM(ArraySize(g_aSound_Grenade_Flare_Explode)), szSound, charsmax(szSound));
			emit_sound(iEntity, CHAN_VOICE, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

			// Set duration and start lightning loop on next think
			set_entvar(iEntity, PEV_FLARE_DURATION, 1 + get_pcvar_num(g_pCvar_Grenade_Flare_Duration) / 2);
			set_entvar(iEntity, var_dmgtime, fCurrent_Time + 0.1);
		}

		else
		{
			// Delay explosion until we hit ground
			set_entvar(iEntity, var_dmgtime, fCurrent_Time + 0.5);
		}
	}

	return HAM_IGNORED;
}

public Event_CurWeapon(iPlayer)
{
	if (get_pcvar_num(g_pCvar_Grenade_Flare_Hudicon_Player))
	{
		if (read_data(2) == CSW_SMOKEGRENADE)
		{
			message_begin(MSG_ONE, g_iStatus_Icon, _, iPlayer);
			write_byte(1);
			write_string("dmg_shock");
			write_byte(get_pcvar_num(g_pCvar_Grenade_Flare_Hudicon_Player_Color_R));
			write_byte(get_pcvar_num(g_pCvar_Grenade_Flare_Hudicon_Player_Color_G));
			write_byte(get_pcvar_num(g_pCvar_Grenade_Flare_Hudicon_Player_Color_B));
			message_end();
		}

		else
		{
			Grenade_Icon_Remove(iPlayer);

			return;
		}
	}
}

public Event_DeathMsg()
{
	if (get_pcvar_num(g_pCvar_Grenade_Flare_Hudicon_Player))
	{
		Grenade_Icon_Remove(read_data(2));
	}
}

Grenade_Icon_Remove(iPlayer)
{
	message_begin(MSG_ONE, g_iStatus_Icon, _, iPlayer);
	write_byte(0);
	write_string("dmg_shock");
	message_end();
}

// Flare Lighting Effects
Flare_Lighting(iEntity, iDuration)
{
	// Get origin and color
	new Float:fOrigin[3];
	get_entvar(iEntity, var_origin, fOrigin);

	// Lighting
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_DLIGHT); // TE player
	engfunc(EngFunc_WriteCoord, fOrigin[0]); // x
	engfunc(EngFunc_WriteCoord, fOrigin[1]); // y
	engfunc(EngFunc_WriteCoord, fOrigin[2]); // z
	write_byte(get_pcvar_num(g_pCvar_Grenade_Flare_Radius)); // radius

	if (get_pcvar_num(g_pCvar_Grenade_Flare_Random_Hue_Color))
	{
		new Float:fRGB[3];
		get_entvar(iEntity, var_rendercolor, fRGB);

		write_byte(floatround(fRGB[0])); // r
		write_byte(floatround(fRGB[1])); // g
		write_byte(floatround(fRGB[2])); // b
	}

	else
	{
		write_byte(get_pcvar_num(g_pCvar_Grenade_Flare_Lighting_Rendering_R)); // r
		write_byte(get_pcvar_num(g_pCvar_Grenade_Flare_Lighting_Rendering_G)); // g
		write_byte(get_pcvar_num(g_pCvar_Grenade_Flare_Lighting_Rendering_B)); // b
	}

	write_byte(21); //life
	write_byte((iDuration < 2) ? 3 : 0); //decay rate
	message_end();

	// Sparks
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
	write_byte(TE_SPARKS); // TE player
	engfunc(EngFunc_WriteCoord, fOrigin[0]); // x
	engfunc(EngFunc_WriteCoord, fOrigin[1]); // y
	engfunc(EngFunc_WriteCoord, fOrigin[2]); // z
	message_end();
}