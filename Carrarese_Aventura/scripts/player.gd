extends CharacterBody2D
class_name Player

## Protagonist controller for "El Viaje del Hincha del Carrarese"
## Highly responsive arcade movement, jump, collision and animations

# --- Tuning ---
const WALK_SPEED: float = 185.0
const RUN_SPEED: float = 260.0
const ACCELERATION: float = 1400.0
const FRICTION: float = 1600.0
const JUMP_VELOCITY: float = -370.0
const COYOTE_TIME: float = 0.14
const JUMP_BUFFER_TIME: float = 0.12
const HURT_DURATION: float = 0.35
const INVULNERABILITY_TIME: float = 1.0

const BASE_SCALE: Vector2 = Vector2(1.18, 1.18)

# --- Audio streams ---
var sfx_jump: AudioStream = preload("res://assets/audio/sfx/jump.wav")
var sfx_land: AudioStream = preload("res://assets/audio/sfx/land.wav")
var sfx_step: AudioStream = preload("res://assets/audio/sfx/step.wav")
var sfx_hurt: AudioStream = preload("res://assets/audio/sfx/hurt.wav")
var sfx_throw: AudioStream = preload("res://assets/audio/sfx/throw.wav")
var sfx_collect: AudioStream = preload("res://assets/audio/sfx/collect.wav")

# Projectile
var projectile_scene: PackedScene = preload("res://scenes/tren/piedra_projectile.tscn")

# --- Costume SpriteFrames ---
var frames_base: SpriteFrames = preload("res://resources/player_frames.tres")
var frames_camiseta: SpriteFrames = preload("res://resources/costume_camiseta.tres")
var frames_bufanda: SpriteFrames = preload("res://resources/costume_bufanda.tres")
var frames_completo: SpriteFrames = preload("res://resources/costume_completo.tres")
var frames_todo: SpriteFrames = preload("res://resources/costume_todo.tres")

# --- Nodes ---
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var throw_point: Marker2D = $ThrowPoint

# Overlays
@onready var scarf_overlay: Sprite2D = $ScarfOverlay
@onready var cap_overlay: Sprite2D = $CapOverlay
@onready var jersey_overlay: Sprite2D = $JerseyOverlay

# --- State & Timers ---
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var hurt_timer: float = 0.0
var invulnerable_timer: float = 0.0
var step_timer: float = 0.0
var is_throwing: bool = false
var is_celebrating: bool = false
var was_on_floor: bool = false
var facing_direction: float = 1.0

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)

func _ready() -> void:
	add_to_group("player")
	if GameManager:
		GameManager.accessory_equipped.connect(_on_accessory_equipped)
		update_accessory_visuals()

func _physics_process(delta: float) -> void:
	# Floor detection and Coyote Time
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		if not was_on_floor:
			play_sfx_safe(sfx_land)
			if animated_sprite:
				var tw = create_tween()
				tw.tween_property(animated_sprite, "scale", Vector2(1.36, 1.02), 0.06)
				tw.tween_property(animated_sprite, "scale", BASE_SCALE, 0.10)
	else:
		coyote_timer = max(0.0, coyote_timer - delta)

	# Timers
	if jump_buffer_timer > 0.0:
		jump_buffer_timer = max(0.0, jump_buffer_timer - delta)

	if hurt_timer > 0.0:
		hurt_timer = max(0.0, hurt_timer - delta)

	if invulnerable_timer > 0.0:
		invulnerable_timer = max(0.0, invulnerable_timer - delta)
		animated_sprite.modulate.a = 0.3 if int(invulnerable_timer * 18.0) % 2 == 0 else 1.0
	else:
		animated_sprite.modulate.a = 1.0

	# Lock during celebration
	if is_celebrating:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		play_animation("celebrate")
		return

	# Lock during hurt
	if hurt_timer > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		if not is_on_floor():
			velocity.y += gravity * delta
		move_and_slide()
		play_animation("hurt")
		return

	# Apply gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# --- INPUT GATHERING ---
	# Direct key checks ensure it ALWAYS responds even if InputMap has any edge case
	var pressing_left: bool = (
		Input.is_action_pressed("move_left") or 
		Input.is_key_pressed(KEY_LEFT) or 
		Input.is_key_pressed(KEY_A)
	)
	var pressing_right: bool = (
		Input.is_action_pressed("move_right") or 
		Input.is_key_pressed(KEY_RIGHT) or 
		Input.is_key_pressed(KEY_D)
	)
	var pressed_jump: bool = (
		Input.is_action_just_pressed("jump") or 
		Input.is_key_pressed(KEY_SPACE)
	)
	var released_jump: bool = (
		Input.is_action_just_released("jump")
	)
	var pressed_interact: bool = (
		Input.is_action_just_pressed("interact") or 
		Input.is_key_pressed(KEY_E)
	)
	var pressed_throw: bool = (
		Input.is_action_just_pressed("throw") or 
		Input.is_key_pressed(KEY_F)
	)
	var is_running: bool = (
		Input.is_key_pressed(KEY_SHIFT) or 
		(InputMap.has_action("run") and Input.is_action_pressed("run"))
	)

	# Jump Buffer
	if pressed_jump:
		jump_buffer_timer = JUMP_BUFFER_TIME

	# Jump execution
	if jump_buffer_timer > 0.0 and coyote_timer > 0.0:
		execute_jump()

	# Variable jump cut
	if released_jump and velocity.y < 0.0:
		velocity.y *= 0.5

	# Throw
	if pressed_throw and not is_throwing:
		execute_throw()

	# Interact
	if pressed_interact:
		execute_interact()

	# Horizontal movement
	var input_x: float = 0.0
	if pressing_left and not pressing_right:
		input_x = -1.0
	elif pressing_right and not pressing_left:
		input_x = 1.0

	var max_speed: float = RUN_SPEED if is_running else WALK_SPEED
	var target_speed: float = input_x * max_speed

	if input_x != 0.0:
		velocity.x = move_toward(velocity.x, target_speed, ACCELERATION * delta)
		facing_direction = input_x
		animated_sprite.flip_h = (facing_direction < 0.0)
		if throw_point:
			throw_point.position.x = abs(throw_point.position.x) * facing_direction

		# Footsteps sound
		if is_on_floor():
			step_timer += delta
			var interval: float = 0.22 if is_running else 0.32
			if step_timer >= interval:
				step_timer = 0.0
				play_sfx_safe(sfx_step)
	else:
		velocity.x = move_toward(velocity.x, 0.0, FRICTION * delta)
		step_timer = 0.0

	# Apply motion
	was_on_floor = is_on_floor()
	move_and_slide()

	# Update visual animations
	update_animation(input_x, is_running)

func execute_jump() -> void:
	velocity.y = JUMP_VELOCITY
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	play_sfx_safe(sfx_jump)
	if animated_sprite:
		var tw = create_tween()
		tw.tween_property(animated_sprite, "scale", Vector2(1.02, 1.36), 0.07)
		tw.tween_property(animated_sprite, "scale", BASE_SCALE, 0.12)

func execute_throw() -> void:
	# Check if player has stones
	if GameManager:
		var stones: int = GameManager.collected_items.get("piedra", 0)
		if stones <= 0:
			return
		GameManager.collected_items["piedra"] = stones - 1
		GameManager.item_collected.emit("piedra")

	is_throwing = true
	play_animation("throw")
	
	# Sincronización del movimiento del brazo:
	# Esperar a que el protagonista levante y adelante el brazo (fotogramas 0 y 1)
	await get_tree().create_timer(0.12).timeout
	if not is_instance_valid(self):
		return

	# La piedra sale de la mano en el momento exacto en que el brazo se extiende hacia adelante
	play_sfx_safe(sfx_throw)
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		var spawn_pos: Vector2 = global_position + Vector2(facing_direction * 28.0, -48.0)
		if throw_point:
			spawn_pos = throw_point.global_position
		proj.global_position = spawn_pos
		proj.direction = facing_direction
		get_parent().add_child(proj)

	# Completar el movimiento de seguimiento y recuperación del brazo
	await get_tree().create_timer(0.18).timeout
	is_throwing = false

func execute_interact() -> void:
	# Interaction with train elements (windows, passengers, signs)
	play_sfx_safe(sfx_collect)
	print("Interacción activada con tecla E")

func take_damage(amount: int = 15) -> void:
	if invulnerable_timer > 0.0 or is_celebrating:
		return
	hurt_timer = HURT_DURATION
	invulnerable_timer = INVULNERABILITY_TIME
	velocity.y = -180.0
	velocity.x = -facing_direction * 120.0
	play_sfx_safe(sfx_hurt)
	if GameManager:
		GameManager.take_damage(amount)

func collect_item(item_name: String, points: int = 50) -> void:
	play_sfx_safe(sfx_collect)
	if GameManager:
		GameManager.add_score(points)
		GameManager.collect_item(item_name)
		if item_name in ["bufanda", "camiseta", "gorra"]:
			GameManager.equip_accessory(item_name)
	update_accessory_visuals()

func celebrate() -> void:
	is_celebrating = true
	velocity = Vector2.ZERO
	play_animation("celebrate")

func update_animation(input_x: float, is_running: bool) -> void:
	if is_throwing:
		return
	if not is_on_floor():
		if velocity.y < 0.0:
			play_animation("jump")
		else:
			play_animation("fall")
	else:
		if abs(velocity.x) > 10.0:
			play_animation("run" if is_running else "walk")
		else:
			play_animation("idle")

func play_animation(anim_name: String) -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation(anim_name):
			if animated_sprite.animation != anim_name:
				animated_sprite.play(anim_name)

func play_sfx_safe(stream: AudioStream) -> void:
	if AudioManager:
		AudioManager.play_sfx(stream)

func _on_accessory_equipped(_name: String) -> void:
	update_accessory_visuals()

func update_accessory_visuals() -> void:
	if not GameManager:
		return
	var has_camiseta: bool = ("camiseta" in GameManager.current_accessories)
	var has_bufanda: bool = ("bufanda" in GameManager.current_accessories)
	var has_gorra: bool = ("gorra" in GameManager.current_accessories)
	
	var target_frames: SpriteFrames = frames_base
	if has_camiseta and has_bufanda and has_gorra:
		target_frames = frames_todo
	elif has_camiseta and has_bufanda:
		target_frames = frames_completo
	elif has_camiseta and has_gorra:
		target_frames = frames_completo
	elif has_bufanda and has_gorra:
		target_frames = frames_completo
	elif has_camiseta:
		target_frames = frames_camiseta
	elif has_bufanda:
		target_frames = frames_bufanda
	else:
		target_frames = frames_base
		
	if animated_sprite and animated_sprite.sprite_frames != target_frames:
		var cur_anim: StringName = animated_sprite.animation
		var cur_frame: int = animated_sprite.frame
		var cur_prog: float = animated_sprite.frame_progress
		animated_sprite.sprite_frames = target_frames
		if target_frames.has_animation(cur_anim):
			animated_sprite.play(cur_anim)
			animated_sprite.frame = cur_frame
			animated_sprite.frame_progress = cur_prog
		else:
			animated_sprite.play(&"idle")
			
	if scarf_overlay:
		scarf_overlay.visible = false
	if cap_overlay:
		cap_overlay.visible = has_gorra and not (has_camiseta or has_bufanda)
	if jersey_overlay:
		jersey_overlay.visible = false
