#if defined _zpe_flashlight_included

  #endinput

#endif

#define _zpe_flashlight_included

/**
 * Returns a player's custom flashlight batteries charge.
 *
 * @param {player} Player index.
 *
 * @return Charge percent (0 to 100), or -1 if custom flashlight is disabled.
 */
native zpe_flashlight_get_charge(player);

/**
 * Sets a player's custom flashlight batteries charge.
 *
 * @param {player} Player index.
 * @param {value} New charge percent (0 to 100).
 *
 * @return None.
 */
native zpe_flashlight_set_charge(player, value);