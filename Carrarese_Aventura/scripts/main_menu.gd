extends Control

## Main menu controller for "El Viaje del Hincha del Carrarese".

@onready var btn_jugar: Button = $ButtonsContainer/BtnJugar
@onready var btn_opciones: Button = $ButtonsContainer/BtnOpciones
@onready var btn_creditos: Button = $ButtonsContainer/BtnCreditos

@onready var options_panel: Panel = $OptionsPanel
@onready var music_slider: HSlider = $OptionsPanel/VBoxContainer/MusicSlider
@onready var sfx_slider: HSlider = $OptionsPanel/VBoxContainer/SfxSlider
@onready var btn_close_options: Button = $OptionsPanel/VBoxContainer/BtnCloseOptions

@onready var credits_panel: Panel = $CreditsPanel
@onready var btn_close_credits: Button = $CreditsPanel/VBoxContainer/BtnCloseCredits

@onready var protagonist_sprite: AnimatedSprite2D = $ProtagonistSprite


func _ready() -> void:
	# Hide options and credits panels initially
	if options_panel:
		options_panel.visible = false
	if credits_panel:
		credits_panel.visible = false

	# Play protagonist animation if available
	if protagonist_sprite and protagonist_sprite.sprite_frames:
		if protagonist_sprite.sprite_frames.has_animation("idle"):
			protagonist_sprite.play("idle")

	# Play retro menu music
	if AudioManager:
		var menu_music = load("res://assets/audio/music/menu_theme.wav")
		if menu_music:
			AudioManager.play_music(menu_music)

	# Initialize audio sliders to a sensible default (80%)
	if music_slider:
		music_slider.value = 80.0
	if sfx_slider:
		sfx_slider.value = 80.0


func _on_btn_jugar_pressed() -> void:
	if SceneManager:
		SceneManager.change_scene("res://scenes/intro/intro_secuencia.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/intro/intro_secuencia.tscn")


func _on_btn_opciones_pressed() -> void:
	if options_panel:
		options_panel.visible = !options_panel.visible
		if options_panel.visible and credits_panel:
			credits_panel.visible = false


func _on_btn_creditos_pressed() -> void:
	if credits_panel:
		credits_panel.visible = !credits_panel.visible
		if credits_panel.visible and options_panel:
			options_panel.visible = false


func _on_btn_close_options_pressed() -> void:
	if options_panel:
		options_panel.visible = false


func _on_btn_close_credits_pressed() -> void:
	if credits_panel:
		credits_panel.visible = false


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
