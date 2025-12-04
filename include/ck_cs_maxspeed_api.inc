#if defined _ck_cs_maxspeed_api_included

  #endinput

#endif

#define _ck_cs_maxspeed_api_included

/**
 * Sets a player's maxspeed.
 *
 * @param {player} Player index.
 * @param {maxspeed} Custom maxspeed.
 * @param {multiplier} Treat maxspeed as multiplier instead of absolute value.
 *
 * @return None.
 */
native cs_set_player_maxspeed(player, Float:maxspeed, multiplier = false);

/**
 * Resets a player's maxspeed to default CS maxspeed.
 *
 * @param {player} Player index.
 *
 * @return None.
 */
native cs_reset_player_maxspeed(player);

#define MAXSPEED_BARRIER_MIN 0.0
#define MAXSPEED_BARRIER_MAX 10.0
#define CS_KNIFE_MAXSPEED 250.0

stock cs_set_player_maxspeed_auto(player, Float:maxspeed)
{
	if (MAXSPEED_BARRIER_MIN <= maxspeed <= MAXSPEED_BARRIER_MAX)
	{
		cs_set_player_maxspeed(player, maxspeed, true);
	}

	else
	{
		cs_set_player_maxspeed(player, maxspeed, false);
	}
}

stock cs_maxspeed_display_value(Float:maxspeed)
{
	if (MAXSPEED_BARRIER_MIN <= maxspeed <= MAXSPEED_BARRIER_MAX)
	{
		return floatround(maxspeed * CS_KNIFE_MAXSPEED);
	}

	return floatround(maxspeed);
}