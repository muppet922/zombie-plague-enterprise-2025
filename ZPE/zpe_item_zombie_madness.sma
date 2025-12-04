/* AMX Mod X
*	[ZPE] Item Zombie Madness.
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

#define PLUGIN "item zombie madness"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_items>
#include <zpe_class_zombie>
#include <zpe_grenade_frost>
#include <zpe_grenade_napalm>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>

#define ZPE_CLASS_ZOMBIE_SETTINGS_PATH "ZPE/classes/zombie"

#define ITEM_NAME "Zombie Madness"
#define ITEM_COST 15

#define TASK_MADNESS 100
#define TASK_AURA 200

#define ID_MADNESS (iTask_ID - TASK_MADNESS)
#define ID_AURA (iTask_ID - TASK_AURA)

new const g_Sound_Zombie_Madness[] =
{
	"zombie_plague_enterprise/zombie_sounds/zombie_madness1.wav"
};

new const g_szSound_Section_Name[] = "Sounds";

new Array:g_aSound_Zombie_Madness;

new g_Item_ID;

new g_Zombie_Madness_Block_Damage;

new g_pCvar_Zombie_Madness_Time;

new g_pCvar_Madness_Grenade_Frost;
new g_pCvar_Madness_Grenade_Napalm;

new g_pCvar_Zombie_Madness_Aura_Color_R;
new g_pCvar_Zombie_Madness_Aura_Color_G;
new g_pCvar_Zombie_Madness_Aura_Color_B;

new g_iBit_Alive;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Zombie_Madness_Time = register_cvar("zpe_zombie_madness_time", "5.0");
	
	g_pCvar_Madness_Grenade_Frost = register_cvar("zpe_madness_grenade_frost", "0");
	g_pCvar_Madness_Grenade_Napalm = register_cvar("zpe_madness_grenade_napalm", "0");

	g_pCvar_Zombie_Madness_Aura_Color_R = register_cvar("zpe_zombie_madness_aura_color_r", "150");
	g_pCvar_Zombie_Madness_Aura_Color_G = register_cvar("zpe_zombie_madness_aura_color_g", "0");
	g_pCvar_Zombie_Madness_Aura_Color_B = register_cvar("zpe_zombie_madness_aura_color_b", "0");

	RegisterHookChain(RG_CBasePlayer_TraceAttack, "RG_CBasePlayer_TraceAttack_");
	RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_CBasePlayer_TakeDamage_");
	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);

	g_Item_ID = zpe_items_register(ITEM_NAME, ITEM_COST);
}

public plugin_natives()
{
	register_library("ck_zp50_item_zombie_madness");

	register_native("zp_item_zombie_madness_get", "native_item_zombie_madness_get");
}

public native_item_zombie_madness_get(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "Invalid player (%d)", iPlayer);

		return false;
	}

	return BIT_VALID(g_Zombie_Madness_Block_Damage, iPlayer);
}

public zpe_fw_class_zombie_register_post(iClass_ID)
{
	if (g_aSound_Zombie_Madness == Invalid_Array)
	{
		g_aSound_Zombie_Madness = ArrayCreate(1, 1);
	}

	new szReal_Name[32];
	zpe_class_zombie_get_real_name(iClass_ID, szReal_Name, charsmax(szReal_Name));

	new szClass_Zombie_Settings_Path[64];
	formatex(szClass_Zombie_Settings_Path, charsmax(szClass_Zombie_Settings_Path), "%s/%s.ini", ZPE_CLASS_ZOMBIE_SETTINGS_PATH, szReal_Name);

	new Array:aZombie_Madness_Sound = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(szClass_Zombie_Settings_Path, g_szSound_Section_Name, "MADNESS", aZombie_Madness_Sound);

	new iArray_Size = ArraySize(aZombie_Madness_Sound);

	if (iArray_Size > 0)
	{
		Precache_Sounds(aZombie_Madness_Sound);
	}

	else
	{
		ArrayDestroy(aZombie_Madness_Sound);

		amx_save_setting_string(szClass_Zombie_Settings_Path, g_szSound_Section_Name, "MADNESS", g_Sound_Zombie_Madness);
	}

	ArrayPushCell(g_aSound_Zombie_Madness, aZombie_Madness_Sound);
}

public zpe_fw_items_select_pre(iPlayer, iItem_ID)
{
	// This is not our item
	if (iItem_ID != g_Item_ID)
	{
		return ZPE_ITEM_AVAILABLE;
	}

	// Zombie madness only available to zombies
	if (!zpe_core_is_zombie(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	// Zombie madness not available to nemesis/assassin
	if (zpe_class_nemesis_get(iPlayer) || zpe_class_assassin_get(iPlayer))
	{
		return ZPE_ITEM_DONT_SHOW;
	}

	// Player already has madness
	if (BIT_VALID(g_Zombie_Madness_Block_Damage, iPlayer))
	{
		return ZPE_ITEM_NOT_AVAILABLE;
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

	// Do not take damage
	BIT_ADD(g_Zombie_Madness_Block_Damage, iPlayer);

	// Madness aura
	set_task(0.1, "Madness_Aura", iPlayer + TASK_AURA, _, _, "b");

	// Madness sound
	new Array:aZombie_Madness_Sound = ArrayGetCell(g_aSound_Zombie_Madness, zpe_class_zombie_get_current(iPlayer));

	if (aZombie_Madness_Sound != Invalid_Array)
	{
		new szSound_Path[64];
		ArrayGetString(aZombie_Madness_Sound, RANDOM(ArraySize(aZombie_Madness_Sound)), szSound_Path, charsmax(szSound_Path));

		emit_sound(iPlayer, CHAN_VOICE, szSound_Path, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}

	else
	{
		emit_sound(iPlayer, CHAN_VOICE, g_Sound_Zombie_Madness, 1.0, ATTN_NORM, 0, PITCH_NORM);
	}

	// Set task to remove it
	set_task(get_pcvar_float(g_pCvar_Zombie_Madness_Time), "Remove_Zombie_Madness", iPlayer + TASK_MADNESS);
}

// Remove spawn protection task
public Remove_Zombie_Madness(iTask_ID)
{
	// Remove aura
	remove_task(ID_MADNESS + TASK_AURA);

	// Remove zombie madness
	BIT_SUB(g_Zombie_Madness_Block_Damage, ID_MADNESS);
}

public RG_CBasePlayer_TraceAttack_(iVictim, iAttacker)
{
	// Non-player damage or self damage
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return HC_CONTINUE;
	}

	// Prevent attacks when victim has zombie madness
	if (BIT_VALID(g_Zombie_Madness_Block_Damage, iVictim))
	{
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

// Needed to block explosion damage too
public RG_CBasePlayer_TakeDamage_(iVictim, iInflictor, iAttacker)
{
	// Non-player damage or self damage
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return HC_CONTINUE;
	}

	// Prevent attacks when victim has zombie madness
	if (BIT_VALID(g_Zombie_Madness_Block_Damage, iVictim))
	{
		return HC_SUPERCEDE;
	}

	return HC_CONTINUE;
}

public zpe_fw_grenade_frost_pre(iPlayer)
{
	// Prevent frost when victim has zombie madness
	if (BIT_VALID(g_Zombie_Madness_Block_Damage, iPlayer) && !get_pcvar_num(g_pCvar_Madness_Grenade_Frost))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_grenade_napalm_pre(iPlayer)
{
	// Prevent burning when victim has zombie madness
	if (BIT_VALID(g_Zombie_Madness_Block_Damage, iPlayer) && !get_pcvar_num(g_pCvar_Madness_Grenade_Napalm))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public zpe_fw_core_cure(iPlayer)
{
	// Remove zombie madness task
	remove_task(iPlayer + TASK_MADNESS);
	remove_task(iPlayer + TASK_AURA);

	BIT_SUB(g_Zombie_Madness_Block_Damage, iPlayer);
}

public RG_CSGameRules_PlayerKilled_Post(iVictim)
{
	// Remove zombie madness task
	remove_task(iVictim + TASK_MADNESS);
	remove_task(iVictim + TASK_AURA);

	BIT_SUB(g_Zombie_Madness_Block_Damage, iVictim);
}

// Madness aura task
public Madness_Aura(iTask_ID)
{
	// Get player's origin
	static iOrigin[3];

	get_user_origin(ID_AURA, iOrigin);

	// Colored aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, iOrigin);
	write_byte(TE_DLIGHT); // TE id
	write_coord(iOrigin[0]); // x
	write_coord(iOrigin[1]); // y
	write_coord(iOrigin[2]); // z
	write_byte(20); // radius
	write_byte(get_pcvar_num(g_pCvar_Zombie_Madness_Aura_Color_R)); // r
	write_byte(get_pcvar_num(g_pCvar_Zombie_Madness_Aura_Color_G)); // g
	write_byte(get_pcvar_num(g_pCvar_Zombie_Madness_Aura_Color_B)); // b
	write_byte(2); // life
	write_byte(0); // decay rate
	message_end();
}

public client_disconnected(iPlayer)
{
	// Remove tasks on disconnect
	remove_task(iPlayer + TASK_MADNESS);
	remove_task(iPlayer + TASK_AURA);

	BIT_SUB(g_Zombie_Madness_Block_Damage, iPlayer);

	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	// Remove zombie madness from a previous round
	remove_task(iPlayer + TASK_MADNESS);
	remove_task(iPlayer + TASK_AURA);

	BIT_SUB(g_Zombie_Madness_Block_Damage, iPlayer);

	BIT_ADD(g_iBit_Alive, iPlayer);
}