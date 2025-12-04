/* AMX Mod X
*	CS Weapon Restrict API.
*	Author: WiLS. Edition: C&K Corporation.
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

#define PLUGIN "cs weapon restrict api"
#define VERSION "4.2.4.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <hamsandwich>
#include <zpe_kernel>

// Weapon entity names
new const g_Weapon_Entity_Names[][] =
{
	"",
	"weapon_p228",
	"",
	"weapon_scout",
	"weapon_hegrenade",
	"weapon_xm1014",
	"weapon_c4",
	"weapon_mac10",
	"weapon_aug",
	"weapon_smokegrenade",
	"weapon_elite",
	"weapon_fiveseven",
	"weapon_ump45",
	"weapon_sg550",
	"weapon_galil",
	"weapon_famas",
	"weapon_usp",
	"weapon_glock18",
	"weapon_awp",
	"weapon_mp5navy",
	"weapon_m249",
	"weapon_m3",
	"weapon_m4a1",
	"weapon_tmp",
	"weapon_g3sg1",
	"weapon_flashbang",
	"weapon_deagle",
	"weapon_sg552",
	"weapon_ak47",
	"weapon_knife",
	"weapon_p90"
};

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM =
	(1 << CSW_SCOUT)
	| (1 << CSW_XM1014) | (1 << CSW_MAC10) | (1 << CSW_AUG) | (1 << CSW_UMP45) | (1 << CSW_SG550)
	| (1 << CSW_GALIL) | (1 << CSW_FAMAS) | (1 << CSW_AWP) | (1 << CSW_MP5NAVY) | (1 << CSW_M249)
	| (1 << CSW_M3) | (1 << CSW_M4A1) | (1 << CSW_TMP)
	| (1 << CSW_G3SG1) | (1 << CSW_SG552) | (1 << CSW_AK47) | (1 << CSW_P90);

const SECONDARY_WEAPONS_BIT_SUM = (1 << CSW_P228) | (1 << CSW_ELITE) | (1 << CSW_FIVESEVEN) | (1 << CSW_USP) | (1 << CSW_GLOCK18) | (1 << CSW_DEAGLE);
const GRENADES_WEAPONS_BIT_SUM = (1 << CSW_HEGRENADE) | (1 << CSW_FLASHBANG) | (1 << CSW_SMOKEGRENADE);
const OTHER_WEAPONS_BIT_SUM = (1 << CSW_KNIFE) | (1 << CSW_C4);

const ALL_WEAPONS_BIT_SUM = PRIMARY_WEAPONS_BIT_SUM | SECONDARY_WEAPONS_BIT_SUM | GRENADES_WEAPONS_BIT_SUM | OTHER_WEAPONS_BIT_SUM;

new g_Has_Weapon_Restrictions;

new g_Allowed_Weapons_Bitsum[33];
new g_Default_Allowed_Weapon[33];

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	for (new i = 1; i < sizeof g_Weapon_Entity_Names; i++)
	{
		if (g_Weapon_Entity_Names[i][0])
		{
			RegisterHam(Ham_Item_Deploy, g_Weapon_Entity_Names[i], "Ham_Item_Deploy_Post", 1);
		}
	}
}

public plugin_natives()
{
	register_library("ck_cs_weap_restrict_api");

	register_native("cs_set_player_weap_restrict", "native_set_player_weap_restrict");
	register_native("cs_get_player_weap_restrict", "native_get_player_weap_restrict");
}

public native_set_player_weap_restrict(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", iPlayer);

		return false;
	}

	new iSet = get_param(2);

	if (!iSet)
	{
		// Player doesn't have weapon restrictions, no need to reset
		if (BIT_NOT_VALID(g_Has_Weapon_Restrictions, iPlayer))
		{
			return true;
		}

		BIT_SUB(g_Has_Weapon_Restrictions, iPlayer);

		// Re-deploy current weapon, to unlock weapon's firing if we were blocking it
		new iCurrent_Weapon_Entity = CS_GET_CURRENT_WEAPON_ENTITY(iPlayer);

		if (is_entity(iCurrent_Weapon_Entity)) // pev_valid
		{
			ExecuteHamB(Ham_Item_Deploy, iCurrent_Weapon_Entity);
		}

		return true;
	}

	new iAllowed_Bitsum = get_param(3);
	new iAllowed_Default = get_param(4);

	if (!(iAllowed_Bitsum & ALL_WEAPONS_BIT_SUM))
	{
		// Bitsum does not contain any weapons, set allowed default weapon to 0 (0 = no weapon)
		iAllowed_Default = 0;
	}

	else if (!(iAllowed_Bitsum & iAllowed_Default))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Default allowed weapon must be in allowed weapons bitsum");

		return false;
	}

	BIT_ADD(g_Has_Weapon_Restrictions, iPlayer);

	g_Allowed_Weapons_Bitsum[iPlayer] = iAllowed_Bitsum;
	g_Default_Allowed_Weapon[iPlayer] = iAllowed_Default;

	// Update weapon restrictions
	new iCurrent_Weapon_Entity = CS_GET_CURRENT_WEAPON_ENTITY(iPlayer);

	if (is_entity(iCurrent_Weapon_Entity))
	{
		Ham_Item_Deploy_Post(iCurrent_Weapon_Entity);
	}

	return true;
}

public native_get_player_weap_restrict(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", iPlayer);

		return false;
	}

	if (BIT_NOT_VALID(g_Has_Weapon_Restrictions, iPlayer))
	{
		return false;
	}

	set_param_byref(2, g_Allowed_Weapons_Bitsum[iPlayer]);
	set_param_byref(3, g_Default_Allowed_Weapon[iPlayer]);

	return true;
}

public Ham_Item_Deploy_Post(iWeapon_Entity)
{
	// Get weapon's owner
	new iOwner = CS_GET_WEAPON_ENTITY_OWNER(iWeapon_Entity)

	// Owner not valid or does not have any restrictions set
	if (BIT_NOT_VALID(g_iBit_Alive, iOwner) || BIT_NOT_VALID(g_Has_Weapon_Restrictions, iOwner))
	{
		return;
	}

	// Get weapon's player
	new iWeapon_ID = get_member(iWeapon_Entity, m_iId);

	// Owner not holding an allowed weapon
	if (!((1 << iWeapon_ID) & g_Allowed_Weapons_Bitsum[iOwner]))
	{
		new iCurrent_Weapons_Bitsum = get_entvar(iOwner, var_weapons);

		if (iCurrent_Weapons_Bitsum & (1 << g_Default_Allowed_Weapon[iOwner]))
		{
			// Switch to default weapon
			engclient_cmd(iOwner, g_Weapon_Entity_Names[g_Default_Allowed_Weapon[iOwner]]);
		}

		else
		{
			// Otherwise, block weapon firing and hide current weapon
			CS_SET_USER_NEXT_ATTACK(iOwner, 99999.0);

			set_entvar(iOwner, var_viewmodel, "");
			set_entvar(iOwner, var_weaponmodel, "");
		}
	}
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);
}

public client_disconnected(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
	BIT_SUB(g_iBit_Connected, iPlayer);

	BIT_SUB(g_Has_Weapon_Restrictions, iPlayer);
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}