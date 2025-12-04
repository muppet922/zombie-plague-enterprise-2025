#if defined _zpe_class_zombie_included

  #endinput

#endif

#define _zpe_class_zombie_included

#include <zpe_class_zombie_const>

/**
 * Returns a player's current zombie class ID.
 *
 * @param {player} Player index.
 *
 * @return Internal zombie class ID, or ZPE_INVALID_CLASS_ZOMBIE if not yet chosen.
 */
native zpe_class_zombie_get_current(player);

/**
 * Returns a player's next zombie class ID (for the next infection).
 *
 * @param {player} Player index.
 *
 * @return Internal zombie class ID, or ZPE_INVALID_CLASS_ZOMBIE if not yet chosen.
 */
native zpe_class_zombie_get_next(player);

/**
 * Sets a player's next zombie class ID (for the next infection).
 *
 * @param {player} Player index.
 * @param {classid} A valid zombie class ID.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_zombie_set_next(player, classid);

/**
 * Returns the default maximum health for a specific zombie class.
 *
 * Note: does not take into account any kind of HP multipliers.
 *
 * @param {classid} A valid zombie class ID.
 *
 * @return Maximum amount of health points.
 */
native Float:zpe_class_zombie_get_max_health(classid);

/**
 * Registers a custom class which will be added to the zombie classes menu of ZPE.
 *
 * Note: the returned zombie class ID can be later used to identify
 * the class when calling the zpe_get_user_zombie_class() natives.
 *
 * @param {name} Caption to display on the menu.
 * @param {description} Brief description of the class.
 * @param {health} Class health.
 * @param {armor} Class armor.
 * @param {speed} Class maxspeed (can be a multiplier).
 * @param {gravity} Class gravity multiplier.
 *
 * @return An internal zombie class ID, or ZPE_INVALID_CLASS_ZOMBIE on failure.
 */
native zpe_class_zombie_register(const name[], const description[], Float:health, armor, Float:speed, Float:gravity);

/**
 * Registers a custom player model for a given zombie class.
 *
 * @param {classid} A valid zombie class ID.
 * @param {model} Player model's short name.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_zombie_register_model(classid, const model[]);

/**
 * Registers a custom claw model for a given zombie class.
 *
 * @param {classid} A valid zombie class ID.
 * @param {clawmodel} Claw model filename.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_zombie_register_claw(classid, const clawmodel[]);

/**
 * Registers a zombie class's knockback multiplier.
 *
 * @param {classid} A valid zombie class ID.
 * @param {knockback} Knockback multiplier.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_zombie_register_kb(classid, Float:knockback);

/**
 * Returns a zombie class's ID.
 *
 * @param {name} Class name to look for.
 *
 * @return Internal zombie class ID, or ZPE_INVALID_CLASS_ZOMBIE if not found.
 */
native zpe_class_zombie_get_id(const real_name[]);

/**
 * Returns a zombie class's name.
 *
 * @param {classid} A valid zombie class ID.
 * @param {name} The buffer to store the string in.
 * @param {len} Character size of the output buffer.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_zombie_get_name(classid, name[], len);

/**
 * Returns a zombie class's real name (used when registering the class).
 *
 * @param {classid} A valid zombie class ID.
 * @param {name} The buffer to store the string in.
 * @param {len} Character size of the output buffer.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_zombie_get_real_name(classid, real_name[], len);

/**
 * Returns a zombie class's description.
 *
 * @param {classid} A valid zombie class ID.
 * @param {description} The buffer to store the string in.
 * @param {len} Character size of the output buffer.
 *
 * @return True on success, false otherwise.
 */
native zpe_class_zombie_get_description(classid, description[], len);

/**
 * Returns a zombie class's knockback multiplier.
 *
 * @param {classid} A valid zombie class ID.
 *
 * @return Knockback multiplier (float value).
 */
native Float:zpe_class_zombie_get_kb(classid);

/**
 * Returns number of registered zombie classes.
 *
 * @return Zombie class count.
 */
native zpe_class_zombie_get_count();

/**
 * Shows menu with available zombie classes to a player.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
native zpe_class_zombie_show_menu(player);

/**
 * Appends text to a class being displayed on the zombie classes menu.
 * Use this on the class select pre forward.
 *
 * @param {text} Additional text to display.
 *
 * @return None.
 */
native zpe_class_zombie_menu_text_add(const text[]);

/**
 * Called when determining whether a class should be available to a player.
 *
 * @param {player} Player index.
 * @param {classid} Internal zombie class ID.
 *
 * @return
 * {ZPE_CLASS_AVAILABLE} Show in menu, allow selection.
 * {ZPE_CLASS_NOT_AVAILABLE} Show in menu, don't allow selection.
 * {ZPE_CLASS_DONT_SHOW} Don't show in menu, don't allow selection.
 */
forward zpe_fw_class_zombie_select_pre(player, classid);

/**
 * Called right after a player selects a class from the menu.
 *
 * @param {player} Player index.
 * @param {classid} Internal zombie class ID.
 *
 * @return None.
 */
forward zpe_fw_class_zombie_select_post(player, classid);

/**
 * Called after zombie class registered.
 *
 * @param {classid} Internal zombie class ID.
 *
 * @return None.
 */
forward zpe_fw_class_zombie_register_post(classid);