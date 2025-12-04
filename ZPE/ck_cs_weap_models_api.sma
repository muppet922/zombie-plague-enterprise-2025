/* AMX Mod X
*	CS Weapon Models API.
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

#define PLUGIN "cs weapon models api"
#define VERSION "3.2.5.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <hamsandwich>

#define CSW_FIRST_WEAPON CSW_P228
#define CSW_LAST_WEAPON CSW_P90
#define POSITION_NULL -1

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

new g_Custom_View_Models_Position[33][CSW_LAST_WEAPON + 1];
new g_Custom_Weapon_Models_Position[33][CSW_LAST_WEAPON + 1];

new Array:g_aCustom_View_Models_Names;
new Array:g_aCustom_Weapon_Models_Names;

new g_Custom_View_Models_Count;
new g_Custom_Weapon_Models_Count;

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

	// Initialize dynamic arrays
	g_aCustom_View_Models_Names = ArrayCreate(128, 1);
	g_aCustom_Weapon_Models_Names = ArrayCreate(128, 1);

	// Initialize array positions
	new szWeapon_ID;

	for (new i = 1; i <= MaxClients; i++)
	{
		for (szWeapon_ID = CSW_FIRST_WEAPON; szWeapon_ID <= CSW_LAST_WEAPON; szWeapon_ID++)
		{
			g_Custom_View_Models_Position[i][szWeapon_ID] = POSITION_NULL;

			g_Custom_Weapon_Models_Position[i][szWeapon_ID] = POSITION_NULL;
		}
	}
}

public plugin_natives()
{
	register_library("ck_cs_weap_models_api");

	register_native("cs_set_player_view_model", "native_set_player_view_model");
	register_native("cs_reset_player_view_model", "native_reset_player_view_model");
	register_native("cs_set_player_weap_model", "native_set_player_weapon_model");
	register_native("cs_reset_player_weap_model", "native_reset_player_weap_model");
}

public native_set_player_view_model(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1)

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", iPlayer);

		return false;
	}

	new szWeapon_ID = get_param(2);

	if (szWeapon_ID < CSW_FIRST_WEAPON || szWeapon_ID > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon player (%d)", szWeapon_ID);

		return false;
	}

	new szView_Model[128];

	get_string(3, szView_Model, charsmax(szView_Model));

	// Check whether player already has a custom view model set
	if (g_Custom_View_Models_Position[iPlayer][szWeapon_ID] == POSITION_NULL)
	{
		Add_Custom_View_Model(iPlayer, szWeapon_ID, szView_Model);
	}

	else
	{
		Replace_Custom_View_Model(iPlayer, szWeapon_ID, szView_Model);
	}

	// Get current weapon's player
	new iCurrent_Weapon_Entity = CS_GET_CURRENT_WEAPON_ENTITY(iPlayer);
	new iCurrent_Weapon_ID = is_entity(iCurrent_Weapon_Entity) ? get_member(iCurrent_Weapon_Entity, m_iId) : -1;

	// Model was set for the current weapon?
	if (szWeapon_ID == iCurrent_Weapon_ID)
	{
		// Update weapon models manually
		Ham_Item_Deploy_Post(iCurrent_Weapon_Entity);
	}

	return true;
}

public native_reset_player_view_model(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", iPlayer);

		return false;
	}

	new szWeapon_ID = get_param(2);

	if (szWeapon_ID < CSW_FIRST_WEAPON || szWeapon_ID > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon player (%d)", szWeapon_ID);

		return false;
	}

	// Player doesn't have a custom view model, no need to reset
	if (g_Custom_View_Models_Position[iPlayer][szWeapon_ID] == POSITION_NULL)
	{
		return true;
	}

	Remove_Custom_View_Model(iPlayer, szWeapon_ID);

	// Get current weapon's player
	new iCurrent_Weapon_Entity = CS_GET_CURRENT_WEAPON_ENTITY(iPlayer);
	new iCurrent_Weapon_ID = is_entity(iCurrent_Weapon_Entity) ? get_member(iCurrent_Weapon_Entity, m_iId) : -1;

	// Model was reset for the current weapon?
	if (szWeapon_ID == iCurrent_Weapon_ID)
	{
		// Let CS update weapon models
		ExecuteHamB(Ham_Item_Deploy, iCurrent_Weapon_Entity);
	}

	return true;
}

public native_set_player_weapon_model(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", iPlayer);

		return false;
	}

	new szWeapon_ID = get_param(2);

	if (szWeapon_ID < CSW_FIRST_WEAPON || szWeapon_ID > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon player (%d)", szWeapon_ID);

		return false;
	}

	new szWeapon_Model[128];

	get_string(3, szWeapon_Model, charsmax(szWeapon_Model));

	// Check whether player already has a custom view model set
	if (g_Custom_Weapon_Models_Position[iPlayer][szWeapon_ID] == POSITION_NULL)
	{
		Add_Custom_Weapon_Model(iPlayer, szWeapon_ID, szWeapon_Model);
	}

	else
	{
		Replace_Custom_Weapon_Model(iPlayer, szWeapon_ID, szWeapon_Model);
	}

	// Get current weapon's player
	new iCurrent_Weapon_Entity = CS_GET_CURRENT_WEAPON_ENTITY(iPlayer);
	new iCurrent_Weapon_ID = is_entity(iCurrent_Weapon_Entity) ? get_member(iCurrent_Weapon_Entity, m_iId) : -1;

	// Model was reset for the current weapon?
	if (szWeapon_ID == iCurrent_Weapon_ID)
	{
		// Update weapon models manually
		Ham_Item_Deploy_Post(iCurrent_Weapon_Entity);
	}

	return true;
}

public native_reset_player_weap_model(iPlugin_ID, iNum_Params)
{
	new iPlayer = get_param(1);

	if (BIT_NOT_VALID(g_iBit_Connected, iPlayer))
	{
		log_error(AMX_ERR_NATIVE, "[CS] Player is not in game (%d)", iPlayer);

		return false;
	}

	new szWeapon_ID = get_param(2);

	if (szWeapon_ID < CSW_FIRST_WEAPON || szWeapon_ID > CSW_LAST_WEAPON)
	{
		log_error(AMX_ERR_NATIVE, "[CS] Invalid weapon player (%d)", szWeapon_ID);

		return false;
	}

	// Player doesn't have a custom weapon model, no need to reset
	if (g_Custom_Weapon_Models_Position[iPlayer][szWeapon_ID] == POSITION_NULL)
	{
		return true;
	}

	Remove_Custom_Weapon_Model(iPlayer, szWeapon_ID);

	// Get current weapon's player
	new iCurrent_Weapon_Entity = CS_GET_CURRENT_WEAPON_ENTITY(iPlayer);
	new iCurrent_Weapon_ID = is_entity(iCurrent_Weapon_Entity) ? get_member(iCurrent_Weapon_Entity, m_iId) : -1;

	// Model was reset for the current weapon?
	if (szWeapon_ID == iCurrent_Weapon_ID)
	{
		// Let CS update weapon models
		ExecuteHamB(Ham_Item_Deploy, iCurrent_Weapon_Entity);
	}

	return true;
}

Add_Custom_View_Model(iPlayer, szWeapon_ID, const szView_Model[])
{
	g_Custom_View_Models_Position[iPlayer][szWeapon_ID] = g_Custom_View_Models_Count;

	ArrayPushString(g_aCustom_View_Models_Names, szView_Model);

	g_Custom_View_Models_Count++;
}

Replace_Custom_View_Model(iPlayer, szWeapon_ID, const szView_Model[])
{
	ArraySetString(g_aCustom_View_Models_Names, g_Custom_View_Models_Position[iPlayer][szWeapon_ID], szView_Model);
}

Remove_Custom_View_Model(iPlayer, szWeapon_ID)
{
	new iPosition_Delete = g_Custom_View_Models_Position[iPlayer][szWeapon_ID];

	ArrayDeleteItem(g_aCustom_View_Models_Names, iPosition_Delete);

	g_Custom_View_Models_Position[iPlayer][szWeapon_ID] = POSITION_NULL;
	g_Custom_View_Models_Count--;

	// Fix view models array positions
	for (new i = 1; i <= MaxClients; i++)
	{
		for (szWeapon_ID = CSW_FIRST_WEAPON; szWeapon_ID <= CSW_LAST_WEAPON; szWeapon_ID++)
		{
			if (g_Custom_View_Models_Position[i][szWeapon_ID] > iPosition_Delete)
			{
				g_Custom_View_Models_Position[i][szWeapon_ID]--;
			}
		}
	}
}

Add_Custom_Weapon_Model(iPlayer, szWeapon_ID, const szWeapon_Model[])
{
	ArrayPushString(g_aCustom_Weapon_Models_Names, szWeapon_Model);

	g_Custom_Weapon_Models_Position[iPlayer][szWeapon_ID] = g_Custom_Weapon_Models_Count;

	g_Custom_Weapon_Models_Count++;
}

Replace_Custom_Weapon_Model(iPlayer, szWeapon_ID, const szWeapon_Model[])
{
	ArraySetString(g_aCustom_Weapon_Models_Names, g_Custom_Weapon_Models_Position[iPlayer][szWeapon_ID], szWeapon_Model);
}

Remove_Custom_Weapon_Model(iPlayer, szWeapon_ID)
{
	new iPosition_Delete = g_Custom_Weapon_Models_Position[iPlayer][szWeapon_ID];

	ArrayDeleteItem(g_aCustom_Weapon_Models_Names, iPosition_Delete);

	g_Custom_Weapon_Models_Position[iPlayer][szWeapon_ID] = POSITION_NULL;
	g_Custom_Weapon_Models_Count--;

	// Fix weapon models array positions
	for (new i = 1; i <= MaxClients; i++)
	{
		for (szWeapon_ID = CSW_FIRST_WEAPON; szWeapon_ID <= CSW_LAST_WEAPON; szWeapon_ID++)
		{
			if (g_Custom_Weapon_Models_Position[i][szWeapon_ID] > iPosition_Delete)
			{
				g_Custom_Weapon_Models_Position[i][szWeapon_ID]--;
			}
		}
	}
}

public Ham_Item_Deploy_Post(iEntity)
{
	// Get weapon's owner
	new iOwner = CS_GET_WEAPON_ENTITY_OWNER(iEntity);

	// Owner not valid
	if (BIT_NOT_VALID(g_iBit_Alive, iOwner))
	{
		return;
	}

	// Get weapon's player
	new szWeapon_ID = get_member(iEntity, m_iId);

	// Custom view model?
	if (g_Custom_View_Models_Position[iOwner][szWeapon_ID] != POSITION_NULL)
	{
		new szView_Model[128];

		ArrayGetString(g_aCustom_View_Models_Names, g_Custom_View_Models_Position[iOwner][szWeapon_ID], szView_Model, charsmax(szView_Model));

		set_entvar(iOwner, var_viewmodel, szView_Model);
	}

	// Custom weapon model?
	if (g_Custom_Weapon_Models_Position[iOwner][szWeapon_ID] != POSITION_NULL)
	{
		new szWeapon_Model[128];

		ArrayGetString(g_aCustom_Weapon_Models_Names, g_Custom_Weapon_Models_Position[iOwner][szWeapon_ID], szWeapon_Model, charsmax(szWeapon_Model));

		set_entvar(iOwner, var_weaponmodel, szWeapon_Model);
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

	// Remove custom models for player after disconnecting
	for (new i = CSW_FIRST_WEAPON; i <= CSW_LAST_WEAPON; i++)
	{
		if (g_Custom_View_Models_Position[iPlayer][i] != POSITION_NULL)
		{
			Remove_Custom_View_Model(iPlayer, i);
		}

		if (g_Custom_Weapon_Models_Position[iPlayer][i] != POSITION_NULL)
		{
			Remove_Custom_Weapon_Model(iPlayer, i);
		}
	}
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}