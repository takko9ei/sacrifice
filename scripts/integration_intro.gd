extends Node
# Integration-level intro gate: the player begins as the title character art,
# cannot move, and pressing interact sacrifices that intro shell into gameplay.

@export var player_path: NodePath = ^"Player"
@export var prompt_path: NodePath = ^"IntroPrompt"
@export var gameplay_frames: SpriteFrames
@export var locked_frames: SpriteFrames
@export var gameplay_animation: String = "idle"
@export var locked_animation: String = "stand"
@export var unlock_flash_duration: float = 0.18
@export var shatter_duration: float = 0.45
@export var shard_distance: float = 42.0

var _player: Player
var _sprite: AnimatedSprite2D
var _prompt: Label
var _unlocked: bool = false


func _ready() -> void:
	_player = get_node(player_path) as Player
	_sprite = _player.get_node(_player.sprite_path) as AnimatedSprite2D
	_prompt = get_node(prompt_path) as Label

	_player.velocity = Vector2.ZERO
	_player.set_physics_process(false)
	if locked_frames:
		_sprite.sprite_frames = locked_frames
	_sprite.play(locked_animation)
	_prompt.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if _unlocked or not event.is_action_pressed("interact"):
		return
	_unlocked = true
	get_viewport().set_input_as_handled()
	_unlock_player()


func _unlock_player() -> void:
	_prompt.hide()
	var shards: Array[Sprite2D] = _spawn_shards()
	_sprite.hide()

	var shatter_tween: Tween = create_tween()
	shatter_tween.set_parallel(true)
	var directions: Array[Vector2] = [
		Vector2(-1, -1),
		Vector2(1, -1),
		Vector2(-1, 1),
		Vector2(1, 1),
	]
	for i in range(shards.size()):
		var shard: Sprite2D = shards[i]
		var direction: Vector2 = directions[i % directions.size()].normalized()
		shatter_tween.tween_property(shard, "global_position", shard.global_position + direction * shard_distance, shatter_duration) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shatter_tween.tween_property(shard, "rotation", (-0.35 if i % 2 == 0 else 0.35), shatter_duration)
		shatter_tween.tween_property(shard, "modulate:a", 0.0, shatter_duration)

	shatter_tween.set_parallel(false)
	shatter_tween.tween_callback(func() -> void:
		for shard in shards:
			shard.queue_free()
		_show_gameplay_sprite()
	)


func _show_gameplay_sprite() -> void:
	if gameplay_frames:
		_sprite.sprite_frames = gameplay_frames
	_sprite.play(gameplay_animation)
	_sprite.modulate = Color(1, 1, 1, 0.2)
	_sprite.show()

	var tween: Tween = create_tween()
	tween.tween_property(_sprite, "modulate:a", 1.0, unlock_flash_duration)
	tween.tween_callback(_enable_player)


func _enable_player() -> void:
	_player.set_physics_process(true)


func _spawn_shards() -> Array[Sprite2D]:
	var shards: Array[Sprite2D] = []
	if _sprite.sprite_frames == null or not _sprite.sprite_frames.has_animation(locked_animation):
		return shards

	var frame_count: int = _sprite.sprite_frames.get_frame_count(locked_animation)
	if frame_count <= 0:
		return shards

	var frame_index: int = clampi(_sprite.frame, 0, frame_count - 1)
	var texture: Texture2D = _sprite.sprite_frames.get_frame_texture(locked_animation, frame_index)
	if texture == null:
		return shards

	var texture_size: Vector2 = texture.get_size()
	var half_size: Vector2 = texture_size / 2.0
	var quarter_size: Vector2 = texture_size / 4.0
	var rects: Array[Rect2] = [
		Rect2(Vector2.ZERO, half_size),
		Rect2(Vector2(half_size.x, 0), half_size),
		Rect2(Vector2(0, half_size.y), half_size),
		Rect2(half_size, half_size),
	]
	var offsets: Array[Vector2] = [
		Vector2(-quarter_size.x, -quarter_size.y),
		Vector2(quarter_size.x, -quarter_size.y),
		Vector2(-quarter_size.x, quarter_size.y),
		Vector2(quarter_size.x, quarter_size.y),
	]

	for i in rects.size():
		var shard := Sprite2D.new()
		shard.texture = texture
		shard.region_enabled = true
		shard.region_rect = rects[i]
		shard.centered = true
		shard.texture_filter = _sprite.texture_filter
		shard.flip_h = _sprite.flip_h
		shard.flip_v = _sprite.flip_v
		shard.scale = _sprite.global_scale
		shard.global_rotation = _sprite.global_rotation
		get_parent().add_child(shard)
		shard.global_position = _sprite.global_position + offsets[i] * _sprite.global_scale
		shards.append(shard)

	return shards
