extends Control

## Game over screen for "El Viaje del Hincha del Carrarese".
## Displays final score and provides retry or return to main menu options.

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var btn_reintentar: Button = $CenterContainer/VBoxContainer/ButtonsContainer/BtnReintentar
@onready var btn_menu: Button = $CenterContainer/VBoxContainer/ButtonsContainer/BtnMenu


func _ready() -> void:
	# Update score display from GameManager
	if GameManager:
		score_label.text = "Puntuación Final: %d" % GameManager.score
	else:
		score_label.text = "Puntuación Final: 0"

	# Connect buttons if not already connected
	if not btn_reintentar.pressed.is_connected(_on_btn_reintentar_pressed):
		btn_reintentar.pressed.connect(_on_btn_reintentar_pressed)
	if not btn_menu.pressed.is_connected(_on_btn_menu_pressed):
		btn_menu.pressed.connect(_on_btn_menu_pressed)


func _on_btn_reintentar_pressed() -> void:
	if GameManager:
		GameManager.reset_game()
	if SceneManager:
		SceneManager.change_scene("res://scenes/tren/tren_level.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/tren/tren_level.tscn")


func _on_btn_menu_pressed() -> void:
	if GameManager:
		GameManager.reset_game()
	if SceneManager:
		SceneManager.change_scene("res://scenes/menu/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
