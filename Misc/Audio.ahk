class DeviceType { ; EDataFlow
	static Render  => 0
	static Capture => 1
	static All     => 2
}

class DeviceState {
	static Active     => 0x01 ; DEVICE_STATE_ACTIVE
	static Disabled   => 0x02 ; DEVICE_STATE_DISABLED
	static NotPresent => 0x04 ; DEVICE_STATE_NOTPRESENT
	static Unplugged  => 0x08 ; DEVICE_STATE_UNPLUGGED
	static All => this.Active | this.Disabled | this.NotPresent | this.Unplugged ; DEVICE_STATEMASK_ALL
}

class Audio {
	
	; #region Device

	static SetMute(deviceName, mute, &err, dType := DeviceType.All, dState := DeviceState.Active) {
		if iMMDevice := this._FindDevice(deviceName, dType, dState) {
			err := ""
			this._SetMuteInternal(mute, iMMDevice)
		} else {
			err := this._GetDeviceNotFoundError(deviceName)
		}
	}

	static GetMute(deviceName, &err, dType := DeviceType.All, dState := DeviceState.Active) {
		if iMMDevice := this._FindDevice(deviceName, dType, dState) {
			err := ""
			return this._GetMuteInternal(iMMDevice)
		} else {
			err := this._GetDeviceNotFoundError(deviceName)
			return ""
		}
	}
	
	static SetMuteDefault(mute, dType) => this._SetMuteInternal(mute, this._GetDefaultDevice(dType))
	
	static GetMuteDefault(dType) => this._GetMuteInternal(this._GetDefaultDevice(dType))
	
	static _SetMuteInternal(mute, iMMDevice) {
		this._ThrowHR(iMMDevice.Activate_IAudioEndpointVolume(&iAudioEndpointVolume))
		this._ThrowHR(iAudioEndpointVolume.SetMute(mute))
	}
	
	static _GetMuteInternal(iMMDevice) {
		this._ThrowHR(iMMDevice.Activate_IAudioEndpointVolume(&iAudioEndpointVolume))
		this._ThrowHR(iAudioEndpointVolume.GetMute(&mute))
		return mute
	}
	
	static ToggleMute(deviceName, &err, dType := DeviceType.All, dState := DeviceState.Active) {
		if iMMDevice := this._FindDevice(deviceName, dType, dState) {
			err := ""
			return this._ToggleMuteInternal(iMMDevice)
		} else {
			err := this._GetDeviceNotFoundError(deviceName)
			return ""
		}
	}
	
	static ToggleMuteDefault(dType) => this._ToggleMuteInternal(this._GetDefaultDevice(dType))
	
	static _ToggleMuteInternal(iMMDevice) {
		this._ThrowHR(iMMDevice.Activate_IAudioEndpointVolume(&iAudioEndpointVolume))
		this._ThrowHR(iAudioEndpointVolume.GetMute(&mute))
		this._ThrowHR(iAudioEndpointVolume.SetMute(newState := !mute))
		return newState
	}
	
	static SetVolume(deviceName, volume, &err, dType := DeviceType.All, dState := DeviceState.Active) {
		if iMMDevice := this._FindDevice(deviceName, dType, dState) {
			err := ""
			this._SetVolumeInternal(volume, iMMDevice)
		} else {
			err := this._GetDeviceNotFoundError(deviceName)
		}
	}
	
	static GetVolume(deviceName, &err, dType := DeviceType.All, dState := DeviceState.Active) {
		if iMMDevice := this._FindDevice(deviceName, dType, dState) {
			err := ""
			return this._GetVolumeInternal(iMMDevice)
		} else {
			err := this._GetDeviceNotFoundError(deviceName)
			return ""
		}
	}
	
	static SetVolumeDefault(volume, dType) => this._SetVolumeInternal(volume, this._GetDefaultDevice(dType))
	
	static GetVolumeDefault(dType) => this._GetVolumeInternal(this._GetDefaultDevice(dType))
	
	static _SetVolumeInternal(volume, iMMDevice) {
		this._ThrowHR(iMMDevice.Activate_IAudioEndpointVolume(&iAudioEndpointVolume))
		this._ThrowHR(iAudioEndpointVolume.SetMasterVolumeLevelScalar(this._VolumeTo(volume)))
	}
	
	static _GetVolumeInternal(iMMDevice) {
		this._ThrowHR(iMMDevice.Activate_IAudioEndpointVolume(&iAudioEndpointVolume))
		this._ThrowHR(iAudioEndpointVolume.GetMasterVolumeLevelScalar(&volume))
		return this._VolumeFrom(volume)
	}
	
	static VolumeStepUp(deviceName, &err, dType := DeviceType.All, dState := DeviceState.Active) {
		if iMMDevice := this._FindDevice(deviceName, dType, dState) {
			err := ""
			this._VolumeStepUpInternal(iMMDevice)
		} else {
			err := this._GetDeviceNotFoundError(deviceName)
		}
	}
	
	static VolumeStepDown(deviceName, &err, dType := DeviceType.All, dState := DeviceState.Active) {
		if iMMDevice := this._FindDevice(deviceName, dType, dState) {
			err := ""
			this._VolumeStepDownInternal(iMMDevice)
		} else {
			err := this._GetDeviceNotFoundError(deviceName)
		}
	}
	
	static VolumeStepUpDefault(dType) => this._VolumeStepUpInternal(this._GetDefaultDevice(dType))
	
	static VolumeStepDownDefault(dType) => this._VolumeStepDownInternal(this._GetDefaultDevice(dType))
	
	static _VolumeStepUpInternal(iMMDevice) {
		this._ThrowHR(iMMDevice.Activate_IAudioEndpointVolume(&iAudioEndpointVolume))
		this._ThrowHR(iAudioEndpointVolume.VolumeStepUp())
	}
	
	static _VolumeStepDownInternal(iMMDevice) {
		this._ThrowHR(iMMDevice.Activate_IAudioEndpointVolume(&iAudioEndpointVolume))
		this._ThrowHR(iAudioEndpointVolume.VolumeStepDown())
	}
	
	; #endregion

	; #region Session
	
	static SetAppMute(appName, mute, &err) {
		for s in this._ListSessionsDefault(DeviceType.Render) {
			if s.AppName = appName {
				(err := "", s.SetMute(mute))
				return
			}
		}
		
		err := this._GetAppNotFoundError(appName)
	}
	
	static GetAppMute(appName, &err) {
		for s in this._ListSessionsDefault(DeviceType.Render) {
			if s.AppName = appName {
				err := ""
				return s.GetMute()
			}
		}
		
		err := this._GetAppNotFoundError(appName)
		return ""
	}
	
	static ToggleAppMute(appName, &err) {
		for s in this._ListSessionsDefault(DeviceType.Render) {
			if s.AppName = appName {
				err := ""
				return s.ToggleMute()
			}
		}
		
		err := this._GetAppNotFoundError(appName)
		return ""
	}
	
	static SetAppVolume(appName, volume, &err) {
		for s in this._ListSessionsDefault(DeviceType.Render) {
			if s.AppName = appName {
				(err := "", s.SetVolume(volume))
				return
			}
		}
		
		err := this._GetAppNotFoundError(appName)
	}
	
	static GetAppVolume(appName, &err) {
		for s in this._ListSessionsDefault(DeviceType.Render) {
			if s.AppName = appName {
				err := ""
				return s.GetVolume()
			}
		}
		
		err := this._GetAppNotFoundError(appName)
		return ""
	}
	
	; #endregion

	/**
	 * @returns {Audio.Device | String} 
	 */
	static FindDevice(deviceName, dType := DeviceType.All, dState := DeviceState.Active) {
		if not iMMDevice := this._FindDevice(deviceName, dType, dState) {
			return ""
		}
		
		this._ThrowHR(iMMDevice.OpenPropertyStore(&iPropertyStore))
		this._ThrowHR(iPropertyStore.GetValue_PKEY_Device_FriendlyName(&friendlyName))
		this._ThrowHR(iMMDevice.QueryInterface_IMMEndpoint(&iMMEndpoint))
		this._ThrowHR(iMMDevice.GetState(&dState))
		
		if dType == DeviceType.All {
			this._ThrowHR(iMMEndpoint.GetDataFlow(&dType))
		}
		
		return Audio.Device(friendlyName, dType, dState, iMMDevice)
	}
	
	/**
	 * @returns {Audio.Device} 
	 */
	static GetDefaultDevice(dType) {
		iMMDevice := this._GetDefaultDevice(dType)
		this._ThrowHR(iMMDevice.OpenPropertyStore(&iPropertyStore))
		this._ThrowHR(iPropertyStore.GetValue_PKEY_Device_FriendlyName(&friendlyName))
		
		return Audio.Device(friendlyName, dType, DeviceState.Active, iMMDevice)
	}
	
	/**
	 * @returns {Array<Audio.Device>} 
	 */
	static GetDevices(dType := DeviceType.All, dState := DeviceState.Active) {
		if dType < DeviceType.Render || dType > DeviceType.All {
			throw ValueError("'dType' is invalid")
		}
		
		if (dState & ~DeviceState.All) != 0 {
			throw ValueError("'dState' has invalid flag(s)")
		}
		
		iMMDeviceEnumerator := this._IMMDeviceEnumerator()
		this._ThrowHR(iMMDeviceEnumerator.EnumAudioEndpoints(dType, dState, &iMMDeviceCollection))
		this._ThrowHR(iMMDeviceCollection.GetCount(&deviceCount))
		
		list := []
		list.Capacity := deviceCount
		
		loop deviceCount {
			this._ThrowHR(iMMDeviceCollection.Item(A_Index - 1, &iMMDevice))
			
			this._ThrowHR(iMMDevice.OpenPropertyStore(&iPropertyStore))
			this._ThrowHR(iPropertyStore.GetValue_PKEY_Device_FriendlyName(&friendlyName))
			
			this._ThrowHR(iMMDevice.GetState(&dState))
			
			this._ThrowHR(iMMDevice.QueryInterface_IMMEndpoint(&iMMEndpoint))
			this._ThrowHR(iMMEndpoint.GetDataFlow(&dType))
			
			list.Push(Audio.Device(friendlyName, dType, dState, iMMDevice))
		}
		
		return list
	}
	
	/**
	 * @returns {Array<Audio.App>} 
	 */
	static _ListSessionsDefault(dType) => this._ListSessions(this._GetDefaultDevice(dType))

	/**
	 * @returns {Array<Audio.App>} 
	 */
	static _ListSessions(iMMDevice) {
		this._ThrowHR(iMMDevice.Activate_IAudioSessionManager2(&iAudioSessionManager2))
		this._ThrowHR(iAudioSessionManager2.GetSessionEnumerator(&iAudioSessionEnumerator))
		this._ThrowHR(iAudioSessionEnumerator.GetCount(&sessionCount))
		
		m := Map(), m.Capacity := sessionCount, m.Default := ""
		foundSystemSounds := false
		
		loop sessionCount {
			this._ThrowHR(iAudioSessionEnumerator.GetSession(A_Index - 1, &iAudioSessionControl))
			this._ThrowHR(iAudioSessionControl.QueryInterface_IAudioSessionControl2(&iAudioSessionControl2))
			
			if not foundSystemSounds {
				this._ThrowHR(hr := iAudioSessionControl2.IsSystemSoundsSession())
				if !hr {
					isSystemSounds := foundSystemSounds := true
					sessionName := "SystemSounds"
					goto push_value
				}
			}
			
			isSystemSounds := false
			
			this._ThrowHR(iAudioSessionControl2.GetProcessId(&pid))
			if not pid {
				throw Error("ProcessId == 0")
			}
			
			try {
				SplitPath(ProcessGetName(pid),,,, &sessionName)
			} catch {
				this._ThrowHR(iAudioSessionControl.GetDisplayName(&sessionName))
			}
			
		push_value: 
			this._ThrowHR(iAudioSessionControl.QueryInterface_ISimpleAudioVolume(&iSimpleAudioVolume))
			
			if s := m[sessionName] {
				s._Push(iSimpleAudioVolume)
			} else {
				m[sessionName] := Audio.App(sessionName, iSimpleAudioVolume, isSystemSounds)
			}
		}
		
		sessions := [], sessions.Capacity := m.Count
		for _, s in m {
			sessions.Push(s)
		}
		
		return sessions
	}
	
	/**
	 * @returns {Audio._IMMDevice} 
	 */
	static _GetDefaultDevice(dType) {
		if dType != DeviceType.Render && dType != DeviceType.Capture {
			throw ValueError("Argument 'dType' is invalid")
		}
		
		this._ThrowHR(Audio._IMMDeviceEnumerator().GetDefaultAudioEndpoint(dType, 0, &iMMDevice))
		return iMMDevice
	}

	/**
	 * @returns {Audio._IMMDevice | String} 
	 */
	static _FindDevice(deviceName, dType, dState) {
		if dType < DeviceType.Render || dType > DeviceType.All {
			throw ValueError("'dType' is invalid")
		}
		
		if (dState & ~DeviceState.All) != 0 {
			throw ValueError("'dState' has invalid flag(s)")
		}
		
		iMMDeviceEnumerator := this._IMMDeviceEnumerator()
		this._ThrowHR(iMMDeviceEnumerator.EnumAudioEndpoints(dType, dState, &iMMDeviceCollection))
		this._ThrowHR(iMMDeviceCollection.GetCount(&deviceCount))
		
		loop deviceCount {
			this._ThrowHR(iMMDeviceCollection.Item(A_Index - 1, &iMMDevice))
			this._ThrowHR(iMMDevice.OpenPropertyStore(&iPropertyStore))
			this._ThrowHR(iPropertyStore.GetValue_PKEY_Device_FriendlyName(&friendlyName))
			
			if deviceName = friendlyName {
				return iMMDevice
			}
		}
		
		return ""
	}

	static _MakeGuid(a, b, c, d) {
		buff := Buffer(16)
		
		NumPut(
			"UInt", a, "UShort", b, "UShort", c,
			"UChar", d >> 7*8 & 0xFF, "UChar", d >> 6*8 & 0xFF, "UChar", d >> 5*8 & 0xFF,
			"UChar", d >> 4*8 & 0xFF, "UChar", d >> 3*8 & 0xFF, "UChar", d >> 2*8 & 0xFF,
			"UChar", d >>   8 & 0xFF, "UChar", d        & 0xFF,
			buff)
		
		return buff
	}

	static _ThrowHR(hr) {
		if hr < 0 {
			throw OSError(hr)
		}
	}
	
	static _GetDeviceNotFoundError(deviceName) => ValueError(Format("Device endpoint '{}' not found", deviceName), -1)
	static _GetAppNotFoundError(appName) => ValueError(Format("App '{}' not found", appName), -1)
	
	static _VolumeFrom(volume) => Round(volume * 100)
	static _VolumeTo(volume) => Max(0, Min(1, Round(volume / 100, 2)))

	class Device {
		__New(deviceName, deviceType, deviceState, iMMDevice) {
			this.DeviceName := deviceName
			this.DeviceType := deviceType
			this.DeviceState := deviceState
			
			Audio._ThrowHR(iMMDevice.Activate_IAudioEndpointVolume(&iAudioEndpointVolume))
			/**
			 * @type {Audio._IAudioEndpointVolume}
			 */
			this._iAudioEndpointVolume := iAudioEndpointVolume
			/**
			 * @type {Audio._IMMDevice}
			 */
			this._iMMDevice := iMMDevice
		}
		
		SetVolume(volume) =>
			Audio._ThrowHR(this._iAudioEndpointVolume.SetMasterVolumeLevelScalar(Audio._VolumeTo(volume)))
			
		GetVolume() =>
			(Audio._ThrowHR(this._iAudioEndpointVolume.GetMasterVolumeLevelScalar(&volume)), Audio._VolumeFrom(volume))
		
		SetMute(mute) => Audio._ThrowHR(this._iAudioEndpointVolume.SetMute(mute))
		
		GetMute() => (Audio._ThrowHR(this._iAudioEndpointVolume.GetMute(&mute)), mute)
		
		ToggleMute() {
			Audio._ThrowHR(this._iAudioEndpointVolume.GetMute(&mute))
			Audio._ThrowHR(this._iAudioEndpointVolume.SetMute(newState := !mute))
			return newState
		}
		
		/**
		 * @returns {Array<Audio.App>} 
		 */
		GetApps() => Audio._ListSessions(this._iMMDevice)
		
		/**
		 * @returns {Audio.App | String} 
		 */
		FindApp(appName) {
			for s in Audio._ListSessions(this._iMMDevice) {
				if s.AppName = appName {
					return s
				}
			}
			return ""
		}
	}
	
	class App {
		__New(appName, iSimpleAudioVolume, isSystemSounds) {
			this.AppName := appName
			this.IsSystemSounds := isSystemSounds
			
			/**
			 * @type {Audio._ISimpleAudioVolume}
			 */
			this._iSimpleAudioVolume := iSimpleAudioVolume
			
			/**
			 * Some applications (e.g. Discord) may expose multiple audio sessions. These will be treated
			 * as a single logical application session:
			 * - SetMute and SetVolume affect all sessions.
			 * - GetMute returns `true` only if all sessions are muted.
			 * - GetVolume returns the volume of the first session.
			 * @type {Array<Audio._ISimpleAudioVolume>}
			 */
			this._volumes := ""
		}
		
		_Push(iSimpleAudioVolume) {
			if this._volumes {
				this._volumes.Push(iSimpleAudioVolume)
			} else {
				this._volumes := [ iSimpleAudioVolume ]
			}
		}
		
		SetVolume(volume) {
			Audio._ThrowHR(this._iSimpleAudioVolume.SetMasterVolume(volume := Audio._VolumeTo(volume)))
			
			if this._volumes {
				for v in this._volumes {
					Audio._ThrowHR(v.SetMasterVolume(volume))
				}
			}
		}
		
		GetVolume() => (Audio._ThrowHR(this._iSimpleAudioVolume.GetMasterVolume(&volume)), Audio._VolumeFrom(volume))
		
		SetMute(mute) {
			Audio._ThrowHR(this._iSimpleAudioVolume.SetMute(mute))
			
			if this._volumes {
				for v in this._volumes {
					Audio._ThrowHR(v.SetMute(mute))
				}
			}
		}
		
		GetMute() {
			if not (Audio._ThrowHR(this._iSimpleAudioVolume.GetMute(&mute)), mute) {
				return false
			}
			
			if this._volumes
				for v in this._volumes
					if not (Audio._ThrowHR(v.GetMute(&mute)), mute)
						return false
			
			return true
		}
		
		ToggleMute() {
			Audio._ThrowHR(this._iSimpleAudioVolume.GetMute(&mute))
			Audio._ThrowHR(this._iSimpleAudioVolume.SetMute(newState := !mute))
			
			if this._volumes {
				for v in this._volumes {
					Audio._ThrowHR(v.SetMute(newState))
				}
			}
			
			return newState
		}
	}
	
	; #region Interfaces
	
	class _IMMDeviceEnumerator {
		__New() {
			CLSID_MMDeviceEnumerator := "{BCDE0395-E52F-467C-8E3D-C4579291692E}"
			IID_IMMDeviceEnumerator  := "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
			
			this.Value := ComObject(CLSID_MMDeviceEnumerator, IID_IMMDeviceEnumerator)
		}
		
		/**
		 * @param {VarRef<Audio._IMMDeviceCollection>} iMMDeviceCollection 
		 */
		EnumAudioEndpoints(dType, dState, &iMMDeviceCollection) {
			hr := ComCall(3, this.Value, "Int", dType, "UInt", dState, "Ptr*", &iMMDeviceCollection:=0)
			if hr == 0 {
				iMMDeviceCollection := Audio._IMMDeviceCollection(iMMDeviceCollection)
			}
			
			return hr
		}
		
		/**
		 * @param {VarRef<Audio._IMMDevice>} iMMDevice 
		 */
		GetDefaultAudioEndpoint(dType, dRole, &iMMDevice) {
			hr := ComCall(4, this.Value, "UInt", dType, "UInt", dRole, "Ptr*", &iMMDevice:=0)
			if hr == 0 {
				iMMDevice := Audio._IMMDevice(iMMDevice)
			}
			
			return hr
		}
	}

	class _IMMDeviceCollection {
		__New(iMMDeviceCollection) => this.Value := ComValue(13, iMMDeviceCollection)
		
		GetCount(&deviceCount) => ComCall(3, this.Value, "UInt*", &deviceCount:=0)
		
		/**
		 * @param {VarRef<Audio._IMMDevice>} iMMDevice 
		 */
		Item(index, &iMMDevice) {
			hr := ComCall(4, this.Value, "UInt", index, "Ptr*", &iMMDevice:=0)
			if hr == 0 {
				iMMDevice := Audio._IMMDevice(iMMDevice)
			}
			
			return hr
		}
	}
	
	class _IMMDevice {
		__New(iMMDevice) => this.Value := ComValue(13, iMMDevice)
		
		/**
		 * @param {VarRef<Audio._IMMEndpoint>} iMMEndpoint 
		 */
		QueryInterface_IMMEndpoint(&iMMEndpoint) {
			IID_IMMEndpoint := Audio._MakeGuid(0x1BE09788, 0x6894, 0x4089, 0x85869A2A6C265AC5)
			
			hr := ComCall(0, this.Value, "Ptr", IID_IMMEndpoint, "Ptr*", &iMMEndpoint:=0)
			if hr == 0 {
				iMMEndpoint := Audio._IMMEndpoint(iMMEndpoint)
			}
			
			return hr
		}
		
		/**
		 * @param {VarRef<Audio._IAudioEndpointVolume>} iAudioEndpointVolume 
		 */
		Activate_IAudioEndpointVolume(&iAudioEndpointVolume) {
			IID_IAudioEndpointVolume := Audio._MakeGuid(0x5CDF2C82, 0x841E, 0x4546, 0x97220CF74078229A)
			
			hr := ComCall(3, this.Value,
				"Ptr", IID_IAudioEndpointVolume, "UInt", CLSCTX_ALL := 23, "Ptr", 0, "Ptr*", &iAudioEndpointVolume:=0)
			
			if hr == 0 {
				iAudioEndpointVolume := Audio._IAudioEndpointVolume(iAudioEndpointVolume)
			}
			
			return hr
		}
		
		/**
		 * @param {VarRef<Audio._IAudioSessionManager2>} iAudioSessionManager2 
		 */
		Activate_IAudioSessionManager2(&iAudioSessionManager2) {
			IID_IAudioSessionManager2 := Audio._MakeGuid(0x77AA99A0, 0x1BD6, 0x484F, 0x8BC72C654C9A9B6F)
			
			hr := ComCall(3, this.Value,
				"Ptr", IID_IAudioSessionManager2, "UInt", CLSCTX_ALL := 23, "Ptr", 0, "Ptr*", &iAudioSessionManager2:=0)
				
			if hr == 0 {
				iAudioSessionManager2 := Audio._IAudioSessionManager2(iAudioSessionManager2)
			}
			
			return hr
		}
		
		/**
		 * @param {VarRef<Audio._IPropertyStore>} iPropertyStore
		 */
		OpenPropertyStore(&iPropertyStore) {
			hr := ComCall(4, this.Value, "UInt", STGM_READ := 0x00, "Ptr*", &iPropertyStore:=0)
			if hr == 0 {
				iPropertyStore := Audio._IPropertyStore(iPropertyStore)
			}
			return hr
		}
		
		GetState(&dState) => ComCall(6, this.Value, "Int*", &dState:=0)
	}
	
	class _IMMEndpoint {
		__New(iMMEndpoint) => this.Value := ComValue(13, iMMEndpoint)
		
		GetDataFlow(&dataFlow) => ComCall(3, this.Value, "Int*", &dataFlow:=0)
	}
	
	class _IPropertyStore {
		__New(iPropertyStore) => this.Value := ComValue(13, iPropertyStore)
		
		GetValue_PKEY_Device_FriendlyName(&friendlyName) {
			propertyKey := Get_PKEY_Device_FriendlyName()
			propVariant := Buffer(16)
			
			hr := ComCall(5, this.Value, "Ptr", propertyKey, "Ptr", propVariant)
			
			if hr != 0 && hr != 0x000401A0 { ; INPLACE_S_TRUNCATED
				friendlyName := ""
				return hr
			}
			
			if NumGet(propVariant, "UShort") != 31 { ;  vt != VT_LPWSTR
				throw OSError("Empty FriendlyName ???")
			}
			
			friendlyName := StrGet(NumGet(propVariant, 8, "Ptr"), , "UTF-16")
			Audio._ThrowHR(DllCall("Ole32\PropVariantClear", "Ptr", propVariant))
			
			return 0
			
			static Get_PKEY_Device_FriendlyName() {
				buff := Buffer(20)
				
				NumPut(
					"UInt",  0xA45C254E, "UShort", 0xDF1C, "UShort", 0x4EFD,
					"UChar", 0x80,       "UChar",  0x20,   "UChar",  0x67,   "UChar", 0xD1,
					"UChar", 0x46,       "UChar",  0xA8,   "UChar",  0x50,   "UChar", 0xE0,
					"UInt",  14, buff)
					
				return buff
			}
		}
	}
	
	class _IAudioEndpointVolume {
		__New(iAudioEndpointVolume) => this.Value := ComValue(13, iAudioEndpointVolume)
		
		SetMasterVolumeLevelScalar(volume) => ComCall(7, this.Value, "Float", volume, "Ptr", 0)
		GetMasterVolumeLevelScalar(&volume) => ComCall(9, this.Value, "Float*", &volume:=0)
		
		SetMute(mute) => ComCall(14, this.Value, "Int", mute, "Ptr", 0)
		GetMute(&mute) => ComCall(15, this.Value, "Int*", &mute:=0)
		
		VolumeStepUp() => ComCall(17, this.Value, "Ptr", 0)
		VolumeStepDown() => ComCall(18, this.Value, "Ptr", 0)
	}
	
	class _IAudioSessionManager2 {
		__New(iAudioSessionManager2) => this.Value := ComValue(13, iAudioSessionManager2)
		
		/**
		 * @param {VarRef<Audio._IAudioSessionEnumerator>} iAudioSessionEnumerator 
		 */
		GetSessionEnumerator(&iAudioSessionEnumerator) {
			hr := ComCall(5, this.Value, "Ptr*", &iAudioSessionEnumerator:=0)
			if hr == 0 {
				iAudioSessionEnumerator := Audio._IAudioSessionEnumerator(iAudioSessionEnumerator)
			}
			return hr
		}
	}
	
	class _IAudioSessionEnumerator {
		__New(iAudioSessionEnumerator) => this.Value := ComValue(13, iAudioSessionEnumerator)
		
		GetCount(&sessionCount) => ComCall(3, this.Value, "Int*", &sessionCount:=0)
		
		/**
		 * @param {VarRef<Audio._IAudioSessionControl>} iAudioSessionControl 
		 */
		GetSession(index, &iAudioSessionControl) {
			hr := ComCall(4, this.Value, "Int", index, "Ptr*", &iAudioSessionControl:=0)
			if hr == 0 {
				iAudioSessionControl := Audio._IAudioSessionControl(iAudioSessionControl)
			}
			return hr
		}
	}
	
	class _IAudioSessionControl {
		__New(iAudioSessionControl) => this.Value := ComValue(13, iAudioSessionControl)
		
		/**
		 * @param {VarRef<Audio._IAudioSessionControl2>} iAudioSessionControl2 
		 */
		QueryInterface_IAudioSessionControl2(&iAudioSessionControl2) {
			IID_IAudioSessionControl2 := Audio._MakeGuid(0xbfb7ff88, 0x7239, 0x4fc9, 0x8fa207c950be9c6d)
			
			hr := ComCall(0, this.Value, "Ptr", IID_IAudioSessionControl2, "Ptr*", &iAudioSessionControl2:=0)
			if hr == 0 {
				iAudioSessionControl2 := Audio._IAudioSessionControl2(iAudioSessionControl2)
			}
			
			return hr
		}
		
		/**
		 * @param {VarRef<Audio._ISimpleAudioVolume>} iSimpleAudioVolume 
		 */
		QueryInterface_ISimpleAudioVolume(&iSimpleAudioVolume) {
			IID_ISimpleAudioVolume := Audio._MakeGuid(0x87CE5498, 0x68D6, 0x44E5, 0x92156DA47EF883D8)
			
			hr := ComCall(0, this.Value, "Ptr", IID_ISimpleAudioVolume, "Ptr*", &iSimpleAudioVolume:=0)
			if hr == 0 {
				iSimpleAudioVolume := Audio._ISimpleAudioVolume(iSimpleAudioVolume)
			}
			
			return hr
		}
		
		GetDisplayName(&displayName) {
			hr := ComCall(4, this.Value, "Ptr*", &pDisplayName:=0)
			if hr == 0 {
				displayName := StrGet(pDisplayName, , "UTF-16")
				DllCall("Ole32\CoTaskMemFree", "Ptr", pDisplayName)
			}
			return hr
		}
	}
	
	class _IAudioSessionControl2 {
		__New(iAudioSessionControl2) => this.Value := ComValue(13, iAudioSessionControl2)
		
		; Fix: AUDCLNT_S_NO_SINGLE_PROCESS = 0x0889000D
		GetProcessId(&pid) => ComCall(14, this.Value, "UInt*", &pid:=0)
		IsSystemSoundsSession() => ComCall(15, this.Value)
	}
	
	class _ISimpleAudioVolume {
		__New(iSimpleAudioVolume) => this.Value := ComValue(13, iSimpleAudioVolume)
		
		SetMasterVolume(volume) => ComCall(3, this.Value, "Float", volume, "Ptr", 0)
		GetMasterVolume(&volume) => ComCall(4, this.Value, "Float*", &volume:=0)
		SetMute(mute) => ComCall(5, this.Value, "Int", mute, "Ptr", 0)
		GetMute(&mute) => ComCall(6, this.Value, "Int*", &mute:=0)
	}
	
	; #endregion
}