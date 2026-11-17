extends Node

## Handles scene transitions with a fade-to-black overlay.

signal scene_changed

var _overlay: ColorRect
var _tween: Tween
var _next_scene_path: String = ""

const FADE_DURATION: float = 0.5


func _ready() -> void:
	# Create a full-screen overlay for fade transitions.
	_overlay = ColorRect.new()
	_overlay.color = Color.BLACK
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Cover the entire viewport.
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.modulate.a = 0.0
	# Make sure overlay is always on top.
	var canvas_layer := CanvasLayer.new()
	canvas_layer.layer = 100
	canvas_layer.add_child(_overlay)
	add_child(canvas_layer)


func change_scene(scene_path: String) -> void:
	_next_scene_path = scene_path

	# Fade out (overlay becomes opaque).
	if _tween and _tween.is_running():
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(_overlay, "modulate:a", 1.0, FADE_DURATION)
	_tween.tween_callback(_on_fade_out_finished)


func _on_fade_out_finished() -> void:
	get_tree().change_scene_to_file(_next_scene_path)

	# Fade in (overlay becomes transparent).
	_tween = create_tween()
	_tween.tween_property(_overlay, "modulate:a", 0.0, FADE_DURATION)
	_tween.tween_callback(_on_fade_in_finished)


func _on_fade_in_finished() -> void:
	scene_changed.emit()
