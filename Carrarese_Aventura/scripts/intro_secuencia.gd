extends Control

@onready var station_view: Control = $StationView
@onready var map_view: Control = $MapView
@onready var fade_rect: ColorRect = $FadeRect

# Station nodes
@onready var protagonist_sprite: AnimatedSprite2D = $StationView/Protagonist
@onready var station_label: Label = $StationView/SignContainer/StationLabel
@onready var station_sublabel: Label = $StationView/NarrativePanel/NarrativeLabel

# Map nodes
@onready var map_route: Line2D = $MapView/RouteLine
@onready var train_icon: Sprite2D = $MapView/TrainIcon
@onready var map_narrative_label: Label = $MapView/NarrativePanel/NarrativeLabel

var is_transitioning: bool = false

# Sounds
var sfx_door: AudioStream = preload("res://assets/audio/sfx/door.wav")
var sfx_horn: AudioStream = preload("res://assets/audio/sfx/train_ambient.wav")
var sfx_step: AudioStream = preload("res://assets/audio/sfx/step.wav")
var music_intro: AudioStream = preload("res://assets/audio/music/menu_theme.wav")

func _ready() -> void:
	station_view.visible = true
	map_view.visible = false
	fade_rect.modulate.a = 1.0 # Start black, fade in
	if AudioManager and music_intro:
		AudioManager.play_music(music_intro)
	
	_start_intro()

func _input(event: InputEvent) -> void:
	# Press Space, Enter, or Click to skip intro directly to train
	if event.is_action_pressed("jump") or event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE)):
		_skip_to_game()
	elif event is InputEventMouseButton and event.pressed:
		_skip_to_game()

func _start_intro() -> void:
	# 1. Fade in on station
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 0.0, 0.8)
	await tw.finished

	# 2. Protagonist walks towards the train door
	if protagonist_sprite and protagonist_sprite.sprite_frames:
		protagonist_sprite.play("walk")
	
	# Footsteps sound timer
	var step_tween = create_tween().set_loops(10)
	step_tween.tween_callback(func():
		if AudioManager and sfx_step:
			AudioManager.play_sfx(sfx_step)
	).set_delay(0.35)

	# Walk across platform to train door at x=380
	var walk_tw = create_tween()
	walk_tw.tween_property(protagonist_sprite, "position:x", 380.0, 3.8)
	await walk_tw.finished
	step_tween.kill()

	if is_transitioning:
		return

	# 3. Arrived at train door: boarding sequence
	if protagonist_sprite:
		protagonist_sprite.play("idle")
	station_sublabel.text = "¡El Hincha del Carrarese sube al tren con destino a La Spezia!"
	
	if AudioManager and sfx_door:
		AudioManager.play_sfx(sfx_door)
	
	await get_tree().create_timer(0.6).timeout
	if is_transitioning:
		return

	# Fade protagonist into train door
	var board_tw = create_tween()
	board_tw.tween_property(protagonist_sprite, "modulate:a", 0.0, 0.6)
	board_tw.parallel().tween_property(protagonist_sprite, "position:y", protagonist_sprite.position.y - 15.0, 0.6)
	await board_tw.finished

	if AudioManager and sfx_horn:
		AudioManager.play_sfx(sfx_horn)

	await get_tree().create_timer(0.4).timeout
	if is_transitioning:
		return

	# 4. Transition to Map of Italy
	var fade_tw = create_tween()
	fade_tw.tween_property(fade_rect, "modulate:a", 1.0, 0.6)
	await fade_tw.finished

	station_view.visible = false
	map_view.visible = true

	# Fade in map
	var map_in = create_tween()
	map_in.tween_property(fade_rect, "modulate:a", 0.0, 0.6)
	await map_in.finished

	# 5. Animate train on map strictly descending from Carrara (top) to La Spezia (bottom)
	var waypoints: Array[Vector2] = [
		Vector2(300.0, 70.0),
		Vector2(275.0, 125.0),
		Vector2(250.0, 175.0),
		Vector2(225.0, 225.0),
		Vector2(200.0, 275.0)
	]
	train_icon.position = waypoints[0]
	train_icon.visible = true

	map_narrative_label.text = "Viajando desde Carrara hacia La Spezia... ¡Descenso por la costa hacia el derbi!"

	var train_tw = create_tween()
	for i in range(1, waypoints.size()):
		var target_pos = waypoints[i]
		# Move downwards along each segment smoothly
		train_tw.tween_property(train_icon, "position", target_pos, 0.9).set_trans(Tween.TRANS_LINEAR)
	
	await train_tw.finished

	if is_transitioning:
		return

	map_narrative_label.text = "¡Atención pasajeros: Próxima estación La Spezia! El Hincha se prepara a bordo..."
	if AudioManager and sfx_horn:
		AudioManager.play_sfx(sfx_horn)

	await get_tree().create_timer(1.2).timeout
	_skip_to_game()

func _skip_to_game() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	var tw = create_tween()
	tw.tween_property(fade_rect, "modulate:a", 1.0, 0.5)
	await tw.finished
	if SceneManager:
		SceneManager.change_scene("res://scenes/tren/tren_level.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/tren/tren_level.tscn")
