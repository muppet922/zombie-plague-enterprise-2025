#if defined _zpe_class_sniper_included

  #endinput

#endif

#define _zpe_class_sniper_included

#include <cs_util_const>

/**
 * Returns whether a player is a Sniper.
 *
 * @param {player} Player index.
 *
 * @return True if it is, false otherwise.
 */
#define zpe_class_sniper_get(%0) BIT_VALID(g_iBit_Sniper, %0)

new stock g_iBit_Sniper;

public zpe_fw_class_sniper_bit_change(player)
{
	g_iBit_Sniper = player;
}

/**
 * Forces a player to become a Sniper.
 *
 * @param {player} Player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_sniper_set(player);

/**
 * Returns number of alive Sniper.
 *
 * @return Sniper count.
 */
native zpe_class_sniper_get_count();