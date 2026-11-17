extends Node

func _ready() -> void:
	print("==================================================")
	print("PRUEBAS DE JEFE FINAL: HINCHA GIGANTE DE SPEZIA")
	print("==================================================")
	_run_tests()

func _run_tests() -> void:
	var level_scene = load("res://scenes/tren/tren_level.tscn")
	var level = level_scene.instantiate()
	add_child(level)

	var player: Player = level.get_node_or_null("Player")
	var boss: BossSpezia = level.get_node_or_null("BossSpezia")
	var hud: HUD = level.get_node_or_null("HUD")

	if not player or not boss:
		printerr("ERROR: Player o BossSpezia no encontrados")
		get_tree().quit(1)
		return

	# Settle physics
	for i in range(20):
		await get_tree().physics_frame

	print("✓ TEST 1: Hincha Gigante de Spezia instanciado en posición: ", boss.global_position)
	if not boss.is_on_floor():
		printerr("ERROR: El jefe no está en contacto con el suelo")
		get_tree().quit(1)
		return
	print("✓ TEST 2: El jefe hace contacto sólido con el suelo del último vagón")

	# 2. Test Boss Activation
	boss.activate_boss()
	if not boss.is_active:
		printerr("ERROR: El jefe no se activó correctamente")
		get_tree().quit(1)
		return
	print("✓ TEST 3: Activación del combate del jefe exitosa")

	# 3. Test Boss Attack (Throw rock)
	boss.execute_throw_attack()
	# Wait for throw sequence
	for i in range(40):
		await get_tree().physics_frame
	
	var found_rock = false
	for child in level.get_children():
		if child is BossRockProjectile or child.is_in_group("boss_projectiles"):
			found_rock = true
			break
	if not found_rock:
		printerr("ERROR: El proyectil de piedra del jefe no se generó")
		get_tree().quit(1)
		return
	print("✓ TEST 4: Ataque del jefe lanza proyectil de piedra hacia el jugador")

	# 4. Test 5 Hits to Defeat
	print("--- Simulando 5 impactos de piedras contra el jefe ---")
	for hit in range(1, 6):
		boss.is_invulnerable = false # Clear invulnerability between test hits
		boss.take_damage(1)
		await get_tree().physics_frame
		print("  Impacto ", hit, "/5 registrado. Contador del jefe: ", boss.hits_received, "/5")
		if boss.hits_received != hit:
			printerr("ERROR: El contador de impactos debería ser ", hit)
			get_tree().quit(1)
			return

	if not boss.is_defeated:
		printerr("ERROR: El jefe debería estar derrotado tras 5 impactos")
		get_tree().quit(1)
		return
	print("✓ TEST 5: Condición de victoria cumplida tras 5 impactos válidos")

	# 5. Check Defeat Animation & Victory State
	if boss.animated_sprite.animation != "defeated":
		printerr("ERROR: La animación del jefe debería ser 'defeated'")
		get_tree().quit(1)
		return
	print("✓ TEST 6: Animación caricaturesca de derrota activada correctamente")

	if hud and hud.victory_banner and not hud.victory_banner.visible:
		printerr("ERROR: El cartel de victoria '¡DERROTADO!' no se mostró")
		get_tree().quit(1)
		return
	print("✓ TEST 7: Mensaje '¡DERROTADO! EL CARRARESE SUPERA AL RIVAL' mostrado en pantalla")

	print("==================================================")
	print("¡TODAS LAS PRUEBAS DEL JEFE FINAL COMPLETADAS CON ÉXITO!")
	print("==================================================")
	get_tree().quit(0)
