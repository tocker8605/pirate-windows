extends RefCounted
const Stages=preload("res://scripts/stage_catalog.gd")
static func stage_count(boss_rush: bool = false) -> int:return Stages.count(boss_rush)
static func music(stage: int) -> String:return Stages.definition(stage).music
