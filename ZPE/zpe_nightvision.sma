/* AMX Mod X
*	[ZPE] Night Vision.
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

#define PLUGIN "night vision"
#define VERSION "6.0.0"
#define AUTHOR "C&K Corporation"

#include <amxmodx>
#include <cs_util>
#include <cstrike>
#include <zpe_kernel>
#include <zpe_class_nemesis>
#include <zpe_class_assassin>
#include <zpe_class_survivor>
#include <zpe_class_sniper>

#define TASK_NIGHT_VISION 100
#define ID_NIGHT_VISION (iTask_ID - TASK_NIGHT_VISION)

new g_Night_Vision_Active;

new g_Message_NVG_Toggle;

new g_pCvar_Night_Vision_Custom;

new g_pCvar_Night_Vision_Zombie;
new g_pCvar_Night_Vision_Zombie_Radius;
new g_pCvar_Night_Vision_Zombie_Color_R;
new g_pCvar_Night_Vision_Zombie_Color_G;
new g_pCvar_Night_Vision_Zombie_Color_B;

new g_pCvar_Night_Vision_Human;
new g_pCvar_Night_Vision_Human_Radius;
new g_pCvar_Night_Vision_Human_Color_R;
new g_pCvar_Night_Vision_Human_Color_G;
new g_pCvar_Night_Vision_Human_Color_B;

new g_pCvar_Night_Vision_Spectator;
new g_pCvar_Night_Vision_Spectator_Radius;
new g_pCvar_Night_Vision_Spectator_Color_R;
new g_pCvar_Night_Vision_Spectator_Color_G;
new g_pCvar_Night_Vision_Spectator_Color_B;

new g_pCvar_Night_Vision_Nemesis;
new g_pCvar_Night_Vision_Nemesis_Radius;
new g_pCvar_Night_Vision_Nemesis_Color_R;
new g_pCvar_Night_Vision_Nemesis_Color_G;
new g_pCvar_Night_Vision_Nemesis_Color_B;

new g_pCvar_Night_Vision_Assassin;
new g_pCvar_Night_Vision_Assassin_Radius;
new g_pCvar_Night_Vision_Assassin_Color_R;
new g_pCvar_Night_Vision_Assassin_Color_G;
new g_pCvar_Night_Vision_Assassin_Color_B;

new g_pCvar_Night_Vision_Survivor;
new g_pCvar_Night_Vision_Survivor_Radius;
new g_pCvar_Night_Vision_Survivor_Color_R;
new g_pCvar_Night_Vision_Survivor_Color_G;
new g_pCvar_Night_Vision_Survivor_Color_B;

new g_pCvar_Night_Vision_Sniper;
new g_pCvar_Night_Vision_Sniper_Radius;
new g_pCvar_Night_Vision_Sniper_Color_R;
new g_pCvar_Night_Vision_Sniper_Color_G;
new g_pCvar_Night_Vision_Sniper_Color_B;

new g_iBit_Alive;
new g_iBit_Connected;

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);

	g_pCvar_Night_Vision_Custom = register_cvar("zpe_night_vision_custom", "0");

	g_pCvar_Night_Vision_Zombie = register_cvar("zpe_night_vision_zombie", "2"); // 1-give only // 2-give and enable
	g_pCvar_Night_Vision_Zombie_Radius = register_cvar("zpe_night_vision_zombie_radius", "80");
	g_pCvar_Night_Vision_Zombie_Color_R = register_cvar("zpe_night_vision_zombie_color_r", "0");
	g_pCvar_Night_Vision_Zombie_Color_G = register_cvar("zpe_night_vision_zombie_color_g", "150");
	g_pCvar_Night_Vision_Zombie_Color_B = register_cvar("zpe_night_vision_zombie_color_b", "0");

	g_pCvar_Night_Vision_Human = register_cvar("zpe_night_vision_human", "0"); // 1-give only // 2-give and enable
	g_pCvar_Night_Vision_Human_Radius = register_cvar("zpe_night_vision_human_radius", "80");
	g_pCvar_Night_Vision_Human_Color_R = register_cvar("zpe_night_vision_human_color_r", "0");
	g_pCvar_Night_Vision_Human_Color_G = register_cvar("zpe_night_vision_human_color_g", "150");
	g_pCvar_Night_Vision_Human_Color_B = register_cvar("zpe_night_vision_human_color_b", "0");

	g_pCvar_Night_Vision_Spectator = register_cvar("zpe_night_vision_spectator", "2"); // 1-give only // 2-give and enable
	g_pCvar_Night_Vision_Spectator_Radius = register_cvar("zpe_night_vision_spectator_radius", "80");
	g_pCvar_Night_Vision_Spectator_Color_R = register_cvar("zpe_night_vision_spectator_color_r", "0");
	g_pCvar_Night_Vision_Spectator_Color_G = register_cvar("zpe_night_vision_spectator_color_g", "150");
	g_pCvar_Night_Vision_Spectator_Color_B = register_cvar("zpe_night_vision_spectator_color_b", "0");

	g_pCvar_Night_Vision_Nemesis = register_cvar("zpe_night_vision_nemesis", "2"); // 1-give only // 2-give and enable
	g_pCvar_Night_Vision_Nemesis_Radius = register_cvar("zpe_night_vision_nemesis_radius", "80");
	g_pCvar_Night_Vision_Nemesis_Color_R = register_cvar("zpe_night_vision_nemesis_color_r", "150");
	g_pCvar_Night_Vision_Nemesis_Color_G = register_cvar("zpe_night_vision_nemesis_color_g", "0");
	g_pCvar_Night_Vision_Nemesis_Color_B = register_cvar("zpe_night_vision_nemesis_color_b", "0");

	g_pCvar_Night_Vision_Assassin = register_cvar("zpe_night_vision_assassin", "2"); // 1-give only // 2-give and enable
	g_pCvar_Night_Vision_Assassin_Radius = register_cvar("zpe_night_vision_assassin_radius", "80");
	g_pCvar_Night_Vision_Assassin_Color_R = register_cvar("zpe_night_vision_assassin_color_r", "150");
	g_pCvar_Night_Vision_Assassin_Color_G = register_cvar("zpe_night_vision_assassin_color_g", "0");
	g_pCvar_Night_Vision_Assassin_Color_B = register_cvar("zpe_night_vision_assassin_color_b", "0");

	g_pCvar_Night_Vision_Survivor = register_cvar("zpe_night_vision_survivor", "0"); // 1-give only // 2-give and enable
	g_pCvar_Night_Vision_Survivor_Radius = register_cvar("zpe_night_vision_survivor_radius", "80");
	g_pCvar_Night_Vision_Survivor_Color_R = register_cvar("zpe_night_vision_survivor_color_r", "0");
	g_pCvar_Night_Vision_Survivor_Color_G = register_cvar("zpe_night_vision_survivor_color_g", "0");
	g_pCvar_Night_Vision_Survivor_Color_B = register_cvar("zpe_night_vision_survivor_color_b", "150");

	g_pCvar_Night_Vision_Sniper = register_cvar("zpe_night_vision_sniper", "0"); // 1-give only // 2-give and enable
	g_pCvar_Night_Vision_Sniper_Radius = register_cvar("zpe_night_vision_sniper_radius", "80");
	g_pCvar_Night_Vision_Sniper_Color_R = register_cvar("zpe_night_vision_sniper_color_r", "0");
	g_pCvar_Night_Vision_Sniper_Color_G = register_cvar("zpe_night_vision_sniper_color_g", "0");
	g_pCvar_Night_Vision_Sniper_Color_B = register_cvar("zpe_night_vision_sniper_color_b", "150");

	g_Message_NVG_Toggle = get_user_msgid("NVGToggle");

	register_message(g_Message_NVG_Toggle, "Message_NVG_Toggle");

	register_clcmd("nightvision", "Client_Command_Night_Vision");

	register_event("ResetHUD", "Event_Reset_Hud", "b");

	RegisterHookChain(RG_CSGameRules_PlayerKilled, "RG_CSGameRules_PlayerKilled_Post", 1);
}

public RG_CSGameRules_PlayerKilled_Post(iPlayer)
{
	Spectator_Night_Vision(iPlayer);
}

public client_putinserver(iPlayer)
{
	BIT_ADD(g_iBit_Connected, iPlayer);

	set_task(0.1, "Spectator_Night_Vision", iPlayer);
}

public zpe_fw_core_infect_post(iPlayer)
{
	// Nemesis Class loaded?
	if (zpe_class_nemesis_get(iPlayer))
	{
		if (get_pcvar_num(g_pCvar_Night_Vision_Nemesis))
		{
			if (!cs_get_user_nvg(iPlayer))
			{
				cs_set_user_nvg(iPlayer, 1);
			}

			if (get_pcvar_num(g_pCvar_Night_Vision_Nemesis) == 2)
			{
				if (BIT_NOT_VALID(g_Night_Vision_Active, iPlayer))
				{
					Client_Command_Night_Vision(iPlayer);
				}
			}

			else if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Client_Command_Night_Vision(iPlayer);
			}
		}

		else
		{
			cs_set_user_nvg(iPlayer, 0);

			if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Disable_Night_Vision(iPlayer);
			}
		}
	}

	// Assassin Class loaded?
	else if (zpe_class_assassin_get(iPlayer))
	{
		if (get_pcvar_num(g_pCvar_Night_Vision_Assassin))
		{
			if (!cs_get_user_nvg(iPlayer))
			{
				cs_set_user_nvg(iPlayer, 1);
			}

			if (get_pcvar_num(g_pCvar_Night_Vision_Assassin) == 2)
			{
				if (BIT_NOT_VALID(g_Night_Vision_Active, iPlayer))
				{
					Client_Command_Night_Vision(iPlayer);
				}
			}

			else if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Client_Command_Night_Vision(iPlayer);
			}
		}

		else
		{
			cs_set_user_nvg(iPlayer, 0);

			if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Disable_Night_Vision(iPlayer);
			}
		}
	}

	else
	{
		if (get_pcvar_num(g_pCvar_Night_Vision_Zombie))
		{
			if (!cs_get_user_nvg(iPlayer))
			{
				cs_set_user_nvg(iPlayer, 1);
			}

			if (get_pcvar_num(g_pCvar_Night_Vision_Zombie) == 2)
			{
				if (BIT_NOT_VALID(g_Night_Vision_Active, iPlayer))
				{
					Client_Command_Night_Vision(iPlayer);
				}
			}

			else if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Client_Command_Night_Vision(iPlayer);
			}
		}

		else
		{
			cs_set_user_nvg(iPlayer, 0);

			if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Disable_Night_Vision(iPlayer);
			}
		}
	}
}

public zpe_fw_core_cure_post(iPlayer)
{
	// Survivor Class loaded?
	if (zpe_class_survivor_get(iPlayer))
	{
		if (get_pcvar_num(g_pCvar_Night_Vision_Survivor))
		{
			if (!cs_get_user_nvg(iPlayer))
			{
				cs_set_user_nvg(iPlayer, 1);
			}

			if (get_pcvar_num(g_pCvar_Night_Vision_Survivor) == 2)
			{
				if (BIT_NOT_VALID(g_Night_Vision_Active, iPlayer))
				{
					Client_Command_Night_Vision(iPlayer);
				}
			}

			else if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Client_Command_Night_Vision(iPlayer);
			}

			else
			{
				cs_set_user_nvg(iPlayer, 0);

				if (BIT_VALID(g_Night_Vision_Active, iPlayer))
				{
					Disable_Night_Vision(iPlayer);
				}
			}
		}
	}

	// Sniper Class loaded?
	else if (zpe_class_sniper_get(iPlayer))
	{
		if (get_pcvar_num(g_pCvar_Night_Vision_Sniper))
		{
			if (!cs_get_user_nvg(iPlayer))
			{
				cs_set_user_nvg(iPlayer, 1);
			}

			if (get_pcvar_num(g_pCvar_Night_Vision_Sniper) == 2)
			{
				if (BIT_NOT_VALID(g_Night_Vision_Active, iPlayer))
				{
					Client_Command_Night_Vision(iPlayer);
				}
			}

			else if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Client_Command_Night_Vision(iPlayer);
			}
		}

		else
		{
			cs_set_user_nvg(iPlayer, 0);

			if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Disable_Night_Vision(iPlayer);
			}
		}
	}

	else
	{
		if (get_pcvar_num(g_pCvar_Night_Vision_Human))
		{
			if (!cs_get_user_nvg(iPlayer))
			{
				cs_set_user_nvg(iPlayer, 1);
			}

			if (get_pcvar_num(g_pCvar_Night_Vision_Human) == 2)
			{
				if (BIT_NOT_VALID(g_Night_Vision_Active, iPlayer))
				{
					Client_Command_Night_Vision(iPlayer);
				}
			}

			else if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Client_Command_Night_Vision(iPlayer);
			}
		}

		else
		{
			cs_set_user_nvg(iPlayer, 0);

			if (BIT_VALID(g_Night_Vision_Active, iPlayer))
			{
				Disable_Night_Vision(iPlayer);
			}
		}
	}
}

public Client_Command_Night_Vision(iPlayer)
{
	if (BIT_VALID(g_iBit_Alive, iPlayer))
	{
		// Player owns nightvision?
		if (!cs_get_user_nvg(iPlayer))
		{
			return PLUGIN_CONTINUE;
		}
	}

	else
	{
		// Spectator night vision disabled?
		if (!get_pcvar_num(g_pCvar_Night_Vision_Spectator))
		{
			return PLUGIN_CONTINUE;
		}
	}

	if (BIT_VALID(g_Night_Vision_Active, iPlayer))
	{
		Disable_Night_Vision(iPlayer);
	}

	else
	{
		Enable_Night_Vision(iPlayer);
	}

	return PLUGIN_HANDLED;
}

// ResetHUD removes CS night vision (bugfix)
public Event_Reset_Hud(iPlayer)
{
	if (!get_pcvar_num(g_pCvar_Night_Vision_Custom) && BIT_VALID(g_Night_Vision_Active, iPlayer))
	{
		set_user_night_vision_active(iPlayer, true);
	}
}

public Spectator_Night_Vision(iEntity)
{
	if (BIT_NOT_VALID(g_iBit_Connected, iEntity))
	{
		return;
	}

	if (BIT_VALID(g_iBit_Alive, iEntity))
	{
		return;
	}

	if (get_pcvar_num(g_pCvar_Night_Vision_Spectator) == 2)
	{
		if (BIT_NOT_VALID(g_Night_Vision_Active, iEntity))
		{
			Client_Command_Night_Vision(iEntity);
		}
	}

	else if (BIT_VALID(g_Night_Vision_Active, iEntity))
	{
		Disable_Night_Vision(iEntity);
	}
}

// Prevent spectators' nightvision from being turned off when switching targets, etc.
public Message_NVG_Toggle()
{
	return PLUGIN_HANDLED;
}

public client_disconnected(iPlayer)
{
	// Reset nightvision flags
	BIT_SUB(g_Night_Vision_Active, iPlayer);

	BIT_SUB(g_iBit_Alive, iPlayer);
	BIT_SUB(g_iBit_Connected, iPlayer);

	remove_task(iPlayer + TASK_NIGHT_VISION);
}

public zpe_fw_kill_pre_bit_sub(iPlayer)
{
	BIT_SUB(g_iBit_Alive, iPlayer);
}

public zpe_fw_spawn_post_bit_add(iPlayer)
{
	BIT_ADD(g_iBit_Alive, iPlayer);
}

Enable_Night_Vision(iPlayer)
{
	BIT_ADD(g_Night_Vision_Active, iPlayer);

	if (!get_pcvar_num(g_pCvar_Night_Vision_Custom))
	{
		set_user_night_vision_active(iPlayer, true);
	}

	else
	{
		set_task(0.1, "Custom_Night_Vision_Task", iPlayer + TASK_NIGHT_VISION, _, _, "b");
	}
}

// Custom night vision Task
public Custom_Night_Vision_Task(iTask_ID)
{
	// Get player's origin
	static iOrigin[3];

	get_user_origin(ID_NIGHT_VISION, iOrigin);

	// Night vision message
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, ID_NIGHT_VISION);
	write_byte(TE_DLIGHT); // TE player
	write_coord(iOrigin[0]); // x
	write_coord(iOrigin[1]); // y
	write_coord(iOrigin[2]); // z

	// Spectator
	if (BIT_NOT_VALID(g_iBit_Alive, ID_NIGHT_VISION))
	{
		write_byte(get_pcvar_num(g_pCvar_Night_Vision_Spectator_Radius)); // radius

		write_byte(get_pcvar_num(g_pCvar_Night_Vision_Spectator_Color_R)); // r
		write_byte(get_pcvar_num(g_pCvar_Night_Vision_Spectator_Color_G)); // g
		write_byte(get_pcvar_num(g_pCvar_Night_Vision_Spectator_Color_B)); // b
	}

	// Zombie
	else if (zpe_core_is_zombie(ID_NIGHT_VISION))
	{
		// Nemesis Class loaded?
		if (zpe_class_nemesis_get(ID_NIGHT_VISION))
		{
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Nemesis_Radius)); // radius

			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Nemesis_Color_R)); // r
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Nemesis_Color_G)); // g
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Nemesis_Color_B)); // b
		}

		// Assassin Class loaded?
		else if (zpe_class_assassin_get(ID_NIGHT_VISION))
		{
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Assassin_Radius)); // radius

			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Assassin_Color_R)); // r
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Assassin_Color_G)); // g
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Assassin_Color_B)); // b
		}

		else
		{
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Zombie_Radius)); // radius

			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Zombie_Color_R)); // r
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Zombie_Color_G)); // g
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Zombie_Color_B)); // b
		}
	}

	// Human
	else
	{
		// Survivor Class loaded?
		if (zpe_class_survivor_get(ID_NIGHT_VISION))
		{
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Survivor_Radius)); // radius

			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Survivor_Color_R)); // r
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Survivor_Color_G)); // g
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Survivor_Color_B)); // b
		}

		// Sniper Class loaded?
		else if (zpe_class_sniper_get(ID_NIGHT_VISION))
		{
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Sniper_Radius)); // radius

			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Sniper_Color_R)); // r
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Sniper_Color_G)); // g
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Sniper_Color_B)); // b
		}

		else
		{
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Human_Radius)); // radius

			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Human_Color_R)); // r
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Human_Color_G)); // g
			write_byte(get_pcvar_num(g_pCvar_Night_Vision_Human_Color_B)); // b
		}
	}

	write_byte(2); // life
	write_byte(0); // decay rate
	message_end();
}

Disable_Night_Vision(iPlayer)
{
	BIT_SUB(g_Night_Vision_Active, iPlayer);

	if (!get_pcvar_num(g_pCvar_Night_Vision_Custom))
	{
		set_user_night_vision_active(iPlayer, false);
	}

	else
	{
		remove_task(iPlayer + TASK_NIGHT_VISION);
	}
}

stock set_user_night_vision_active(iPlayer, bool:bActive)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_Message_NVG_Toggle, _, iPlayer);
	write_byte(bActive); // toggle
	message_end();
}