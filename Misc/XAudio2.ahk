#DllLoad XAudio2_9.dll

class XAudio2 {
	static _ixAudio2 := unset
	
	static _chunks := Map()
	static _voices := []
	
	static __New() {
		this._ThrowIf(DllCall("XAudio2_9\XAudio2Create", "Ptr*", &IXAudio2:=0, "UInt", 0, "UInt", 1)) ; XAUDIO2_DEFAULT_PROCESSOR
		
		this._ThrowIf(ComCall(7, IXAudio2, ; IXAudio2::CreateMasteringVoice; (6 == AudioCategory_GameEffects, audiosessiontypes.h)
			"Ptr*", &_:=0, "UInt", 0, "UInt", 0, "UInt", 0, "Ptr", 0, "Ptr", 0, "Ptr", 6))
		
		this._ixAudio2 := IXAudio2
		this._chunks.Default := ""
	}
	
	static PlaySound(path, volume?) {
		this._CleanUp()
		
		if not chunk := this._chunks[path] {
			this._chunks[path] := chunk := this._ParseChunks(path)
		}
		
		; TODO: use WAVEFORMATEXTENSIBLE if Fmt.Size is > 16 bytes and wTagFormat != WAVE_FORMAT_PCM ???
		
		this._ThrowIf(ComCall(5, this._ixAudio2, ; IXAudio2::CreateSourceVoice
			"Ptr*", &IXAudio2SourceVoice:=0, "Ptr", chunk.FmtPtr, "UInt", 0, "Float", 2.0, "Ptr", 0, "Ptr", 0, "Ptr", 0))
		
		if IsSet(volume) {
			this._ThrowIf(ComCall(12, IXAudio2SourceVoice, "Float", volume, "UInt", 0)) ; IXAudio2Voice::SetVolume
		}
		
		XAUDIO2_BUFFER := Buffer(48, 0)
		NumPut("UInt", 0x40, "UInt", chunk.DataSize, "Ptr", chunk.DataPtr, XAUDIO2_BUFFER) ; XAUDIO2_END_OF_STREAM
		
		this._ThrowIf(ComCall(21, IXAudio2SourceVoice, "Ptr", XAUDIO2_BUFFER, "Ptr", 0)) ; IXAudio2SourceVoice::SubmitSourceBuffer
		this._ThrowIf(ComCall(19, IXAudio2SourceVoice, "UInt", 0, "UInt", 0)) ; IXAudio2SourceVoice::Start
		
		this._voices.Push(IXAudio2SourceVoice)
	}
	
	static _CleanUp() {
		Critical()
		
		XAUDIO2_VOICE_STATE := Buffer(24)
		indicesToDelete := []
		voices := this._voices
		
		for i, voice in voices {
			ComCall(25, voice, "Ptr", XAUDIO2_VOICE_STATE, "UInt", 0) ; IXAudio2SourceVoice::GetState
			if not NumGet(XAUDIO2_VOICE_STATE, 8, "UInt") { ; BuffersQueued
				indicesToDelete.Push(i)
			}
		}
		
		i := indicesToDelete.Length + 1
		
		while --i >= 1 { ; reversed loop
			index := indicesToDelete[i]
			ComCall(18, voices[index]) ; IXAudio2Voice::DestroyVoice
			
			voices[index] := voices[-1]
			voices.Pop()
		}
		
		Critical("Off")
	}
	
	static _ParseChunks(path) {
		buff := FileRead(path, "RAW")
		chunk := this.ChunkTable(buff)
		offset := 0
		
		; RIFF fileSize fileType ("fmt " chunkSize <data> "data" chunkSize <data>)
		
		while offset < buff.Size {
			type := StrGet(buff.Ptr+offset, 4, "CP0")
			size := NumGet(buff, offset+4, "UInt")
			offset += 8
			
			switch type {
			case "RIFF":
				fileType := StrGet(buff.Ptr+offset, 4, "CP0")
				if fileType != "WAVE" {
					throw Error(Format("Unsupported file type '{}'.", fileType))
				}
				offset += 4
				continue
			case "fmt ": chunk._fmt  := this.Chunk(offset, size)
			case "data": chunk._data := this.Chunk(offset, size)
			}
			
			offset += size
		}
		
		; Dummy validation to verify that all 3 chunks are present and processed.
		; It will throw if any of these members aren't yet set.
		_ := StrLen(fileType) + chunk._fmt.Offset + chunk._data.Offset
		
		return chunk
	}
	
	static _ThrowIf(errorCode) {
		switch errorCode {
		case 0: return
		case 0x88960001: ; XAUDIO2_E_INVALID_CALL
			throw Error("Invalid call.")
		case 0x88960002: ; XAUDIO2_E_XMA_DECODER_ERROR
			throw Error("The Xbox 360 XMA hardware suffered an unrecoverable error.")
		case 0x88960003: ; XAUDIO2_E_XAPO_CREATION_FAILED
			throw Error("An effect failed to instantiate.")
		case 0x88960004: ; XAUDIO2_E_DEVICE_INVALIDATED
			throw Error("An audio device became unusable through being unplugged or some other event.")
		default: throw OSError(errorCode)
		}
	}
	
	class ChunkTable {
		/**
		 * @type {XAudio2.Chunk}
		 */
		_fmt := unset
		/**
		 * @type {XAudio2.Chunk}
		 */
		_data := unset
		/**
		 * @type {Buffer}
		 */
		_buffer := unset
		
		__New(buff) => this._buffer := buff
		
		FmtPtr  => this._buffer.Ptr + this._fmt.Offset
		DataPtr => this._buffer.Ptr + this._data.Offset
		
		DataSize => this._data.Size
	}
	
	class Chunk {
		__New(offset, size) => (this.Offset := offset, this.Size := size)
	}
}