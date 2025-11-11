#Include <System\Paths>
#Include <Misc\CommandRunner>

class WindowsTerminal {
	static _processName     := "WindowsTerminal.exe"
	static _winProcessName  := "ahk_exe " this._processName
	static _fullProcessName := Paths.Local "\Microsoft\WindowsApps\wt.exe"
	
	static __New() {
		CommandRunner.AddCommands("wt", this._HandleCommand.Bind(this))
	}
	
	static IsActive => WinActive(this._winProcessName)
	
	/**
	 * @param {CommandRunner.ArgsIter} args 
	 * @param {CommandRunner.Output} output
	 */
	static _HandleCommand(args, hwnd, output) {
		if not args.Next(&arg) {
			Run(this._fullProcessName)
			return
		}
		
		switch value := arg.Value {
		case ".":
			if not Paths.TryGet(&path, hwnd) {
				output.WriteError("path not found.")
			} else {
				RunAndOutput(path, output)
			}
		default:
			if not Paths.TryGetAliased(value, &path, &isFile) {
				output.WriteError(Format("alias '{}' not found.", value))
			} else if isFile {
				output.WriteError("files are not supported.")
			} else {
				RunAndOutput(path, output)
			}
		}
		
		return
		
		RunAndOutput(path, output) {
			this._Run(path)
			output.WriteSilent(Format('Opening folder "{}".', path))
		}
	}
	
	static _Run(path) => Run(Format('{} -d "{}"', this._fullProcessName, path))
	
	
	; --- Shortcuts ---
	
	static DuplicateTab() => SendInput("+^d")
	
	static NewTab() => SendInput("+^t")
	
	static ClosePane() => SendInput("+^w")
	
	static NextTab() => SendInput("^{Tab}")
	
	static PreviousTab() => SendInput("+^{Tab}")
	
	static OpenSettings() => SendInput("^,")
	
	static SwitchToTab0() => SendInput("!^1")
	
	static SwitchToTab1() => SendInput("!^2")
	
	static SwitchToTab2() => SendInput("!^3")
	
	static SwitchToTab3() => SendInput("!^4")
	
	static SwitchToTab4() => SendInput("!^5")
	
	static SwitchToTab5() => SendInput("!^6")
	
	static SwitchToLastTab() => SendInput("!^9")
	
	static ScrollUp() => SendInput("+^{Up}")
	
	static ScrollDown() => SendInput("+^{Down}")
	
	static ScrollPageUp() => SendInput("+^{PgUp}")
	
	static ScrollPageDown() => SendInput("+^{PgDn}")
	
}