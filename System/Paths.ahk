class Paths {
	
	static Desktop   := A_Desktop
	static User      := "C:\Users\" A_UserName
	static Study     := this.User "\OneDrive\Study"
	static Torrent   := "D:\Torrent"
	static Radeon    := "D:\Radeon ReLive\unknown"
	static ScriptDir := A_ScriptDir
	
	static ProgramFiles := A_ProgramFiles
	
	static Projects        := "D:\Projects"
	static ProjectsCSharp  := this.Projects "\CSharp"
	static ProjectsRust    := this.Projects "\Rust"
	static RustTestProject := this.ProjectsRust "\test_proj"
	
	static Qmk          := this.User "\qmk_firmware"
	static QmkKeyboards := this.Qmk "\keyboards"
	static QmkUsers     := this.Qmk "\users"
	static QmkKbI44     := this.QmkKeyboards "\ergohaven\imperial44"
	static QmkKbK02     := this.QmkKeyboards "\ergohaven\k02"
	static QmkUsersMe   := this.QmkUsers "\schmidt-x"
	
	static AppData  := this.User "\AppData"
	static Local    := this.AppData "\Local"
	static LocalLow := this.AppData "\LocalLow"
	static Roaming  := this.AppData "\Roaming" ; A_AppData
	
	static LocalPrograms := this.Local "\Programs"
	
	static VsCodeUser := this.Roaming "\Code\User"
	static AhkLib     := A_MyDocuments "\AutoHotkey\Lib"
	
	
	static _paths := Map()
	
	static __New() {
		this._paths.Set(
			"desk",        this.Desktop,
			"std",         this.Study,
			"torr",        this.Torrent,
			"radeon",      this.Radeon,
			"proj",        this.Projects,
			"proj/c#",     this.ProjectsCSharp,
			"proj/r",      this.ProjectsRust,
			"proj/r/test", this.RustTestProject,
			"qmk",         this.Qmk,
			"qmk/i44",     this.QmkKbI44,
			"qmk/k02",     this.QmkKbK02,
			"qmk/usr",     this.QmkUsers,
			"qmk/usr/me",  this.QmkUsersMe,
			"ahk/i44",     this.ScriptDir,
			"ahk/lib",     this.AhkLib,
			"me",          this.User,
			"code/usr",    this.VsCodeUser,
			
			"test.ahk",    this._FilePath(this.Desktop "\test.ahk")
		)
		
		this._paths.Default := ""
	}
	
	/**
	 * Attempts to find a path by its alias.
	 * @param {String} alias
	 * File/folder's alias
	 * @param {&String} path
	 * Path to a file/folder is assigned on `return` (if found)
	 * @param {&Boolean} isFile
	 * Indicates whether the path is a file or a folder (if found)
	 * @returns {Boolean}
	 * `True` if path is found; `False` otherwise
	 */
	static TryGetAliased(alias, &path, &isFile) {
		path := isFile := ""
		
		if not value := this._paths[alias] {
			return false
		}
		
		if value is Paths._FilePath {
			path := value.Path
			isFile := true
		} else {
			path := value
			isFile := false
		}
		
		return true
	}
	
	
	/**
	 * Attempts to find a path of a selected tab in File Explorer
	 * @param {&String} path
	 * Path to the selected tab is assigned on `return` (if found)
	 * @param {Integer} hwnd
	 * Handle of the File Explorer's window to search on. <br>
	 * If `hwnd` is not provided, the current active window is considered
	 * @param {Boolean} clsid
	 * Defines whether to return the path if it's CLSID path
	 * @returns {Boolean}
	 * `True` if path is found; `False` otherwise
	 */
	static TryGet(&path, hwnd := 0, clsid := false) {
		path := ""
		
		if not hwnd {
			hwnd := WinActive("A")
		}
		
		if WinGetProcessName(hwnd) !== "explorer.exe" {
			return false
		}
		
		if hwnd == DllCall("GetShellWindow") {
			path := this.Desktop
			return true
		}
		
		; get WinTitle and remove the suffix
		title := RegExReplace(WinGetTitle(hwnd), " (?:and [0-9]+ more tabs? )?- File Explorer$")
		
		for window in ComObject("Shell.Application").Windows {
			if window.hwnd != hwnd || window.Document.Folder.Self.Name != title {
				continue
			}
			
			p := window.Document.Folder.Self.Path
		
			if !clsid && SubStr(p, 1, 2) == "::" {
				return false
			}
		
			path := p
			return true
		}
		
		return false
	}
	
	/**
	 * Retrieves path(s) of selected file(s)/folder(s) in File Explorer
	 * @param {&Error} err
	 * `Error` is assigned if no file/folder were selected
	 * @returns {Array}
	 * Paths to selected file(s)/folder(s)
	 */
	static GetSelected(&err) {
		prevClip := ClipboardAll()
		A_Clipboard := ""
		SendInput("+^c")
		
		if not ClipWait(0.5) {
			err := Error("No file/folder were selected.")
			paths := ""
		} else {
			err := ""
			paths := StrSplit(A_Clipboard, "`r`n")
		}
		
		A_Clipboard := prevClip
		return paths
	}
	
	class _FilePath {
		__New(path) => this.Path := path
	}
}