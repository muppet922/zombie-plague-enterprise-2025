/* AMX Mod X
*	[ZPE] Human Ammo.
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

#define PLUGIN "human ammo"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <hamsandwich>
#include <zpe_kernel>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

// Weapon id for ammo types
new const any:g_Ammo_Weapon[] =
{
	0,
	WEAPON_AWP,
	WEAPON_SCOUT,
	WEAPON_M249,
	WEAPON_AUG,
	WEAPON_XM1014,
	WEAPON_MAC10,
	WEAPON_FIVESEVEN,
	WEAPON_DEAGLE,
	WEAPON_P228,
	WEAPON_ELITE,
	WEAPON_FLASHBANG,
	WEAPON_HEGRENADE,
	WEAPON_SMOKEGRENADE,
	WEAPON_C4
};

new g_Message_Ammo_Pickup;

new g_pCvar_Human_Unlimited_Ammo;
new g_pCvar_Survivor_Unlimited_Ammo;
new g_pCvar_Sniper_Unlimited_Ammo;

new g_iBit_Alive;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Human_Unlimited_Ammo = register_cvar("zpe_human_unlimited_ammo", "0"); // 1-bp ammo // 2-clip ammo

	g_pCvar_Survivor_Unlimited_Ammo = register_cvar("zpe_survivor_unlimited_ammo", "1"); // 1-bp ammo // 2-clip ammo
	g_pCvar_Sniper_Unlimited_Ammo = register_cvar("zpe_sniper_unlimited_ammo", "1"); // 1-bp ammo // 2-clip ammo

	register_event("AmmoX", "Event_Ammo_X", "be");

	register_message(get_user_msgid("CurWeapon"), "Message_Cur_Weapon");

	g_Message_Ammo_Pickup = get_user_msgid("AmmoPickup");
}

// BP Ammo update
public Event_Ammo_X(iPlayer)
{
	// Not alive or not human
	if (BIT_NOT_VALID(g_iBit_Alive, iPlayer) || zpe_core_is_zombie(iPlayer))
	{
		return;
	}

	// Survivor Class loaded?
	if (zpe_class_survivor_get(iPlayer))
	{
		// Unlimited BP ammo enabled for survivor?
		if (get_pcvar_num(g_pCvar_Survivor_Unlimited_Ammo) != 1)
		{
			return;
		}
	}

	// Sniper Class loaded?
	else if (zpe_class_sniper_get(iPlayer))
	{
		// Unlimited BP ammo enabled for sniper?
		if (get_pcvar_num(g_pCvar_Sniper_Unlimited_Ammo) != 1)
		{
			return;
		}
	}

	else
	{
		// Unlimited BP ammo enabled for humans?
		if (get_pcvar_num(g_pCvar_Human_Unlimited_Ammo) != 1)
		{
			return;
		}
	}

	// Get ammo type
	new iType = read_data(1);

	// Unknown ammo type
	if (iType >= sizeof g_Ammo_Weapon)
	{
		return;
	}

	new iWeapon = g_Ammo_Weapon[iType];

	// Primary and secondary only
	if (!IS_GUN(iWeapon))
	{
		return;
	}

	// Get ammo amount
	new iAmount = read_data(2);
	new iMax_BP_Ammo = rg_get_weapon_info(iWeapon, WI_MAX_ROUNDS);

	// Unlimited BP Ammo
	if (iAmount < iMax_BP_Ammo)
	{
		new iBlock_Status = get_msg_block(g_Message_Ammo_Pickup);
		set_msg_block(g_Message_Ammo_Pickup, BLOCK_ONCE);

		new szAmmo_Name[AMMO_NAME_MAX_LENGTH];
		rg_get_weapon_info(iWeapon, WI_AMMO_NAME, szAmmo_Name, charsmax(szAmmo_Name));

		// szAmmo_Name[5] to skip "ammo_" prefix
		ExecuteHamB(Ham_GiveAmmo, iPlayer, iMax_BP_Ammo, szAmmo_Name[5], iMax_BP_Ammo);

		set_msg_block(g_Message_Ammo_Pickup, iBlock_Status);
	}
}

// Current Weapon info
public Message_Cur_Weapon(iMessage_ID, iMessage_Dest, iMessage_Entity)
{
	// Not alive or not human
	if (BIT_NOT_VALID(g_iBit_Alive, iMessage_Entity) || zpe_core_is_zombie(iMessage_Entity))
	{
		return;
	}

	// Survivor Class loaded?
	if (zpe_class_survivor_get(iMessage_Entity))
	{
		// Unlimited Clip ammo enabled for humans?
		if (get_pcvar_num(g_pCvar_Survivor_Unlimited_Ammo) != 2)
		{
			return;
		}
	}

	// Sniper Class loaded?
	else if (zpe_class_sniper_get(iMessage_Entity))
	{
		// Unlimited Clip ammo enabled for humans?
		if (get_pcvar_num(g_pCvar_Sniper_Unlimited_Ammo) != 2)
		{
			return;
		}
	}

	else
	{
		// Unlimited Clip ammo enabled for humans?
		if (get_pcvar_num(g_pCvar_Human_Unlimited_Ammo) != 2)
		{
			return;
		}
	}

	// Not an active weapon
	if (get_msg_arg_int(1) != 1)
	{
		return;
	}

	new iWeapon = get_msg_arg_int(2);

	// Primary and secondary only
	if (!IS_GUN(iWeapon))
	{
		return;
	}

	// Max out clip ammo
	new iWeapon_Entity = CS_GET_CURRENT_WEAPON_ENTITY(iMessage_Entity);
	new iMax_Clip = rg_get_weapon_info(iWeapon, WI_GUN_CLIP_SIZE);

	if (is_entity(iWeapon_Entity)) // pev_valid
	{
		CS_SET_WEAPON_AMMO(iWeapon_Entity, iMax_Clip);
	}

	// HUD should show full clip all the time
	set_msg_arg_int(3, get_msg_argtype(3), iMax_Clip);
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