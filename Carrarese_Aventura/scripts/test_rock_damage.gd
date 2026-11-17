extends Node

func _ready() -> void:
	print("=== TEST DE DAÑO DE PIEDRA CONTRA EL JEFE ===")
	var level_scene = load("res://scenes/tren/tren_level.tscn")
	var level = level_scene.instantiate()
	add_child(level)

	var boss = level.get_node("BossSpezia")
	
	# Wait for physics
	for i in range(10):
		await get_tree().physics_frame

	print("Boss hits iniciales: ", boss.hits_received)
	
	# Spawn a rock flying right into the boss hitbox
	var proj_scene = load("res://scenes/tren/piedra_projectile.tscn")
	var rock = proj_scene.instantiate()
	rock.direction = 1.0
	rock.global_position = boss.global_position + Vector2(-30, -60)
	level.add_child(rock)

	# Simulate physics frames for collision
	for i in range(15):
		await get_tree().physics_frame

	print("Boss hits tras impacto de piedra: ", boss.hits_received)
	if boss.hits_received != 1:
		printerr("ERROR: El jefe no recibió daño de la piedra!")
		get_tree().quit(1)
		return

	print("✓ TEST EXITOSO: La piedra arrojada impactó al Jefe Gordo Spezia y le infligió daño!")
	get_tree().quit(0)
