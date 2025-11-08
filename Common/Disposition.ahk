class Disposition {
	static None     => 0
	static Centered => 1
	static Inverted => 2
	
	; TODO: add docs
	static GetOffset(d, wh) {
		switch d {
		case Disposition.Inverted: 
			return -wh
		case Disposition.Centered, Disposition.Centered | Disposition.Inverted: 
			return -(wh/2)
		default:
			return 0
		}
	}
}