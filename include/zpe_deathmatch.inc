#if defined _zpe_deathmatch_included

  #endinput

#endif

#define _zpe_deathmatch_included

/**
 * Called before the deathmatch module respawns a player.
 * Returning PLUGIN_HANDLED will block respawn.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
forward zpe_fw_deathmatch_respawn_pre(player);