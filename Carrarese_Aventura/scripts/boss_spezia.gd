extends CharacterBody2D
class_name BossSpezia

## Boss Controller: Hincha Gigante de Spezia
## Final Boss for "El Viaje del Hincha del Carrarese"

signal boss_hit(current_hits: int, max_hits: int)
signal boss_defeated

const MAX_HITS: int = 5
const ATTACK_INTERVAL: float = 2.2

# Preloaded resources
var projectile_scene: PackedScene = preload("res://scenes/tren/boss_rock_projectile.tscn")
var sfx_attack: AudioStream = preload("res://assets/audio/sfx/boss_attack.wav")
var sfx_hit: AudioStream = preload("res://assets/audio/sfx/hit_enemy.wav")
var sfx_defeated: AudioStream = preload("res://assets/audio/sfx/boss_defeated.wav")
var music_boss: AudioStream = preload("res://assets/audio/music/boss_theme.wav")
var sfx_victory: AudioStream = preload("res://assets/audio/music/victory_theme.wav")

# Nodes
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var throw_point: Marker2D = $ThrowPoint
@onready var hitbox: Area2D = $Hitbox

# State
var is_active: bool = false
var is_defeated: bool = false
var is_invulnerable: bool = false
var attack_timer: float = 0.0
var hits_received: int = 0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)
		hitbox.area_entered.connect(_on_hitbox_area_entered)
	if animated_sprite:
		animated_sprite.flip_h = false
		animated_sprite.play("idle")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
		move_and_slide()

	if not is_active or is_defeated:
		return

	# Attack cycle
	attack_timer += delta
	if attack_timer >= ATTACK_INTERVAL:
		attack_timer = 0.0
		execute_throw_attack()

func activate_boss() -> void:
	if is_active or is_defeated:
		return
	is_active = true
	attack_timer = 1.0 # First attack after 1.2s
	if AudioManager and music_boss:
		AudioManager.play_music(music_boss)
	emit_signal("boss_hit", hits_received, MAX_HITS)

func execute_throw_attack() -> void:
	if is_defeated or is_invulnerable:
		return

	# 1. Prepare throw animation
	if animated_sprite:
		animated_sprite.play("prepare")
	
	await get_tree().create_timer(0.4).timeout
	if is_defeated:
		return

	# 2. Release stone
	if animated_sprite:
		animated_sprite.play("throw")
	
	if AudioManager and sfx_attack:
		AudioManager.play_sfx(sfx_attack)

	if projectile_scene:
		var rock = projectile_scene.instantiate()
		var spawn_pos: Vector2 = global_position + Vector2(-32.0, -75.0)
		if throw_point:
			spawn_pos = throw_point.global_position
		rock.global_position = spawn_pos
		rock.direction = -1.0 # Towards player
		get_parent().add_child(rock)

	await get_tree().create_timer(0.35).timeout
	if is_defeated:
		return

	# 3. Recovery to idle
	if animated_sprite:
		animated_sprite.play("idle")

func take_damage(_amount: int = 1) -> void:
	# Called when a player's stone hits the boss
	if is_defeated or is_invulnerable:
		return

	# If hit before trigger, wake up immediately
	if not is_active:
		activate_boss()

	hits_received += 1
	is_invulnerable = true
	emit_signal("boss_hit", hits_received, MAX_HITS)

	if AudioManager and sfx_hit:
		AudioManager.play_sfx(sfx_hit)

	# Visual hurt effect: flash red/white and wobble
	if animated_sprite:
		animated_sprite.play("hurt")
	
	var tw = create_tween()
	tw.tween_property(self, "position:x", position.x + 12.0, 0.05)
	tw.tween_property(self, "position:x", position.x - 6.0, 0.05)
	tw.tween_property(self, "position:x", position.x, 0.05)
	tw.parallel().tween_property(animated_sprite, "modulate", Color(2.5, 0.5, 0.5), 0.08)
	tw.tween_property(animated_sprite, "modulate", Color.WHITE, 0.1)

	if hits_received >= MAX_HITS:
		die()
	else:
		await get_tree().create_timer(0.4).timeout
		is_invulnerable = false
		if animated_sprite and not is_defeated:
			animated_sprite.play("idle")

func die() -> void:
	is_defeated = true
	is_active = false
	is_invulnerable = true
	emit_signal("boss_defeated")

	# Immediately disable all collisions and hitbox so player can advance freely
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if hitbox:
		hitbox.set_deferred("monitoring", false)
		hitbox.set_deferred("monitorable", false)
	collision_layer = 0
	collision_mask = 0

	# Play special victory fanfare / theme
	if AudioManager:
		if sfx_victory:
			AudioManager.play_music(sfx_victory)
		elif sfx_defeated:
			AudioManager.play_sfx(sfx_defeated)

	if GameManager:
		GameManager.add_score(1000)

	if animated_sprite:
		animated_sprite.play("defeated")

	# Dramatic defeat animation and complete disappearance
	var tw = create_tween()
	tw.tween_property(self, "position:y", position.y + 10.0, 0.3)
	tw.parallel().tween_property(animated_sprite, "modulate", Color(2.2, 1.8, 1.8), 0.2)
	tw.tween_property(animated_sprite, "modulate", Color.WHITE, 0.2)
	# Disappear completely (shrink + fade out)
	tw.tween_interval(0.5)
	tw.tween_property(animated_sprite, "modulate:a", 0.0, 0.6)
	tw.parallel().tween_property(animated_sprite, "scale", Vector2.ZERO, 0.6)
	tw.tween_callback(func():
		visible = false
		queue_free()
	)

func _on_hitbox_body_entered(body: Node) -> void:
	if body.is_in_group("projectiles"):
		take_damage(1)

func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("projectiles"):
		take_damage(1)
