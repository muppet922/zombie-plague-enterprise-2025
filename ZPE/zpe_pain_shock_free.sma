/* AMX Mod X
*	[ZPE] Pain shock free.
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

#define PLUGIN "pain shock free"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <zpe_kernel>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

new g_pCvar_Pain_Shock_Free_Zombie;
new g_pCvar_Pain_Shock_Free_Human;

new g_pCvar_Pain_Shock_Free_Nemesis;
new g_pCvar_Pain_Shock_Free_Assassin;
new g_pCvar_Pain_Shock_Free_Survivor;
new g_pCvar_Pain_Shock_Free_Sniper;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Pain_Shock_Free_Zombie = register_cvar("zpe_pain_shock_free_zombie", "1"); // 1-all // 2-first only // 3-last only
	g_pCvar_Pain_Shock_Free_Human = register_cvar("zpe_pain_shock_free_human", "0"); // 1-all // 2-last only

	g_pCvar_Pain_Shock_Free_Nemesis = register_cvar("zpe_pain_shock_free_nemesis", "0");
	g_pCvar_Pain_Shock_Free_Assassin = register_cvar("zpe_pain_shock_free_assassin", "0");
	g_pCvar_Pain_Shock_Free_Survivor = register_cvar("zpe_pain_shock_free_survivor", "1");
	g_pCvar_Pain_Shock_Free_Sniper = register_cvar("zpe_pain_shock_free_sniper", "1");

	RegisterHookChain(RG_CBasePlayer_TakeDamage, "RG_CBasePlayer_TakeDamage_Post", 1);
}

public RG_CBasePlayer_TakeDamage_Post(iVictim)
{
	if (zpe_core_is_zombie(iVictim))
	{
		// Nemesis Class loaded?
		if (zpe_class_nemesis_get(iVictim))
		{
			if (!get_pcvar_num(g_pCvar_Pain_Shock_Free_Nemesis))
			{
				return;
			}
		}

		// Assassin Class loaded?
		else if (zpe_class_assassin_get(iVictim))
		{
			if (!get_pcvar_num(g_pCvar_Pain_Shock_Free_Assassin))
			{
				return;
			}
		}

		// Check if zombie should be pain shock free
		else
		{
			// Check if zombie should be pain shock free
			switch (get_pcvar_num(g_pCvar_Pain_Shock_Free_Zombie))
			{
				case 0:
				{
					return;
				}

				case 2:
				{
					if (!zpe_core_is_first_zombie(iVictim))
					{
						return;
					}
				}

				case 3:
				{
					if (!zpe_core_is_last_zombie(iVictim))
					{
						return;
					}
				}
			}
		}
	}

	else
	{
		// Survivor class loaded?
		if (zpe_class_survivor_get(iVictim))
		{
			if (!get_pcvar_num(g_pCvar_Pain_Shock_Free_Survivor))
			{
				return;
			}
		}

		// Sniper Class loaded?
		else if (zpe_class_sniper_get(iVictim))
		{
			if (!get_pcvar_num(g_pCvar_Pain_Shock_Free_Sniper))
			{
				return;
			}
		}

		else
		{
			// Check if human should be pain shock free
			switch (get_pcvar_num(g_pCvar_Pain_Shock_Free_Human))
			{
				case 0:
				{
					return;
				}

				case 2:
				{
					if (!zpe_core_is_last_human(iVictim))
					{
						return;
					}
				}
			}
		}
	}

	// Set pain shock free offset
	set_member(iVictim, m_flVelocityModifier, 1.0); // OFFSET_PAINSHOCK
}