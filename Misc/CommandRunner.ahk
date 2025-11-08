#Include <Collections\LinkedList>
#Include <Common\Disposition>
#Include <Common\Helpers>

class CommandRunner {
	static _console  := Gui()
	static _commands := Map()
	
	/**
	 * @type {Gui.Control}
	 */
	static _consoleEdit := unset
	
	static _xPos := A_ScreenWidth / 2
	static _yPos := A_ScreenHeight / 100 * 20
	
	static _xDisposition := Disposition.Centered
	static _yDisposition := Disposition.Centered
	
	static _width  := 900
	static _height := 35
	
	/**
	 * @type {Gui.Control}
	 */
	static _outputEdit       := unset
	static _outputRowCount   := 20
	static _outputEditPaddY  := 15
	
	static _prevWinHwnd := 0
	static _isRunning := false
	
	static IsActive => WinActive(this._console.Hwnd)
	
	static __New() {
		this._InitCommands()
		this._InitConsole()
		
		OnMessage(0x0006, this._OnACTIVATE.Bind(this))               ; WM_ACTIVATE
		OnMessage(0x0050, this._OnINPUTLANGCHANGEREQUEST.Bind(this)) ; WM_INPUTLANGCHANGEREQUEST
		OnMessage(0x0100, this._OnKEYDOWN.Bind(this))                ; WM_KEYDOWN
		OnMessage(0x0104, this._OnSYSKEYDOWN.Bind(this))             ; WM_SYSKEYDOWN
		OnMessage(0x020A, this._OnMOUSEWHEEL.Bind(this))             ; WM_MOUSEWHEEL
	}
	
	static Open() {
		hwnd := WinExist("A") 
		
		if hwnd == this._console.Hwnd { ; if the console is already open — toggle output
			this._outputEdit.Visible ^= 1
			return
		}
		
		this._prevWinHwnd := hwnd
		this._console.Show()
	}
	
	; TODO: add docs
	static AddCommands(command, callback, params*) {
		if Mod(params.Length, 2) != 0 {
			throw ValueError("Error adding commands: invalid number of commands", params)
		}
		
		ThrowIfDuplicate(command)
		this._commands.Set(command, callback)
		
		i := 1
		while i < params.Length {
			ThrowIfDuplicate(params[i])
			
			this._commands.Set(params[i], params[i+1])
			i += 2
		}
		
		
		ThrowIfDuplicate(key) {
			if this._commands.Has(key) {
				throw ValueError(Format("Error adding commands: command «{1}» already exists", key))
			}
		}
	}
	
	
	; --- private ---

	static _OnKEYDOWN(wParam, lParam, msg, hwnd) {
		isEdit := hwnd == this._consoleEdit.Hwnd
		
		if !isEdit && hwnd != this._outputEdit.Hwnd {
			return
		}
		
		VK_BACK   := 0x08
		VK_RETURN := 0x0D
		VK_ESCAPE := 0x1B
		VK_UP     := 0x26
		VK_DOWN   := 0x28
		
		switch wParam {
		case VK_ESCAPE:
			this._Escape()
		case VK_RETURN:
			if !isEdit {
				return
			}
			this._Execute()
		case VK_BACK:
			if not isEdit || not GetKeyState("LCtrl", "P") {
				return
			}
			
			if not value := this._consoleEdit.Value {
				return 0
			}
			
			EM_GETSEL := 0x00B0, EM_SETSEL := 0x00B1, EM_REPLACESEL := 0x00C2
			
			DllCall("SendMessageW", "Ptr", hwnd, "UInt", EM_GETSEL, "Int*", &selStart:=0, "Int*", &selEnd:=0)
			
			if selStart != selEnd { ; we have a selected area, so we will simply delete it and return
				SendMessage(EM_REPLACESEL, true, "", hwnd)
				return 0
			}
			
			if (caretPos := selStart) == 0 { ; caret is at the beginning
				return 0
			}
			
			if SubStr(value, caretPos, 1) != A_Space {
				caretDest := FindWhitespace(value, caretPos)
			} else {
				caretDest := FindWhitespace(value, FindNonWhitespace(value, caretPos))
			}
			
			SendMessage(EM_SETSEL, caretPos, caretDest, hwnd)
			SendMessage(EM_REPLACESEL, true, "", hwnd)
		case VK_UP:
			if !isEdit {
				return
			}
			this.History.Up(this._consoleEdit)
		case VK_DOWN:
			if !isEdit {
				return
			}
			this.History.Down(this._consoleEdit)
		default: return
		}
		
		return 0
		
		static FindNonWhitespace(value, currentPos) {
			loop {
				currentPos--
			} until currentPos < 1 || SubStr(value, currentPos, 1) != A_Space
			
			return currentPos
		}
		
		static FindWhitespace(value, currentPos) => InStr(value, A_Space, , currentPos-StrLen(value)-1)
	}
	
	static _OnSYSKEYDOWN(wParam, lParam, _, hwnd) {
		if (lParam & 0x20000000) == 0 { ; not an Alt event
			return
		}
		
		if not this._outputEdit.Visible
			|| hwnd != this._consoleEdit.Hwnd && hwnd != this._outputEdit.Hwnd {
			return
		}
		
		VK_UP   := 0x26
		VK_DOWN := 0x28
		
		scrollStep := 2
		
		switch wParam {
		case VK_UP:   count := -scrollStep
		case VK_DOWN: count := scrollStep
		default: return
		}
		
		this._LineScroll(count, this._outputEdit.Hwnd)
		return 0
	}
	
	static _OnMOUSEWHEEL(wParam, lParam, _, hwnd) {
		if hwnd != this._outputEdit.Hwnd || not this._outputEdit.Visible {
			return
		}
		
		if (hi := wParam >> 16) & 0x8000 {
			hi -= 0x10000
		}
		
		scrollStep := 2
		
		count := hi < 0 ? scrollStep : -scrollStep
		if wParam & 0x0004 { ; shifted
			count *= 5
		}
		
		this._LineScroll(count, hwnd)
		return 0
	}
	
	static _OnACTIVATE(wParam, lParam, msg, hwnd) {
		WA_INACTIVE := 0
		
		if hwnd != this._console.Hwnd || wParam != WA_INACTIVE {
			return
		}
		
		if this._isRunning { ; the focus was stolen by the executing command
			this._ClearConsole()
		}
		
		this._prevWinHwnd := 0
		this._console.Hide()
		return 0
	}
	
	static _OnINPUTLANGCHANGEREQUEST(wParam, lParam, msg, hwnd) {
		if hwnd == this._console.Hwnd {
			return DllCall("user32\DefWindowProc", "Ptr", hwnd, "UInt", msg, "Ptr", wParam, "Ptr", lParam)
		}
	}
	
	static _Escape() {
		this._ClearConsole()
		this._HideOutput()
		this._console.Hide()
		
		if this._prevWinHwnd {
			if WinExist(this._prevWinHwnd) {
				WinActivate(this._prevWinHwnd)
			}
			this._prevWinHwnd := 0
		}
		
		this.History.Reset()
	}
	
	static _Execute() {
		input := Trim(this._consoleEdit.Value)
		this._ClearConsole()
		
		if not input {
			return
		}
		
		this.History.Add(input)
		SplitInput(input, &command, &rawArgs)
		 
		this._SetOutputCaretIndex(0)
		this._WriteOutput(Format("> {}`n", input))
		
		; TODO: let's just hardcode it for now :)
		static separator := "--------------------------------------------------------------------------------`n"
		
		if not func := this._commands.Get(command) {
			this._WriteOutput(Format("Error: command '{}' not found.`n{}", command, separator))
			return
		}
		
		if not args := ParseArgs(rawArgs, &errorMessage) {
			this._WriteOutput(Format("Error: {}`n{}", errorMessage, separator))
			return
		}
		
		this._isRunning := true
		try {
			; TODO: pass the Output edit to handlers (a wrapper with limited functionality), letting them output
			; any text and any times during their execution.
			; Since it would expect the running handlers to take as long as they need, hide the caret and make
			; the Console edit 'ReadOnly' during their execution. (EM_SETREADONLY, Show/HideCaret)
			func.Call(args, this._prevWinHwnd, &output)
		} finally {
			this._isRunning := false
		}
		
		if IsSet(output) {
			this._WriteOutput(output "`n" separator)
		}
		
		return
		
		static SplitInput(input, &command, &rawArgs) {
			parts := StrSplit(input, A_Space, , 2)
			command := parts[1]
			rawArgs := parts.Length == 2 ? parts[2] : ""
		}
		
		static ParseArgs(args, &errorMessage) {
			if not len := StrLen(args) {
				return CommandRunner.ArgsIter([])
			}
			
			normalizedArgs := []
			
			isSQuoted := isDQuoted := false
			start := 1, i := 0

			while ++i <= len {
				switch SubStr(args, i, 1) {
				case '"':
					if not isDQuoted {
						if isSQuoted
							continue
						
						if start < i {
							AddArgument(normalizedArgs, SubStr(args, start, i-start))
						}
						
						isDQuoted := true
						start := i+1
						continue
					}
					
					isDQuoted := false
					
					if start == i {
						start++
						continue
					}
				
				case "'":
					if not isSQuoted {
						if isDQuoted
							continue
						
						if start < i {
							AddArgument(normalizedArgs, SubStr(args, start, i-start))
						}
						
						isSQuoted := true
						start := i+1
						continue
					}
					
					isSQuoted := false
					
					if start == i {
						start++
						continue
					}
					
				case A_Space:
					if isSQuoted || isDQuoted {
						if start == i { ; trim the beginning
							start++
						}
						continue
					}
					
					if start == i { ; trim the beginning
						start++
						continue
					}
				
				default: continue
				}
				
				AddArgument(normalizedArgs, RTrim(SubStr(args, start, i-start)))
				start := i+1
			}

			if isSQuoted || isDQuoted {
				errorMessage := "Missing closing quote."
				return ""
			}

			if start < i {
				AddArgument(normalizedArgs, SubStr(args, start))
			}
			
			return CommandRunner.ArgsIter(normalizedArgs)
			
			static AddArgument(list, arg) {
				if SubStr(arg, 1, 2) == "--" {
					HandleLong(list, arg)
				} else if SubStr(arg, 1, 1) == "-" {
					HandleShort(list, arg)
				} else {
					list.Push(Argument(arg))
				}
			}
			
			static HandleLong(list, arg) {
				if i := InStr(arg, "=") {
					AddCombinedKeyValue(arg, i, list)
				} else {
					list.Push(OptArgument(arg))
				}
			}
			
			static HandleShort(list, arg) {
				if i := InStr(arg, "=") {
					AddCombinedKeyValue(arg, i, list)
					return
				}
				if (len := StrLen(arg)) < 3 {
					list.Push(OptArgument(arg))
					return
				}
				i := 1
				while ++i <= len {
					list.Push(OptArgument("-" SubStr(arg, i, 1)))
				}
			}
			
			static AddCombinedKeyValue(list, arg, i) => list.Push(OptArgument(SubStr(arg, 1, i-1)), Argument(SubStr(arg, i+1)))
			
			static OptArgument(value) => CommandRunner.Argument(value, true)
			
			static Argument(value) => CommandRunner.Argument(value, false)
		}
	}
	
	static _ClearConsole() {
		; DllCall("HideCaret", "Ptr", this._consoleEdit.Hwnd)
		this._consoleEdit.Value := ""
		DllCall("UpdateWindow", "Ptr", this._consoleEdit.Hwnd)
		; DllCall("ShowCaret", "Ptr", this._consoleEdit.Hwnd)
	}
	
	static _HideOutput() {
		this._outputEdit.Visible := false
	}
	
	static _WriteOutput(output, silentMode := true) {
		this._SetTextAtCaretPosition(StrReplace(output, "`n", "`r`n"), this._outputEdit.Hwnd)
		 
		; We could reset the caret to index 0 to scroll the output up,
		; but if the output is hidden or need to be kept hidden — it wont scroll.
		this._LineScroll(-10000000, this._outputEdit.Hwnd)
		
		; TODO: once implement passing Output object (with .Write() and .WriteError() methods) to the callers, 
		; make the output edit appear only for the errors.
		; Also, let the callers decide whether to show the output edit for non-error messages
		; (eg: output.Write("message", silentMode: true)).
		if not silentMode {
			this._outputEdit.Visible := true
		}
	}
	
	static _LineScroll(count, hwnd) => SendMessage(0xB6, 0, count, hwnd) ; EM_LINESCROLL
	
	static _SetOutputCaretIndex(index) => this._SetCaretIndex(index, this._outputEdit.Hwnd)
	
	static _SetCaretIndex(index, hwnd) => SendMessage(0x1511, index, 0, hwnd) ; EM_SETCARETINDEX
	
	static _SetTextAtCaretPosition(text, hwnd, canUndo := false) =>
		DllCall("SendMessageW", "Ptr", hwnd, "UInt", 0xC2, "Int", canUndo, "Str", text) ; EM_REPLACESEL
	
	static _InitCommands() {
		this._commands.CaseSense := false
		this._commands.Set("this", this._HandleCommand.Bind(this))
		this._commands.Default := ""
	}
	
	/**
	 * @param {CommandRunner.ArgsIter} args
	 */
	static _HandleCommand(args, _, &output) {
		if not args.Next(&arg) || arg.Value == "-h" {
			output := GetUsage()
			return
		}
		
		switch command := arg.Value {
			case "ch":
				this.History.ClearHistory()
				output := "History cleared."
			
			case "co":
				this._outputEdit.Value := ""
				
			default:
				output := Format("Unknown command '{}'. {}", command, GetUsage())
		}
		
		return
		
		GetUsage() => "
		(
			Usage: this [OPTIONS] COMMAND
			
			Options:
			-h:  Get usage
			
			Commands:
			ch:  Clear history
			co:  Clear output
		)"
	}
	
	static _InitConsole() {
		console := this._console
		
		console.Opt("-Caption ToolWindow AlwaysOnTop")
		console.MarginX := console.MarginY := 0
		
		console.BackColor := "000000"
		WinSetTransColor(console.BackColor . " 250", console.Hwnd)
		
		console.SetFont("s18 c0xbdbdbd", "JetBrains Mono Regular")
		
		editOpts := Format("Background171717 -E0x200 Center Border w{} h{}", this._width, this._height)
		this._consoleEdit := console.AddEdit(editOpts)
		
		console.SetFont("s14") ; Output edit will inherit this size and use it to adjust its row count.
		
		editOpts := Format(
			"Background171717 -E0x200 y+{} wP R{} -VScroll ReadOnly Hidden Border",
			this._outputEditPaddY, this._outputRowCount)
		
		this._outputEdit := console.AddEdit(editOpts)
		
		x := this._xPos + Disposition.GetOffset(this._xDisposition, this._width)
		y := this._yPos + Disposition.GetOffset(this._yDisposition, this._height)
		
		console.Show(Format("Hide x{} y{}", x, y))
	}
	
	class ArgsIter {
		_args  := unset
		_index := 0
		
		__New(args) {
			if !(args is Array) {
				throw Error(Format("Invalid type for 'args'. Expected: 'Array'; got: '{}'.", Type(args)))
			}
			this._args := args
		}
		
		Next(&arg) {
			if this._index >= this._args.Length {
				arg := ""
				return false
			}
			
			arg := this._args[++this._index]
			return true
		}
		
		IsEmpty => this._args.Length == 0
	}
	
	class Argument {
		Value    := unset
		IsOption := unset
		
		__New(val, isOption) => (this.Value := val, this.IsOption := isOption)
	}
	
	class History {
		static _commands    := LinkedList()
		static _commandsMap := Map()
		
		/** 
		 * @type {LinkedListNode}
		 */
		static _current := ""
		static _maxSize := 32
		static _tempCommand := ""
		
		static __New() {
			this._commandsMap.Default := ""
		}
		
		/**
		 * @param {Gui.Edit} edit
		 */
		static Up(edit) {
			if this._commands.Size == 0 {
				return
			}
			
			if this._current == "" {
				SetLastAndDisplay(edit)
				return
			}
			
			if this.IsContentUpdated(edit) {
				this.Reset()
				SetLastAndDisplay(edit)
				return
			}
			
			if (prev := this._current.Prev) == "" {
				return
			}
			
			this.Display(edit, prev.Value)
			this._current := prev
			
			
			SetLastAndDisplay(edit) {
				this._current := this._commands.Last
				this._tempCommand := edit.Value ; don't trim
				this.Display(edit, this._current.Value)
			}
		}
		
		/**
		 * @param {Gui.Edit} edit 
		 */
		static Down(edit) {
			if this._commands.Size == 0 || this._current == "" {
				return
			} 
			
			if (next := this._current.Next) == "" {
				if not this.IsContentUpdated(edit) {
					this.Display(edit, this._tempCommand)
				}
				this.Reset()
				return
			}
			
			if this.IsContentUpdated(edit) {
				this.Reset()
				return
			}
			
			this.Display(edit, next.Value)
			this._current := next
		}
		
		static Add(command) {
			this.Reset()
			
			if node := this._commandsMap[command] {
				this._commands.MoveToEnd(node)
				return
			}
			
			if this._commands.Size == this._maxSize {
				this._commands.RemoveFirst(&deletedCommand)
				this._commandsMap.Delete(deletedCommand)
			}
			
			node := LinkedListNode(command)
			this._commandsMap.Set(node.Value, node)
			this._commands.AddLast(node)
		}
		
		static Reset() {
			this._current := ""
			this._tempCommand := ""
		}
		
		static ClearHistory() {
			this._commandsMap.Clear()
			this._commands.Clear()
		}
		
		static IsContentUpdated(edit) => this._current.Value != Trim(edit.Value)
		
		/**
		 * @param {Gui.Edit} edit
		 */
		static Display(edit, value) {
			edit.Value := value
			PostMessage(0x1511, StrLen(value), 0, edit.Hwnd) ; EM_SETCARETINDEX
		}
	}
}