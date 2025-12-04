/* AMX Mod X
*	[ZPE] Greande Frost.
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

#define PLUGIN "grenade frost"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <ck_cs_weap_models_api>
#include <zpe_kernel>

#define ZPE_SETTINGS_FILE "ZPE/zpe_items.ini"

#define GRAVITY_HIGH 999999.9
#define GRAVITY_NONE 0.000001

#define TASK_FROST_REMOVE 100
#define ID_FROST_REMOVE (iTask_ID - TASK_FROST_REMOVE)

// HACK: var_ field used to store custom nade types and their values
#define PEV_NADE_TYPE var_flTimeStepSound
#define NADE_TYPE_FROST 3333

// Some constants
#define UNIT_SECOND (1 << 12)
#define BREAK_GLASS 0x01
#define FFADE_IN 0x0000
#define FFADE_STAYOUT 0x0004

// Sprites
#define SPRITE_GRENADE_TRAIL "sprites/laserbeam.spr"
#define SPRITE_GRENADE_RING "sprites/shockwave.spr"
#define SPRITE_GRENADE_GLASS "models/glassgibs.mdl"

new g_V_Model_Grenade_Frost[MODEL_MAX_LENGTH] = "models/zombie_plague_enterprise/v_grenade_frost.mdl";
new g_P_Model_Grenade_Frost[MODEL_MAX_LENGTH] = "models/p_flashbang.mdl";
new g_W_Model_Grenade_Frost[MODEL_MAX_LENGTH] = "models/w_flashbang.mdl";

// Hack to be able to use Ham_Player_ResetMaxSpeed (by joaquimandrade)
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;

// Custom Forwards
enum TOTAL_FORWARDS
{
	FW_USER_FREEZE_PRE = 0,
	FW_USER_UNFROZEN
};

new Array:g_aSound_Grenade_Frost_Explode;
new Array:g_aSound_Grenade_Frost_Player;
new Array:g_aSound_Grenade_Frost_Break;

new g_Forwards[TOTAL_FORWARDS];
new g_Forward_Result;

new g_Is_Frozen;

new g_Frozen_Rendering_Fx[33];
new g_Frozen_Rendering_Render[33];

new Float:g_fFrozen_Gravity[33];
new Float:g_fFrozen_Rendering_Color[33][3];
new Float:g_fFrozen_Rendering_Amount[33];

new g_Message_Damage;
new g_Message_Screen_Fade;
new g_iStatus_Icon;

new g_Trail_Sprite;
new g_Explode_Sprite;
new g_Glass_Sprite;

new g_pCvar_Grenade_Frost_Duration;
new g_pCvar_Grenade_Frost_Hudicon_Player;
new g_pCvar_Grenade_Frost_Hudicon_Enemy;
new g_pCvar_Grenade_Frost_Frozen_Hit;

new g_pCvar_Grenade_Frost_Hudicon_Player_Color_R;
new g_pCvar_Grenade_Frost_Hudicon_Player_Color_G;
new g_pCvar_Grenade_Frost_Hudicon_Player_Color_B;

new g_pCvar_Grenade_Frost_Small_Ring_Rendering_R;
new g_pCvar_Grenade_Frost_Small_Ring_Rendering_G;
new g_pCvar_Grenade_Frost_Small_Ring_Rendering_B;

new g_pCvar_Grenade_Frost_Medium_Ring_Rendering_R;
new g_pCvar_Grenade_Frost_Medium_Ring_Rendering_G;
new g_pCvar_Grenade_Frost_Medium_Ring_Rendering_B;

new g_pCvar_Grenade_Frost_Largest_Ring_Rendering_R;
new g_pCvar_Grenade_Frost_Largest_Ring_Rendering_G;
new g_pCvar_Grenade_Frost_Largest_Ring_Rendering_B;

new g_pCvar_Grenade_Frost_Glow_Rendering_R;
new g_pCvar_Grenade_Frost_Glow_Rendering_G;
new g_pCvar_Grenade_Frost_Glow_Rendering_B;

new g_pCvar_Grenade_Frost_Trail_Rendering_R;
new g_pCvar_Grenade_Frost_Trail_Rendering_G;
new g_pCvar_Grenade_Frost_Trail_Rendering_B;

new g_pCvar_Grenade_Frost_Screen_Rendering_R;
new g_pCvar_Grenade_Frost_Screen_Rendering_G;
new g_pCvar_Grenade_Frost_Screen_Rendering_B;

new Float:g_fGrenade_Radius;

new g_iBit_Alive;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Grenade_Frost_Duration = register_cvar("zpe_grenade_frost_duration", "3.0");
	g_pCvar_Grenade_Frost_Hudicon_Player = register_cvar("zpe_grenade_frost_hudicon_player", "1");
	g_pCvar_Grenade_Frost_Hudicon_Enemy = register_cvar("zpe_grenade_frost_hudicon_enemy", "1");
	g_pCvar_Grenade_Frost_Frozen_Hit = register_cvar("zpe_grenade_frost_frozen_hit", "1");

	g_pCvar_Grenade_Frost_Hudicon_Player_Color_R = register_cvar("zpe_grenade_frost_hudicon_player_color_r", "100");
	g_pCvar_Grenade_Frost_Hudicon_Player_Color_G = register_cvar("zpe_grenade_frost_hudicon_player_color_g", "149");
	g_pCvar_Grenade_Frost_Hudicon_Player_Color_B = register_cvar("zpe_grenade_frost_hudicon_player_color_b", "237");

	g_pCvar_Grenade_Frost_Small_Ring_Rendering_R = register_cvar("zpe_grenade_frost_small_ring_rendering_r", "0");
	g_pCvar_Grenade_Frost_Small_Ring_Rendering_G = register_cvar("zpe_grenade_frost_small_ring_rendering_g", "100");
	g_pCvar_Grenade_Frost_Small_Ring_Rendering_B = register_cvar("zpe_grenade_frost_small_ring_rendering_b", "200");

	g_pCvar_Grenade_Frost_Medium_Ring_Rendering_R = register_cvar("zpe_grenade_frost_medium_ring_rendering_r", "0");
	g_pCvar_Grenade_Frost_Medium_Ring_Rendering_G = register_cvar("zpe_grenade_frost_medium_ring_rendering_g", "100");
	g_pCvar_Grenade_Frost_Medium_Ring_Rendering_B = register_cvar("zpe_grenade_frost_medium_ring_rendering_b", "200");

	g_pCvar_Grenade_Frost_Largest_Ring_Rendering_R = register_cvar("zpe_grenade_frost_largest_ring_rendering_r", "0");
	g_pCvar_Grenade_Frost_Largest_Ring_Rendering_G = register_cvar("zpe_grenade_frost_largest_ring_rendering_g", "100");
	g_pCvar_Grenade_Frost_Largest_Ring_Rendering_B = register_cvar("zpe_grenade_frost_largest_ring_rendering_b", "200");

	g_pCvar_Grenade_Frost_Glow_Rendering_R = register_cvar("zpe_grenade_frost_glow_rendering_r", "0");
	g_pCvar_Grenade_Frost_Glow_Rendering_G = register_cvar("zpe_grenade_frost_glow_rendering_g", "100");
	g_pCvar_Grenade_Frost_Glow_Rendering_B = register_cvar("zpe_grenade_frost_glow_rendering_b", "200");

	g_pCvar_Grenade_Frost_Trail_Rendering_R = register_cvar("zpe_grenade_frost_trail_rendering_r", "0");
	g_pCvar_Grenade_Frost_Trail_Rendering_G = register_cvar("zpe_grenade_frost_trail_rendering_g", "100");
	g_pCvar_Grenade_Frost_Trail_Rendering_B = register_cvar("zpe_grenade_frost_trail_rendering_b", "200");

	g_pCvar_Grenade_Frost_Screen_Rendering_R = register_cvar("zpe_grenade_frost_screen_rendering_r", "0");
	g_pCvar_Grenade_Frost_Screen_Rendering_G = register_cvar("zpe_grenade_frost_screen_rendering_g", "255");
	g_pCvar_Grenade_Frost_Screen_Rendering_B = register_cvar("zpe_grenade_frost_screen_rendering_b", "0");

	bind_pcvar_float(register_cvar("zpe_grenade_frost_explosion_radius", "240"), g_fGrenade_Radius);

	RegisterHookChain(RG_CBasePlayer_TraceAttack, "RG_CBasePlayer_TraceAttack_");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_CBasePlayer_TakeDamage_");

	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "Ham_Player_ResetMaxSpeed_Post", 1);
	RegisterHam(Ham_Think, "grenade", "Ham_Think_Grande_");

	register_forward(FM_PlayerPreThink, "FM_PlayerPreThink_");
	register_forward(FM_SetModel, "FM_SetModel_");

	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
	register_event("DeathMsg", "Event_DeathMsg", "a");

	g_iStatus_Icon = get_user_msgid("StatusIcon");
	g_Message_Damage = get_user_msgid("Damage");
	g_Message_Screen_Fade = get_user_msgid("ScreenFade");

	g_Forwards[FW_USER_FREEZE_PRE] = CreateMultiForward("zpe_fw_grenade_frost_pre", ET_CONTINUE, FP_CELL);
	g_Forwards[FW_USER_UNFROZEN] = CreateMultiForward("zpe_fw_grenade_frost_unfreeze", ET_IGNORE, FP_CELL);
}

public plugin_precache()
{
	g_aSound_Grenade_Frost_Explode = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Grenade_Frost_Player = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Grenade_Frost_Break = ArrayCreate(SOUND_MAX_LENGTH, 1);

	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "GRENADE FROST EXPLODE", g_aSound_Grenade_Frost_Explode);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "GRENADE FROST PLAYER", g_aSound_Grenade_Frost_Player);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "GRENADE FROST BREAK", g_aSound_Grenade_Frost_Break);

	Precache_Sounds(g_aSound_Grenade_Frost_Explode);
	Precache_Sounds(g_aSound_Grenade_Frost_Player);
	Precache_Sounds(g_aSound_Grenade_Frost_Break);

	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "V GRENADE FROST", g_V_Model_Grenade_Frost, charsmax(g_V_Model_Grenade_Frost));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "P GRENADE FROST", g_P_Model_Grenade_Frost, charsmax(g_P_Model_Grenade_Frost));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "W GRENADE FROST", g_W_Model_Grenade_Frost, charsmax(g_W_Model_Grenade_Frost));

	precache_model(g_V_Model_Grenade_Frost);
	precache_model(g_P_Model_Grenade_Frost);
	precache_model(g_W_Model_Grenade_Frost);

	g_Trail_Sprite = precache_model(SPRITE_GRENADE_TRAIL);
	g_Explode_Sprite = precache_model(SPRITE_GRENADE_RING);
	g_Glass_Sprite = precache_model(SPRITE_GRENADE_GLASS);
}

public plugin_natives()
{
	register_library("zpe_grenade_frost");

	register_native("zpe_grenade_frost_get", "native_grenade_frost_get");
	register_native("zpe_grenade_frost_set", "native_grenade_frost_set");
}

public native_grenade_frost_get(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	return BIT_VALID(g_Is_Frozen, iPlayer);
}

public native_grenade_frost_set(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	new iSet = get_param(2);

	// Unfreeze
	if (!iSet)
	{
		// Not frozen
		if (BIT_NOT_VALID(g_Is_Frozen, iPlayer))
		{
			return true;
		}

		// Remove freeze right away and stop the task
		Remove_Freeze(iPlayer + TASK_FROST_REMOVE);
		remove_task(iPlayer + TASK_FROST_REMOVE);

		return true;
	}

	return Set_Freeze(iPlayer);
}

public zpe_fw_core_cure_post(iPlayer)
{
	// Set custom grenade model
	cs_set_player_view_model(iPlayer, CSW_FLASHBANG, g_V_Model_Grenade_Frost);
	cs_set_player_weap_model(iPlayer, CSW_FLASHBANG, g_P_Model_Grenade_Frost);

	// If frozen, remove freeze after player is cured
	if (BIT_VALID(g_Is_Frozen, iPlayer))
	{
		// Update gravity and rendering values first
		Apply_Frozen_Gravity(iPlayer);
		Apply_Frozen_Rendering(iPlayer);

		// Remove freeze right away and stop the task
		Remove_Freeze(iPlayer + TASK_FROST_REMOVE);
		remove_task(iPlayer + TASK_FROST_REMOVE);
	}
}

public zpe_fw_core_infect(iPlayer)
{
	// Remove custom grenade model
	cs_reset_player_view_model(iPlayer, CSW_FLASHBANG);
}

public zpe_fw_core_infect_post(iPlayer)
{
	// If frozen, update gravity and rendering
	if (BIT_VALID(g_Is_Frozen, iPlayer))
	{
		Apply_Frozen_Gravity(iPlayer);
		Apply_Frozen_Rendering(iPlayer);
	}
}

public Ham_Player_ResetMaxSpeed_Post(iPlayer)
{
	// Dead or not frozen
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer) || BIT_NOT_VALID(g_Is_Frozen, iPlayer))
	{
		return;
	}

	// Prevent from moving
	set_user_maxspeed(iPlayer, 1.0);
}

public RG_CBasePlayer_TraceAttack_(iVictim, iAttacker)
{
	// Non-player damage or self damage
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return HC_CONTINUE;
	}

	// Block damage while frozen, as it makes killing zombies too easy
	if (BIT_VALID(g_Is_Frozen, iVictim) && !(get_pcvar_num(g_pCvar_Grenade_Frost_Frozen_Hit)))
	{
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

// ReAPI Take Damage Forward (needed to block explosion damage too)
public RG_CBasePlayer_TakeDamage_(iVictim, iInflictor, iAttacker)
{
	// Non-player damage or self damage
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return HC_CONTINUE;
	}

	// Block damage while frozen, as it makes killing zombies too easy
	if (BIT_VALID(g_Is_Frozen, iVictim) && !(get_pcvar_num(g_pCvar_Grenade_Frost_Frozen_Hit)))
	{
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public zpe_fw_kill_pre_bit_sub(iVictim)
{
	// Frozen player being killed (usually caused by a 3rd party plugin, e.g. lasermines)
	if (BIT_VALID(g_Is_Frozen, iVictim))
	{
		// Remove freeze right away and stop the task
		Remove_Freeze(iVictim + TASK_FROST_REMOVE);
		remove_task(iVictim + TASK_FROST_REMOVE);
	}

	BIT_SUB(g_iBit_Alive, iVictim);
}

// Forward Player PreThink
public FM_PlayerPreThink_(iPlayer)
{
	// Not alive or not frozen
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer) || BIT_NOT_VALID(g_Is_Frozen, iPlayer))
	{
		return;
	}

	// Stop motion
	set_entvar(iPlayer, var_velocity, Float:{0.0, 0.0, 0.0});
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
		rg_set_user_rendering(iEntity, kRenderFxGlowShell, get_pcvar_num(g_pCvar_Grenade_Frost_Glow_Rendering_R), get_pcvar_num(g_pCvar_Grenade_Frost_Glow_Rendering_G), get_pcvar_num(g_pCvar_Grenade_Frost_Glow_Rendering_B), kRenderNormal, 16);

		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW); // TE player
		write_short(iEntity); // entity
		write_short(g_Trail_Sprite); // sprite
		write_byte(10); // life
		write_byte(10); // width
		write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Trail_Rendering_R)); // r
		write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Trail_Rendering_G)); // g
		write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Trail_Rendering_B)); // b
		write_byte(200); // brightness
		message_end();

		// Set grenade type on the thrown grenade entity
		set_entvar(iEntity, PEV_NADE_TYPE, NADE_TYPE_FROST);

		engfunc(EngFunc_SetModel, iEntity, g_W_Model_Grenade_Frost);

		return FMRES_SUPERCEDE;
	}

	return FMRES_IGNORED;
}

// Ham Grenade Think Forward
public Ham_Think_Grande_(iEntity)
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
	if (get_entvar(iEntity, PEV_NADE_TYPE) == NADE_TYPE_FROST)
	{
		Frost_Explode(iEntity);

		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
}

public client_disconnected(iPlayer)
{
	remove_task(iPlayer + TASK_FROST_REMOVE);

	BIT_SUB(g_Is_Frozen, iPlayer);
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}

// Frost Grenade Explosion
Frost_Explode(iEntity)
{
	// Get origin
	static Float:fOrigin[3];

	get_entvar(iEntity, var_origin, fOrigin);

	// Make the explosion
	Create_Blast3(fOrigin);

	new szSound[SOUND_MAX_LENGTH];
	ArrayGetString(g_aSound_Grenade_Frost_Explode, RANDOM(ArraySize(g_aSound_Grenade_Frost_Explode)), szSound, charsmax(szSound));
	emit_sound(iEntity, CHAN_VOICE, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

	// Collisions
	new iVictim = -1;

	while ((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, fOrigin, g_fGrenade_Radius)) != 0)
	{
		// Only effect alive zombies
		if (iVictim <= MaxClients && BIT_VALID(g_iBit_Alive, iVictim) && zpe_core_is_zombie(iVictim))
		{
			Set_Freeze(iVictim);
		}
	}

	// Get rid of the grenade
	rg_remove_entity(iEntity);
}

Set_Freeze(iVictim)
{
	// Already frozen
	if (BIT_VALID(g_Is_Frozen, iVictim))
	{
		return false;
	}

	// Allow other plugins to decide whether player should be frozen or not
	ExecuteForward(g_Forwards[FW_USER_FREEZE_PRE], g_Forward_Result, iVictim);

	if (g_Forward_Result >= PLUGIN_HANDLED)
	{
		// Get player's origin
		static iOrigin[3];

		get_user_origin(iVictim, iOrigin);

		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSound_Grenade_Frost_Break, RANDOM(ArraySize(g_aSound_Grenade_Frost_Break)), szSound, charsmax(szSound));
		emit_sound(iVictim, CHAN_VOICE, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

		// Glass shatter
		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_BREAKMODEL); // TE player
		write_coord(iOrigin[0]); // x
		write_coord(iOrigin[1]); // y
		write_coord(iOrigin[2] + 24); // z
		write_coord(16); // size x
		write_coord(16); // size y
		write_coord(16); // size z
		write_coord(random_num(-50, 50)); // velocity x
		write_coord(random_num(-50, 50)); // velocity y
		write_coord(25); // velocity z
		write_byte(10); // random velocity
		write_short(g_Glass_Sprite); // model
		write_byte(10); // count
		write_byte(25); // life
		write_byte(BREAK_GLASS); // flags
		message_end();

		return false;
	}

	// Freeze icon?
	if (get_pcvar_num(g_pCvar_Grenade_Frost_Hudicon_Enemy))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Message_Damage, _, iVictim);
		write_byte(0); // damage save
		write_byte(0); // damage take
		write_long(DMG_DROWN); // damage type
		write_coord(0); // x
		write_coord(0); // y
		write_coord(0); // z
		message_end();
	}

	// Set frozen flag
	BIT_ADD(g_Is_Frozen, iVictim);

	// Freeze sound
	new szSound[SOUND_MAX_LENGTH];
	ArrayGetString(g_aSound_Grenade_Frost_Player, RANDOM(ArraySize(g_aSound_Grenade_Frost_Player)), szSound, charsmax(szSound));
	emit_sound(iVictim, CHAN_VOICE, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

	// Add a blue tint to their screen
	message_begin(MSG_ONE, g_Message_Screen_Fade, _, iVictim);
	write_short(0); // duration
	write_short(0); // hold time
	write_short(FFADE_STAYOUT); // fade type
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Screen_Rendering_R)); // r
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Screen_Rendering_G)); // g
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Screen_Rendering_B)); // b
	write_byte(100); // alpha
	message_end();

	// Update player entity rendering
	Apply_Frozen_Rendering(iVictim);

	// Block gravity
	Apply_Frozen_Gravity(iVictim);

	// Update player's maxspeed
	ExecuteHamB(Ham_Player_ResetMaxSpeed, iVictim);

	// Set a task to remove the freeze
	set_task(get_pcvar_float(g_pCvar_Grenade_Frost_Duration), "Remove_Freeze", iVictim + TASK_FROST_REMOVE);

	return true;
}

Apply_Frozen_Gravity(iPlayer)
{
	// Get current gravity
	new Float:fGravity = GET_USER_GRAVITY(iPlayer);

	// Already set, no worries...
	if (fGravity == GRAVITY_HIGH || fGravity == GRAVITY_NONE)
	{
		return;
	}

	// Save player's old gravity
	g_fFrozen_Gravity[iPlayer] = fGravity;

	// Prevent from jumping
	if (get_entvar(iPlayer, var_flags) & FL_ONGROUND)
	{
		SET_USER_GRAVITY(iPlayer, GRAVITY_HIGH); // set really high
	}

	else
	{
		SET_USER_GRAVITY(iPlayer, GRAVITY_NONE); // no gravity
	}
}

Apply_Frozen_Rendering(iPlayer)
{
	// Get current rendering
	new iRendering_FX = get_entvar(iPlayer, var_renderfx);

	new Float:fRendering_Color[3];

	get_entvar(iPlayer, var_rendercolor, fRendering_Color);

	new iRendering_Render = get_entvar(iPlayer, var_rendermode);

	new Float:fRendering_Amount;

	get_entvar(iPlayer, var_renderamt, fRendering_Amount);

	// Already set, no worries...
	if
	(
		iRendering_FX == kRenderFxGlowShell
		&& fRendering_Color[0] == 0.0
		&& fRendering_Color[1] == 100.0
		&& fRendering_Color[2] == 200.0
		&& iRendering_Render == kRenderNormal
		&& fRendering_Amount == 25.0
	)
	{
		return;
	}

	// Save player's old rendering
	g_Frozen_Rendering_Fx[iPlayer] = get_entvar(iPlayer, var_renderfx);

	get_entvar(iPlayer, var_rendercolor, g_fFrozen_Rendering_Color[iPlayer]);

	g_Frozen_Rendering_Render[iPlayer] = get_entvar(iPlayer, var_rendermode);

	get_entvar(iPlayer, var_renderamt, g_fFrozen_Rendering_Amount[iPlayer]);

	// Light blue glow while frozen
	rg_set_user_rendering(iPlayer, kRenderFxGlowShell, get_pcvar_num(g_pCvar_Grenade_Frost_Glow_Rendering_R), get_pcvar_num(g_pCvar_Grenade_Frost_Glow_Rendering_G), get_pcvar_num(g_pCvar_Grenade_Frost_Glow_Rendering_B), kRenderNormal, 25);
}

// Remove freeze task
public Remove_Freeze(iTask_ID)
{
	// Remove frozen flag
	BIT_SUB(g_Is_Frozen, ID_FROST_REMOVE);

	// Restore gravity
	SET_USER_GRAVITY(ID_FROST_REMOVE, g_fFrozen_Gravity[ID_FROST_REMOVE]);

	// Update player's maxspeed
	ExecuteHamB(Ham_Player_ResetMaxSpeed, ID_FROST_REMOVE);

	// Restore rendering
	rh_set_rendering_float(ID_FROST_REMOVE, g_Frozen_Rendering_Fx[ID_FROST_REMOVE], g_fFrozen_Rendering_Color[ID_FROST_REMOVE], g_Frozen_Rendering_Render[ID_FROST_REMOVE], g_fFrozen_Rendering_Amount[ID_FROST_REMOVE]);

	// Gradually remove screen's blue tint
	message_begin(MSG_ONE, g_Message_Screen_Fade, _, ID_FROST_REMOVE);
	write_short(UNIT_SECOND); // duration
	write_short(0); // hold time
	write_short(FFADE_IN); // fade type
	write_byte(0); // red
	write_byte(50); // green
	write_byte(200); // blue
	write_byte(100); // alpha
	message_end();

	new szSound[SOUND_MAX_LENGTH];
	ArrayGetString(g_aSound_Grenade_Frost_Break, RANDOM(ArraySize(g_aSound_Grenade_Frost_Break)), szSound, charsmax(szSound));
	emit_sound(ID_FROST_REMOVE, CHAN_VOICE, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

	// Get player's origin
	static iOrigin[3];

	get_user_origin(ID_FROST_REMOVE, iOrigin);

	// Glass shatter
	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
	write_byte(TE_BREAKMODEL); // TE player
	write_coord(iOrigin[0]); // x
	write_coord(iOrigin[1]); // y
	write_coord(iOrigin[2] + 24); // z
	write_coord(16); // size x
	write_coord(16); // size y
	write_coord(16); // size z
	write_coord(random_num(-50, 50)); // velocity x
	write_coord(random_num(-50, 50)); // velocity y
	write_coord(25); // velocity z
	write_byte(10); // random velocity
	write_short(g_Glass_Sprite); // model
	write_byte(10); // count
	write_byte(25); // life
	write_byte(BREAK_GLASS); // flags
	message_end();

	ExecuteForward(g_Forwards[FW_USER_UNFROZEN], g_Forward_Result, ID_FROST_REMOVE);
}

public Event_CurWeapon(iPlayer)
{
	if (get_pcvar_num(g_pCvar_Grenade_Frost_Hudicon_Player))
	{
		if (read_data(2) == CSW_FLASHBANG)
		{
			message_begin(MSG_ONE, g_iStatus_Icon, _, iPlayer);
			write_byte(1);
			write_string("dmg_cold");
			write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Hudicon_Player_Color_R));
			write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Hudicon_Player_Color_G));
			write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Hudicon_Player_Color_B));
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
	if (get_pcvar_num(g_pCvar_Grenade_Frost_Hudicon_Player))
	{
		Grenade_Icon_Remove(read_data(2));
	}
}

Grenade_Icon_Remove(iPlayer)
{
	message_begin(MSG_ONE, g_iStatus_Icon, _, iPlayer);
	write_byte(0);
	write_string("dmg_cold");
	message_end();
}

// Frost Grenade: Freeze Blast
Create_Blast3(const Float:fOrigin[3])
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
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Small_Ring_Rendering_R)); // red
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Small_Ring_Rendering_G)); // green
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Small_Ring_Rendering_B)); // blue
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
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Medium_Ring_Rendering_R)); // red
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Medium_Ring_Rendering_G)); // green
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Medium_Ring_Rendering_B)); // blue
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
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Largest_Ring_Rendering_R)) ;// red
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Largest_Ring_Rendering_G)); // green
	write_byte(get_pcvar_num(g_pCvar_Grenade_Frost_Largest_Ring_Rendering_B)); // blue
	write_byte(200); // brightness
	write_byte(0); // speed
	message_end();
}