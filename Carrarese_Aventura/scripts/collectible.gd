extends Area2D
class_name Collectible

## Collectible item inside the train (stones, scarf, jersey, cap)

@export_enum("piedra", "bufanda", "camiseta", "gorra") var item_type: String = "piedra"
@export var points: int = 50

@onready var sprite: Sprite2D = $Sprite2D
var start_y: float = 0.0
var float_time: float = 0.0

func _ready() -> void:
	start_y = position.y
	body_entered.connect(_on_body_entered)
	_setup_texture()

func _setup_texture() -> void:
	if not sprite:
		return
	var tex_path = "res://assets/objetos/" + item_type + ".png"
	if ResourceLoader.exists(tex_path):
		sprite.texture = load(tex_path)

func _process(delta: float) -> void:
	float_time += delta * 3.0
	position.y = start_y + sin(float_time) * 4.0

func _on_body_entered(body: Node) -> void:
	if body is Player or body.has_method("collect_item"):
		body.collect_item(item_type, points)
		# Spawn small sparkle or fade effect
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector2(1.4, 1.4), 0.15)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.15)
		tw.tween_callback(queue_free)
