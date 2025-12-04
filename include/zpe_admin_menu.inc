#if defined _zpe_admin_menu_included

  #endinput

#endif

#define _zpe_admin_menu_included

/**
 * Shows admin menu to a specific player. Commands will only
 * be available if player has the required admin flags.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
native zpe_admin_menu_show(player);