/*
 * Language Module - Client language preferences with cookie support
 * Original author: Grey83
 * Adapted for Eclipse Management System
 */

#if !defined EMS_MAIN_FILE
	#error You must compile main file "scripting/Eclipse Management System.sp". This is only an auxiliary file.
#endif
#define _LANGUAGE_MODULE_

//==================================================
// === LANGUAGE MODULE ===
// Allows players to set and save their preferred language
//==================================================

Handle lang_cookie;
char cLangPref[MAXPLAYERS + 1][4];

/**
 * Initialize language module
 */
public void Language_OnPluginStart()
{
	LoadTranslations("eclipse.phrases");

	lang_cookie = RegClientCookie("client_lang", "Saved client language", CookieAccess_Private);
	SetCookieMenuItem(LanguageCookieMenu, 0, "Language");
}

/**
 * Called when client cookies are cached
 */
public void Language_OnClientCookiesCached(int client)
{
	char sPref[4];
	GetClientCookie(client, lang_cookie, sPref, sizeof(sPref));
	cLangPref[client] = sPref;
}

/**
 * Called when client is post admin checked
 */
public void Language_OnClientPostAdminCheck(int client)
{
	char code[4];
	GetClientCookie(client, lang_cookie, code, sizeof(code));
	int lang = GetLanguageByCode(code);
	if (lang >= 0)
	{
		SetClientLanguage(client, lang);
	}
}

/**
 * Command: sm_lang / sm_language
 * Shows language selection panel or sets a new language by code
 */
public Action Command_Language(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %T", "Command is in-game only", client);
		return Plugin_Handled;
	}

	if (args == 0)
	{
		// Show language selection panel
		ShowLanguagePanel(client);
	}
	else
	{
		// Set new language by code (for advanced users)
		char code[4];
		GetCmdArg(1, code, sizeof(code));
		ChangeLanguage(client, GetLanguageByCode(code));
	}

	return Plugin_Handled;
}

/**
 * Shows the language selection panel
 */
void ShowLanguagePanel(int client)
{
	Menu langmenu = new Menu(LanguageMenuHandler_Command);

	char title[128];
	Format(title, sizeof(title), "%T", "Lang_MenuTitle", client);
	langmenu.SetTitle(title);

	// Get current language
	int currentLang = GetClientLanguage(client);
	char currentCode[4];
	if (currentLang >= 0)
	{
		GetLanguageInfo(currentLang, currentCode, sizeof(currentCode));
	}

	// Only add languages that we have translations for
	// These are the languages in eclipse.phrases.txt
	char supportedLangs[][] = {
		"en", "es", "pt", "fr", "de", "ru", "it", "pl", "tr", "chi"
	};
	char langNames[][] = {
		"English", "Espanol", "Português", "Français", "Deutsch",
		"Русский", "Italiano", "Polski", "Turkçe", "中文"
	};

	for (int i = 0; i < sizeof(supportedLangs); i++)
	{
		bool isCurrent = StrEqual(currentCode, supportedLangs[i], false);
		char menuItem[128];

		if (isCurrent)
		{
			Format(menuItem, sizeof(menuItem), "%s ☑", langNames[i]);
		}
		else
		{
			Format(menuItem, sizeof(menuItem), "%s", langNames[i]);
		}

		langmenu.AddItem(supportedLangs[i], menuItem);
	}

	langmenu.ExitButton = true;
	langmenu.Display(client, MENU_TIME_FOREVER);
}

/**
 * Menu handler for !lang command
 */
public int LanguageMenuHandler_Command(Menu langmenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char code[4];
			langmenu.GetItem(item, code, sizeof(code));
			ChangeLanguage(client, GetLanguageByCode(code));
		}
		case MenuAction_End:
		{
			delete langmenu;
		}
	}
	return 0;
}

/**
 * Cookie menu handler
 */
public void LanguageCookieMenu(int client, CookieMenuAction action, any info, char[] buffer, int maxlen)
{
	if (action == CookieMenuAction_DisplayOption)
	{
		Format(buffer, maxlen, "%T", "Lang_CookieOption", client, cLangPref[client]);
	}
	else if (action == CookieMenuAction_SelectOption)
	{
		char MenuItem[64];
		Menu langmenu = new Menu(LanguageMenuHandler);

		char title[64];
		Format(title, sizeof(title), "%T", "Lang_MenuTitle", client);
		langmenu.SetTitle(title);

		int num = GetLanguageCount();
		for (int i = 0; i < num; i++)
		{
			char code[4], name[64];
			GetLanguageInfo(i, code, sizeof(code), name, sizeof(name));
			bool used = StrEqual(cLangPref[client], code, false);
			Format(MenuItem, sizeof(MenuItem), "%s %s", name, used ? "☑" : "");
			langmenu.AddItem(code, MenuItem, used ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
		}

		if (num < 10)
			langmenu.Pagination = 0;

		langmenu.ExitButton = true;
		langmenu.Display(client, MENU_TIME_FOREVER);
	}
}

/**
 * Language menu handler
 */
public int LanguageMenuHandler(Menu langmenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Display:
		{
			char title[64];
			Format(title, sizeof(title), "%T", "Lang_CookieOption", client, cLangPref[client]);
			langmenu.SetTitle(title);
		}
		case MenuAction_DisplayItem:
		{
			char buffer[64];
			langmenu.GetItem(item, buffer, sizeof(buffer));
			bool used = StrEqual(buffer, cLangPref[client]);
			Format(buffer, sizeof(buffer), "%s%s", buffer, used ? " ☑" : "");
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Select:
		{
			char code[4];
			GetMenuItem(langmenu, item, code, sizeof(code));
			ChangeLanguage(client, GetLanguageByCode(code));
		}
		case MenuAction_End:
		{
			delete langmenu;
		}
	}
	ShowCookieMenu(client);
	return 0;
}

/**
 * Changes client language
 */
void ChangeLanguage(int client, int lang)
{
	char code[4], name[64];
	if (lang >= 0)
	{
		GetLanguageInfo(lang, code, sizeof(code), name, sizeof(name));
		SetClientLanguage(client, lang);
		SetClientCookie(client, lang_cookie, code);
		cLangPref[client] = code;

		char message[128];
		Format(message, sizeof(message), "%T", "Lang_Changed", client, name, code, lang);
		CPrintToChat(client, "\x04[Language]\x01 %s", message);
	}
	else
	{
		char message[128];
		Format(message, sizeof(message), "%T", "Lang_ErrorCode", client);
		CPrintToChat(client, "\x05[Language]\x01 %s", message);
	}
}
