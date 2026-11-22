extends RefCounted
## Thin solid telegraphs and visual width envelopes. No particle spawning or simulation changes.
const Style=preload("res://scripts/beam_style.gd")
const Beams=preload("res://scripts/beam_attack.gd")
static func draw(canvas: Node2D,segments: Array) -> void:
	for beam in segments:
		if not Beams.alive(beam):continue
		var color: Color=beam.color
		if not beam.damaging:
			canvas.draw_line(beam.origin,beam.end,Color(color,0.7),beam.visual_width,true)
		else:
			canvas.draw_line(beam.origin,beam.end,Style.core_color(color,true),beam.visual_width,true)
			canvas.draw_line(beam.origin,beam.end,Style.core_color(color,true).lightened(0.65),minf(1.5,beam.visual_width),true)
