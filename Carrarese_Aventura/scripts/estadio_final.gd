extends Control

@onready var protagonist_sprite: AnimatedSprite2D = $ProtagonistSprite
@onready var score_label: Label = $VBoxContainer/ScoreLabel
@onready var btn_menu: Button = $VBoxContainer/BtnMenu

func _ready() -> void:
	if protagonist_sprite and protagonist_sprite.sprite_frames:
		protagonist_sprite.play("celebrate")
	
	if score_label and GameManager:
		score_label.text = "PUNTUACIÓN FINAL: %d PUNTOS" % GameManager.score

	if AudioManager:
		var victory_music = load("res://assets/audio/music/victory_theme.wav")
		if victory_music:
			AudioManager.play_music(victory_music)

func _on_btn_menu_pressed() -> void:
	if GameManager:
		GameManager.reset_game()
	if SceneManager:
		SceneManager.change_scene("res://scenes/menu/main_menu.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
