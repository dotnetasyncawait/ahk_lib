/**
 * Wrapper around `Shell_NotifyIconW` (`Shell32.dll`).
 * Each `TrayIcon` instance represents a single physical tray icon and allows managing multiple visual variants.
 * 
 * Usage:
 * ```ahk
 * #Requires AutoHotkey v2.0
 * #Include <TrayIcon>
 * 
 * gIcon := "green.ico"
 * gIconTip := "I am a green icon"
 * 
 * rIcon := "red.ico"
 * rIconTip := "I am a red icon"
 * 
 * icon := TrayIcon(42) ; icon id
 *   .Add(gIcon, gIconTip) ; index 0
 *   .Add(rIcon, rIconTip) ; index 1
 *   .OnLeftClick(LClickCallback)
 *   .OnRightClick(RClickCallback)
 *   .OnDoubleClick(DClickCallback)
 * 
 * F1:: { ; cycle through icon variants
 *   static index := 0
 *   icon.Display(index)
 *   if ++index >= icon.Count {
 *     index := 0
 *   }
 * }
 * F2::icon.Hide()
 * F3::icon.Show()
 * F4::ToolTip("Icon is toggled " (icon.ToggleVisibility() ? "on." : "off."))
 * 
 * LClickCallback(iconIndex, iconId) {
 *   ToolTip(Format("Left-click on icon: {} (TrayIcon: {})", iconIndex, iconId))
 * }
 * 
 * RClickCallback(iconIndex, iconId) {
 *   ToolTip(Format("Right-click on icon: {} (TrayIcon: {})", iconIndex, iconId))
 * }
 * 
 * DClickCallback(iconIndex, iconId) {
 *   ToolTip(Format("Double-click on icon: {} (TrayIcon: {})", iconIndex, iconId))
 * }
 * ```
 */
class TrayIcon {
	_size  := 976
	_nid   := Buffer(this._size, 0)
	_icons := []
	
	_visible := false
	_iconIndex := -1
	
	_id := _msg := _hwnd := unset
	
	_OnLClick := ""
	_OnRClick := ""
	_OnDClick := ""
	_onMessageInitialized := false
	
	Count => this._icons.Length
	IsVisible => this._visible
	
	__New(id, hwnd := A_ScriptHwnd, msg := 0x04FF) {
		NumPut(
			"UInt",  this._size,  ; cbSize
			"UInt",  0,           ; padd
			"Ptr",   hwnd,        ; hWnd
			"UInt",  id,          ; uID
			"UInt",  0x01 | 0x08, ; uFlags (NIF_MESSAGE | NIF_STATE)
			"UInt",  msg,         ; uCallbackMessage (default: WM_USER + 0xFF)
			this._nid)
		
		NumPut(
			"UInt", 1, ; dwState (NIS_HIDDEN)
			"UInt", 1, ; dwStateMask (NIS_HIDDEN)
			this._nid, 296)
			
		if not DllCall("Shell32\Shell_NotifyIconW", "UInt", 0, "Ptr", this._nid) { ; NIM_ADD
			throw OSError()
		}
		
		this._id := id, this._msg := msg, this._hwnd := hwnd
	}
	
	__Delete() {
		if this._nid {
			_ := DllCall("Shell32\Shell_NotifyIconW", "UInt", 2, "Ptr", this._nid) ; NIM_DELETE
		}
		
		if icons := this._icons {
			for icon in icons {
				_ := DllCall("DestroyIcon", "Ptr", icon.HIcon)
			}
		}
	}
	
	/**
	 * Adds an icon variant to the tray icon instance.
	 * This method does not create multiple tray icons; it registers an additional variant under
	 * the same physical tray icon, and only one variant can be active at a time.
	 * Each call assigns the variant the next sequential index (starting from 0).
	 * Use `Display(index)` to switch which variant is currently displayed.
	 * @param {String | TrayIcon.HICON} icon
	 * Icon to add.
	 * When a `String` is provided, it is interpreted as a filesystem path to a `.ico` file.
	 * When a `TrayIcon.HICON` wrapper is provided, it is treated as a raw `HICON` value manually 
	 * loaded by the caller. Note that in this case, no validity checks are performed on the handle.
	 * @param {String} tipText
	 * Text shown when the cursor hovers over the tray icon. Automatically truncated to
	 * a maximum of 127 characters.
	 * @returns {TrayIcon} 
	 */
	Add(icon, tipText) {
		this._icons.Push(TrayIcon._Item(TrayIcon._GetIcon(icon), SubStr(tipText, 1, 127)))
		return this
	}
	
	; #region Display
	
	/**
	 * Displays the icon variant at the specified index.
	 * @param {Integer} index Index of the icon variant to display (0-based).
	 */
	Display(index) {
		if index == this._iconIndex { ; -1 case :)
			this.Show()
			return
		}
		
		uFlags := 0x02 | 0x04 | (this._visible ? 0 : 0x08) ; NIF_ICON | NIF_TIP | NIF_STATE
		
		this._NotifyIcon(this._GetItem(index), uFlags, 1, false) ; NIM_MODIFY
		this._visible := true
		this._iconIndex := index
	}
	
	/**
	 * Shows the icon.
	 */
	Show() {
		if not this._visible {
			this.ToggleVisibility()
		}
	}
	
	/**
	 * Hides the icon.
	 */
	Hide() {
		if this._visible {
			this.ToggleVisibility()
		}
	}
	
	/**
	 * Toggles the icon's visibility.
	 * @returns {Boolean} New visibility state. `True` if visible, `False` otherwise.
	 */
	ToggleVisibility() {
		this._NotifyIcon("", 0x08, 1, this._visible) ; 'item' is ignored; NIF_STATE
		return this._visible ^= 1
	}
	
	/**
	 * Updates the icon (and optionally its tip text) at the specified index.
	 * @param {Integer} index
	 * Index of the icon variant to update (0-based).
	 * @param {String | TrayIcon.HICON} icon
	 * New icon to replace the existing one.
	 * When a `String` is provided, it is interpreted as a filesystem path to a `.ico` file.
	 * When a `TrayIcon.HICON` wrapper is provided, it is treated as a raw `HICON` value manually 
	 * loaded by the caller. Note that in this case, no validity checks are performed on the handle.
	 * @param {String?} tipText
	 * New tip text to display on mouse hover. Automatically truncated to a maximum of 127 characters.
	 * Optional.
	 */
	Update(index, icon, tipText?) {
		item := this._GetItem(index)
		
		uFlags := 0x02 ; NIF_ICON
		hOldIcon := item.HIcon
		item.HIcon := TrayIcon._GetIcon(icon)
		
		if IsSet(tipText) {
			uFlags |= 0x04 ; NIF_TIP
			item.TipText := SubStr(tipText, 1, 127)
		}
		
		try {
			if index == this._iconIndex {
				this._NotifyIcon(item, uFlags, 1) ; NIM_MODIFY
			}
		} finally {
			if not DllCall("DestroyIcon", "Ptr", hOldIcon) {
				throw OSError()
			}
		}
	}
	
	/**
	 * Updates the tip text of an icon at the specified index.
	 * @param {Integer} index
	 * Index of the icon variant whose tip text is to be updated (0-based).
	 * @param {String} tipText
	 * New tip text to display on mouse hover. Automatically truncated to a maximum of 127 characters.
	 */
	UpdateTip(index, tipText) {
		item := this._GetItem(index)
		item.TipText := SubStr(tipText, 1, 127)
		
		if index == this._iconIndex {
			this._NotifyIcon(item, 0x04, 1) ; NIF_TIP, NIM_MODIFY
		}
	}
	
	; #endregion
	
	; #region Events
	
	/**
	 * Registers a callback to execute when the tray icon receives a left-click event.
	 * @param {(Int: iconIndex, Int: iconId) => Integer} callback 
	 * @returns {TrayIcon}
	 */
	OnLeftClick(callback) {
		this._OnLClick := TrayIcon._ValidateCallback(callback, 2, "Int: iconIndex, Int: iconId")
		this._InitOnMessage()
		return this
	}
	
	/**
	 * Registers a callback to execute when the tray icon receives a right-click event.
	 * @param {(Int: iconIndex, Int: iconId) => Integer} callback 
	 * @returns {TrayIcon}
	 */
	OnRightClick(callback) {
		this._OnRClick := TrayIcon._ValidateCallback(callback, 2, "Int: iconIndex, Int: iconId")
		this._InitOnMessage()
		return this
	}
	
	/**
	 * Registers a callback to execute when the tray icon receives a left-double-click event.
	 * @param {(Int: iconIndex, Int: iconId) => Integer} callback 
	 * @returns {TrayIcon} 
	 */
	OnDoubleClick(callback) {
		this._OnDClick := TrayIcon._ValidateCallback(callback, 2, "Int: iconIndex, Int: iconId")
		this._InitOnMessage()
		return this
	}
	
	static _ValidateCallback(callback, paramCount, signature) {
		if not HasMethod(callback, , paramCount) {
			throw ValueError(Format("Callback must be a function of signature: Callback({});", signature))
		}
		return callback
	}
	
	_InitOnMessage() {
		if this._onMessageInitialized {
			return
		}
		OnMessage(this._msg, this._MessageHandler.Bind(this))
		this._onMessageInitialized := true
	}
	
	_MessageHandler(wParam, lParam, _, hwnd) {
		if wParam != this._id || hwnd != this._hwnd {
			return
		}
		
		fn := ""
		
		switch lParam {
		; case 0x0200: ; WM_MOUSEMOVE
		; Does this event make sense if no x and y coordinates are provided?
		; TODO: switch to NOTIFYICON_VERSION_4
		
		; Since both mouse-click events (Down and Up) are fired on button release (one after another),
		; we will ignore the latter ones (ie, Up-events).
		
		case 0x0201: ; WM_LBUTTONDOWN (WM_LBUTTONUP is deliberately ignored)
			fn := this._OnLClick
		case 0x0203: ; WM_LBUTTONDBLCLK
			fn := this._OnDClick
		case 0x0204: ; WM_RBUTTONDOWN (WM_RBUTTONUP is deliberately ignored)
			fn := this._OnRClick
		}
		
		if fn {
			return fn(this._iconIndex, this._id)
		}
	}
	
	; #endregion
	
	; #region Private
	
	_NotifyIcon(item, uFlags, dwMessage, hide := false) {
		; if uFlags & 0x01 { ; NIF_MESSAGE
			; Skipped intentionally. 
			; Value uCallbackMessage is set only once, in the constructor.
		; }
		
		if uFlags & 0x02 { ; NIF_ICON
			NumPut("Ptr", item.HIcon, this._nid, 32) ; hIcon
		}
		
		if uFlags & 0x04 { ; NIF_TIP
			StrPut(item.TipText, this._nid.Ptr+40) ; szTip (should be trimmed to 127 characters during .Add or .Update)
		}
		
		if uFlags & 0x08 { ; NIF_STATE
			NumPut(
				"UInt", hide & 1, ; dwState (only NIS_HIDDEN is considered)
				"UInt", 1,        ; dwStateMask (ignore NIS_SHAREDICON)
				this._nid, 296)
		}
		
		; TODO: implement notifications?
		
		NumPut("UInt", uFlags, this._nid, 20) ; uFlags
		
		if not DllCall("Shell32\Shell_NotifyIconW", "UInt", dwMessage, "Ptr", this._nid) {
			throw OSError()
		}
	}
	
	_GetItem(index) {
		if index < 0 || index >= this._icons.Length { ; 'index' is 0 based
			throw IndexError()
		}
		return this._icons[index+1]
	}
	
	static _GetIcon(icon) {
		switch Type(icon) {
			case "String":         return this._LoadIcon(icon)
			case "TrayIcon.HICON": return icon.Value
			default: throw TypeError("Argument 'icon' must be either String or TrayIcon.HICON.")
		}
	}
	
	static _LoadIcon(icon) {
		hIcon := DllCall("LoadImageW",
			"Ptr",  0,    ; hInst
			"Str",  icon, ; name
			"UInt", 1,    ; type (IMAGE_ICON)
			"Int",  0,    ; cx
			"Int",  0,    ; cy
			"UInt", 0x10 | 0x40) ; fuLoad (LR_LOADFROMFILE | LR_DEFAULTSIZE)
		
		if not hIcon {
			throw OSError()
		}
		
		return hIcon
	}
	
	; #endregion

	/**
	 * Dummy wrapper for passing a raw handle to an icon.
	 */
	class HICON {
		__New(hIcon) => this.Value := hIcon
	}

	class _Item {
		__New(hIcon, tipText) => (this.HIcon := hIcon, this.TipText := tipText)
	}
	
	/* struct NOTIFYICONDATAW
			"UInt" cbSize            ; 0   (+4)
			"UInt" padd              ; 4   (+4)
			"Ptr"  hWnd              ; 8   (+8)
			"UInt" uID               ; 16  (+4)
			"UInt" uFlags            ; 20  (+4)
			"UInt" uCallbackMessage  ; 24  (+4)
			"UInt" padd              ; 28  (+4)
			"Ptr"  hIcon             ; 32  (+8)
			"Str"  szTip[128]        ; 40  (+256)
			"UInt" dwState           ; 296 (+4)
			"UInt" dwStateMask       ; 300 (+4)
			"Str"  szInfo[256]       ; 304 (+512)
			"UInt" uTimeout|uVersion ; 816 (+4)
			"Str"  szInfoTitle[64]   ; 820 (+128)
			"UInt" dwInfoFlags       ; 948 (+4)
			"Guid" guidItem          ; 952 (+16)
			"Ptr"  hBalloonIcon      ; 968 (+8) -> 976
	*/
}