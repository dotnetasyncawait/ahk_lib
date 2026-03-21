class Chrome {
	static _processName     := "chrome.exe"
	static _winProcessName  := "ahk_exe " this._processName
	static _fullProcessName := A_ProgramFiles . "\Google\Chrome\Application\" this._processName
	
	static ProcessName => this._processName
	static IsActive => WinActive(this._winProcessName)
	
	static IsYoutube(title) {
		len := StrLen(title)
		return len >= 25 && SubStr(title, len-24) == "- YouTube - Google Chrome"
	}
	
	; --- Shortcuts ---
	
	static NewTab() => SendInput("^t")
	
	static CloseTab() => SendInput("^w")
	
	static ReopenLastClosedTab() => SendInput("+^t")
	
	static ReloadTab() => SendInput("^r")
	
	static ReloadTabIgnoringCache() => SendEvent("^+r")
	
	static NextTab() => SendInput("^{PgDn}")
	
	static PreviousTab() => SendInput("^{PgUp}")
	
	static Forward() => SendInput("!{Right}")
	
	static Back() => SendInput("!{Left}")
	
	static FocusOnAddressBar() => SendInput("^l")
	
	static OpenHomePage() => SendEvent("!{Home}")
	
	static JumpToRightmostTab() => SendEvent("^9")
	
	static Tabs() => SendEvent("^+a")
	
	static RecentTab() {
		SendEvent("^+a")
		Sleep(100)
		SendEvent("{Enter}")
	}
	
	static ToggleLoopMode() {
		; modified
		; default: none
		; extension: Enhancer for YouTube™
		
		; SendEvent("{LAlt Down}l{LCtrl Down}{LAlt Up}{LCtrl Up}")
		SendEvent("!l")
	}
	
	static IncreasePlaybackSpeed() => SendEvent("!4")
	
	static DecreasePlaybackSpeed() => SendEvent("!5")
	
	static DefaultPlaybackSpeed() => SendEvent("!6")
	
}