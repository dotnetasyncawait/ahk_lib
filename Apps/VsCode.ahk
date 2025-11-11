#Include <System\Paths>
#Include <Misc\CommandRunner>

class VsCode {
	static _processName     := "Code.exe"
	static _winProcessName  := "ahk_exe " this._processName
	static _fullProcessName := Paths.LocalPrograms "\Microsoft VS Code\" this._processName
	
	static ProcessName     => this._processName
	static FullProcessName => this._fullProcessName
	
	static IsActive => WinActive(this._winProcessName)
	
	static __New() {
		CommandRunner.AddCommands("code", this._HandleCommand.Bind(this))
	}
	
	static OpenSelected(&err) {
		selectedPaths := Paths.GetSelected(&err)
		if err {
			return
		}
		
		maxPaths := 3
		loop Min(maxPaths, selectedPaths.Length) {
			; Don't use quotes (selected path is already quoted).
			Run(Format('"{}" {}', this._fullProcessName, selectedPaths[A_Index]))
		}
	}
	
	static Open(path) => Run(Format('"{}" "{}"', this._fullProcessName, path))
	
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
				this.Open(path)
				output.WriteSilent(Format('Opening folder "{}".', path))
			}
		default:
			if not Paths.TryGetAliased(value, &path, &isFile) {
				output.WriteError(Format("alias '{}' not found.", value))
			} else {
				this.Open(path)
				output.WriteSilent(Format('Opening {} "{}".', isFile ? "file" : "folder", path))
			}
		}
	}
	
	
	; --- Shortcuts ---
	
	static OpenSettings() => SendInput("^,")
	
	static Fold() => SendInput("+^[")
	
	static Unfold() => SendInput("+^]")
	
	static FoldAll() => SendInput("^k^0")
	
	static UnfoldAll() => SendInput("^k^j")
	
	static GotoBracket() => SendInput("+^\")
	
	static ParameterHints() => SendInput("+^{Space}")
	
	static CloseEditor() => SendInput("^{F4}")
	
	static GoToDefinition() => SendInput("{F12}")
	
	static GoToImplementation() => SendInput("^{F12}")
	
	; This shortcut does both: Quck documentation and Error description (if there's any)
	static ShowOrFocusHover() => SendInput("^k^i")
	
	static CommentLine() => SendInput("^/")
	
	static QuickFix() => SendInput("^.")
	
	static ToggleBreakpoint() => SendInput("{F9}") ; editor.debug.action.toggleBreakpoint
	
	static NextTab() => SendInput("^{PgDn}")
	
	static PreviousTab() => SendInput("^{PgUp}")
	
	static ReopenLastClosedTab() => SendInput("+^t")
	
	static NewFile() {
		; modified
		; name: explorer.newFile
		; default: none
		SendInput("!{Insert}")
	}
	
	static CopyCursorUp() => SendInput("^!{Up}") ; add cursor above
	
	static CopyCursorDown() => SendInput("^!{Down}") ; add cursor below
	
	static CopyLineDown() => SendInput("^d")
	
	; --- Tool Windows ---
	
	static ShowExplorer() => SendInput("^+e")
	
	static Debug() => SendInput("^+d")
	
	static Terminal() {
		; modified
		; name: «View: Toggle Terminal»
		; command: workbench.action.terminal.toggleTerminal
		; reason: focuses Qmk Msys instead
		; default: ^` (ctrl + `)
		SendInput("+!2")
	}
	
	; --- ---
	
	static ExpandSelection() => SendInput("+!{Right}")
	
	static ShrinkSelection() => SendInput("+!{Left}")
	
	static GoForward() => SendInput("!{Right}")
	
	static GoBack() => SendInput("!{Left}")
	
	static PrevMember() => SendInput("!{Up}")
	
	static NextMember() => SendInput("!{Down}")
	
	static ToggleSourceControl() => SendInput("^+g")
	
	static InsertLineAbove() => SendInput("+^{Enter}")
	
	static InsertLineBelow() => SendInput("^{Enter}")
	
	static ToTabs() {
		; modified
		; default: None
		SendInput("+^4")
	}
	
	static ToSpaces() {
		; modified
		; default: None
		SendInput("+^7")
	}
	
	static ScrollTerminalUpByLine() => SendInput("!^{PgUp}")
	
	static ScrollTerminalDownByLine() => SendInput("!^{PgDn}")
	
	static ScrollTerminalUpByPage() => SendInput("+{PgUp}")
	
	static ScrollTerminalDownByPage() => SendInput("+{PgDn}")
	
	; --- Debugger ---
	
	static StopDebugger() => SendInput("+{F5}")
	
	static RestartDebugger() => SendInput("+^{F5}")
	
	static StepOver() => SendInput("{F10}")
	
	static StepInto() => SendInput("{F11}")
	
	static StepOut() => SendInput("+{F11}")
	
	; --- ---
}
