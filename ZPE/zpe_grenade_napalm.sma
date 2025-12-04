/* AMX Mod X
*	[ZPE] Grenade Napalm.
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

#define PLUGIN "grenade napalm"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <hamsandwich>
#include <xs>
#include <ck_cs_weap_models_api>
#include <zpe_kernel>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>

#define ZPE_SETTINGS_FILE "ZPE/zpe_items.ini"

// HACK: var_ field used to store custom nade types and their values
#define PEV_NADE_TYPE var_flTimeStepSound
#define NADE_TYPE_NAPALM 2222

#define TASK_BURN 100
#define ID_BURN (iTask_ID - TASK_BURN)

#define GRENADE_NAPALM_SPRITE_FIRE "sprites/flame.spr"

#define GRENADE_NAPALM_SPRITE_TRAIL "sprites/laserbeam.spr"
#define GRENADE_NAPALM_SPRITE_RING "sprites/shockwave.spr"
#define GRENADE_NAPALM_SPRITE_SMOKE "sprites/black_smoke3.spr"

new g_V_Model_Grenade_Napalm[MODEL_MAX_LENGTH] = "models/zombie_plague_enterprise/v_grenade_napalm.mdl";
new g_P_Model_Grenade_Napalm[MODEL_MAX_LENGTH] = "models/p_hegrenade.mdl";
new g_W_Model_Grenade_Napalm[MODEL_MAX_LENGTH] = "models/w_hegrenade.mdl";

// Custom Forwards
enum TOTAL_FORWARDS
{
	FW_USER_BURN_PRE = 0
};

new g_Forwards[TOTAL_FORWARDS];
new g_Forward_Result;

new g_Explode_Sprite;

new g_Burning_Duration[33];

new Array:g_aSound_Grenade_Napalm_Explode;

new g_Trail_Sprite;
new g_Flame_Sprite;
new g_Smoke_Sprite;

new g_Message_Damage;

new g_iStatus_Icon;

new g_pCvar_Grenade_Napalm_Duration_Nemesis;
new g_pCvar_Grenade_Napalm_Duration_Assassin;
new g_pCvar_Grenade_Napalm_Duration_Zombie;

new g_pCvar_Grenade_Napalm_Slowdown_Nemesis;
new g_pCvar_Grenade_Napalm_Slowdown_Assassin;

new g_pCvar_Grenade_Napalm_Damage_Nemesis;
new g_pCvar_Grenade_Napalm_Damage_Assassin;
new g_pCvar_Grenade_Napalm_Damage_Zombie;

new g_pCvar_Grenade_Napalm_Hudicon_Player;
new g_pCvar_Grenade_Napalm_Hudicon_Enemy;
new g_pCvar_Grenade_Napalm_Explosion;

new g_pCvar_Grenade_Napalm_Hudicon_Player_Color_R;
new g_pCvar_Grenade_Napalm_Hudicon_Player_Color_G;
new g_pCvar_Grenade_Napalm_Hudicon_Player_Color_B;

new g_pCvar_Grenade_Napalm_Glow_Rendering_R;
new g_pCvar_Grenade_Napalm_Glow_Rendering_G;
new g_pCvar_Grenade_Napalm_Glow_Rendering_B;

new g_pCvar_Grenade_Napalm_Trail_Rendering_R;
new g_pCvar_Grenade_Napalm_Trail_Rendering_G;
new g_pCvar_Grenade_Napalm_Trail_Rendering_B;

new g_pCvar_Grenade_Napalm_Small_Ring_Rendering_R;
new g_pCvar_Grenade_Napalm_Small_Ring_Rendering_G;
new g_pCvar_Grenade_Napalm_Small_Ring_Rendering_B;

new g_pCvar_Grenade_Napalm_Medium_Ring_Rendering_R;
new g_pCvar_Grenade_Napalm_Medium_Ring_Rendering_G;
new g_pCvar_Grenade_Napalm_Medium_Ring_Rendering_B;

new g_pCvar_Grenade_Napalm_Largest_Ring_Rendering_R;
new g_pCvar_Grenade_Napalm_Largest_Ring_Rendering_G;
new g_pCvar_Grenade_Napalm_Largest_Ring_Rendering_B;

new Float:g_fGrenade_Radius;

new g_iBit_Alive;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Grenade_Napalm_Duration_Nemesis = register_cvar("zpe_grenade_napalm_duration_nemesis", "10");
	g_pCvar_Grenade_Napalm_Duration_Assassin = register_cvar("zpe_grenade_napalm_duration_assassin", "10");
	g_pCvar_Grenade_Napalm_Duration_Zombie = register_cvar("zpe_grenade_napalm_duration_zombie", "10");

	g_pCvar_Grenade_Napalm_Slowdown_Nemesis = register_cvar("zpe_grenade_napalm_slowdown_nemesis", "0.5");
	g_pCvar_Grenade_Napalm_Slowdown_Assassin = register_cvar("zpe_grenade_napalm_slowdown_assassin", "0.5");

	g_pCvar_Grenade_Napalm_Damage_Nemesis = register_cvar("zpe_grenade_napalm_damage_nemesis", "5.0");
	g_pCvar_Grenade_Napalm_Damage_Assassin = register_cvar("zpe_grenade_napalm_damage_assassin", "5.0");
	g_pCvar_Grenade_Napalm_Damage_Zombie = register_cvar("zpe_grenade_napalm_damage_zombie", "5.0");

	g_pCvar_Grenade_Napalm_Hudicon_Player = register_cvar("zpe_grenade_napalm_hudicon_player", "1");
	g_pCvar_Grenade_Napalm_Hudicon_Enemy = register_cvar("zpe_grenade_napalm_hudicon_enemy", "1");
	g_pCvar_Grenade_Napalm_Explosion = register_cvar("zpe_grenade_napalm_explosion", "0");

	g_pCvar_Grenade_Napalm_Hudicon_Player_Color_R = register_cvar("zpe_grenade_napalm_hudicon_player_color_r", "255");
	g_pCvar_Grenade_Napalm_Hudicon_Player_Color_G = register_cvar("zpe_grenade_napalm_hudicon_player_color_g", "0");
	g_pCvar_Grenade_Napalm_Hudicon_Player_Color_B = register_cvar("zpe_grenade_napalm_hudicon_player_color_b", "0");

	g_pCvar_Grenade_Napalm_Glow_Rendering_R = register_cvar("zpe_grenade_napalm_glow_rendering_r", "200");
	g_pCvar_Grenade_Napalm_Glow_Rendering_G = register_cvar("zpe_grenade_napalm_glow_rendering_g", "0");
	g_pCvar_Grenade_Napalm_Glow_Rendering_B = register_cvar("zpe_grenade_napalm_glow_rendering_b", "0");

	g_pCvar_Grenade_Napalm_Trail_Rendering_R = register_cvar("zpe_grenade_napalm_trail_rendering_r", "200");
	g_pCvar_Grenade_Napalm_Trail_Rendering_G = register_cvar("zpe_grenade_napalm_trail_rendering_g", "0");
	g_pCvar_Grenade_Napalm_Trail_Rendering_B = register_cvar("zpe_grenade_napalm_trail_rendering_b", "0");

	g_pCvar_Grenade_Napalm_Small_Ring_Rendering_R = register_cvar("zpe_grenade_napalm_small_ring_rendering_r", "200");
	g_pCvar_Grenade_Napalm_Small_Ring_Rendering_G = register_cvar("zpe_grenade_napalm_small_ring_rendering_g", "100");
	g_pCvar_Grenade_Napalm_Small_Ring_Rendering_B = register_cvar("zpe_grenade_napalm_small_ring_rendering_b", "0");

	g_pCvar_Grenade_Napalm_Medium_Ring_Rendering_R = register_cvar("zpe_grenade_napalm_medium_ring_rendering_r", "200");
	g_pCvar_Grenade_Napalm_Medium_Ring_Rendering_G = register_cvar("zpe_grenade_napalm_medium_ring_rendering_g", "50");
	g_pCvar_Grenade_Napalm_Medium_Ring_Rendering_B = register_cvar("zpe_grenade_napalm_medium_ring_rendering_b", "0");

	g_pCvar_Grenade_Napalm_Largest_Ring_Rendering_R = register_cvar("zpe_grenade_napalm_largest_ring_rendering_r", "200");
	g_pCvar_Grenade_Napalm_Largest_Ring_Rendering_G = register_cvar("zpe_grenade_napalm_largest_ring_rendering_g", "0");
	g_pCvar_Grenade_Napalm_Largest_Ring_Rendering_B = register_cvar("zpe_grenade_napalm_largest_ring_rendering_b", "0");

	bind_pcvar_float(register_cvar("zpe_grenade_napalm_explosion_radius", "240"), g_fGrenade_Radius);

	RegisterHam(Ham_Think, "grenade", "Ham_Think_Grenade_");

	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);

	register_forward(FM_SetModel, "FM_SetModel_");

	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1");
	register_event("DeathMsg", "Event_DeathMsg", "a");

	g_iStatus_Icon = get_user_msgid("StatusIcon");
	g_Message_Damage = get_user_msgid("Damage");

	g_Forwards[FW_USER_BURN_PRE] = CreateMultiForward("zpe_fw_grenade_napalm_pre", ET_CONTINUE, FP_CELL);
}

public plugin_precache()
{
	g_aSound_Grenade_Napalm_Explode = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "GRENADE NAPALM EXPLODE", g_aSound_Grenade_Napalm_Explode);
	Precache_Sounds(g_aSound_Grenade_Napalm_Explode);

	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "V GRENADE NAPALM", g_V_Model_Grenade_Napalm, charsmax(g_V_Model_Grenade_Napalm));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "P GRENADE NAPALM", g_P_Model_Grenade_Napalm, charsmax(g_P_Model_Grenade_Napalm));
	amx_load_setting_string(ZPE_SETTINGS_FILE, "Weapon Models", "W GRENADE NAPALM", g_W_Model_Grenade_Napalm, charsmax(g_W_Model_Grenade_Napalm));

	precache_model(g_V_Model_Grenade_Napalm);
	precache_model(g_P_Model_Grenade_Napalm);
	precache_model(g_W_Model_Grenade_Napalm);

	g_Explode_Sprite = precache_model(GRENADE_NAPALM_SPRITE_RING);
	g_Trail_Sprite = precache_model(GRENADE_NAPALM_SPRITE_TRAIL);
	g_Flame_Sprite = precache_model(GRENADE_NAPALM_SPRITE_FIRE);
	g_Smoke_Sprite = precache_model(GRENADE_NAPALM_SPRITE_SMOKE);
}

public plugin_natives()
{
	register_library("zpe_grenade_napalm");

	register_native("zpe_grenade_napalm_get", "native_grenade_napalm_get");
	register_native("zpe_grenade_napalm_set", "native_grenade_napalm_set");
}

public native_grenade_napalm_get(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	return task_exists(iPlayer + TASK_BURN);
}

public native_grenade_napalm_set(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	new iSet = get_param(2);

	// End fire
	if (!iSet)
	{
		// Not burning
		if (!task_exists(iPlayer + TASK_BURN))
		{
			return true;
		}

		// Get player origin
		static iOrigin[3];

		get_user_origin(iPlayer, iOrigin);

		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_SMOKE); // TE player
		write_coord(iOrigin[0]); // x
		write_coord(iOrigin[1]); // y
		write_coord(iOrigin[2] - 50); // z
		write_short(g_Smoke_Sprite); // sprite
		write_byte(random_num(15, 20)); // scale
		write_byte(random_num(10, 20)); // framerate
		message_end();

		// Task not needed anymore
		remove_task(iPlayer + TASK_BURN);

		return true;
	}

	// Set on fire
	return Set_On_Fire(iPlayer);
}

public zpe_fw_core_cure_post(iPlayer)
{
	// Stop burning
	remove_task(iPlayer + TASK_BURN);

	g_Burning_Duration[iPlayer] = 0;

	// Set custom grenade model
	cs_set_player_view_model(iPlayer, CSW_HEGRENADE, g_V_Model_Grenade_Napalm);
	cs_set_player_weap_model(iPlayer, CSW_HEGRENADE, g_P_Model_Grenade_Napalm);
}

public zpe_fw_core_infect(iPlayer)
{
	// Remove custom grenade model
	cs_reset_player_view_model(iPlayer, CSW_HEGRENADE);
}

public RG_CSGameRules_PlayerKilled_Post(iVictim)
{
	// Stop burning
	remove_task(iVictim + TASK_BURN);

	g_Burning_Duration[iVictim] = 0;
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

	// HE Grenade
	if (sModel[9] == 'h' && sModel[10] == 'e')
	{
		// Give it a glow
		rg_set_user_rendering(iEntity, kRenderFxGlowShell, get_pcvar_num(g_pCvar_Grenade_Napalm_Glow_Rendering_R), get_pcvar_num(g_pCvar_Grenade_Napalm_Glow_Rendering_G), get_pcvar_num(g_pCvar_Grenade_Napalm_Glow_Rendering_B), kRenderNormal, 16);

		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW); // TE player
		write_short(iEntity); // entity
		write_short(g_Trail_Sprite); // sprite
		write_byte(10); // life
		write_byte(10); // width
		write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Trail_Rendering_R)); // r
		write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Trail_Rendering_G)); // g
		write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Trail_Rendering_B)); // b
		write_byte(200); // brightness
		message_end();

		// Set grenade type on the thrown grenade entity
		set_entvar(iEntity, PEV_NADE_TYPE, NADE_TYPE_NAPALM);

		engfunc(EngFunc_SetModel, iEntity, g_W_Model_Grenade_Napalm);

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

	// Check if it's time to go off
	if (fDamage_Time > get_gametime())
	{
		return HAM_IGNORED;
	}

	// Not a napalm grenade
	if (get_entvar(iEntity, PEV_NADE_TYPE) != NADE_TYPE_NAPALM)
	{
		return HAM_IGNORED;
	}

	Fire_Explode(iEntity);

	// Keep the original explosion?
	if (get_pcvar_num(g_pCvar_Grenade_Napalm_Explosion))
	{
		set_entvar(iEntity, PEV_NADE_TYPE, 0);

		return HAM_IGNORED;
	}

	// Get rid of the grenade
	rg_remove_entity(iEntity);

	return HAM_SUPERCEDE;
}

public client_disconnected(iPlayer)
{
	// Stop burning
	remove_task(iPlayer + TASK_BURN);

	g_Burning_Duration[iPlayer] = 0;

	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

// Napalm Grenade Explosion
Fire_Explode(iEntity)
{
	// Get origin
	static Float:fOrigin[3];

	get_entvar(iEntity, var_origin, fOrigin);

	// Override original HE grenade explosion?
	if (!get_pcvar_num(g_pCvar_Grenade_Napalm_Explosion))
	{
		// Make the explosion
		Create_Blast2(fOrigin);

		// Fire grenade explode sound
		new szSound[SOUND_MAX_LENGTH];
		ArrayGetString(g_aSound_Grenade_Napalm_Explode, RANDOM(ArraySize(g_aSound_Grenade_Napalm_Explode)), szSound, charsmax(szSound));
		emit_sound(iEntity, CHAN_VOICE, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}

	// Collisions
	new iVictim = -1;

	while ((iVictim = engfunc(EngFunc_FindEntityInSphere, iVictim, fOrigin, g_fGrenade_Radius)) != 0)
	{
		// Only effect alive zombies
		if (iVictim <= MaxClients && BIT_VALID(g_iBit_Alive, iVictim) && zpe_core_is_zombie(iVictim))
		{
			Set_On_Fire(iVictim);
		}
	}
}

Set_On_Fire(iVictim)
{
	// Allow other plugins to decide whether player should be burned or not
	ExecuteForward(g_Forwards[FW_USER_BURN_PRE], g_Forward_Result, iVictim);

	if (g_Forward_Result >= PLUGIN_HANDLED)
	{
		return false;
	}

	// Heat icon?
	if (get_pcvar_num(g_pCvar_Grenade_Napalm_Hudicon_Enemy))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Message_Damage, _, iVictim);
		write_byte(0); // damage save
		write_byte(0); // damage take
		write_long(DMG_BURN); // damage type
		write_coord(0); // x
		write_coord(0); // y
		write_coord(0); // z
		message_end();
	}

	// Reduced duration for nemesis
	if (zpe_class_nemesis_get(iVictim))
	{
		// Fire duration (nemesis)
		g_Burning_Duration[iVictim] += get_pcvar_num(g_pCvar_Grenade_Napalm_Duration_Nemesis);
	}

	// Reduced duration for assassin
	else if (zpe_class_assassin_get(iVictim))
	{
		// Fire duration (assassin)
		g_Burning_Duration[iVictim] += get_pcvar_num(g_pCvar_Grenade_Napalm_Duration_Assassin);
	}

	else
	{
		// Fire duration (zombie)
		g_Burning_Duration[iVictim] += get_pcvar_num(g_pCvar_Grenade_Napalm_Duration_Zombie) * 5;
	}

	// Set burning task on victim
	remove_task(iVictim + TASK_BURN);

	set_task(0.2, "Burning_Flame", iVictim + TASK_BURN, _, _, "b");

	return true;
}

// Burning Flames
public Burning_Flame(iTask_ID)
{
	// Get player origin and flags
	static iOrigin[3];

	get_user_origin(ID_BURN, iOrigin);

	new iFlags = get_entvar(ID_BURN, var_flags);

	// In water or burning stopped
	if ((iFlags & FL_INWATER) || g_Burning_Duration[ID_BURN] < 1)
	{
		// Smoke sprite
		message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
		write_byte(TE_SMOKE); // TE player
		write_coord(iOrigin[0]); // x
		write_coord(iOrigin[1]); // y
		write_coord(iOrigin[2] - 50); // z
		write_short(g_Smoke_Sprite); // sprite
		write_byte(random_num(15, 20)); // scale
		write_byte(random_num(10, 20)); // framerate
		message_end();

		// Task not needed anymore
		remove_task(iTask_ID);

		return;
	}

	// Nemesis Class loaded?
	if (zpe_class_nemesis_get(ID_BURN))
	{
		// Fire slow down
		if ((iFlags & FL_ONGROUND) && get_pcvar_float(g_pCvar_Grenade_Napalm_Slowdown_Nemesis) > 0.0)
		{
			static Float:fVelocity[3];

			get_entvar(ID_BURN, var_velocity, fVelocity);

			xs_vec_mul_scalar(fVelocity, get_pcvar_float(g_pCvar_Grenade_Napalm_Slowdown_Nemesis), fVelocity);

			set_entvar(ID_BURN, var_velocity, fVelocity);
		}

		new Float:fHealth_After_Damage = Float:GET_USER_HEALTH(ID_BURN) - get_pcvar_float(g_pCvar_Grenade_Napalm_Damage_Nemesis);

		// Take damage from the fire
		if (fHealth_After_Damage > 0.0)
		{
			SET_USER_HEALTH(ID_BURN, fHealth_After_Damage);
		}
	}

	// Assassin Class loaded?
	else if (zpe_class_assassin_get(ID_BURN))
	{
		// Fire slow down
		if ((iFlags & FL_ONGROUND) && get_pcvar_float(g_pCvar_Grenade_Napalm_Slowdown_Assassin) > 0.0)
		{
			static Float:fVelocity[3];

			get_entvar(ID_BURN, var_velocity, fVelocity);

			xs_vec_mul_scalar(fVelocity, get_pcvar_float(g_pCvar_Grenade_Napalm_Slowdown_Assassin), fVelocity);

			set_entvar(ID_BURN, var_velocity, fVelocity);
		}

		new Float:fHealth_After_Damage = Float:GET_USER_HEALTH(ID_BURN) - get_pcvar_float(g_pCvar_Grenade_Napalm_Damage_Assassin);

		// Take damage from the fire
		if (fHealth_After_Damage > 0.0)
		{
			SET_USER_HEALTH(ID_BURN, fHealth_After_Damage);
		}
	}

	else
	{
		new Float:fHealth_After_Damage = Float:GET_USER_HEALTH(ID_BURN) - get_pcvar_float(g_pCvar_Grenade_Napalm_Damage_Zombie);

		// Take damage from the fire
		if (fHealth_After_Damage > 0.0)
		{
			SET_USER_HEALTH(ID_BURN, fHealth_After_Damage);
		}
	}

	// Flame sprite
	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
	write_byte(TE_SPRITE); // TE player
	write_coord(iOrigin[0] + random_num(-5, 5)); // x
	write_coord(iOrigin[1] + random_num(-5, 5)); // y
	write_coord(iOrigin[2] + random_num(-10, 10)); // z
	write_short(g_Flame_Sprite); // sprite
	write_byte(random_num(5, 10)); // scale
	write_byte(200); // brightness
	message_end();

	// Decrease burning duration counter
	g_Burning_Duration[ID_BURN] -= 1;
}

public Event_CurWeapon(iPlayer)
{
	if (get_pcvar_num(g_pCvar_Grenade_Napalm_Hudicon_Player))
	{
		// TODO: if zpe_core_is_zombie - crutch. Use wpn key
		if (read_data(2) == CSW_HEGRENADE && !zpe_core_is_zombie(iPlayer))
		{
			message_begin(MSG_ONE, g_iStatus_Icon, _, iPlayer);
			write_byte(1);
			write_string("dmg_heat");
			write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Hudicon_Player_Color_R));
			write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Hudicon_Player_Color_G));
			write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Hudicon_Player_Color_B));
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
	if (get_pcvar_num(g_pCvar_Grenade_Napalm_Hudicon_Player))
	{
		Grenade_Icon_Remove(read_data(2));
	}
}

Grenade_Icon_Remove(iPlayer)
{
	message_begin(MSG_ONE, g_iStatus_Icon, _, iPlayer);
	write_byte(0);
	write_string("dmg_heat");
	message_end();
}

// Fire Blast
Create_Blast2(const Float:fOrigin[3])
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
	write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Small_Ring_Rendering_R)); // red
	write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Small_Ring_Rendering_G)); // green
	write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Small_Ring_Rendering_B)); // blue
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
	write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Medium_Ring_Rendering_R)); // red
	write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Medium_Ring_Rendering_G)); // green
	write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Medium_Ring_Rendering_B)); // blue
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
	write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Largest_Ring_Rendering_R)); // red
	write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Largest_Ring_Rendering_G)); // green
	write_byte(get_pcvar_num(g_pCvar_Grenade_Napalm_Largest_Ring_Rendering_B)); // blue
	write_byte(200); // brightness
	write_byte(0); // speed
	message_end();
}