extends RefCounted
## Preserve render order while selecting each non-smoke batch only once.
enum Layer { ALL=0, SMOKE=1, GENERAL=2, BEAM_FOREGROUND=3 }
static func shows_smoke(layer: int) -> bool:return layer in [Layer.ALL,Layer.SMOKE]
static func select_non_smoke(particles: Array,layer: int) -> Array:
	var result: Array=[]
	for part in particles:
		if part.smoke or layer==Layer.SMOKE:continue
		var beam: bool=part.get("enemy_beam_effect",false)
		if layer==Layer.GENERAL and beam:continue
		if layer==Layer.BEAM_FOREGROUND and not beam:continue
		result.append(part)
	return result
