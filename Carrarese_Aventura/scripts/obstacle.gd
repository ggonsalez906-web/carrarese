extends Area2D
class_name Obstacle

## Obstacle inside the train (luggage, bags, Spezia flags)

@export_enum("bandera_spezia", "equipaje", "bolso") var obstacle_type: String = "bandera_spezia"
@export var damage: int = 15

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("obstacles")
	body_entered.connect(_on_body_entered)
	_setup_texture()

func _setup_texture() -> void:
	if not sprite:
		return
	var tex_path = "res://assets/objetos/" + obstacle_type + ".png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)

func _on_body_entered(body: Node) -> void:
	if body is Player or body.has_method("take_damage"):
		body.take_damage(damage)

func hit_by_rock() -> void:
	# Wobble effect when hit by a thrown rock
	var tw = create_tween()
	tw.tween_property(self, "rotation_degrees", 15.0, 0.08)
	tw.tween_property(self, "rotation_degrees", -15.0, 0.08)
	tw.tween_property(self, "rotation_degrees", 0.0, 0.08)
