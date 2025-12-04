#if defined _cs_util_included

  #endinput

#endif

#define _cs_util_included

#include <amxmodx>
#include <fakemeta>
#include <cs_util_const>
#include <reapi>

new stock __g_Message_ID_ScreenFade = -1;

#define MESSAGE_ID_SCREEN_FADE (__g_Message_ID_ScreenFade != -1 ? __g_Message_ID_ScreenFade : (__g_Message_ID_ScreenFade = get_user_msgid("ScreenFade")))

stock UTIL_ScreenFade(iPlayer, iDuration, iHold_Time, iFlags, iRed, iGreen, iBlue, iAlpha, iReliable = 0)
{
	if (iPlayer == 0)
	{
		message_begin(iReliable ? MSG_ALL : MSG_BROADCAST, MESSAGE_ID_SCREEN_FADE);
	}

	else
	{
		engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MESSAGE_ID_SCREEN_FADE, {0.0, 0.0, 0.0}, iPlayer);
	}

	write_short(iDuration);
	write_short(iHold_Time);
	write_short(iFlags);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}

new stock __g_Message_ID_ScreenShake = -1;

#define MESSAGE_ID_SCREEN_SHAKE (__g_Message_ID_ScreenShake != -1 ? __g_Message_ID_ScreenShake : (__g_Message_ID_ScreenShake = get_user_msgid("ScreenShake")))

stock UTIL_ScreenShake(iPlayer, iAmplitude, iDuration, iFrequency, iReliable = 0)
{
	engfunc(EngFunc_MessageBegin, iReliable ? MSG_ONE : MSG_ONE_UNRELIABLE, MESSAGE_ID_SCREEN_SHAKE, {0.0, 0.0, 0.0}, iPlayer);
	write_short(iAmplitude);
	write_short(iDuration);
	write_short(iFrequency);
	message_end();
}

new stock __g_Message_ID_SendAudio = -1;

#define MESSAGE_ID_SEND_AUDIO (__g_Message_ID_SendAudio != -1 ? __g_Message_ID_SendAudio : (__g_Message_ID_SendAudio = get_user_msgid("SendAudio")))

stock UTIL_SendAudio(iPlayer, iPitch = 100, const szPath_Sound[], any:...)
{
	new szBuffer[128];

	if (numargs() > 3)
	{
		vformat(szBuffer, charsmax(szBuffer), szPath_Sound, 4);
	}

	else
	{
		copy(szBuffer, charsmax(szBuffer), szPath_Sound);
	}

	if (iPlayer == 0)
	{
		message_begin(MSG_BROADCAST, MESSAGE_ID_SEND_AUDIO);
	}

	else
	{
		engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, MESSAGE_ID_SEND_AUDIO, {0.0, 0.0, 0.0}, iPlayer);
	}

	write_byte(iPlayer);
	write_string(szBuffer);
	write_short(iPitch);
	message_end();
}

new stock __g_Message_ID_BarTime = -1;

#define MESSAGE_ID_BAR_TIME (__g_Message_ID_BarTime != -1 ? __g_Message_ID_BarTime : (__g_Message_ID_BarTime = get_user_msgid("BarTime")))

stock UTIL_Show_Task_Bar(iPlayer, iTime)
{
	message_begin(MSG_ONE_UNRELIABLE, MESSAGE_ID_BAR_TIME, _, iPlayer);
	write_short(iTime);
	message_end();
}

new stock __g_Message_ID_Money = -1;

#define MESSAGE_ID_MONEY (__g_Message_ID_Money != -1 ? __g_Message_ID_Money : (__g_Message_ID_Money = get_user_msgid("Money")))

stock UTIL_Set_User_Money(iPlayer, iAmount, bool:bFlash = true)
{
	set_member(iPlayer, m_iAccount, iAmount);

	message_begin(MSG_ONE, MESSAGE_ID_MONEY, _, iPlayer);
	write_long(iAmount);
	write_byte(bFlash);
	message_end();
}

stock UTIL_Weapon_Animation(iPlayer, iAnimation)
{
	set_pev(iPlayer, pev_weaponanim, iAnimation);
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0.0, 0.0, 0.0}, iPlayer);
	write_byte(iAnimation);
	write_byte(0);
	message_end();
}

stock UTIL_Player_Animation(iPlayer, const szAnimation[])
{
	new iAnim_Desired;

	new Float:fFrame_Rate;
	new Float:fGround_Speed;

	new bool:bLoops;

	if ((iAnim_Desired = lookup_sequence(iPlayer, szAnimation, fFrame_Rate, bLoops, fGround_Speed)) == -1)
	{
		iAnim_Desired = 0;
	}

	new Float:fGametime = get_gametime();

	set_entvar(iPlayer, var_frame, 0.0);
	set_entvar(iPlayer, var_framerate, 1.0);
	set_entvar(iPlayer, var_animtime, fGametime);
	set_entvar(iPlayer, var_sequence, iAnim_Desired);

	set_member(iPlayer, m_fSequenceLoops, bLoops);
	set_member(iPlayer, m_fSequenceFinished, 0);
	set_member(iPlayer, m_flFrameRate, fFrame_Rate);
	set_member(iPlayer, m_flGroundSpeed, fGround_Speed);
	set_member(iPlayer, m_flLastEventCheck, fGametime);
	set_member(iPlayer, m_Activity, ACT_RANGE_ATTACK1);
	set_member(iPlayer, m_IdealActivity, ACT_RANGE_ATTACK1);
	set_member(iPlayer, m_flLastFired, fGametime); // m_flLastAttackTime
}

stock CREATE_BEAM_CYLINDER(Float:fVecOrigin[3], iRadius, iSprite, iStart_Frame = 0, iFrame_Rate = 0, iLife, iWidth, iAmplitude = 0, iRed, iGreen, iBlue, iBrightness, iScroll_Speed = 0)
{
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, fVecOrigin, 0);
	write_byte(TE_BEAMCYLINDER);
	engfunc(EngFunc_WriteCoord, fVecOrigin[0]);
	engfunc(EngFunc_WriteCoord, fVecOrigin[1]);
	engfunc(EngFunc_WriteCoord, fVecOrigin[2]);
	engfunc(EngFunc_WriteCoord, fVecOrigin[0]);
	engfunc(EngFunc_WriteCoord, fVecOrigin[1]);
	engfunc(EngFunc_WriteCoord, fVecOrigin[2] + 32.0 + iRadius * 2);
	write_short(iSprite);
	write_byte(iStart_Frame);
	write_byte(iFrame_Rate); // 0.1's
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iAmplitude); // 0.01's
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iBrightness);
	write_byte(iScroll_Speed); // 0.1's
	message_end();
}

stock CREATE_BEAM_FOLLOW(iEntity, iSprite, iLife, iWidth, iRed, iGreen, iBlue, iAlpha)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(iEntity);
	write_short(iSprite);
	write_byte(iLife); // 0.1's
	write_byte(iWidth);
	write_byte(iRed);
	write_byte(iGreen);
	write_byte(iBlue);
	write_byte(iAlpha);
	message_end();
}

stock CREATE_PLAYER_ATTACHMENT(iPlayer, iHeight = 50, iSprite, iLife)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(iPlayer);
	write_coord(iHeight);
	write_short(iSprite);
	write_short(iLife); // 0.1's
	message_end();
}

stock CREATE_KILL_PLAYER_ATTACHMENTS(iPlayer)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_KILLPLAYERATTACHMENTS);
	write_byte(iPlayer);
	message_end();
}

stock CREATE_KILLBEAM(iEntity)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(iEntity);
	message_end();
}

stock fm_set_kvd(iEntity, const szClassName[], const szKeyName[], const szValue[])
{
	set_kvd(0, KV_ClassName, szClassName);
	set_kvd(0, KV_KeyName, szKeyName);
	set_kvd(0, KV_Value, szValue);
	set_kvd(0, KV_fHandled, 0);

	return dllfunc(DLLFunc_KeyValue, iEntity, 0);
}

stock rg_set_user_rendering(iEntity, iFx = kRenderFxNone, r = 255, g = 255, b = 255, iRender = kRenderNormal, iAmount = 16)
{
	new Float:fRender_Color[3];

	fRender_Color[0] = float(r);
	fRender_Color[1] = float(g);
	fRender_Color[2] = float(b);

	set_entvar(iEntity, var_renderfx, iFx);
	set_entvar(iEntity, var_rendercolor, fRender_Color);
	set_entvar(iEntity, var_rendermode, iRender);
	set_entvar(iEntity, var_renderamt, float(iAmount));
}

// Set entity's rendering type (float parameters version)
stock rh_set_rendering_float(iEntity, iFX = kRenderFxNone, Float:fColor[3], iRender = kRenderNormal, Float:fAmount = 16.0)
{
	set_entvar(iEntity, var_renderfx, iFX);
	set_entvar(iEntity, var_rendercolor, fColor);
	set_entvar(iEntity, var_rendermode, iRender);
	set_entvar(iEntity, var_renderamt, fAmount);
}

// Get entity's aim origins (from fakemeta_util)
stock UTIL_fm_get_aim_origin(iPlayer, Float:fOrigin[3])
{
	static Float:fOrigin1[3];
	static Float:fOrigin2[3];

	pev(iPlayer, pev_origin, fOrigin1);
	pev(iPlayer, pev_view_ofs, fOrigin2);

	xs_vec_add(fOrigin1, fOrigin2, fOrigin1);

	pev(iPlayer, pev_v_angle, fOrigin2);

	engfunc(EngFunc_MakeVectors, fOrigin2);

	global_get(glb_v_forward, fOrigin2);

	xs_vec_mul_scalar(fOrigin2, 9999.0, fOrigin2);
	xs_vec_add(fOrigin1, fOrigin2, fOrigin2);

	engfunc(EngFunc_TraceLine, fOrigin1, fOrigin2, 0, iPlayer, 0);

	get_tr2(0, TR_vecEndPos, fOrigin);
}

enum
{
	INFO_TARGET,
	ENV_SPRITE,

	END
};

stock UTIL_Create_Entity(iEntity_Type)
{
	static iClass_Cache[END];

	static const sValid_Classes[END][] =
	{
		"info_target",
		"env_sprite"
	};

	new iReturn = -1;
	new iEntity = 0;

	if (iClass_Cache[iEntity_Type] || (iClass_Cache[iEntity_Type] = engfunc(EngFunc_AllocString, sValid_Classes[iEntity_Type])))
	{
		if (is_entity((iEntity = engfunc(EngFunc_CreateNamedEntity, iClass_Cache[iEntity_Type]))))
		{
			iReturn = iEntity;
		}
	}

	return iReturn;
}

stock UTIL_Play_Weapon_Animation(const iPlayer, const iSequence)
{
	set_entvar(iPlayer, var_weaponanim, iSequence);

	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, .player = iPlayer);
	write_byte(iSequence);
	write_byte(0);
	message_end();
}

stock _fm_get_speed(iEntity)
{
	new Float:fVel[3];

	get_entvar(iEntity, var_velocity, fVel);

	return floatround(vector_length(fVel));
}

// Check if a player is stuck (credits to VEN)
stock Is_Player_Stuck(iPlayer)
{
	static Float:fOrigin[3];

	get_entvar(iPlayer, var_origin, fOrigin);

	engfunc(EngFunc_TraceHull, fOrigin, fOrigin, 0, (get_entvar(iPlayer, var_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, iPlayer, 0);

	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
	{
		return true;
	}

	return false;
}

// Checks if a space is vacant (credits to VEN)
stock Is_Hull_Vacant(Float:fOrigin[3], iHull)
{
	engfunc(EngFunc_TraceHull, fOrigin, fOrigin, 0, iHull, 0, 0);

	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
	{
		return true;
	}

	return false;
}

// Stock by (probably) Twilight Suzuka -counts number of chars in a string
stock Str_Count(const sStr[], iSearch_Char)
{
	new iCount;
	new iLen = strlen(sStr);

	for (new i = 0; i <= iLen; i++)
	{
		if (sStr[i] == iSearch_Char)
		{
			iCount++
		}
	}

	return iCount;
}

stock zpe_client_print_color(iIdex, iSender, const szMessage[], any:...)
{
	static szBuffer[512];

	// Format message for player (+add ZP prefix)
	vformat(szBuffer, charsmax(szBuffer), szMessage, 4);
	format(szBuffer, charsmax(szBuffer), "%L %s", iIdex, "ZP_PREFIX", szBuffer);

	replace_all(szBuffer, charsmax(szBuffer), "!g", "^4"); // Green Color
	replace_all(szBuffer, charsmax(szBuffer), "!y", "^1"); // Default Color
	replace_all(szBuffer, charsmax(szBuffer), "!t", "^3"); // Team Color

	client_print_color(iIdex, iSender, szBuffer);
}

stock Recursive_Mkdir(szPath[])
{
	static szPath_Copy[128];
	static szRecursive_Path[128];

	static bool:bFirst_Iteration = true;
	static bool:bRecursive_Creating = false;

	if (bFirst_Iteration)
	{
		copy(szPath_Copy, charsmax(szPath_Copy), szPath);

		bFirst_Iteration = false;
	}

	new szDir_Name[64];
	strtok(szPath_Copy, szDir_Name, charsmax(szDir_Name), szPath_Copy, charsmax(szPath_Copy), '/');
	format(szRecursive_Path, charsmax(szRecursive_Path), "%s%s%s", szRecursive_Path, bFirst_Iteration ? "" : "/", szDir_Name);

	if (!szPath_Copy[0])
	{
		mkdir(szRecursive_Path);

		szPath_Copy[0] = '^0';
		szRecursive_Path[0] = '^0';

		bFirst_Iteration = true;
		bRecursive_Creating = false;

		return;
	}

	if (bRecursive_Creating)
	{
		mkdir(szRecursive_Path);
	}

	else if (!dir_exists(szRecursive_Path))
	{
		mkdir(szRecursive_Path);

		bRecursive_Creating = true;
	}

	Recursive_Mkdir(szPath_Copy);
}

stock Precache_Models(Array:aModels)
{
	new szModel[MODEL_MAX_LENGTH];
	new iCount = ArraySize(aModels);

	for (new i = 0; i < iCount; i++)
	{
		ArrayGetString(aModels, i, szModel, charsmax(szModel));
		precache_model(szModel);
	}
}

stock Precache_Player_Models(Array:aPlayer_Models)
{
	new szPlayer_Model[PLAYER_MODEL_MAX_LENGTH];
	new szModel_Path[PLAYER_MODEL_PATH_MAX_LENGTH];
	new iCount = ArraySize(aPlayer_Models);

	for (new i = 0; i < iCount; i++)
	{
		ArrayGetString(aPlayer_Models, i, szPlayer_Model, charsmax(szPlayer_Model));
		formatex(szModel_Path, charsmax(szModel_Path), "models/player/%s/%s.mdl", szPlayer_Model, szPlayer_Model);
		precache_model(szModel_Path);
	}
}

stock Precache_Sounds(Array:aSounds)
{
	new szSound[SOUND_MAX_LENGTH];
	new iCount = ArraySize(aSounds);

	for (new i = 0; i < iCount; i++)
	{
		ArrayGetString(aSounds, i, szSound, charsmax(szSound));
		precache_sound(szSound);
	}
}

stock bool:Ends_With(const szString[], const szSuffix[])
{
	new iString_Length = strlen(szString);
	new iSuffix_Length = strlen(szSuffix);

	return iString_Length >= iSuffix_Length && equal(szString[iString_Length - iSuffix_Length], szSuffix);
}

stock HSV_To_RGB(const HSV[3], RGB[3])
{
	new H = clamp(HSV[0], 0, 360);
	new S = clamp(HSV[1], 0, 100);
	new V = clamp(HSV[2], 0, 100);

	new Hi = (H / 60) % 6;

	new Vmin = (100 - S) * V / 100;
	new a = (V - Vmin) * (H % 60) / 60;

	new Vinc = Vmin + a;
	new Vdec = V - a

	switch (Hi)
	{
		case 0:
		{
			RGB[0] = V;
			RGB[1] = Vinc;
			RGB[2] = Vmin;
		}

		case 1:
		{
			RGB[0] = Vdec;
			RGB[1] = V;
			RGB[2] = Vmin;
		}

		case 2:
		{
			RGB[0] = Vmin;
			RGB[1] = V;
			RGB[2] = Vinc;
		}

		case 3:
		{
			RGB[0] = Vmin;
			RGB[1] = Vdec;
			RGB[2] = V;
		}

		case 4:
		{
			RGB[0] = Vinc;
			RGB[1] = Vmin;
			RGB[2] = V;
		}

		case 5:
		{
			RGB[0] = V;
			RGB[1] = Vmin;
			RGB[2] = Vdec;
		}
	}

	RGB[0] = RGB[0] * 255 / 100;
	RGB[1] = RGB[1] * 255 / 100;
	RGB[2] = RGB[2] * 255 / 100;
}