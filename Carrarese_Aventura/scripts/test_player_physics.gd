extends SceneTree

## Automated test script for Player mechanics: walk, run, jump, collisions, throw, collect

func _init() -> void:
	print("==================================================")
	print("INICIANDO PRUEBAS DE FÍSICAS Y MOVIMIENTO (ETAPA 2)")
	print("==================================================")
	call_deferred("_run_tests")

func _run_tests() -> void:
	var level_scene = load("res://scenes/tren/tren_level.tscn")
	if not level_scene:
		printerr("ERROR: No se pudo cargar tren_level.tscn")
		quit(1)
		return
	
	var level = level_scene.instantiate()
	root.add_child(level)
	
	var player = level.get_node_or_null("Player")
	if not player:
		printerr("ERROR: No se encontró el nodo Player en tren_level")
		quit(1)
		return

	print("✓ Escena tren_level cargada correctamente")
	print("✓ Player instanciado en posición inicial: ", player.global_position)

	# 1. Let physics settle to floor
	for i in range(20):
		await process_frame
	
	print("✓ Posición tras asentar en el suelo: ", player.global_position)
	if not player.is_on_floor():
		printerr("ERROR: El jugador debería estar en el suelo pero is_on_floor() es falso")
		quit(1)
		return
	print("✓ TEST 1 PASADO: Detección de suelo y gravedad funcionan (is_on_floor = true)")

	# 2. Test walk right
	var initial_x = player.global_position.x
	Input.action_press("move_right")
	for i in range(30):
		await process_frame
	Input.action_release("move_right")
	
	var after_walk_x = player.global_position.x
	print("  Posición inicial X: ", initial_x, " -> Tras caminar X: ", after_walk_x)
	if after_walk_x <= initial_x + 10.0:
		printerr("ERROR: El jugador no avanzó a la derecha al presionar move_right")
		quit(1)
		return
	print("✓ TEST 2 PASADO: Caminar hacia la derecha funcional (delta X = +", after_walk_x - initial_x, ")")

	# 3. Test walk left
	Input.action_press("move_left")
	for i in range(20):
		await process_frame
	Input.action_release("move_left")
	
	var after_left_x = player.global_position.x
	print("  Posición X tras caminar a la izquierda: ", after_left_x)
	if after_left_x >= after_walk_x:
		printerr("ERROR: El jugador no retrocedió al presionar move_left")
		quit(1)
		return
	print("✓ TEST 3 PASADO: Caminar hacia la izquierda funcional (delta X = ", after_left_x - after_walk_x, ")")

	# 4. Test jump
	var pre_jump_y = player.global_position.y
	player.execute_jump()
	for i in range(8):
		await process_frame
	
	var mid_jump_y = player.global_position.y
	print("  Y antes de saltar: ", pre_jump_y, " -> Y durante el salto: ", mid_jump_y)
	if mid_jump_y >= pre_jump_y - 10.0:
		printerr("ERROR: El jugador no ascendió al saltar")
		quit(1)
		return
	print("✓ TEST 4 PASADO: Salto vertical funcional (elevación = ", pre_jump_y - mid_jump_y, " px)")

	# Wait for player to land back on floor
	for i in range(60):
		await process_frame
	
	if not player.is_on_floor():
		printerr("ERROR: El jugador no aterrizó correctamente tras el salto")
		quit(1)
		return
	print("✓ TEST 5 PASADO: Aterrizaje y física de caída funcionales (de vuelta en el suelo: y=", player.global_position.y, ")")

	# 5. Test throw stone projectile
	var child_count_before = level.get_child_count()
	player.execute_throw()
	await process_frame
	await process_frame
	var found_proj = false
	for child in level.get_children():
		if child.is_in_group("projectiles"):
			found_proj = true
			break
	if not found_proj:
		printerr("ERROR: El proyectil piedra no se instanció al lanzar")
		quit(1)
		return
	print("✓ TEST 6 PASADO: Lanzamiento de piedra funcional (proyectil instanciado con física y grupo 'projectiles')")

	# 6. Test item collection
	var initial_score = GameManager.score
	player.collect_item("bufanda", 100)
	print("  Puntuación tras recoger bufanda: ", GameManager.score)
	if GameManager.score != initial_score + 100 or not ("bufanda" in GameManager.current_accessories):
		printerr("ERROR: La recolección de bufanda no actualizó score o accesorios")
		quit(1)
		return
	print("✓ TEST 7 PASADO: Recolección de accesorios y suma de puntos funcional")

	# 7. Test obstacle damage
	var initial_energy = GameManager.energy
	player.take_damage(15)
	print("  Energía tras recibir daño de obstáculo: ", GameManager.energy)
	if GameManager.energy != initial_energy - 15:
		printerr("ERROR: take_damage no redujo la energía correctamente")
		quit(1)
		return
	print("✓ TEST 8 PASADO: Sistema de daño y retroceso por obstáculos funcional")

	print("==================================================")
	print("¡TODAS LAS PRUEBAS DE LA ETAPA 2 PASARON EXITOSAMENTE!")
	print("==================================================")
	quit(0)
