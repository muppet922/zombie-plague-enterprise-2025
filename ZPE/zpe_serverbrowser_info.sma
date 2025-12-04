/* AMX Mod X
*	[ZPE] Serverbrowser info.
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

#define PLUGIN "serverbrowser info"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <fakemeta>
#include <zpe_kernel>

new g_Mode_Name[64];

new g_pCvar_Mode_Name;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Mode_Name = register_cvar("zpe_mode_name", "");

	register_forward(FM_GetGameDescription, "FM_GetGameDescription_");

	new szMode_Name[32];

	get_pcvar_string(g_pCvar_Mode_Name, szMode_Name, charsmax(szMode_Name));

	formatex(g_Mode_Name, charsmax(g_Mode_Name), szMode_Name);
}

// Forward Get Game Description
public FM_GetGameDescription_()
{
	// Return the mod name so it can be easily identified
	forward_return(FMV_STRING, g_Mode_Name);

	return FMRES_SUPERCEDE;
}