#if defined _ck_cs_weap_models_api_included

  #endinput

#endif

#define _ck_cs_weap_models_api_included

/**
 * Sets a custom view model for a specific weapon for a player.
 *
 * Note: if you pass an empty string, model will be hidden.
 *
 * @param {player} Player index.
 * @param {weaponid} Weapon to replace model for. (in CSW_ format)
 * @param {view_model} Full path to model. (e.g. "models/v_knife_custom.mdl")
 *
 * @return None.
 */
native cs_set_player_view_model(player, weaponid, const view_model[]);

/**
 * Restores a custom view model for a specific weapon for a player.
 *
 * @param {player} Player index.
 * @param {weaponid} Weapon to restore model for. (in CSW_ format)
 *
 * @return None.
 */
native cs_reset_player_view_model(player, weaponid);

/**
 * Sets a custom weapon model for a specific weapon for a player.
 *
 * Note: if you pass an empty string, model will be hidden.
 *
 * @param {player} Player index.
 * @param {weaponid} Weapon to replace model for. (in CSW_ format)
 * @param {view_model} Full path to model. (e.g. "models/p_knife_custom.mdl")
 *
 * @return None.
 */
native cs_set_player_weap_model(player, weaponid, const weapon_model[]);

/**
 * Restores a custom weapon model for a specific weapon for a player.
 *
 * @param {player} Player index.
 * @param {weaponid} Weapon to restore model for. (in CSW_ format)
 *
 * @return None.
 */
native cs_reset_player_weap_model(player, weaponid);