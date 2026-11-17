extends Control

## Italy Map Journey Scene - Carrara to La Spezia

@onready var train_icon: Sprite2D = $TrainIcon
@onready var prompt_label: Label = $PromptLabel
@onready var route_line: Line2D = $RouteLine

# Carrara coordinates on the 640x360 map
const POS_CARRARA: Vector2 = Vector2(250.0, 160.0)
const POS_LA_SPEZIA: Vector2 = Vector2(220.0, 145.0)

var journey_duration: float = 3.5
var timer: float = 0.0
var started_transition: bool = false

var sfx_train: AudioStream = preload("res://assets/audio/sfx/train_ambient.wav")

func _ready() -> void:
	if GameManager:
		GameManager.game_state = GameManager.GameState.MAP
	
	if AudioManager:
		AudioManager.play_sfx(sfx_train)

	if train_icon:
		train_icon.position = POS_CARRARA

func _process(delta: float) -> void:
	if started_transition:
		return

	timer += delta
	var progress: float = clamp(timer / journey_duration, 0.0, 1.0)
	
	if train_icon:
		train_icon.position = POS_CARRARA.lerp(POS_LA_SPEZIA, progress)

	# Blinking prompt
	if prompt_label:
		prompt_label.modulate.a = 0.5 + 0.5 * sin(timer * 6.0)

	if Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("interact") or progress >= 1.0:
		start_train_level()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		start_train_level()

func start_train_level() -> void:
	if started_transition:
		return
	started_transition = true
	if SceneManager:
		SceneManager.change_scene("res://scenes/tren/tren_level.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/tren/tren_level.tscn")
