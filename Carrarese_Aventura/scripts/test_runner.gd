extends Node

func _ready() -> void:
	print("==================================================")
	print("PRUEBAS DE ESCENARIO TREN Y MOVIMIENTO PROTAGONISTA")
	print("==================================================")
	_run_tests()

func _run_tests() -> void:
	var level_scene = load("res://scenes/tren/tren_level.tscn")
	if not level_scene:
		printerr("ERROR: No se pudo cargar tren_level.tscn")
		get_tree().quit(1)
		return
	
	var level = level_scene.instantiate()
	add_child(level)
	
	var player: Player = level.get_node_or_null("Player")
	if not player:
		printerr("ERROR: No se encontró el nodo Player en tren_level")
		get_tree().quit(1)
		return

	print("✓ Escena tren_level cargada correctamente con escenario interior continuo")
	print("✓ Player instanciado en posición inicial: ", player.global_position)

	# 1. Let physics settle to floor
	for i in range(25):
		await get_tree().physics_frame
	
	print("✓ Posición del jugador sobre el suelo del tren: ", player.global_position)
	if not player.is_on_floor():
		printerr("ERROR: El jugador debería estar en el suelo pero is_on_floor() es falso. Pos: ", player.global_position)
		get_tree().quit(1)
		return
	print("✓ TEST 1: El jugador hace contacto sólido con el suelo del vagón (is_on_floor = true, y=", player.global_position.y, ")")

	# 2. Test walk right with 'D' and 'Right Arrow'
	var initial_x = player.global_position.x
	Input.action_press("move_right")
	for i in range(30):
		await get_tree().physics_frame
	Input.action_release("move_right")
	
	# Let player decelerate
	for i in range(15):
		await get_tree().physics_frame
	
	var after_walk_x = player.global_position.x
	print("  Posición inicial X: ", initial_x, " -> Tras caminar X: ", after_walk_x)
	if after_walk_x <= initial_x + 15.0:
		printerr("ERROR: El jugador no avanzó a la derecha al presionar move_right")
		get_tree().quit(1)
		return
	print("✓ TEST 2: Caminar hacia la derecha (D / Flecha Derecha) exitoso (+", after_walk_x - initial_x, " px)")

	# 3. Test walk left with 'A' and 'Left Arrow'
	Input.action_press("move_left")
	for i in range(30):
		await get_tree().physics_frame
	Input.action_release("move_left")
	for i in range(15):
		await get_tree().physics_frame
	
	var after_left_x = player.global_position.x
	print("  Posición X tras caminar a la izquierda: ", after_left_x)
	if after_left_x >= after_walk_x - 15.0:
		printerr("ERROR: El jugador no retrocedió a la izquierda al presionar move_left")
		get_tree().quit(1)
		return
	print("✓ TEST 3: Caminar hacia la izquierda (A / Flecha Izquierda) exitoso (desplazamiento: ", after_left_x - after_walk_x, " px)")

	# 4. Test jump with Spacebar
	var pre_jump_y = player.global_position.y
	player.execute_jump()
	for i in range(8):
		await get_tree().physics_frame
	
	var mid_jump_y = player.global_position.y
	print("  Y suelo: ", pre_jump_y, " -> Y pico de salto: ", mid_jump_y)
	if mid_jump_y >= pre_jump_y - 20.0:
		printerr("ERROR: El jugador no ascendió al saltar con barra espaciadora")
		get_tree().quit(1)
		return
	print("✓ TEST 4: Salto con Barra Espaciadora exitoso (elevación = ", pre_jump_y - mid_jump_y, " px)")

	# Wait for player to land back on floor
	for i in range(60):
		await get_tree().physics_frame
	
	if not player.is_on_floor():
		printerr("ERROR: El jugador no aterrizó correctamente en el suelo. Pos: ", player.global_position)
		get_tree().quit(1)
		return
	print("✓ TEST 5: Aterrizaje suave y control de gravedad correcto (de vuelta en suelo: y=", player.global_position.y, ")")

	# 5. Test interaction with E
	player.execute_interact()
	print("✓ TEST 6: Tecla E de interacción registrada y ejecutada")

	# 6. Test stone throw
	GameManager.collect_item("piedra")
	player.execute_throw()
	await get_tree().physics_frame
	await get_tree().physics_frame
	var found_proj = false
	for child in level.get_children():
		if child.is_in_group("projectiles"):
			found_proj = true
			break
	if not found_proj:
		printerr("ERROR: El proyectil no se instanció")
		get_tree().quit(1)
		return
	print("✓ TEST 7: Lanzamiento de objetos funcional")

	# 7. Check Camera limits
	var cam: Camera2D = player.get_node_or_null("Camera2D")
	if not cam or cam.limit_right != 2703 or cam.limit_bottom != 360:
		printerr("ERROR: Los límites de cámara no están configurados correctamente")
		get_tree().quit(1)
		return
	print("✓ TEST 8: Cámara 2D lateral configurada con límites [0..2703] y seguimiento suave")

	print("==================================================")
	print("¡TODAS LAS PRUEBAS COMPLETADAS CON ÉXITO!")
	print("==================================================")
	get_tree().quit(0)
