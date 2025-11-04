#Include <Misc\CommandRunner>
#Include <System\Paths>

class Explorer {
	static _processName     := "explorer.exe"
	static _winProcessName  := "ahk_exe " this._processName
	static _fullProcessName := "C:\Windows\" this._processName
	
	static ProcessName => this._processName
	static IsActive => WinActive(this._winProcessName)
	
	static __New() {
		CommandRunner.AddCommands("exp", this._Handle.Bind(this))
	}
	
	static Open(path) => ComObject("Shell.Application").Explore(path)
	
	static _Handle(args, _, &output) {
		if not args.Next(&arg) {
			this.Open(Paths.Desktop)
			return
		}
		
		alias := arg.Value
		
		if not Paths.TryGetAliased(alias, &path, &isFile) {
			output := Format("Alias '{}' not found.", alias)
		} else if isFile {
			output := "Files are not supported."
		} else {
			this.Open(path)
		}
	}
	
	
	; --- Shortcuts ---
	
	static FocusOnAddressBar() => SendInput("!d")
	
	static CloseTab() => SendInput("^w")
	
	static NextTab() => SendInput("^{tab}")
	
	static PreviousTab() => SendInput("^+{tab}")
	
	static NewTab() => SendInput("^t")
	
	static CreateFolder() => SendInput("+^n")
	
	static OpenContextMenu() => SendInput("+{F10}")
}