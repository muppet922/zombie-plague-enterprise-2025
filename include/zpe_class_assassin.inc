#if defined _zpe_class_assassin_included

  #endinput

#endif

#define _zpe_class_assassin_included

#include <cs_util_const>

/**
 * Returns whether a player is a Assassin.
 *
 * @param {player} Player index.
 *
 * @return True if it is, false otherwise.
 */
#define zpe_class_assassin_get(%0) BIT_VALID(g_iBit_Assassin, %0)

new stock g_iBit_Assassin;

public zpe_fw_class_asassin_bit_change(player)
{
	g_iBit_Assassin = player;
}

/**
 * Forces a player to become a Assassin.
 *
 * @param {player} Player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_assassin_set(player);

/**
 * Returns number of alive Assassin.
 *
 * @return Assassin count.
 */
native zpe_class_assassin_get_count();