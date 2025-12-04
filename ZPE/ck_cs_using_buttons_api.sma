/* AMX Mod X
*	CS Using buttons API.
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

#define PLUGIN "cs using buttons api"
#define VERSION "2.1.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>

enum TOTAL_FORWARDS
{
	FW_USER_PRETHINK_PRE
};

new g_Forward_Result;
new g_Forwards[TOTAL_FORWARDS];

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	RegisterHookChain(RG_CBasePlayer_PreThink, "RG_CBasePlayer_PreThink_Pre");

	g_Forwards[FW_USER_PRETHINK_PRE] = CreateMultiForward("fw_button_changed", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL);
}

public RG_CBasePlayer_PreThink_Pre(iPlayer)
{
	static iButton;
	static iOld_Button;

	iButton = get_entvar(iPlayer, var_button);
	iOld_Button = get_entvar(iPlayer, var_oldbuttons);

	if (iButton != iOld_Button)
	{
		ExecuteForward(g_Forwards[FW_USER_PRETHINK_PRE], g_Forward_Result, iPlayer, iButton & ~iOld_Button, ~iButton & iOld_Button);
	}
}