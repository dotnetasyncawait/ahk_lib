#Include <Misc\CommandRunner>
#Include <Common\Disposition>

class ModeType {
	static None   := 0
	static Normal := 1
	static Insert := 2
	static Symbol := 4
	static Mouse  := 8
	static Select := 16
}

class Mode {
	static _current := 0
	
	static _display := Gui()
	static _enabled := false
	
	/**
	 * @type {Gui.Control}
	 */
	static _displayText := unset
	
	static _xDisposition := Disposition.None
	static _yDisposition := Disposition.Inverted
	
	static _xPos := 0
	static _yPos := A_ScreenHeight - 50
	
	static _width  := 90
	static _height := 27
	
	
	static IsNormal  => this._current == ModeType.Normal
	static IsInsert  => this._current == ModeType.Insert
	static IsMouse   => this._current == ModeType.Mouse
	static IsSelect  => this._current == ModeType.Select
	static IsNSymbol => this._current == ModeType.Normal | ModeType.Symbol
	static IsISymbol => this._current == ModeType.Insert | ModeType.Symbol
	static IsSSymbol => this._current == ModeType.Select | ModeType.Symbol
	
	static __New() {
		this._InitDisplay()
		CommandRunner.AddCommands("mode", this._HandleCommand.Bind(this))
	}
	
	
	static Show() {
		this._enabled := true
		this._display.Show("NoActivate")
	}
	
	static Hide() {
		this._enabled := false
		this._display.Hide()
	}
	
	static ToggleDisplay() {
		if this._enabled {
			this.Hide()
		} else {
			this.Show()
		}
	}
	
	static Move(
		x := this._xPos,
		y := this._yPos, 
		width := this._width, 
		height := this._height,
		xDisposition := this._xDisposition,
		yDisposition := this._yDisposition) 
	{
		this._display.Move(
			x + Disposition.GetShift(xDisposition, width),
			y + Disposition.GetShift(yDisposition, height),
			width,
			height)

		this._displayText.Move(, , width, height)
		
		this._xPos := x
		this._yPos := y
		this._width := width
		this._height := height
		this._xDisposition := xDisposition
		this._yDisposition := yDisposition
		
		this._displayText.Redraw()
	}
	
	static SetNormal() => this._SetMode(ModeType.Normal)
	static SetInsert() => this._SetMode(ModeType.Insert)
	static SetMouse()  => this._SetMode(ModeType.Mouse)
	static SetSelect() => this._SetMode(ModeType.Select)
	static SetNone()   => this._SetMode(ModeType.None)
	
	static AddSymbol() => this._AddMode(ModeType.Symbol)
	static DelSymbol() => this._DelMode(ModeType.Symbol)
	
	static SetDefault() => this.SetNormal()
	
	
	; --- private ---
	
	/** 
	 * @param {CommandRunner.ArgsIter} args
	 */
	static _HandleCommand(args, _, &output) {
		if not args.Next(&arg) || arg.Value == "-h" {
			output := GetUsage()
			return
		}
		
		switch command := arg.Value {
			case "tg": this.ToggleDisplay()
			default:
				output := Format("Unknown command '{}'. {}", command, GetUsage())
		}
		
		
		GetUsage() => "
		(
			Usage: mode [OPTIONS] COMMAND
			
			Options:
			-h:  Print usage
			
			Commands:
			tg:  Toggle window's visibility
		)"
	}
	
	static _InitDisplay() {
		this._display.Opt("AlwaysOnTop -Caption ToolWindow")
		this._display.MarginX := this._display.MarginY := 0
		
		this._display.BackColor := "000000" ; any color (since we're gonna make it transparent)
		WinSetTransColor(this._display.BackColor " 240", this._display.Hwnd)
		this._display.SetFont("s16 c0x5c5c5c", "JetBrains Mono Regular")
		
		textOpts := Format("Background171717 w{1} h{2} Center", this._width, this._height)
		this._displayText := this._display.AddText(textOpts)
		
		this._display.Show("Hide")
		
		this._display.Move(
			this._xPos + Disposition.GetShift(this._xDisposition, this._width),
			this._yPos + Disposition.GetShift(this._yDisposition, this._height)
		)
		
		this.SetDefault()
	}
	
	static _SetMode(mode) {
		if this._current == mode {
			return
		}
		
		this._current := mode
		this._DisplayCurrentMode()
	}
	
	static _AddMode(mode) {
		if this._current & mode {
			return
		}
		
		this._current |= mode
		this._DisplayCurrentMode()
	}
	
	static _DelMode(mode) {
		if not (this._current & mode) {
			return
		}
		
		this._current &= ~mode
		this._DisplayCurrentMode()
	}
	
	static _DisplayCurrentMode() {
		switch this._current {
			case ModeType.Normal: this._DisplayMode("Normal")
			case ModeType.Insert: this._DisplayMode("Insert")
			case ModeType.Mouse:  this._DisplayMode("Mouse")
			case ModeType.Select: this._DisplayMode("Select")
			case ModeType.None:   this._DisplayMode("None")
			case ModeType.Normal | ModeType.Symbol: this._DisplayMode("N_Symb")
			case ModeType.Insert | ModeType.Symbol: this._DisplayMode("I_Symb")
			case ModeType.Select | ModeType.Symbol: this._DisplayMode("S_Symb")
			default: this._DisplayMode("Undef")
		}
	}
	
	static _DisplayMode(mode) {
		this._displayText.Value := mode
	}
	
}