extends Area2D

## Projectile thrown by the protagonist
@export var speed: float = 340.0
@export var fall_gravity: float = 380.0
@export var damage: int = 1

var direction: float = 1.0
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	velocity = Vector2(direction * speed, -80.0) # slight upward arc
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# Auto despawn after 3.5 seconds
	await get_tree().create_timer(3.5).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	velocity.y += fall_gravity * delta
	position += velocity * delta
	rotation += direction * 12.0 * delta

func _resolve_damage_target(node: Node) -> Node:
	if node == null:
		return null
	if node.has_method("take_damage"):
		return node
	var parent = node.get_parent()
	if parent != null and parent.has_method("take_damage"):
		return parent
	return node

func _on_body_entered(body: Node) -> void:
	if body == null or body.is_in_group("player"):
		return
	var target = _resolve_damage_target(body)
	if target.is_in_group("enemies") or target.is_in_group("boss") or target.has_method("take_damage"):
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
	elif body.is_in_group("obstacles"):
		if body.has_method("hit_by_rock"):
			body.hit_by_rock()
		queue_free()
	elif body is TileMap or body is StaticBody2D or body.name == "Floor" or body.name == "StaticCollisions":
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area == null or area.is_in_group("player"):
		return
	var target = _resolve_damage_target(area)
	if target.is_in_group("enemies") or target.is_in_group("boss") or target.has_method("take_damage"):
		if target.has_method("take_damage"):
			target.take_damage(damage)
		queue_free()
