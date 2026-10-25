class_name PirateRandom
extends RefCounted
## VB6-compatible 24-bit Rnd() generator. The original never invokes Randomize.
## Arithmetic verified against Microsoft.VisualBasic.VBMath (rtRandomNext equivalent).
static var state: int = 0x50000
static func next_value() -> float:
	state = (state*0x43FD43FD+0xC39EC3)&0xFFFFFF
	return float(state)/16777216.0
static func between(low: int, high: int) -> int:
	return low+int(floorf(next_value()*(high-low+1)))
