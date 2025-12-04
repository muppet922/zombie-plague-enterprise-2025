#if defined _zpe_class_survivor_included

  #endinput

#endif

#define _zpe_class_survivor_included

#include <cs_util_const>

/**
 * Returns whether a player is a Survivor.
 *
 * @param {player} Player index.
 *
 * @return True if it is, false otherwise.
 */
#define zpe_class_survivor_get(%0) BIT_VALID(g_iBit_Survivor, %0)

new stock g_iBit_Survivor;

public zpe_fw_class_survivor_bit_change(player)
{
	g_iBit_Survivor = player;
}

/**
 * Forces a player to become a Survivor.
 *
 * @param {player} Player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_survivor_set(player);

/**
 * Returns number of alive Survivors.
 *
 * @return Survivor count.
 */
native zpe_class_survivor_get_count();