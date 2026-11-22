extends RefCounted
## Shared core/body color keeps the active beam and its stage2 particle edge identical.
static func core_color(base: Color,active: bool) -> Color:
	return base.lightened(0.75 if active else 0.25)
