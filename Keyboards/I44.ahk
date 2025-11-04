#Include <RawHID\HidDevices>
#Include <RawHID\HidDevice>
#Include <Common\Stopwatch>
#Include <Keyboards\HidConstants>

class I44 {
	static _vendorID  := 0xFEED
	static _productID := 0x03
	
	static _usagePage := 0xFF60
	static _usageID   := 0x61
	
	/**
	 * @type {HidDeviceInfo}
	 */
	static _deviceInfo := unset
	
	static __New() {
		deviceInfo := HidDevices.Find(this._vendorID, this._productID, this._usagePage, this._usageID, &err)
		if err {
			throw err
		}
		
		this._deviceInfo := deviceInfo
	}
	
	static _NORMAL := 1 << 0
	static _INSERT := 1 << 1
	static _SELECT := 1 << 2
	static _SYMBOL := 1 << 3
	static _U_SYMB := 1 << 4
	static _MOUSE  := 1 << 5
	static _SYSTEM := 1 << 6
	
	static NewDevice() => HidDevice(this._deviceInfo)
	
	static EnableAhk(&err) => this.NewDevice().Write([HID_AHK, 1], &err)
	
	static DisableAhk(&err) => this.NewDevice().Write([HID_AHK, 0], &err)
	
	static SetMouseLayer(&err) => this.SetLayer(this._MOUSE, &err)
	
	static SetLayer(layerMask, &err) => this.NewDevice().Write([HID_SET_LAYER, layerMask >> 8, layerMask], &err)
	
	static Default(&err, device?) => (device ?? this.NewDevice()).Write([HID_DEFAULT], &err)
	
	/**
	 * Checks if a keyboard is resposive and measures the ReadWrite time by simply sending `HID_PING`
	 * output (with the current time) to the keyboard and waiting for the response.
	 * @param {&Integer} ms On success, the measured time (in milliseconds) is stored. -1 otherwise.
	 * @param {&Integer} ms On success, the measured time (in microseconds) is stored. -1 otherwise.
	 * @returns {Boolean} `True` if the keyboard is responsive. `False` if not or timed out.
	 */
	static Ping(&ms, &us) {
		ms := -1
		us := -1
		
		sw := Stopwatch.StartNew()
		device := this.NewDevice()
		
		device.Open(&err)
		if err {
			return false
		}
		
		try {
			timeParts := StrSplit(FormatTime(, "hh tt"), A_Space)
			
			hours   := timeParts[1]
			minutes := A_Min
			seconds := A_Sec
			isPM    := timeParts[2] == "PM"
			
			device.Write([HID_PING, hours, minutes, seconds, isPM], &err)
			if err {
				return false
			}
			
			_ := device.Read(200, &err)
			if err {
				return false
			}
		} finally device.Close()
		
		sw.Stop()
		ms := sw.ElapsedMilliseconds
		us := sw.ElapsedMicroseconds
		return true
	}
}