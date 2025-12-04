#if defined _zpe_class_human_included

  #endinput

#endif

#define _zpe_class_human_included

#include <zpe_class_human_const>

/**
 * Returns a player's current human class ID.
 *
 * @param {player} Player index.
 *
 * @return Internal human class ID, or ZPE_INVALID_CLASS_HUMAN if not yet chosen.
 */
native zpe_class_human_get_current(player);

/**
 * Returns a player's next human class ID (for the next infection).
 *
 * @param {player} Player index.
 *
 * @return Internal human class ID, or ZPE_INVALID_CLASS_HUMAN if not yet chosen.
 */
native zpe_class_human_get_next(player);

/**
 * Sets a player's next human class ID (for the next infection).
 *
 * @param {player} Player index.
 * @param {classid} A valid human class ID.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_human_set_next(player, classid);

/**
 * Returns the default maximum health for a specific human class.
 *
 * Note: does not take into account any kind of HP bonuses.
 *
 * @param {classid} A valid human class ID.
 *
 * @return Maximum amount of health points.
 */
native Float:zpe_class_human_get_max_health(classid);

/**
 * Registers a custom class which will be added to the human classes menu of ZPE.
 *
 * Note: the returned human class ID can be later used to identify
 * the class when calling the zp_get_user_human_class() natives.
 *
 * @param {name} Caption to display on the menu.
 * @param {description} Brief description of the class.
 * @param {health} Class health.
 * @param {armor} Class armor.
 * @param {speed} Class maxspeed (can be a multiplier).
 * @param {gravity} Class gravity multiplier.
 *
 * @return An internal human class ID, or ZPE_INVALID_CLASS_HUMAN on failure.
 */
native zpe_class_human_register(const name[], const description[], Float:health, armor, Float:speed, Float:gravity);

/**
 * Registers a custom player model for a given human class.
 *
 * @param {classid} A valid human class ID.
 * @param {model} Player model's short name.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_human_register_model(classid, const model[]);

/**
 * Returns a human class's ID.
 *
 * @param {name} Class name to look for.
 *
 * @return Internal human class ID, or ZPE_INVALID_CLASS_HUMAN if not found.
 */
native zpe_class_human_get_id(const real_name[]);

/**
 * Returns a human class's name.
 *
 * @param {classid}	A valid human class ID.
 * @param {name} The buffer to store the string in.
 * @param {len} Character size of the output buffer.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_human_get_name(classid, name[], len);

/**
 * Returns a human class's real name (used when registering the class).
 *
 * @param {classid} A valid human class ID.
 * @param {name} The buffer to store the string in.
 * @param {len} Character size of the output buffer.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_human_get_real_name(classid, real_name[], len);

/**
 * Returns a human class's description.
 *
 * @param {classid} A valid human class ID.
 * @param {description}	The buffer to store the string in.
 * @param {len} Character size of the output buffer.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_human_get_description(classid, description[], len);

/**
 * Returns number of registered human classes.
 *
 * @return Human class count.
 */
native zpe_class_human_get_count();

/**
 * Shows menu with available human classes to a player.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
native zpe_class_human_show_menu(player);

/**
 * Appends text to a class being displayed on the human classes menu.
 * Use this on the class select pre forward.
 *
 * @param {text} Additional text to display.
 *
 * @return None.
 */
native zpe_class_human_menu_text_add(const text[]);

/**
 * Called when determining whether a class should be available to a player.
 *
 * @param {player} Player index.
 * @param {classid} Internal human class ID.
 *
 * @return
 * {ZPE_CLASS_AVAILABLE} Show in menu, allow selection.
 * {ZPE_CLASS_NOT_AVAILABLE} Show in menu, don't allow selection.
 * {ZPE_CLASS_DONT_SHOW} Don't show in menu, don't allow selection.
 */
forward zpe_fw_class_human_select_pre(player, classid);

/**
 * Called right after a player selects a class from the menu.
 *
 * @param {player} Player index.
 * @param {classid} Internal human class ID.
 *
 * @return None.
 */
forward zpe_fw_class_human_select_post(player, classid);

/**
 * Called after human class registered.
 *
 * @param {classid} Internal human class ID.
 *
 * @return None.
 */
forward zpe_fw_class_human_register_post(classid);