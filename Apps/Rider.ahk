#Include <System\Paths>

class Rider {
	static _processName     := "rider64.exe"
	static _winProcessName  := "ahk_exe " this._processName
	static _fullProcessName := Paths.LocalPrograms "\Rider\bin\" this._processName
	
	static ProcessName => this._processName
	static IsActive => WinActive(this._winProcessName)
	
	
	; --- Shortcuts ---
	
	static OpenSettings() => SendInput("^,")
	
	static Collapse() => SendInput("+^[")
	
	static Expand() => SendInput("+^]")
	
	static CollapseAll() => SendInput("^k^0")
	
	static ExpandAll() => SendInput("^k^j")
	
	static MoveCaretToMatchingBrace() => SendInput("+^\")
	
	static ParameterInfo() => SendInput("+^{Space}")
	
	static CloseTab() => SendInput("^w")
	
	; Same shortcut for «Other/Refresh»
	; Database Explorer/Refresh is also derived 
	static ErrorDescription() => SendInput("^{F1}")
	
	static GoToDeclarationOrUsages() => SendInput("{F12}")
	
	static GoToImplementation() => SendInput("^{F12}")
	
	static QuickDocumentation() {
		SetKeyDelay(50)
		SendEvent("^k^i")
	}
	
	static CommentLine() => SendInput("^/")
	
	static ContextActions() => SendInput("^.")
	
	static ToggleBreakpoint() => SendInput("{F9}")
	
	static NextTab() => SendInput("^{PgDn}")
	
	static PreviousTab() => SendInput("^{PgUp}")
	
	static ReopenLastClosedTab() => SendInput("+^t")
	
	static NewFile() {
		SendInput("{LAlt Down}{Ins}")
		SendInput("{Blind}{LAlt Up}")
	}
	
	static ExtendSelection() => SendInput("+!{Right}")
	
	static ShrinkSelection() {
		; modified
		; name:
		; default: +^w
		SendInput("+!{Left}")
	}
	
	static CloneCaretAboveWithVirtualSpace() {
		; modified
		; replaced instead: CloneCaretAbove
		; name: 
		; default: none
		SendEvent("!^{Up}")
	}
	
	static CloneCaretBelowWithVirtualSpace() {
		; modified
		; replaced instead: CloneCaretBelow
		; name: 
		; default: none
		SendEvent("!^{Down}")
	}
	
	static DuplicateLineOrSelection() => SendInput("^d")
	
	static StartNewLine() => SendInput("^{Enter}")
	
	static StartNewLineBeforeCurrent() => SendInput("+^{Enter}")
	
	; --- Tool Windows ---
	
	static Explorer() => SendInput("+^e")
	
	static Terminal() => SendInput("^``")
	
	static Debug() => SendInput("+^d")
	
	static Database() => SendInput("!1")
	
	static UnitTests() => SendInput("+!8")
	
	static Commit() => SendInput("!0")
	
	static Git() => SendInput("+^g")
	
	static Structure() => SendInput("!7")
	
	static IL() => SendInput("!4")
	
	; --- ---
	
	static ToTabs() => SendInput("^{Numpad0}")
	
	static BuildSolution() => SendInput("^{Numpad1}")
	
	static ToggleToolbar() => SendInput("^{Numpad2}")
	
	static NugetRestore() => SendInput("^{Numpad3}")
	
	static ToggleInlayHints() => SendInput("^{Numpad4}")
	
	static Forward() => SendInput("{Blind+#^}!{Right}")
	
	static Back() => SendInput("{Blind+#^}!{Left}")
	
	static NextMethod() => SendInput("{LAlt Down}{Down}{Ctrl Down}{LAlt Up}{Ctrl Up}")
	
	static PrevMethod() => SendInput("{LAlt Down}{Up}{Ctrl Down}{LAlt Up}{Ctrl Up}")
	
	static ScrollTerminalUp() => SendInput("^{Up}")
	
	static ScrollTerminalDown() => SendInput("^{Down}")
	
	static Execute() => SendInput("!^1") ; Database\Execution\Execution\Execute
	
	; --- Debugger ---
	
	static RerunDebugger() => SendInput("+^{F5}") ; Other/Touchbar/Debugger/Rerun
	
	static StopDebugger() => SendInput("+{F5}") ; Other/Touchbar/Debugger/Stop
	
	static StepOut() => SendInput("+{F11}") ; Main Menu/Run/Debugger Actions/Step Out
	
	static StepOver() => SendInput("{F10}") ; Main Menu/Run/Debugger Actions/Step Over
	
	static StepInto() => SendInput("{F11}") ; Main Menu/Run/Debugger Actions/Step Into
	
	; --- ---
	
	static SelectTab1() => SendInput("!^2")
	
	static SelectTab2() => SendInput("!^3")
	
	static SelectTab3() => SendInput("!^4")
	
	static SelectTab4() => SendInput("!^5")
	
	static SelectTab5() => SendInput("!^6")
	
	static SelectTab6() => SendInput("!^7")
	
	static SelectLastTab() => SendInput("!^0")
	
	static JumpToQueryConsole() => SendInput("+^{F10}")
}