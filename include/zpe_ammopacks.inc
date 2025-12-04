#if defined _zpe_ammopacks_included

  #endinput

#endif

#define _zpe_ammopacks_included

/**
 * Returns a player's ammo pack count.
 *
 * @param {player} Player index.
 *
 * @return Number of ammo packs owned.
 */
native zpe_ammopacks_get(player);

/**
 * Sets a player's ammo pack count.
 *
 * @param {player} Player index.
 * @param {amount} New quantity of ammo packs owned.
 *
 * @return None.
 */
native zpe_ammopacks_set(player, amount);