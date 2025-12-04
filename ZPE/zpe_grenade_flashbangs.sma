/* AMX Mod X
*	[ZPE] Grenade Flashbang.
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

#define PLUGIN "grenade flashbang"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <fakemeta>
#include <ck_cs_weap_models_api>
#include <zpe_kernel>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>

#define ZPE_SETTINGS_FILE "ZPE/zpe_items.ini"

// HACK: var_ field used to store custom nade types and their values
#define PEV_NADE_TYPE var_flTimeStepSound
#define NADE_TYPE_FLASHBANG 3334

#define GRENADE_FLASHBANG_SPRITE_TRAIL "sprites/laserbeam.spr"

new g_V_Model_Grenade_Flashbang[MODEL_MAX_LENGTH] = "models/v_flashbang.mdl";
new g_P_Model_Grenade_Flashbang[MODEL_MAX_LENGTH] = "models/p_flashbang.mdl";
new g_W_Model_Grenade_Flashbang[MODEL_MAX_LENGTH] = "models/w_flashbang.mdl";

new g_pCvar_Grenade_Flashbang_Color_R;
new g_pCvar_Grenade_Flashbang_Color_G;
new g_pCvar_Grenade_Flashbang_Color_B;

new g_pCvar_Grenade_Flashbang_Glow_Rendering_R;
new g_pCvar_Grenade_Flashbang_Glow_Rendering_G;
new g_pCvar_Grenade_Flashbang_Glow_Rendering_B;

new g_pCvar_Grenade_Flashbang_Trail_Rendering_R;
new g_pCvar_Grenade_Flashbang_Trail_Rendering_G;
new g_pCvar_Grenade_Flashbang_Trail_Rendering_B;

new g_pCvar_Grenade_Flashbang_Nemesis;
new g_pCvar_Grenade_Flashbang_Assassin;

new g_Trail_Sprite;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Grenade_Flashbang_Color_R = register_cvar("zpe_grenade_flashbang_color_r", "0");
	g_pCvar_Grenade_Flashbang_Color_G = register_cvar("zpe_grenade_flashbang_color_g", "150");
	g_pCvar_Grenade_Flashbang_Color_B = register_cvar("zpe_grenade_flashbang_color_b", "0");

	g_pCvar_Grenade_Flashbang_Glow_Rendering_R = register_cvar("zpe_grenade_flashbang_glow_rendering_r", "0");
	g_pCvar_Grenade_Flashbang_Glow_Rendering_G = register_cvar("zpe_grenade_flashbang_glow_rendering_g", "0");
	g_pCvar_Grenade_Flashbang_Glow_Rendering_B = register_cvar("zpe_grenade_flashbang_glow_rendering_b", "0");

	g_pCvar_Grenade_Flashbang_Trail_Rendering_R = register_cvar("zpe_grenade_flashbang_trail_rendering_r", "0");
	g_pCvar_Grenade_Flashbang_Trail_Rendering_G = register_cvar("zpe_grenade_flashbang_trail_rendering_g", "0");
	g_pCvar_Grenade_Flashbang_Trail_Rendering_B = register_cvar("zpe_grenade_flashbang_trail_rendering_b", "0");

	g_pCvar_Grenade_Flashbang_Nemesis = register_cvar("zpe_grenade_flashbang_nemesis", "0");
	g_pCvar_Grenade_Flashbang_Assassin = register_cvar("zpe_grenade_flashbang_assassin", "0");

	register_message(get_user_msgid("ScreenFade"), "Message_ScreenFade");

	register_forward(FM_SetModel, "FM_SetModel_");
}

public plugin_precache()
{
	// Load from external file
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "V GRENADE FLASHBANG", g_V_Model_Grenade_Flashbang, charsmax(g_V_Model_Grenade_Flashbang));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "P GRENADE FLASHBANG", g_P_Model_Grenade_Flashbang, charsmax(g_P_Model_Grenade_Flashbang));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "W GRENADE FLASHBANG", g_W_Model_Grenade_Flashbang, charsmax(g_W_Model_Grenade_Flashbang));

	// Precache models
	precache_model(g_V_Model_Grenade_Flashbang);
	precache_model(g_P_Model_Grenade_Flashbang);
	precache_model(g_W_Model_Grenade_Flashbang);

	g_Trail_Sprite = precache_model(GRENADE_FLASHBANG_SPRITE_TRAIL);
}

// Make flashbangs only affect zombies
public Message_ScreenFade(iMessage_ID, iMessage_Dest, iMessage_Entity)
{
	// Is this a flashbang?
	if (get_msg_arg_int(4) != 255 || get_msg_arg_int(5) != 255 || get_msg_arg_int(6) != 255 || get_msg_arg_int(7) < 200)
	{
		return PLUGIN_CONTINUE;
	}

	// Block for humans
	if (!zpe_core_is_zombie(iMessage_Entity))
	{
		return PLUGIN_HANDLED;
	}

	// Nemesis Class loaded?
	if (zpe_class_nemesis_get(iMessage_Entity) && !get_pcvar_num(g_pCvar_Grenade_Flashbang_Nemesis))
	{
		return PLUGIN_HANDLED;
	}

	// Assassin Class loaded?
	if (zpe_class_assassin_get(iMessage_Entity) && !get_pcvar_num(g_pCvar_Grenade_Flashbang_Assassin))
	{
		return PLUGIN_HANDLED;
	}

	// Set flash color
	set_msg_arg_int(4, get_msg_argtype(4), get_pcvar_num(g_pCvar_Grenade_Flashbang_Color_R));
	set_msg_arg_int(5, get_msg_argtype(5), get_pcvar_num(g_pCvar_Grenade_Flashbang_Color_G));
	set_msg_arg_int(6, get_msg_argtype(6), get_pcvar_num(g_pCvar_Grenade_Flashbang_Color_B));

	return PLUGIN_CONTINUE;
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

	// Flashbang
	if (sModel[9] == 'f' && sModel[10] == 'l')
	{
		// Give it a glow
		rg_set_user_rendering(iEntity, kRenderFxGlowShell, get_pcvar_num(g_pCvar_Grenade_Flashbang_Glow_Rendering_R), get_pcvar_num(g_pCvar_Grenade_Flashbang_Glow_Rendering_G), get_pcvar_num(g_pCvar_Grenade_Flashbang_Glow_Rendering_B), kRenderNormal, 16);

		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW); // TE player
		write_short(iEntity); // entity
		write_short(g_Trail_Sprite); // sprite
		write_byte(10); // life
		write_byte(10); // width
		write_byte(get_pcvar_num(g_pCvar_Grenade_Flashbang_Trail_Rendering_R)); // r
		write_byte(get_pcvar_num(g_pCvar_Grenade_Flashbang_Trail_Rendering_G)); // g
		write_byte(get_pcvar_num(g_pCvar_Grenade_Flashbang_Trail_Rendering_B)); // b
		write_byte(200); // brightness
		message_end();

		// Set grenade type on the thrown grenade entity
		set_entvar(iEntity, PEV_NADE_TYPE, NADE_TYPE_FLASHBANG);

		engfunc(EngFunc_SetModel, iEntity, g_W_Model_Grenade_Flashbang);

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

public zpe_fw_core_cure_post(iPlayer)
{
	// Set custom grenade model
	cs_set_player_view_model(iPlayer, CSW_FLASHBANG, g_V_Model_Grenade_Flashbang);
	cs_set_player_weap_model(iPlayer, CSW_FLASHBANG, g_P_Model_Grenade_Flashbang);
}