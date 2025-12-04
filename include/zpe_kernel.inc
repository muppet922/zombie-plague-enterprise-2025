#if defined _zpe_kernel_included

  #endinput

#endif

#define _zpe_kernel_included

/**
 * Returns whether a player is a zombie.
 *
 * @param {player} Player index.
 *
 * @return True if it is, false otherwise.
 */
#define zpe_core_is_zombie(%0) BIT_VALID(g_iBit_Zombie, %0)

new stock g_iBit_Zombie;

public zpe_fw_class_zombie_bit_change(player)
{
	g_iBit_Zombie = player;
}

/**
 * Returns whether a player is the first zombie.
 *
 * @param {player} Player index.
 *
 * @return True if it is, false otherwise.
 */
native zpe_core_is_first_zombie(player);

/**
 * Returns whether a player is the last zombie.
 *
 * @param {player} Player index.
 *
 * @return True if it is, false otherwise.
 */
native zpe_core_is_last_zombie(player);

/**
 * Returns whether a player is the last human.
 *
 * @param {player} Player index.
 *
 * @return True if it is, false otherwise.
 */
native zpe_core_is_last_human(player);

/**
 * Returns number of alive zombies.
 *
 * @return Zombie count.
 */
native zpe_core_get_zombie_count();

/**
 * Returns number of alive humans.
 *
 * @return Human count.
 */
native zpe_core_get_human_count();

/**
 * Turns a player into a zombie.
 *
 * @param {player} Player index to be infected.
 * @param {attacker} Player who triggered the infection. (optional)
 *
 * @return True on success, false otherwise.
 */
native zpe_core_infect(player, attacker = false);

/**
 * Turns a player into a human.
 *
 * @param {player} Player index to be cured.
 * @param {attacker} Player who triggered the cure. (optional)
 *
 * @return True on success, false otherwise.
 */
native zpe_core_cure(player, attacker = false);

/**
 * Forces a player to become a zombie or human.
 *
 * Note: use this only when previous checks need to be skipped.
 *
 * @param {player} Player index to be infected or cured.
 *
 * @return True on success, false otherwise.
 */
native zpe_core_force_infect(player);
native zpe_core_force_cure(player);

/**
 * Sets whether the player will be respawned as zombie or human.
 *
 * @param {player} Player index.
 * @param {zombie} True to respawn as zombie, false otherwise.
 *
 * @return None.
 */
native zpe_core_respawn_as_zombie(player, zombie = true);

/**
 * Called when a player gets infected.
 *
 * @param {player} Player index who was infected.
 * @param {attacker} Player who triggered the infection. (0 if not available, player = attacker if he infected himself)	
 *
 * @return None.
 */
forward zpe_fw_core_infect(player, attacker);
forward zpe_fw_core_infect_post(player, attacker);

/**
 * Called when a player turns back to human.
 *
 * @param {player} Player index who was cured.
 * @param {attacker} Player who triggered the cure. (0 if not available, player = attacker if he cured himself)
 *
 * @return None.
 */
forward zpe_fw_core_cure(player, attacker);
forward zpe_fw_core_cure_post(player, attacker);

/**
 * Called on a player infect or cure attempt. You can block it by
 * returning PLUGIN_HANDLED in your plugin.
 *
 * @param {player} Player index who is being infected or cured.
 * @param {attacker} Player who is triggering the infection or cure. (0 if not available, player = attacker if he is infecting or curing himself)
 *
 * @return None.
 */
forward zpe_fw_core_infect_pre(player, attacker);
forward zpe_fw_core_cure_pre(player, attacker);

/**
 * Called when a player becomes the last zombie or human.
 *
 * Note: this is called for the first zombie too.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
forward zpe_fw_core_last_zombie(player);
forward zpe_fw_core_last_human(player);

/**
 * Called when a player spawns, before applying human or zombie attributes to him.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
forward zpe_fw_core_spawn_post(player);

/**
 * Called by CBasePlayer::Spawn just before releasing the player into the game.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
forward zpe_fw_spawn_post_bit_add(player);

/**
 * Called each time a player dies.
 *
 * @param {player} Player index.
 * @param {killer} Killer index.
 * @param {inflictor} The object with which the damage was inflicted.
 *
 * @return None.
 */
forward zpe_fw_kill_pre_bit_sub(player, killer, inflictor);