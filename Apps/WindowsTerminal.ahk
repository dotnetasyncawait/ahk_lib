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
	
	static Open(path) => Run(Format('{} -d "{}"', this._fullProcessName, path))
	
	/**
	 * @param {CommandRunner.ArgsIter} args 
	 * @param {CommandRunner.Output} output
	 */
	static _HandleCommand(args, hwnd, output) {
		; Usage: wt [. | ALIAS] [-e]
		
		if args.IsEmpty {
			Run(this._fullProcessName)
			return
		}
		
		prefix := ""
		path := ""
		
		while args.Next(&arg) {
			switch value := arg.Value {
			case "-e": ; run elevated
				if args.Next(&arg) { ; we should have no arguments followed this flag
					output.WriteError(Format("invalid argument '{}'.", arg.Value))
					return
				}
				prefix := "*RunAs "
				break ; break of the while loop
			case ".":
				if path {
					output.WriteError("invalid argument '.'.")
				} else if not Paths.TryGet(&path, hwnd) {
					output.WriteError("path not found.")
				} else {
					continue
				}
				return
			default:
				if path {
					output.WriteError(Format("invalid argument '{}'.", value))
				} else if not Paths.TryGetAliased(value, &path, &isFile) {
					output.WriteError(Format("alias '{}' not found.", value))
				} else if isFile {
					output.WriteError("files are not supported.")
				} else {
					continue
				}
				return
			}
		}
		
		if path {
			Run(Format('{} -d "{}"', prefix . this._fullProcessName, path))
			output.WriteSilent(Format('Opening folder "{}".', path))
		} else {
			Run(prefix . this._fullProcessName)
		}
	}
	
	
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