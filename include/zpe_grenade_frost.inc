#if defined _zpe_grenade_frost_included

  #endinput

#endif

#define _zpe_grenade_frost_included

/**
 * Returns whether a player is frozen.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
native zpe_grenade_frost_get(player);

/**
 * Freezes or unfreezes a player.
 *
 * @param {player} Player index.
 * @param {set} True to freeze, false to unfreeze.
 *
 * @return True on success, false otherwise.
 */
native zpe_grenade_frost_set(player, set = true);

/**
 * Called when a player is about to be frozen.
 * Returning PLUGIN_HANDLED will block it.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
forward zpe_fw_grenade_frost_pre(player);

/**
 * Called after a player recovers from a frost nade.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
forward zpe_fw_grenade_frost_unfreeze(player);