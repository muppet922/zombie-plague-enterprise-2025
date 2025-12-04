#if defined _zpe_sounds_api_included

  #endinput

#endif

#define _zpe_sounds_api_included

enum ZOMBIE_SOUNDS
{
	ZOMBIE_SOUND_DIE = 0,
	ZOMBIE_SOUND_FALL,
	ZOMBIE_SOUND_PAIN,
	ZOMBIE_SOUND_MISS_SLASH,
	ZOMBIE_SOUND_HIT_SOLID,
	ZOMBIE_SOUND_HIT_NORMAL,
	ZOMBIE_SOUND_HIT_STAB,
	ZOMBIE_SOUND_INFECT,
	ZOMBIE_SOUND_IDLE,
	ZOMBIE_SOUND_FLAME
};

enum HUMAN_SOUNDS
{
	HUMAN_SOUND_DIE = 0,
	HUMAN_SOUND_FALL,
	HUMAN_SOUND_PAIN,
	HUMAN_SOUND_MISS_SLASH,
	HUMAN_SOUND_HIT_SOLID,
	HUMAN_SOUND_HIT_NORMAL,
	HUMAN_SOUND_HIT_STAB,
	HUMAN_SOUND_IDLE
};

/**
 * Called in plugin_precache.
 *
 * @param {classid} A valid zombie class ID.
 * @param {sound_type} Sound type.
 * @param {sound} Full path to sound. (e.g. "sound/zombie/zombie.wav")
 *
 * @return None.
 */
native zpe_class_zombie_register_sound(classid, ZOMBIE_SOUNDS:sound_type, const sound[]);

/**
 * Called in plugin_precache.
 *
 * @param {classid} A valid human class ID.
 * @param {sound_type} Sound type.
 * @param {sound} Full path to sound. (e.g. "sound/human/human.wav")
 *
 * @return None.
 */
native zpe_class_human_register_sound(classid, HUMAN_SOUNDS:sound_type, const sound[]);