#Include <System\Paths>
#Include <Misc\CommandRunner>

class QmkMSys {
	static _fullProcessName         := "C:\QMK_MSYS\conemu\ConEmu64.exe"
	static _fullProcessNameWithArgs := this._fullProcessName ' -NoSingle -NoUpdate -icon "C:\QMK_MSYS\icon.ico" -title "QMK MSYS" -run "C:\QMK_MSYS\usr\bin\bash.exe" -l -i -cur_console:m:""'
	
	static __New() {
		CommandRunner.AddCommands("msys", this._HandleCommand.Bind(this))
	}
	
	/**
	 * @param {CommandRunner.ArgsIter} args 
	 * @param {CommandRunner.Output} output
	 */
	static _HandleCommand(args, hwnd, output) {
		if not args.Next(&arg) {
			Run(this._fullProcessNameWithArgs, Paths.Qmk)
			output.WriteSilent(Format('Opening default location "{}".', Paths.Qmk))
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
			Run(this._fullProcessNameWithArgs, path)
			output.WriteSilent(Format('Opening folder "{}".', path))
		}
	}
}