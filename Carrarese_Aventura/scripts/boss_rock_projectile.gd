extends Area2D
class_name BossRockProjectile

## Rock thrown by the Giant Spezia Fan Boss

@export var speed: float = 230.0
@export var damage: int = 15
var direction: float = -1.0 # Moving left towards player
var fall_velocity: float = -50.0 # Small initial arc
var fall_gravity: float = 380.0

func _ready() -> void:
	add_to_group("boss_projectiles")
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

var collectible_scene: PackedScene = preload("res://scenes/tren/collectible.tscn")

func _physics_process(delta: float) -> void:
	fall_velocity += fall_gravity * delta
	position.x += direction * speed * delta
	position.y += fall_velocity * delta
	rotation += -6.0 * delta

	# Destroy if it hits floor or goes off screen
	if position.y > 332.0 or position.x < 0.0:
		_impact_and_free(false)

func _on_body_entered(body: Node) -> void:
	if body is Player or body.has_method("take_damage"):
		body.take_damage(damage)
		_impact_and_free(true)
	elif body is StaticBody2D or body.name == "Floor" or body.name == "StaticCollisions":
		_impact_and_free(false)

func _on_area_entered(_area: Area2D) -> void:
	pass

func _impact_and_free(hit_player: bool = false) -> void:
	if not hit_player and collectible_scene:
		if randf() < 0.7:
			var stone = collectible_scene.instantiate()
			stone.item_type = "piedra"
			stone.points = 10
			stone.global_position = Vector2(global_position.x, 314.0)
			get_parent().call_deferred("add_child", stone)
	queue_free()
