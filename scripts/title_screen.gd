extends Node2D
# Title screen controller: plays the title character animation, then visually
# "sacrifices" the title screen before loading the integration level.

@export_file("*.tscn") var next_scene_path: String = "res://scenes/Level1.tscn"
@export var crack_duration: float = 0.65
@export var hold_after_crack: float = 0.12
@export var title_label_path: NodePath = ^"TitleLayer/Title"
@export var prompt_label_path: NodePath = ^"TitleLayer/Prompt"
@export var character_path: NodePath = ^"TitleLayer/Character"
@export var shards_root_path: NodePath = ^"TitleLayer/Shards"
@export var preview_player_visual_path: NodePath = ^"IntegrationPreview/Player/AnimatedSprite2D"
@export var preview_intro_prompt_path: NodePath = ^"IntegrationPreview/IntroPrompt"
@export var character_target_position: Vector2 = Vector2(642, 354)
@export var character_target_scale: Vector2 = Vector2(1, 1)

var _started: bool = false
var _title_label: Label
var _prompt_label: Label
var _character: AnimatedSprite2D
var _shards_root: Node


func _ready() -> void:
	Sacrifice.reset()
	_title_label = get_node(title_label_path) as Label
	_prompt_label = get_node(prompt_label_path) as Label
	_character = get_node(character_path) as AnimatedSprite2D
	_shards_root = get_node(shards_root_path)
	_hide_preview_intro()
	_character.play("stand")


func _unhandled_input(event: InputEvent) -> void:
	if _started or not event.is_action_pressed("interact"):
		return
	_started = true
	get_viewport().set_input_as_handled()
	_sacrifice_title()


func _sacrifice_title() -> void:
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(_title_label, "modulate:a", 0.0, crack_duration * 0.5)
	tween.tween_property(_prompt_label, "modulate:a", 0.0, crack_duration * 0.5)
	tween.tween_property(_character, "position", character_target_position, crack_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_character, "scale", character_target_scale, crack_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	var shard_moves: Array[Vector2] = [
		Vector2(-160, -120),
		Vector2(160, -120),
		Vector2(-160, 120),
		Vector2(160, 120),
	]
	var i: int = 0
	for shard in _shards_root.get_children():
		if shard is ColorRect:
			var move: Vector2 = shard_moves[i % shard_moves.size()]
			tween.tween_property(shard, "position", shard.position + move, crack_duration) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tween.tween_property(shard, "rotation", (-0.18 if i % 2 == 0 else 0.18), crack_duration)
			tween.tween_property(shard, "modulate:a", 0.0, crack_duration)
			i += 1

	tween.set_parallel(false)
	tween.tween_interval(hold_after_crack)
	tween.tween_callback(_go_to_next_scene)


func _go_to_next_scene() -> void:
	get_tree().change_scene_to_file(next_scene_path)


func _hide_preview_intro() -> void:
	var preview_player_visual: CanvasItem = get_node_or_null(preview_player_visual_path) as CanvasItem
	if preview_player_visual:
		preview_player_visual.modulate.a = 0.0

	var preview_intro_prompt: CanvasItem = get_node_or_null(preview_intro_prompt_path) as CanvasItem
	if preview_intro_prompt:
		preview_intro_prompt.modulate.a = 0.0
