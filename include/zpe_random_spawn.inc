#if defined _zpe_random_spawn_included

  #endinput

#endif

#define _zpe_random_spawn_included

/**
 * Moves a player to a random spawn point.
 *
 * @param {player} Player index.
 * @param {csdmspawns} Ue CSDM spawn points instead of map defaults.
 *
 * @return None.
 */
native zpe_random_spawn_do(player, csdmspawns = true);