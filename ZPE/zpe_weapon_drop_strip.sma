/* AMX Mod X
*	[ZPE] Weapon Drop Strip.
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

#define PLUGIN "weapon drop strip"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <fakemeta>
#include <hamsandwich>
#include <zpe_kernel>

new g_pCvar_Zombie_Strip_Armor;
new g_pCvar_Remove_Dropped_Weapons;

new g_iBit_Alive;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Zombie_Strip_Armor = register_cvar("zpe_zombie_strip_armor", "1");
	g_pCvar_Remove_Dropped_Weapons = register_cvar("zpe_remove_dropped_weapons", "0");

	RegisterHam(Ham_Touch, "weaponbox", "Ham_Touch_");
	RegisterHam(Ham_Touch, "armoury_entity", "Ham_Touch_");
	RegisterHam(Ham_Touch, "weapon_shield", "Ham_Touch_");

	register_forward(FM_SetModel, "FM_SetModel_");
}

public zpe_fw_core_infect(iPlayer)
{
	rg_remove_all_items(iPlayer); // strip_user_weapons

	rg_give_item(iPlayer, "weapon_knife");

	if (get_pcvar_num(g_pCvar_Zombie_Strip_Armor))
	{
		rg_set_user_armor(iPlayer, 0, ARMOR_NONE);
	}
}

// Forward Set Model
public FM_SetModel_(iEntity, const szModel[])
{
	// We don't care
	if (strlen(szModel) < 8)
	{
		return;
	}

	// Get entity's classname
	new szClassname[10];

	get_entvar(iEntity, var_classname, szClassname, charsmax(szClassname));

	// Check if it's a weapon box
	if (equal(szClassname, "weaponbox"))
	{
		// They get automatically removed when thinking
		set_entvar(iEntity, var_nextthink, get_gametime() + get_pcvar_float(g_pCvar_Remove_Dropped_Weapons));

		return;
	}
}

// Ham Weapon Touch Forward
public Ham_Touch_(iWeapon, iPlayer)
{
	if ((0 < iPlayer <= MaxClients) && BIT_VALID(g_iBit_Alive, iPlayer) && zpe_core_is_zombie(iPlayer))
	{
		return HAM_SUPERCEDE;
	}

	return HAM_IGNORED;
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