#if defined _zpe_admin_commands_included

  #endinput

#endif

#define _zpe_admin_commands_included

/**
 * Manually executes admin command: zpe_zombie.
 *
 * @param {id} Admin player index.
 * @param {player} Target player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_admin_commands_zombie(id, player);

/**
 * Manually executes admin command: zpe_human.
 *
 * @param {id} Admin player index.
 * @param {player} Target player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_admin_commands_human(id, player);

/**
 * Manually executes admin command: zpe_nemesis.
 *
 * @param {id} Admin player index.
 * @param {player} Target player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_admin_commands_nemesis(id, player);

/**
 * Manually executes admin command: zpe_assassin.
 *
 * @param {id} Admin player index.
 * @param {player} Target player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_admin_commands_assassin(id, player);

/**
 * Manually executes admin command: zpe_survivor.
 *
 * @param {id} Admin player index.
 * @param {player} Target player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_admin_commands_survivor(id, player);

/**
 * Manually executes admin command: zpe_sniper.
 *
 * @param {id} Admin player index.
 * @param {player} Target player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_admin_commands_sniper(id, player);

/**
 * Manually executes admin command: zpe_respawn.
 *
 * @param {id} Admin player index.
 * @param {player} Target player index.
 *
 * @return True on success, false otherwise.
 */
native zpe_admin_commands_respawn(id, player);

/**
 * Manually executes admin command: zpe_start_game_mode.
 *
 * @param {id} Admin player index.
 * @param {game_mode_id} A valid game mode ID.
 *
 * @return True on success, false otherwise.
 */
native zpe_admin_commands_start_mode(id, game_mode_id);