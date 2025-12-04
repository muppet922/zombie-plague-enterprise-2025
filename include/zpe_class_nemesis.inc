#if defined _zpe_class_nemesis_included

  #endinput

#endif

#define _zpe_class_nemesis_included

#include <cs_util_const>

/**
 * Returns whether a player is a Nemesis.
 *
 * @param {player} Player index.
 *
 * @return True if it is, false otherwise.
 */
#define zpe_class_nemesis_get(%0) BIT_VALID(g_iBit_Nemesis, %0)

new stock g_iBit_Nemesis;

public zpe_fw_class_nemesis_bit_change(player)
{
	g_iBit_Nemesis = player;
}

/**
 * Forces a player to become a Nemesis.
 *
 * @param {player} Player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_nemesis_set(player);

/**
 * Returns number of alive Nemesis.
 *
 * @return Nemesis count.
 */
native zpe_class_nemesis_get_count();