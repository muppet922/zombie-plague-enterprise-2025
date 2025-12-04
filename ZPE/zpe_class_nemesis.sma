/* AMX Mod X
*	[ZPE] Class Nemesis.
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

#define PLUGIN "class nemesis"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <ck_cs_maxspeed_api>
#include <ck_cs_weap_models_api>
#include <zpe_kernel>

#define ZPE_SETTINGS_FILE "ZPE/classes/other/zpe_nemesis.ini"

#define TASK_AURA 100
#define ID_AURA (iTask_ID - TASK_AURA)

new Array:g_aModels_Nemesis_Player;
new Array:g_aModels_Nemesis_Claw;

new Array:g_aSound_Nemesis_Die;
new Array:g_aSound_Nemesis_Fall;
new Array:g_aSound_Nemesis_Pain;
new Array:g_aSound_Nemesis_Miss_Slash;
new Array:g_aSound_Nemesis_Hit_Solid;
new Array:g_aSound_Nemesis_Hit_Normal;
new Array:g_aSound_Nemesis_Hit_Stab;

new g_Forward;
new g_Forward_Result;

new g_pCvar_Nemesis_Base_Health;
new g_pCvar_Nemesis_Health_Per_Player;
new g_pCvar_Nemesis_Armor;
new g_pCvar_Nemesis_Armor_Type;
new g_pCvar_Nemesis_Speed;
new g_pCvar_Nemesis_Gravity;

new g_pCvar_Nemesis_Glow;
new g_pCvar_Nemesis_Aura;
new g_pCvar_Nemesis_Aura_Radius;
new g_pCvar_Nemesis_Aura_Color_R;
new g_pCvar_Nemesis_Aura_Color_G;
new g_pCvar_Nemesis_Aura_Color_B;
new g_pCvar_Nemesis_Aura_Life;
new g_pCvar_Nemesis_Aura_Decay_Rate;

new g_pCvar_Nemesis_Kill_Splash;
new g_pCvar_Nemesis_Kill_Explode;
new g_pCvar_Nemesis_Gib_Spread;
new g_pCvar_Nemesis_Gib_Count;
new g_pCvar_Nemesis_Gib_Life;
new g_pCvar_Nemesis_Damage;

new g_pCvar_Nemesis_Grenade_Frost;
new g_pCvar_Nemesis_Grenade_Napalm;

new g_Gib_Model;

new g_iBit_Nemesis;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Nemesis_Base_Health = register_cvar("zpe_nemesis_base_health", "2000.0");
	g_pCvar_Nemesis_Health_Per_Player = register_cvar("zpe_nemesis_health_per_player", "500.0");
	g_pCvar_Nemesis_Armor = register_cvar("zpe_nemesis_armor", "0");
	g_pCvar_Nemesis_Armor_Type = register_cvar("zpe_nemesis_armor_type", "0");
	g_pCvar_Nemesis_Speed = register_cvar("zpe_nemesis_speed", "1.05");
	g_pCvar_Nemesis_Gravity = register_cvar("zpe_nemesis_gravity", "0.5");

	g_pCvar_Nemesis_Glow = register_cvar("zpe_nemesis_glow", "0");
	g_pCvar_Nemesis_Aura = register_cvar("zpe_nemesis_aura", "0");
	g_pCvar_Nemesis_Aura_Radius = register_cvar("zpe_nemesis_aura_radius", "20");
	g_pCvar_Nemesis_Aura_Color_R = register_cvar("zpe_nemesis_aura_color_r", "150");
	g_pCvar_Nemesis_Aura_Color_G = register_cvar("zpe_nemesis_aura_color_g", "0");
	g_pCvar_Nemesis_Aura_Color_B = register_cvar("zpe_nemesis_aura_color_b", "0");
	g_pCvar_Nemesis_Aura_Life = register_cvar("zpe_nemesis_aura_life", "2");
	g_pCvar_Nemesis_Aura_Decay_Rate = register_cvar("zpe_nemesis_aura_decay_rate", "0");

	g_pCvar_Nemesis_Kill_Splash = register_cvar("zpe_nemesis_kill_splash", "0");
	g_pCvar_Nemesis_Kill_Explode = register_cvar("zpe_nemesis_kill_explode", "0");
	g_pCvar_Nemesis_Gib_Spread = register_cvar("zpe_nemesis_gib_spread", "10");
	g_pCvar_Nemesis_Gib_Count = register_cvar("zpe_nemesis_gib_count", "8");
	g_pCvar_Nemesis_Gib_Life = register_cvar("zpe_nemesis_gib_life", "30");
	g_pCvar_Nemesis_Damage = register_cvar("zpe_nemesis_damage", "2.0");

	g_pCvar_Nemesis_Grenade_Frost = register_cvar("zpe_nemesis_grenade_frost", "0");
	g_pCvar_Nemesis_Grenade_Napalm = register_cvar("zpe_nemesis_grenade_napalm", "1");

	g_Forward = CreateMultiForward("zpe_fw_class_nemesis_bit_change", ET_CONTINUE, FP_CELL);

	RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_CBasePlayer_TakeDamage_");

	// Dont use ReAPI, in the form of code - load
	register_forward(FM_EmitSound, "FM_EmitSound_");

	register_forward(FM_ClientDisconnect, "FM_ClientDisconnect_Post", 1);
}

public plugin_precache()
{
	g_aModels_Nemesis_Player = ArrayCreate(PLAYER_MODEL_MAX_LENGTH, 1);
	g_aModels_Nemesis_Claw = ArrayCreate(MODEL_MAX_LENGTH, 1);

	g_aSound_Nemesis_Die = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Nemesis_Fall = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Nemesis_Pain = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Nemesis_Miss_Slash = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Nemesis_Hit_Solid = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Nemesis_Hit_Normal = ArrayCreate(SOUND_MAX_LENGTH, 1);
	g_aSound_Nemesis_Hit_Stab = ArrayCreate(SOUND_MAX_LENGTH, 1);

	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Settings", "PLAYER MODELS", g_aModels_Nemesis_Player);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Settings", "CLAWS MODEL", g_aModels_Nemesis_Claw);

	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "DIE", g_aSound_Nemesis_Die);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "FALL", g_aSound_Nemesis_Fall);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "PAIN", g_aSound_Nemesis_Pain);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "MISS SLASH", g_aSound_Nemesis_Miss_Slash);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "HIT SOLID", g_aSound_Nemesis_Hit_Solid);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "HIT NORMAL", g_aSound_Nemesis_Hit_Normal);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "HIT STAB", g_aSound_Nemesis_Hit_Stab);

	Precache_Player_Models(g_aModels_Nemesis_Player);
	Precache_Models(g_aModels_Nemesis_Claw);

	Precache_Sounds(g_aSound_Nemesis_Die);
	Precache_Sounds(g_aSound_Nemesis_Fall);
	Precache_Sounds(g_aSound_Nemesis_Pain);
	Precache_Sounds(g_aSound_Nemesis_Miss_Slash);
	Precache_Sounds(g_aSound_Nemesis_Hit_Solid);
	Precache_Sounds(g_aSound_Nemesis_Hit_Normal);
	Precache_Sounds(g_aSound_Nemesis_Hit_Stab);

	g_Gib_Model = precache_model("models/hgibs.mdl");
}

public plugin_cfg()
{
	server_cmd("exec addons/amxmodx/configs/ZPE/classes/other/zpe_nemesis.cfg");
}

public plugin_natives()
{
	register_library("zpe_class_nemesis");

	register_native("zpe_class_nemesis_set", "native_class_nemesis_set");
	register_native("zpe_class_nemesis_get_count", "native_class_nemesis_get_count");
}

public RG_CBasePlayer_TakeDamage_(iVictim, iInflictor, iAttacker, Float:fDamage)
{
	// Non-player damage or self damage
	if (!(1 <= iAttacker <= MaxClients) || iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return HC_CONTINUE;
	}

	// Nemesis attacking human
	if (BIT_VALID(g_iBit_Nemesis, iAttacker) && !zpe_core_is_zombie(iVictim))
	{
		// Ignore nemesis damage override if damage comes from a 3rd party entity
		// (to prevent this from affecting a sub-plugin's rockets e.g.)
		if (iInflictor == iAttacker)
		{
			// Set nemesis damage
			SetHookChainArg(4, ATYPE_FLOAT, fDamage * get_pcvar_float(g_pCvar_Nemesis_Damage));
		}
	}

	return HC_CONTINUE;
}

public zpe_fw_grenade_frost_pre(iPlayer)
{
	// Prevent frost for Nemesis
	if (BIT_VALID(g_iBit_Nemesis, iPlayer) && !get_pcvar_num(g_pCvar_Nemesis_Grenade_Frost))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_grenade_napalm_pre(iPlayer)
{
	// Prevent burning for Nemesis
	if (BIT_VALID(g_iBit_Nemesis, iPlayer) && !get_pcvar_num(g_pCvar_Nemesis_Grenade_Napalm))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_core_spawn_post(iPlayer)
{
	if (BIT_VALID(g_iBit_Nemesis, iPlayer))
	{
		// Remove nemesis glow
		if (get_pcvar_num(g_pCvar_Nemesis_Glow))
		{
			rg_set_user_rendering(iPlayer);
		}

		// Remove nemesis aura
		if (get_pcvar_num(g_pCvar_Nemesis_Aura))
		{
			remove_task(iPlayer + TASK_AURA);
		}

		// Remove nemesis flag
		BIT_SUB(g_iBit_Nemesis, iPlayer);

		ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Nemesis);
	}
}

public zpe_fw_core_cure(iPlayer)
{
	if (BIT_VALID(g_iBit_Nemesis, iPlayer))
	{
		// Remove nemesis glow
		if (get_pcvar_num(g_pCvar_Nemesis_Glow))
		{
			rg_set_user_rendering(iPlayer);
		}

		// Remove nemesis aura
		if (get_pcvar_num(g_pCvar_Nemesis_Aura))
		{
			remove_task(iPlayer + TASK_AURA);
		}

		// Remove nemesis flag
		BIT_SUB(g_iBit_Nemesis, iPlayer);

		ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Nemesis);
	}
}

public zpe_fw_core_infect_post(iPlayer)
{
	// Apply Nemesis attributes?
	if (BIT_NOT_VALID(g_iBit_Nemesis, iPlayer))
	{
		return;
	}

	// Health
	SET_USER_HEALTH(iPlayer, get_pcvar_float(g_pCvar_Nemesis_Base_Health) + get_pcvar_float(g_pCvar_Nemesis_Health_Per_Player) * Get_Alive_Count());

	// Armor
	if (get_pcvar_num(g_pCvar_Nemesis_Armor_Type))
	{
		rg_set_user_armor(iPlayer, get_pcvar_num(g_pCvar_Nemesis_Armor), ARMOR_VESTHELM);
	}

	else
	{
		rg_set_user_armor(iPlayer, get_pcvar_num(g_pCvar_Nemesis_Armor), ARMOR_KEVLAR);
	}

	// Gravity
	SET_USER_GRAVITY(iPlayer, get_pcvar_float(g_pCvar_Nemesis_Gravity));

	// Speed
	cs_set_player_maxspeed_auto(iPlayer, get_pcvar_float(g_pCvar_Nemesis_Speed));

	// Apply nemesis player model
	new szModel[PLAYER_MODEL_MAX_LENGTH];
	ArrayGetString(g_aModels_Nemesis_Player, RANDOM(ArraySize(g_aModels_Nemesis_Player)), szModel, charsmax(szModel));
	rg_set_user_model(iPlayer, szModel);

	// Apply nemesis claw model
	new szClaw_Model[MODEL_MAX_LENGTH];
	ArrayGetString(g_aModels_Nemesis_Claw, RANDOM(ArraySize(g_aModels_Nemesis_Claw)), szClaw_Model, charsmax(szClaw_Model));
	cs_set_player_view_model(iPlayer, CSW_KNIFE, szClaw_Model);

	// Nemesis glow
	if (get_pcvar_num(g_pCvar_Nemesis_Glow))
	{
		rg_set_user_rendering(iPlayer, kRenderFxGlowShell, get_pcvar_num(g_pCvar_Nemesis_Aura_Color_R), get_pcvar_num(g_pCvar_Nemesis_Aura_Color_G), get_pcvar_num(g_pCvar_Nemesis_Aura_Color_B), kRenderNormal, 25);
	}

	// Nemesis aura task
	if (get_pcvar_num(g_pCvar_Nemesis_Aura))
	{
		set_task(0.1, "Nemesis_Aura", iPlayer + TASK_AURA, _, _, "b");
	}
}

public native_class_nemesis_set(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	if (BIT_VALID(g_iBit_Nemesis, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Player already a nemesis (%d)", iPlayer);

		return false;
	}

	BIT_ADD(g_iBit_Nemesis, iPlayer);

	ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Nemesis);

	zpe_core_force_infect(iPlayer);

	return true;
}

public native_class_nemesis_get_count(iPlugin_ID, iNum_Params)
{
	return Get_Nemesis_Count();
}

// Nemesis aura task
public Nemesis_Aura(iTask_ID)
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
	write_byte(get_pcvar_num(g_pCvar_Nemesis_Aura_Radius)); // radius
	write_byte(get_pcvar_num(g_pCvar_Nemesis_Aura_Color_R)); // r
	write_byte(get_pcvar_num(g_pCvar_Nemesis_Aura_Color_G)); // g
	write_byte(get_pcvar_num(g_pCvar_Nemesis_Aura_Color_B)); // b
	write_byte(get_pcvar_num(g_pCvar_Nemesis_Aura_Life)); // life
	write_byte(get_pcvar_num(g_pCvar_Nemesis_Aura_Decay_Rate)); // decay rate
	message_end();
}

public FM_EmitSound_(iPlayer, iChannel, szSample[], Float:fVolume, Float:fAttn, iFlags, iPitch)
{
	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer) || !zpe_core_is_zombie(iPlayer))
	{
		return FMRES_IGNORED;
	}

	if (BIT_VALID(g_iBit_Nemesis, iPlayer))
	{
		static szSound[SOUND_MAX_LENGTH];

		if (szSample[7] == 'd' && ((szSample[8] == 'i' && szSample[9] == 'e') || (szSample[8] == 'e' && szSample[9] == 'a')))
		{
			ArrayGetString(g_aSound_Nemesis_Die, RANDOM(ArraySize(g_aSound_Nemesis_Die)), szSound, charsmax(szSound));
			emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

			return FMRES_SUPERCEDE;
		}

		if (szSample[10] == 'f' && szSample[11] == 'a' && szSample[12] == 'l' && szSample[13] == 'l')
		{
			ArrayGetString(g_aSound_Nemesis_Fall, RANDOM(ArraySize(g_aSound_Nemesis_Fall)), szSound, charsmax(szSound));
			emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

			return FMRES_SUPERCEDE;
		}

		if (szSample[7] == 'b' && szSample[8] == 'h' && szSample[9] == 'i' && szSample[10] == 't')
		{
			ArrayGetString(g_aSound_Nemesis_Pain, RANDOM(ArraySize(g_aSound_Nemesis_Pain)), szSound, charsmax(szSound));
			emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

			return FMRES_SUPERCEDE;
		}

		if (szSample[8] == 'k' && szSample[9] == 'n' && szSample[10] == 'i')
		{
			if (szSample[14] == 's' && szSample[15] == 'l' && szSample[16] == 'a')
			{
				ArrayGetString(g_aSound_Nemesis_Miss_Slash, RANDOM(ArraySize(g_aSound_Nemesis_Miss_Slash)), szSound, charsmax(szSound));
				emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

				return FMRES_SUPERCEDE;
			}

			if (szSample[14] == 'h' && szSample[15] == 'i' && szSample[16] == 't')
			{
				if (szSample[18] == 's')
				{
					ArrayGetString(g_aSound_Nemesis_Hit_Solid, RANDOM(ArraySize(g_aSound_Nemesis_Hit_Solid)), szSound, charsmax(szSound));
					emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

					return FMRES_SUPERCEDE;
				}

				else
				{
					ArrayGetString(g_aSound_Nemesis_Hit_Normal, RANDOM(ArraySize(g_aSound_Nemesis_Hit_Normal)), szSound, charsmax(szSound));
					emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

					return FMRES_SUPERCEDE;
				}
			}

			if (szSample[14] == 's' && szSample[15] == 't' && szSample[16] == 'a')
			{
				ArrayGetString(g_aSound_Nemesis_Hit_Stab, RANDOM(ArraySize(g_aSound_Nemesis_Hit_Stab)), szSound, charsmax(szSound));
				emit_sound(iPlayer, iChannel, szSound, fVolume, fAttn, iFlags, iPitch);

				return FMRES_SUPERCEDE;
			}
		}
	}

	return FMRES_IGNORED;
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	if (BIT_VALID(g_iBit_Nemesis, iPlayer))
	{
		// Remove nemesis aura
		if (get_pcvar_num(g_pCvar_Nemesis_Aura))
		{
			remove_task(iPlayer + TASK_AURA);
		}
	}

	BIT_SUB(g_iBit_Alive, iPlayer);
	BIT_SUB(g_iBit_Connected, iPlayer);
}

public FM_ClientDisconnect_Post(iPlayer)
{
	// Reset flags AFTER disconnect (to allow checking if the player was nemesis before disconnecting)
	BIT_SUB(g_iBit_Nemesis, iPlayer);

	ExecuteForward(g_Forward, g_Forward_Result, g_iBit_Nemesis);
}

// This is RG_CSGameRules_PlayerKilled Pre. Simply optimization.
public zpe_fw_kill_pre_bit_sub(iVictim, iAttacker)
{
	// When killed by a nemesis victim explodes
	if (BIT_VALID(g_iBit_Nemesis, iAttacker))
	{
		if (get_pcvar_num(g_pCvar_Nemesis_Kill_Splash))
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

		if (get_pcvar_num(g_pCvar_Nemesis_Kill_Explode))
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
			write_byte(get_pcvar_num(g_pCvar_Nemesis_Gib_Spread));
			write_short(g_Gib_Model);
			write_byte(get_pcvar_num(g_pCvar_Nemesis_Gib_Count));
			write_byte(get_pcvar_num(g_pCvar_Nemesis_Gib_Life));
			write_byte(BREAK_FLESH);
			message_end();

			set_entvar(iVictim, var_solid, SOLID_NOT);
			set_entvar(iVictim, var_effects, get_entvar(iVictim, var_effects) | EF_NODRAW);
		}
	}

	if (BIT_VALID(g_iBit_Nemesis, iVictim) && get_pcvar_num(g_pCvar_Nemesis_Aura))
	{
		// Remove nemesis aura
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

// Get nemesis count -returns alive nemesis number-
Get_Nemesis_Count()
{
	new iNemesis;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (BIT_VALID(g_iBit_Alive, i) && BIT_VALID(g_iBit_Nemesis, i))
		{
			iNemesis++;
		}
	}

	return iNemesis;
}