/* AMX Mod X
*	[ZPE] Human Armor.
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

#define PLUGIN "human armor"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <amx_settings_api>
#include <zpe_kernel>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

#define ZPE_SETTINGS_FILE "ZPE/zpe_settings.ini"

// Some constants
#define DMG_HEGRENADE (1 << 24)

new Array:g_aSound_Hit_Armor;

new g_pCvar_Survivor_Armor_Protect;
new g_pCvar_Sniper_Armor_Protect;
new g_pCvar_Human_Armor_Protect;

new g_pCvar_Nemesis_Armor_Protect;
new g_pCvar_Assassin_Armor_Protect;

new g_iBit_Alive;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Survivor_Armor_Protect = register_cvar("zpe_survivor_armor_protect", "1");
	g_pCvar_Sniper_Armor_Protect = register_cvar("zpe_sniper_armor_protect", "1");
	g_pCvar_Human_Armor_Protect = register_cvar("zpe_human_armor_protect", "1");

	g_pCvar_Nemesis_Armor_Protect = register_cvar("zpe_nemesis_armor_protect", "1");
	g_pCvar_Assassin_Armor_Protect = register_cvar("zpe_assassin_armor_protect", "1");

	RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_CBasePlayer_TakeDamage_");
}

public plugin_precache()
{
	g_aSound_Hit_Armor = ArrayCreate(SOUND_MAX_LENGTH, 1);
	amx_load_setting_string_arr(ZPE_SETTINGS_FILE, "Sounds", "HIT ARMOR", g_aSound_Hit_Armor);
	Precache_Sounds(g_aSound_Hit_Armor);
}

// ReAPI Take Damage Forward
public RG_CBasePlayer_TakeDamage_(iVictim, iInflictor, iAttacker, Float:fDamage, iDamage_Type)
{
	// Non-player damage or self damage
	if (iVictim == iAttacker || BIT_NOT_VALID(g_iBit_Alive, iAttacker))
	{
		return HC_CONTINUE;
	}

	// Zombie attacking human...
	if (zpe_core_is_zombie(iAttacker) && !zpe_core_is_zombie(iVictim))
	{
		// Ignore damage coming from a HE grenade (bugfix)
		if (iDamage_Type & DMG_HEGRENADE)
		{
			return HC_CONTINUE;
		}

		// Does human armor need to be reduced before infecting/damaging?
		if (!get_pcvar_num(g_pCvar_Human_Armor_Protect))
		{
			return HC_CONTINUE;
		}

		// Should armor protect against nemesis attacks?
		if (!get_pcvar_num(g_pCvar_Nemesis_Armor_Protect) && zpe_class_nemesis_get(iAttacker))
		{
			return HC_CONTINUE;
		}

		// Should armor protect against assassin attacks?
		if (!get_pcvar_num(g_pCvar_Assassin_Armor_Protect) && zpe_class_assassin_get(iAttacker))
		{
			return HC_CONTINUE;
		}

		// Should armor protect survivor too?
		if (!get_pcvar_num(g_pCvar_Survivor_Armor_Protect) && zpe_class_survivor_get(iVictim))
		{
			return HC_CONTINUE;
		}

		// Should armor protect sniper too?
		if (!get_pcvar_num(g_pCvar_Sniper_Armor_Protect) && zpe_class_sniper_get(iVictim))
		{
			return HC_CONTINUE;
		}

		// Get victim armor
		static Float:fArmor;
		fArmor = GET_USER_ARMOR(iVictim);

		// If he has some, block damage and reduce armor instead
		if (fArmor > 0.0)
		{
			static szSound[SOUND_MAX_LENGTH];
			ArrayGetString(g_aSound_Hit_Armor, RANDOM(ArraySize(g_aSound_Hit_Armor)), szSound, charsmax(szSound));
			emit_sound(iVictim, CHAN_BODY, szSound, 1.0, ATTN_NORM, 0, PITCH_NORM);

			if (fArmor - fDamage > 0.0)
			{
				SET_USER_ARMOR(iVictim, fArmor - fDamage);
			}

			else
			{
				rg_set_user_armor(iVictim, 0, ARMOR_NONE);
			}

			// Block damage, but still set the pain shock offset
			set_member(iVictim, m_flVelocityModifier, 0.5); // OFFSET_PAINSHOCK

			return HC_SUPERCEDE;
		}
	}

	return HC_CONTINUE;
}

public client_disconnected(iPlayer)
{
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