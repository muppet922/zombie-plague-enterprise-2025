/* AMX Mod X
*	[ZPE] Class Assassin.
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

#define PLUGIN "class assassin"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <ck_cs_maxspeed_api>
#include <ck_cs_weap_models_api>
#include <zpe_kernel>

#define ZPE_SETTINGS_FILE "ZPE/classes/other/zpe_assassin.ini"

#define TASK_AURA 100
#define ID_AURA (iTask_ID - TASK_AURA)

new Array:g_aModels_Assassin_Player;
new Array:g_aModels_Assassin_Claw;

new Array:g_aSound_Assassin_Die;
new Array:g_aSound_Assassin_Fall;
new Array:g_aSound_Assassin_Pain;
new Array:g_aSound_Assassin_Miss_Slash;
new Array:g_aSound_Assassin_Hit_Solid;
new Array:g_aSound_Assassin_Hit_Normal;
new Array:g_aSound_Assassin_Hit_Stab;

new g_Forward;
new g_Forward_Result;

new g_pCvar_Assassin_Base_Health;
new g_pCvar_Assassin_Health_Per_Player;
new g_pCvar_Assassin_Armor;
new g_pCvar_Assassin_Armor_Type;
new g_pCvar_Assassin_Speed;
new g_pCvar_Assassin_Gravity;

new g_pCvar_Assassin_Glow;
new g_pCvar_Assassin_Aura;
new g_pCvar_Assassin_Aura_Radius;
new g_pCvar_Assassin_Aura_Color_R;
new g_pCvar_Assassin_Aura_Color_G;
new g_pCvar_Assassin_Aura_Color_B;
new g_pCvar_Assassin_Aura_Life;
new g_pCvar_Assassin_Aura_Decay_Rate;

new g_pCvar_Assassin_Kill_Splash;
new g_pCvar_Assassin_Kill_Explode;
new g_pCvar_Assassin_Gib_Spread;
new g_pCvar_Assassin_Gib_Count;
new g_pCvar_Assassin_Gib_Life;

new g_pCvar_Assassin_Damage;

new g_pCvar_Assassin_Grenade_Frost;
new g_pCvar_Assassin_Grenade_Napalm;

new g_Gib_Model;

new g_iBit_Assassin;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Assassin_Base_Health = register_cvar("zpe_assassin_base_health", "2000.0");
	g_pCvar_Assassin_Health_Per_Player = register_cvar("zpe_assassin_health_per_player", "250.0");
	g_pCvar_Assassin_Armor = register_cvar("zpe_assassin_armor", "0");
	g_pCvar_Assassin_Armor_Type = register_cvar("zpe_assassin_armor_type", "0");
	g_pCvar_Assassin_Speed = register_cvar("zpe_assassin_speed", "1.05");
	g_pCvar_Assassin_Gravity = register_cvar("zpe_assassin_gravity", "0.5");

	g_pCvar_Assassin_Glow = register_cvar("zpe_assassin_glow", "0");
	g_pCvar_Assassin_Aura = register_cvar("zpe_assassin_aura", "0");
	g_pCvar_Assassin_Aura_Radius = register_cvar("zpe_assassin_aura_radius", "20");
	g_pCvar_Assassin_Aura_Color_R = register_cvar("zpe_assassin_aura_color_r", "150");
	g_pCvar_Assassin_Aura_Color_G = register_cvar("zpe_assassin_aura_color_g", "0");
	g_pCvar_Assassin_Aura_Color_B = register_cvar("zpe_assassin_aura_color_b", "0");
	g_pCvar_Assassin_Aura_Life = register_cvar("zpe_assassin_aura_life", "2");
	g_pCvar_Assassin_Aura_Decay_Rate = register_cvar("zpe_assassin_aura_decay_rate", "0");

	g_pCvar_Assassin_Kill_Splash = register_cvar("zpe_assassin_kill_splash", "0");
	g_pCvar_Assassin_Kill_Explode = register_cvar("zpe_assassin_kill_explode", "0");
	g_pCvar_Assassin_Gib_Spread = register_cvar("zpe_assassin_gib_spread", "10");
	g_pCvar_Assassin_Gib_Count = register_cvar("zpe_assassin_gib_count", "8");
	g_pCvar_Assassin_Gib_Life = register_cvar("zpe_assassin_gib_life", "30");
	g_pCvar_Assassin_Damage = register_cvar("zpe_assassin_damage", "1000.0");

	g_pCvar_Assassin_Grenade_Frost = register_cvar("zpe_assassin_grenade_frost", "0");
	g_pCvar_Assassin_Grenade_Napalm = register_cvar("zpe_assassin_grenade_napalm", "1");

	g_Forward = CreateMultiForward("zpe_fw_class_asassin_bit_change", ET_CONTINUE, FP_CELL);

	RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_CBasePlayer_TakeDamage_");

	// Dont use ReAPI, in the form of code - load
	register_forward(FM_EmitSound, "FM_EmitSound_");

	register_forward(FM_ClientDisconnect, "FM_ClientDisconnect_Post", 1);
}

public plugin_precache()
{
	g_aModels_Assassin_Player = ArrayCreate(PLAYER_MODEL_MAX_LENGTH, 1);
	g_aModels_Assassin_Claw = ArrayCreate(MODEL_MAX_LENGTH, 1);

	g_aSound_Assassin_Die = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Assassin_Fall = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Assassin_Pain = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Assassin_Miss_Slash = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Assassin_Hit_Solid = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Assassin_Hit_Normal = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Assassin_Hit_Stab = ArrayCreate(SOUND_MAX_LENGTH, 1);

	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Settings", "PLAYER MODELS", g_aModels_Assassin_Player);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Settings", "CLAWS MODEL", g_aModels_Assassin_Claw);

	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "DIE", g_aSound_Assassin_Die);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "FALL", g_aSound_Assassin_Fall);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "PAIN", g_aSound_Assassin_Pain);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "MISS SLASH", g_aSound_Assassin_Miss_Slash);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "HIT SOLID", g_aSound_Assassin_Hit_Solid);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "HIT NORMAL", g_aSound_Assassin_Hit_Normal);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "HIT STAB", g_aSound_Assassin_Hit_Stab);

	Precache_Player_Models(g_aModels_Assassin_Player);
	Precache_Models(g_aModels_Assassin_Claw);

	Precache_Sounds(g_aSound_Assassin_Die);
	Precache_Sounds(g_aSound_Assassin_Fall); 
	Precache_Sounds(g_aSound_Assassin_Pain);
	Precache_Sounds(g_aSound_Assassin_Miss_Slash);
	Precache_Sounds(g_aSound_Assassin_Hit_Solid);
	Precache_Sounds(g_aSound_Assassin_Hit_Normal);
	Precache_Sounds(g_aSound_Assassin_Hit_Stab);

	g_Gib_Model = precache_model("models/hgibs.mdl");
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/classes/other/zpe_assassin.cfg");
}

public plugin_natives()
{
	register_library("zpe_class_assassin");

	register_native("zpe_class_assassin_set", "native_class_assassin_set");
	register_native("zpe_class_assassin_get_count", "native_class_assassin_get_count");
}

public RG_CBasePlayer_TakeDamage_(iVictim, iInflictor, iAttacker, Float:fDamage)
{
	// Non-player damage or self damage
	if (!(1 <= iAttacker <= MaxClients) || iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return HC_CONTINUE;
	}

	// Assassin attacking human
	if (BIT_VALID(g_iBit_Assassin, iAttacker) && !zpe_core_is_zombie(iVictim))
	{
		// Ignore assassin damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (iInflictor == iAttacker)
		{
			// Set assassin damage
			SetHookChainArg(4, ATYPE_FLOAT, fDamage * get_pcvar_float(g_pCvar_Assassin_Damage)); // ExecuteHamB(Ham_Killed, victim, attacker, 0)
		}
	}

	return HC_CONTINUE;
}

public FM_EmitSound_(iPlayer, iChannel, const szSample[], Float:fVolume, Float:fAttn, iFlags, iPitch)
{
	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer) || !zpe_core_is_zombie(iPlayer))
	{
		return FMRES_IGNORED;
	}

	if (BIT_VALID(g_iBit_Assassin, iPlayer))
	{
		static szSound[SOUND_MAX_LENGTH];

		if (szSample[7] == 'd' && ((szSample[8] == 'i' && szSample[9] == 'e') || (szSample[8] == 'e' && szSample[9] == 'a')))
		{
			ArrayGetString(g_aSound_Assassin_Die, RANDOM(ArraySize(g_aSound_Assassin_Die)), szSound, charsmax(szSound));
			emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

			return FMRES_SUPERCEDE;
		}

		if (szSample[10] == 'f' && szSample[11] == 'a' && szSample[12] == 'l' && szSample[13] == 'l')
		{
			ArrayGetString(g_aSound_Assassin_Fall, RANDOM(ArraySize(g_aSound_Assassin_Fall)), szSound, charsmax(szSound));
			emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

			return FMRES_SUPERCEDE;
		}

		if (szSample[7] == 'b' && szSample[8] == 'h' && szSample[9] == 'i' && szSample[10] == 't')
		{
			ArrayGetString(g_aSound_Assassin_Pain, RANDOM(ArraySize(g_aSound_Assassin_Pain)), szSound, charsmax(szSound));
			emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

			return FMRES_SUPERCEDE;
		}

		if (szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i')
		{
			if (szSample[14] == 's' && szSample[15] == 'l' && szSample[16] == 'a')
			{
				ArrayGetString(g_aSound_Assassin_Miss_Slash, RANDOM(ArraySize(g_aSound_Assassin_Miss_Slash)), szSound, charsmax(szSound));
				emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

				return FMRES_SUPERCEDE;
			}

			if (szSample[14] == 'h' && szSample[15] == 'i' && szSample[16] == 't')
			{
				if (szSample[18] == 's')
				{
					ArrayGetString(g_aSound_Assassin_Hit_Solid, RANDOM(ArraySize(g_aSound_Assassin_Hit_Solid)), szSound, charsmax(szSound));
					emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

					return FMRES_SUPERCEDE;
				}

				else
				{
					ArrayGetString(g_aSound_Assassin_Hit_Normal, RANDOM(ArraySize(g_aSound_Assassin_Hit_Normal)), szSound, charsmax(szSound));
					emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

					return FMRES_SUPERCEDE;
				}
			}

			if (szSample[14] == 's' && szSample[15] == 't' && szSample[16] == 'a')
			{
				ArrayGetString(g_aSound_Assassin_Hit_Stab, RANDOM(ArraySize(g_aSound_Assassin_Hit_Stab)), szSound, charsmax(szSound));
				emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

				return FMRES_SUPERCEDE;
			}
		}
	}

	return FMRES_IGNORED;
}

public zpe_fw_grenade_frost_pre(iPlayer)
{
	// Prevent frost for assassin
	if (BIT_VALID(g_iBit_Assassin, iPlayer) && !get_pcvar_num(g_pCvar_Assassin_Grenade_Frost))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_grenade_napalm_pre(iPlayer)
{
	// Prevent burning for assassin
	if (BIT_VALID(g_iBit_Assassin, iPlayer) && !get_pcvar_num(g_pCvar_Assassin_Grenade_Napalm))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_core_spawn_post(iPlayer)
{
	if (BIT_VALID(g_iBit_Assassin, iPlayer))
	{
		// Remove assassin glow
		if (get_pcvar_num(g_pCvar_Assassin_Glow))
		{
			rg_set_user_rendering(iPlayer);
		}

		// Remove assassin aura
		if (get_pcvar_num(g_pCvar_Assassin_Aura))
		{
			remove_task(iPlayer + TASK_AURA);
		}

		// Remove assassin flag
		BIT_SUB(g_iBit_Assassin, iPlayer);

		ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Assassin);
	}
}

public zpe_fw_core_cure(iPlayer)
{
	if (BIT_VALID(g_iBit_Assassin, iPlayer))
	{
		// Remove assassin glow
		if (get_pcvar_num(g_pCvar_Assassin_Glow))
		{
			rg_set_user_rendering(iPlayer);
		}

		// Remove assassin aura
		if (get_pcvar_num(g_pCvar_Assassin_Aura))
		{
			remove_task(iPlayer + TASK_AURA);
		}

		// Remove assassin flag
		BIT_SUB(g_iBit_Assassin, iPlayer);

		ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Assassin);
	}
}

public zpe_fw_core_infect_post(iPlayer)
{
	// Apply assassin attributes?
	if (BIT_NOT_VALID(g_iBit_Assassin, iPlayer))
	{
		return;
	}

	// Health
	SET_USER_HEALTH(iPlayer, get_pcvar_float(g_pCvar_Assassin_Base_Health) + get_pcvar_float(g_pCvar_Assassin_Health_Per_Player) * Get_Alive_Count());

	// Armor
	if (get_pcvar_num(g_pCvar_Assassin_Armor_Type))
	{
		rg_set_user_armor(iPlayer, get_pcvar_num(g_pCvar_Assassin_Armor), ARMOR_VESTHELM);
	}

	else
	{
		rg_set_user_armor(iPlayer, get_pcvar_num(g_pCvar_Assassin_Armor), ARMOR_KEVLAR);
	}

	// Gravity
	SET_USER_GRAVITY(iPlayer, get_pcvar_float(g_pCvar_Assassin_Gravity));

	// Speed
	cs_set_player_maxspeed_auto(iPlayer, get_pcvar_float(g_pCvar_Assassin_Speed));

	// Apply assassin player model
	new szPlayer_Model[PLAYER_MODEL_MAX_LENGTH];
	ArrayGetString(g_aModels_Assassin_Player, RANDOM(ArraySize(g_aModels_Assassin_Player)), szPlayer_Model, charsmax(szPlayer_Model));
	rg_set_user_model(iPlayer, szPlayer_Model);

	// Apply assassin claw model
	new szClaw_Model[MODEL_MAX_LENGTH];
	ArrayGetString(g_aModels_Assassin_Claw, RANDOM(ArraySize(g_aModels_Assassin_Claw)), szClaw_Model, charsmax(szClaw_Model));
	cs_set_player_view_model(iPlayer, CSW_KNIFE, szClaw_Model);

	// Assassin glow
	if (get_pcvar_num(g_pCvar_Assassin_Glow))
	{
		rg_set_user_rendering(iPlayer, kRenderFxGlowShell, get_pcvar_num(g_pCvar_Assassin_Aura_Color_R), get_pcvar_num(g_pCvar_Assassin_Aura_Color_G), get_pcvar_num(g_pCvar_Assassin_Aura_Color_B), kRenderNormal, 25);
	}

	// Assassin aura task
	if (get_pcvar_num(g_pCvar_Assassin_Aura))
	{
		set_task(0.1, "Assassin_Aura", iPlayer + TASK_AURA, _, _, "b");
	}
}

public native_class_assassin_set(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	if (BIT_VALID(g_iBit_Assassin, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Player already a assassin (%d)", iPlayer);

		return false;
	}

	BIT_ADD(g_iBit_Assassin, iPlayer);

	ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Assassin);

	zpe_core_force_infect(iPlayer);

	return true;
}

public native_class_assassin_get_count(iPlugin_ID, iNum_Params)
{
	return Get_Assassin_Count();
}

// Assassin aura task
public Assassin_Aura(iTask_ID)
{
	// Get player's origin
	static iOrigin[3];

	get_user_origin(ID_AURA, iOrigin);

	// Colored aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
	write_byte(TE_DLIGHT); // TE player
	write_coord(iOrigin[0]); // x
	write_coord(iOrigin[1]); // y
	write_coord(iOrigin[2]); // z
	write_byte(get_pcvar_num(g_pCvar_Assassin_Aura_Radius)); // radius
	write_byte(get_pcvar_num(g_pCvar_Assassin_Aura_Color_R)); // r
	write_byte(get_pcvar_num(g_pCvar_Assassin_Aura_Color_G)); // g
	write_byte(get_pcvar_num(g_pCvar_Assassin_Aura_Color_B)); // b
	write_byte(get_pcvar_num(g_pCvar_Assassin_Aura_Life)); // life
	write_byte(get_pcvar_num(g_pCvar_Assassin_Aura_Decay_Rate)); // decay rate
	message_end();
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	if (BIT_VALID(g_iBit_Assassin, iPlayer))
	{
		// Remove assassin aura
		if (get_pcvar_num(g_pCvar_Assassin_Aura))
		{
			remove_task(iPlayer + TASK_AURA);
		}
	}

	BIT_SUB(g_iBit_Alive, iPlayer);
	BIT_SUB(g_iBit_Connected, iPlayer);
}

public FM_ClientDisconnect_Post(iPlayer)
{
	// Reset flags AFTER disconnect (to allow checking if the player was assassin before disconnecting)
	BIT_SUB(g_iBit_Assassin, iPlayer);

	ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Assassin);
}

// This is RG_CSGameRules_PlayerKilled Pre. Simply optimization.
public zpe_fw_kill_pre_bit_sub(iVictim, iAttacker)
{
	// When killed by a assassin victim explodes
	if (BIT_VALID(g_iBit_Assassin, iAttacker))
	{
		if (get_pcvar_num(g_pCvar_Assassin_Kill_Splash))
		{
			new Float:fOrigin[3];
			get_entvar(iVictim, var_origin, fOrigin);

			message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin, 0);
			write_byte(TE_LAVASPLASH);
			write_coord_f(fOrigin[0]);
			write_coord_f(fOrigin[1]);
			write_coord_f(fOrigin[2] - 26.0);
			message_end();
		}

		if (get_pcvar_num(g_pCvar_Assassin_Kill_Explode))
		{
			new Float:fOrigin[3];
			get_entvar(iVictim, var_origin, fOrigin);

			message_begin_f(MSG_PVS, SVC_TEMPENTITY, fOrigin);
			write_byte(TE_BREAKMODEL);
			write_coord_f(fOrigin[0]);
			write_coord_f(fOrigin[1]);
			write_coord_f(fOrigin[2] + 16.0);
			write_coord(32);
			write_coord(32);
			write_coord(32);
			write_coord(0);
			write_coord(0);
			write_coord(25);
			write_byte(get_pcvar_num(g_pCvar_Assassin_Gib_Spread));
			write_short(g_Gib_Model);
			write_byte(get_pcvar_num(g_pCvar_Assassin_Gib_Count));
			write_byte(get_pcvar_num(g_pCvar_Assassin_Gib_Life));
			write_byte(BREAK_FLESH);
			message_end();

			set_entvar(iVictim, var_solid, SOLID_NOT);
			set_entvar(iVictim, var_effects, get_entvar(iVictim, var_effects) | EF_NODRAW);
		}
	}

	if (BIT_VALID(g_iBit_Assassin, iVictim) && get_pcvar_num(g_pCvar_Assassin_Aura))
	{
		// Remove assassin aura
		remove_task(iVictim + TASK_AURA);
	}

	BIT_SUB(g_iBit_Alive, iVictim);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}

// Get alive count -returns alive players number-
Get_Alive_Count()
{
	new iAlive;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Alive, i))
		{
			iAlive++;
		}
	}

	return iAlive;
}

// Get assassin count -returns alive assassin number-
Get_Assassin_Count()
{
	new iAssassin;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Alive, i) && BIT_VALID(g_iBit_Assassin, i))
		{
			iAssassin++;
		}
	}

	return iAssassin;
}