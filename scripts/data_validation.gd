extends RefCounted
## Shared primitive validation, independent of gameplay catalogs.
static func number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))
static func vector(value: Variant, length: int) -> bool:
	return value is Array and value.size()==length and value.all(func(n): return number(n))
static func unknown_fields(value: Dictionary, allowed: Array, prefix: String, errors: PackedStringArray) -> void:
	for field in value:
		if field not in allowed: errors.append(prefix+"unexpected field "+str(field))

static func nested_fields(value: Variant, allowed: Array, prefix: String, errors: PackedStringArray) -> void:
	if value is Dictionary: unknown_fields(value,allowed,prefix,errors)
	elif value is Array:
		for entry in value:
			if entry is Dictionary: unknown_fields(entry,allowed,prefix,errors)
