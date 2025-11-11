#Include <Misc\CommandRunner>
#Include <System\Paths>

class Explorer {
	static _processName     := "explorer.exe"
	static _winProcessName  := "ahk_exe " this._processName
	static _fullProcessName := "C:\Windows\" this._processName
	
	static ProcessName => this._processName
	static IsActive => WinActive(this._winProcessName)
	
	static __New() {
		CommandRunner.AddCommands("exp", this._HandleCommand.Bind(this))
	}
	
	static Open(path) => ComObject("Shell.Application").Explore(path)
	
	/**
	 * @param {CommandRunner.ArgsIter} args 
	 * @param {CommandRunner.Output} output
	 */
	static _HandleCommand(args, _, output) {
		if not args.Next(&arg) {
			this.Open(Paths.Desktop)
			output.WriteSilent(Format('Opening default location "{}".', Paths.Desktop))
			return
		}
		
		alias := arg.Value
		
		if not Paths.TryGetAliased(alias, &path, &isFile) {
			output.WriteError(Format("alias '{}' not found.", alias))
		} else if isFile {
			output.WriteError("files are not supported.")
		} else {
			this.Open(path)
			output.WriteSilent(Format('Opening folder "{}".', path))
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