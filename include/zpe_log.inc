/**
 * This is used to log ZPE specific information or errors into a
 * location where it is separate from other messages.
*/

stock zpe_log(const message_format[], any:...)
{
	static szMessage[256];
	static szFilename[32];
	static szDate[16];

	vformat(szMessage, charsmax(szMessage), message_format, 2);

	format_time(szDate, charsmax(szDate), "%Y%m%d");

	formatex(szFilename, charsmax(szFilename), "Zombie_Plague_Enterprise_%s.log", szDate);

	log_to_file(szFilename, "%s", szMessage);
}