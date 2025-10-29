#Include <System\Paths>
#Include <Misc\CommandRunner>

class QmkMSys {
	static _fullProcessName         := "C:\QMK_MSYS\conemu\ConEmu64.exe"
	static _fullProcessNameWithArgs := this._fullProcessName ' -NoSingle -NoUpdate -icon "C:\QMK_MSYS\icon.ico" -title "QMK MSYS" -run "C:\QMK_MSYS\usr\bin\bash.exe" -l -i -cur_console:m:""'
	
	static __New() {
		CommandRunner.AddCommands("msys", this.Open.Bind(this))
	}
	
	static Open(args, hwnd, &output) {
		if not args.Next(&arg) {
			Run(this._fullProcessNameWithArgs, Paths.Qmk)
			return
		}
		
		switch value := arg.Value {
			case ".":
				if not Paths.TryGet(&path, hwnd) {
					output := "Path not found."
				} else {
					Run(this._fullProcessNameWithArgs, path)
				}
			default:
				if not Paths.TryGetAliased(value, &path, &isFile) {
					output := Format("Folder '{}' not found.", value)
				} else if isFile {
					output := "Files are not supported."
				} else {
					Run(this._fullProcessNameWithArgs, path)
				}
		}
	}
}