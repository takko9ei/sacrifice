extends CharacterBody2D
class_name Player
# Player movement controller: ground/air acceleration+friction, split-gravity
# jump (GDD §3.2), coyote time, jump buffer, variable jump height, and the
# `gravity` sacrifice (GDD §2.6, §3.5). Every feel number comes from
# `config` (PlayerConfig) — no hardcoded movement/jump numbers here
# (CLAUDE.md rule 2). `blue` and other world-facing concepts are not the
# player's concern (see blue_object.gd / GDD §7.6).

@onready var jump_sound = $JumpSound
@export var config: PlayerConfig
@export var sprite_path: NodePath = ^"AnimatedSprite2D"

var _sprite: AnimatedSprite2D
var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _facing_right: bool = true
var _current_animation: String = ""


func _ready() -> void:
	if config == null:
		config = PlayerConfig.new()
	_sprite = get_node(sprite_path) as AnimatedSprite2D
	Sacrifice.concept_activated.connect(_on_concept_activated)
	Sacrifice.concept_deactivated.connect(_on_concept_deactivated)


func _on_concept_activated(id: String) -> void:
	if id != "gravity":
		return
	# up_direction reversed so is_on_floor()/floor-snap treat the ceiling as
	# the floor; velocity.x is left untouched (GDD §3.5).
	up_direction = Vector2.DOWN
	if _sprite:
		_sprite.flip_v = true


func _on_concept_deactivated(id: String) -> void:
	if id != "gravity":
		return
	up_direction = Vector2.UP
	if _sprite:
		_sprite.flip_v = false


func _gravity_sign() -> float:
	return -1.0 if up_direction == Vector2.DOWN else 1.0


func _physics_process(delta: float) -> void:
	# Split-gravity: rising and falling each get their own derived gravity so
	# jump arcs can be tuned via height/time rather than raw acceleration.
	var gravity_rise: float = (2.0 * config.jump_height) / (config.time_to_peak * config.time_to_peak)
	var gravity_fall: float = (2.0 * config.jump_height) / (config.time_to_fall * config.time_to_fall)
	var jump_velocity: float = (2.0 * config.jump_height) / config.time_to_peak

	_apply_horizontal_movement(delta)
	_apply_gravity(delta, gravity_rise, gravity_fall)
	_update_timers(delta)
	_handle_jump_input(jump_velocity)
	move_and_slide()
	_update_animation()


func _apply_horizontal_movement(delta: float) -> void:
	var input_dir: float = Input.get_axis("move_left", "move_right")
	var grounded: bool = is_on_floor()
	var target_speed: float = input_dir * config.move_speed
	var rate: float
	if input_dir != 0.0:
		rate = config.ground_acceleration if grounded else config.air_acceleration
		_facing_right = input_dir > 0.0
	else:
		rate = config.ground_friction if grounded else config.air_friction
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)


func _apply_gravity(delta: float, gravity_rise: float, gravity_fall: float) -> void:
	# falling_speed is velocity measured along the current gravity direction,
	# so the rise/fall split and the fall-speed clamp work the same whether
	# gravity currently points down (normal) or up (flipped).
	var grav_sign: float = _gravity_sign()
	var falling_speed: float = velocity.y * grav_sign
	var g: float = gravity_fall if falling_speed >= 0.0 else gravity_rise
	falling_speed = min(falling_speed + g * delta, config.max_fall_speed)
	velocity.y = falling_speed * grav_sign


func _update_timers(delta: float) -> void:
	if is_on_floor():
		_coyote_timer = config.coyote_time
	else:
		_coyote_timer = max(_coyote_timer - delta, 0.0)
	if Input.is_action_just_pressed("jump") and not Sacrifice.is_permanently_sacrificed("jump"):
		_jump_buffer_timer = config.jump_buffer_time
	else:
		_jump_buffer_timer = max(_jump_buffer_timer - delta, 0.0)


func _handle_jump_input(jump_velocity: float) -> void:
	var grav_sign: float = _gravity_sign()
	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		velocity.y = -jump_velocity * grav_sign
		jump_sound.play()
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
	elif Input.is_action_just_released("jump") and velocity.y * grav_sign < 0.0:
		velocity.y *= config.jump_cut_multiplier


func _update_animation() -> void:
	if _sprite == null:
		return
	var anim: String
	if is_on_floor():
		anim = "idle" if is_zero_approx(velocity.x) else "run"
	else:
		anim = "jump" if velocity.y * _gravity_sign() < 0.0 else "fall"
	if anim != _current_animation:
		_current_animation = anim
		_sprite.play(anim)
	_sprite.flip_h = not _facing_right
