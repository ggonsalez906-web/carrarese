extends CanvasLayer
class_name HUD

## HUD showing Energy, Score, Accessories, and Mobile controls

@onready var energy_bar: ProgressBar = $TopBar/EnergyContainer/EnergyBar
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var stones_label: Label = $TopBar/StonesLabel
@onready var icon_bufanda: TextureRect = $TopBar/AccessoriesContainer/IconBufanda
@onready var icon_camiseta: TextureRect = $TopBar/AccessoriesContainer/IconCamiseta
@onready var icon_gorra: TextureRect = $TopBar/AccessoriesContainer/IconGorra
@onready var progress_bar: ProgressBar = $BottomBar/ProgressBar
@onready var boss_container: VBoxContainer = $BossContainer
@onready var boss_impacts_label: Label = $BossContainer/BossImpactsLabel
@onready var victory_banner: PanelContainer = $VictoryBanner

func _ready() -> void:
	if GameManager:
		GameManager.score_changed.connect(_on_score_changed)
		GameManager.energy_changed.connect(_on_energy_changed)
		GameManager.accessory_equipped.connect(_on_accessory_equipped)
		GameManager.item_collected.connect(_on_item_collected)
		_on_score_changed(GameManager.score)
		_on_energy_changed(GameManager.energy)
		_update_accessories()
		_update_stones()

func _on_item_collected(_item_name: String) -> void:
	_update_stones()

func _update_stones() -> void:
	if stones_label and GameManager:
		stones_label.text = "PIEDRAS: %d" % GameManager.collected_items.get("piedra", 0)

func _on_score_changed(new_score: int) -> void:
	if score_label:
		score_label.text = "PUNTOS: %04d" % new_score

func _on_energy_changed(new_energy: int) -> void:
	if energy_bar:
		energy_bar.value = new_energy
		# Color modulate
		if new_energy > 60:
			energy_bar.modulate = Color(0.2, 0.9, 0.2)
		elif new_energy > 30:
			energy_bar.modulate = Color(1.0, 0.8, 0.0)
		else:
			energy_bar.modulate = Color(0.9, 0.2, 0.2)

func _on_accessory_equipped(_name: String) -> void:
	_update_accessories()

func _update_accessories() -> void:
	if not GameManager:
		return
	if icon_bufanda:
		icon_bufanda.visible = ("bufanda" in GameManager.current_accessories)
	if icon_camiseta:
		icon_camiseta.visible = ("camiseta" in GameManager.current_accessories)
	if icon_gorra:
		icon_gorra.visible = ("gorra" in GameManager.current_accessories)

func set_train_progress(percent: float) -> void:
	if progress_bar:
		progress_bar.value = clamp(percent * 100.0, 0.0, 100.0)

func show_boss_ui(show: bool) -> void:
	if boss_container:
		boss_container.visible = show

func update_boss_hits(current: int, max_hits: int) -> void:
	if boss_container:
		boss_container.visible = true
	if boss_impacts_label:
		boss_impacts_label.text = "IMPACTOS: %d/%d" % [current, max_hits]

func show_victory_banner() -> void:
	if boss_container:
		boss_container.visible = false
	if victory_banner:
		victory_banner.visible = true
		victory_banner.pivot_offset = victory_banner.size / 2.0
		var tw = create_tween()
		victory_banner.scale = Vector2(0.5, 0.5)
		tw.tween_property(victory_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

# Mobile button actions
func _on_btn_left_down() -> void:
	Input.action_press("move_left")

func _on_btn_left_up() -> void:
	Input.action_release("move_left")

func _on_btn_right_down() -> void:
	Input.action_press("move_right")

func _on_btn_right_up() -> void:
	Input.action_release("move_right")

func _on_btn_jump_down() -> void:
	Input.action_press("jump")

func _on_btn_jump_up() -> void:
	Input.action_release("jump")

func _on_btn_throw_down() -> void:
	Input.action_press("throw")

func _on_btn_throw_up() -> void:
	Input.action_release("throw")

func _on_btn_pause_pressed() -> void:
	var pause_menu = get_tree().get_first_node_in_group("pause_menu")
	if pause_menu:
		pause_menu.visible = true
		get_tree().paused = true
