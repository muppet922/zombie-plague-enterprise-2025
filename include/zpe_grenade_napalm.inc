#if defined _zpe_grenade_napalm_included

  #endinput

#endif

#define _zpe_grenade_napalm_included

/**
 * Returns whether a player is burning.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
native zpe_grenade_napalm_get(player);

/**
 * Sets a player on fire or stops burning.
 *
 * @param {player} Player index.
 * @param {set} True to set on fire, false to stop burning.
 *
 * @return True on success, false otherwise.
 */
native zpe_grenade_napalm_set(player, set = true);

/**
 * Called when a player is about to start burning.
 * Returning PLUGIN_HANDLED will block it.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
forward zpe_fw_grenade_napalm_pre(player);