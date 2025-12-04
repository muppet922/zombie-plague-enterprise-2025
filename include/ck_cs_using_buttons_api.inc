#if defined _ck_cs_using_buttons_api_included

  #endinput

#endif

#define _ck_cs_using_buttons_api_included

/**
 * Called when player press or unpress button.
 *
 * @param {player} Player index.
 * @param {pressed} Pressed button bitsum.
 * @param {unpressed} Unpressed button bitsum.
 *
 * @return None.
 */
forward fw_button_changed(player, pressed, unpressed);