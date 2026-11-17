extends CanvasLayer

## Pause menu for in-game overlay.
## Controls game pause state, audio volumes, restart, and return to main menu.

@onready var overlay: ColorRect = $Overlay
@onready var pause_panel: Panel = $PausePanel
@onready var btn_reanudar: Button = $PausePanel/VBoxContainer/BtnReanudar
@onready var btn_reiniciar: Button = $PausePanel/VBoxContainer/BtnReiniciar
@onready var btn_salir: Button = $PausePanel/VBoxContainer/BtnSalir
@onready var music_slider: HSlider = $PausePanel/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $PausePanel/VBoxContainer/SfxSlider


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Start hidden by default
	hide_menu()

	# Connect buttons if not already connected
	if not btn_reanudar.pressed.is_connected(_on_btn_reanudar_pressed):
		btn_reanudar.pressed.connect(_on_btn_reanudar_pressed)
	if not btn_reiniciar.pressed.is_connected(_on_btn_reiniciar_pressed):
		btn_reiniciar.pressed.connect(_on_btn_reiniciar_pressed)
	if not btn_salir.pressed.is_connected(_on_btn_salir_pressed):
		btn_salir.pressed.connect(_on_btn_salir_pressed)

	# Connect audio sliders if not already connected
	if not music_slider.value_changed.is_connected(_on_music_slider_value_changed):
		music_slider.value_changed.connect(_on_music_slider_value_changed)
	if not sfx_slider.value_changed.is_connected(_on_sfx_slider_value_changed):
		sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)

	# Set default slider values
	music_slider.value = 80.0
	sfx_slider.value = 80.0


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume_game()
		else:
			pause_game()


func pause_game() -> void:
	get_tree().paused = true
	show_menu()


func resume_game() -> void:
	get_tree().paused = false
	hide_menu()


func show_menu() -> void:
	visible = true
	if overlay:
		overlay.visible = true
	if pause_panel:
		pause_panel.visible = true


func hide_menu() -> void:
	visible = false
	if overlay:
		overlay.visible = false
	if pause_panel:
		pause_panel.visible = false


func _on_btn_reanudar_pressed() -> void:
	resume_game()


func _on_btn_reiniciar_pressed() -> void:
	get_tree().paused = false
	hide_menu()
	if GameManager:
		GameManager.reset_game()
	if SceneManager:
		SceneManager.change_scene("res://scenes/tren/tren_level.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/tren/tren_level.tscn")


func _on_btn_salir_pressed() -> void:
	get_tree().paused = false
	hide_menu()
	if GameManager:
		GameManager.reset_game()
	if SceneManager:
		SceneManager.change_scene("res://scenes/menu/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")


func _on_music_slider_value_changed(value: float) -> void:
	if AudioManager:
		if value <= 0.0:
			AudioManager.set_music_volume(-80.0)
		else:
			AudioManager.set_music_volume(linear_to_db(value / 100.0))


func _on_sfx_slider_value_changed(value: float) -> void:
	if AudioManager:
		if value <= 0.0:
			AudioManager.set_sfx_volume(-80.0)
		else:
			AudioManager.set_sfx_volume(linear_to_db(value / 100.0))
