#if defined _zpe_items_included

  #endinput

#endif

#define _zpe_items_included

#include <zpe_items_const>

/**
 * Registers a custom item which will be added to the extra items menu of ZPE.
 *
 * Note: the returned item ID can be later used to catch item
 * selection events for the zpe_item_select_() forwards.
 *
 * @param {name} Caption to display on the menu.
 * @param {cost} Cost to display on the menu.
 *
 * @return An internal item ID, or ZPE_INVALID_ITEM on failure.
 */
native zpe_items_register(const name[], cost);

/**
 * Returns a count of items.
 *
 * @return Items count.
 */
native zpe_items_count();

/**
 * Returns an item's ID.
 *
 * @param {real_name} Item name to look for.
 *
 * @return Internal item ID, or ZPE_INVALID_ITEM if not found.
 */
native zpe_items_get_id(const real_name[]);

/**
 * Returns an item's name.
 *
 * @param {itemid} A valid item ID.
 * @param {name} The buffer to store the string in.
 * @param {len} Character size of the output buffer.
 *
 * @return True on success, false otherwise.
 */
native zpe_items_get_name(itemid, name[], len);

/**
 * Returns an item's real name (used when registering the item).
 *
 * @param {classid}	A valid item ID.
 * @param {real_name} The buffer to store the string in.
 * @param {len} Character size of the output buffer.
 *
 * @return True on success, false otherwise.
 */
native zpe_items_get_real_name(itemid, real_name[], len);

/**
 * Returns an item's cost.
 *
 * @param {itemid} A valid item ID.
 *
 * @return Item's cost.
 */
native zpe_items_get_cost(itemid);

/**
 * Sets new cost for item.
 *
 * @param {itemid} A valid item ID.
 * @param {cost} New cost.
 *
 * @return True on success, false otherwise.
 */
native zpe_items_set_cost(itemid, cost);

/**
 * Shows menu with available extra items for player.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
native zpe_items_show_menu(player);

/**
 * Forces a player to buy an extra item.
 *
 * @param {player} Player index.
 * @param {itemid} A valid extra item ID.
 * @param {ignorecost} If set, item's cost won't be deduced from player.
 *
 * @return True on success, false otherwise.
 */
native zpe_items_force_buy(player, itemid, ignorecost = false);

/**
 * Appends text to an item being displayed on the extra items menu.
 * Use this on the item select pre forward.
 *
 * @param {text} Additional text to display.
 *
 * @return None.
 */
native zpe_items_menu_text_add(const text[]);

/**
 * Get text item being displayed on the extra items menu.
 *
 * @param {text} Get text from display.
 *
 * @return None.
 */
native zpe_items_menu_get_text_add(const text[]);

/**
 * Get accessibility information item.
 *
 * @param {player} Player index.
 * @param {itemid} A valid extra item ID.
 *
 * @return
 * {ZPE_ITEM_AVAILABLE} Show in menu, allow selection.
 * {ZPE_ITEM_NOT_AVAILABLE} Show in menu, don't allow selection.
 * {ZPE_ITEM_DONT_SHOW} Don't show in menu, don't allow selection.
 */
native zpe_items_available(index, itemid);

/**
 * Called when determining whether an item should be available to a player.
 *
 * @param {player} Player index.
 * @param {itemid} Internal item ID.
 * @param {ignorecost} Whether item cost should be ignored.
 *
 * @return
 * {ZPE_ITEM_AVAILABLE} Show in menu, allow selection.
 * {ZPE_ITEM_NOT_AVAILABLE} Show in menu, don't allow selection.
 * {ZPE_ITEM_DONT_SHOW} Don't show in menu, don't allow selection.
 */
forward zpe_fw_items_select_pre(player, itemid, ignorecost);

/**
 * Called after a player selected an item from the extra items menu.
 *
 * @param {player} Player index.
 * @param {itemid} Internal item ID.
 * @param {ignorecost} Whether item cost should be ignored.
 *
 * @return None.
 */
forward zpe_fw_items_select_post(player, itemid, ignorecost);

/**
 * Called after item registered.
 *
 * @param {itemid} Internal item ID.
 *
 * @return None.
 */
forward zpe_fw_items_register_post(itemid);