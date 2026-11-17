extends Node

func _ready() -> void:
	print("==================================================")
	print("PRUEBAS DE SISTEMA DE VESTIMENTA Y BANDERAS SPEZIA")
	print("==================================================")
	_run_tests()

func _run_tests() -> void:
	var level_scene = load("res://scenes/tren/tren_level.tscn")
	var level = level_scene.instantiate()
	add_child(level)
	
	var player: Player = level.get_node_or_null("Player")
	if not player:
		printerr("ERROR: Player no encontrado")
		get_tree().quit(1)
		return

	# Settle physics
	for i in range(15):
		await get_tree().physics_frame

	# 1. Test initial costume (base)
	if player.animated_sprite.sprite_frames != player.frames_base:
		printerr("ERROR: El jugador debería iniciar con frames_base")
		get_tree().quit(1)
		return
	print("✓ TEST 1: Protagonista inicia con SpriteFrames base (sin accesorios)")

	# 2. Test collect camiseta
	player.collect_item("camiseta", 150)
	await get_tree().physics_frame
	if player.animated_sprite.sprite_frames != player.frames_camiseta:
		printerr("ERROR: Al recoger camiseta, debe equiparse frames_camiseta")
		get_tree().quit(1)
		return
	print("✓ TEST 2: Al recoger Camiseta, se equipa visualmente costume_camiseta (150 pts)")

	# 3. Test accumulate bufanda
	player.collect_item("bufanda", 100)
	await get_tree().physics_frame
	if player.animated_sprite.sprite_frames != player.frames_completo:
		printerr("ERROR: Al acumular camiseta + bufanda, debe usar frames_completo")
		get_tree().quit(1)
		return
	print("✓ TEST 3: Al recoger Bufanda, se acumula con la Camiseta (costume_completo activo)")

	# 4. Test accumulate gorra
	player.collect_item("gorra", 100)
	await get_tree().physics_frame
	if player.animated_sprite.sprite_frames != player.frames_todo and player.animated_sprite.sprite_frames != player.frames_completo:
		printerr("ERROR: Con camiseta + bufanda + gorra, debe usar frames_todo o frames_completo")
		get_tree().quit(1)
		return
	print("✓ TEST 4: Al recoger Gorra, se mantienen todas las prendas acumuladas (Camiseta + Bufanda + Gorra)")

	# 5. Test collecting stones
	var initial_score = GameManager.score
	player.collect_item("piedra", 20)
	await get_tree().physics_frame
	if GameManager.score != initial_score + 20:
		printerr("ERROR: La piedra debe sumar 20 puntos")
		get_tree().quit(1)
		return
	if GameManager.collected_items.get("piedra", 0) != 1:
		printerr("ERROR: El conteo de piedras debe ser 1")
		get_tree().quit(1)
		return
	print("✓ TEST 5: Recolección de piedras suma 20 puntos y actualiza el contador de piedras")

	# 6. Test Spezia Flag obstacle damage
	var initial_energy = GameManager.energy
	player.take_damage(15)
	await get_tree().physics_frame
	if GameManager.energy != initial_energy - 15:
		printerr("ERROR: Chocar con obstáculo de Bandera Spezia debe restar 15 de energía")
		get_tree().quit(1)
		return
	print("✓ TEST 6: Obstáculo Bandera de Spezia inflige daño (-15 energía)")

	print("==================================================")
	print("¡TODAS LAS PRUEBAS DE VESTIMENTA Y OBSTÁCULOS SUPERADAS!")
	print("==================================================")
	get_tree().quit(0)
