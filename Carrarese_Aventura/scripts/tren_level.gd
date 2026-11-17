extends Node2D

## Train Level Controller - Single continuous authentic train car interior
## "El Viaje del Hincha del Carrarese"

const LEVEL_LENGTH: float = 2703.0
const TRAIN_SPEED: float = 120.0 # Pixels per second scenery moves outside windows

@onready var player: Player = $Player
@onready var hud: HUD = $HUD
@onready var parallax_bg: ParallaxBackground = $ParallaxBackground
@onready var boss: BossSpezia = get_node_or_null("BossSpezia")
@onready var boss_trigger: Area2D = get_node_or_null("BossTrigger")
@onready var right_wall: CollisionShape2D = get_node_or_null("StaticCollisions/RightWall")

var music_train: AudioStream = preload("res://assets/audio/music/train_theme.wav")
var boss_is_defeated: bool = false
var reached_wagon_end: bool = false

func _ready() -> void:
	if GameManager:
		GameManager.game_state = GameManager.GameState.TRAIN
		GameManager.game_over.connect(_on_game_over)
		if get_tree().current_scene and get_tree().current_scene.name == "TrenLevel":
			if GameManager.collected_items.get("piedra", 0) == 0:
				GameManager.collected_items["piedra"] = 3
				GameManager.item_collected.emit("piedra")
	
	if AudioManager:
		AudioManager.play_music(music_train)

	if boss:
		boss.boss_hit.connect(_on_boss_hit)
		boss.boss_defeated.connect(_on_boss_defeated)

	if boss_trigger:
		boss_trigger.body_entered.connect(_on_boss_trigger_entered)

func _process(delta: float) -> void:
	# Continuously scroll the Italian landscape outside the windows
	if parallax_bg:
		parallax_bg.scroll_offset.x -= TRAIN_SPEED * delta

	# Update journey progress on HUD
	if player and hud:
		var progress: float = clamp(player.global_position.x / LEVEL_LENGTH, 0.0, 1.0)
		hud.set_train_progress(progress)
		
		# If boss defeated, player can walk through the end of the wagon to finish
		if boss_is_defeated and not reached_wagon_end:
			if player.global_position.x >= 2650.0:
				reached_wagon_end = true
				_finish_level()

func _on_boss_trigger_entered(body: Node) -> void:
	if body is Player and boss and not boss.is_active and not boss.is_defeated:
		boss_trigger.set_deferred("monitoring", false)
		boss.activate_boss()
		if player:
			var cam = player.get_node_or_null("Camera2D")
			if cam:
				cam.limit_left = 1800
				cam.limit_right = 2703
		if hud:
			hud.update_boss_hits(0, boss.MAX_HITS)

func _on_boss_hit(current: int, max_hits: int) -> void:
	if hud:
		hud.update_boss_hits(current, max_hits)

func _on_boss_defeated() -> void:
	boss_is_defeated = true
	if hud:
		hud.show_victory_banner()
	if player:
		var cam = player.get_node_or_null("Camera2D")
		if cam:
			cam.limit_right = 3200
	if right_wall:
		right_wall.set_deferred("disabled", true)

func _finish_level() -> void:
	if player:
		player.celebrate()
	await get_tree().create_timer(1.8).timeout
	_transition_to_final()

func _on_game_over() -> void:
	if SceneManager:
		SceneManager.change_scene("res://scenes/menu/game_over.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/game_over.tscn")

func _transition_to_final() -> void:
	# Fade out effect using a ColorRect overlay
	var fade = ColorRect.new()
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.anchors_preset = Control.PRESET_FULL_RECT
	fade.z_index = 100
	
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	canvas.add_child(fade)
	add_child(canvas)
	
	var tw = create_tween()
	tw.tween_property(fade, "modulate:a", 1.0, 1.5)
	await tw.finished
	
	if SceneManager:
		SceneManager.change_scene("res://scenes/final/estadio_final.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/final/estadio_final.tscn")
