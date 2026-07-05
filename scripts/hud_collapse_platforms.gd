extends Node2D
# `hud` sacrifice set-piece (GDD §2.6 hud entry, §5.5): when "hud" is
# permanently sacrificed, drop one static platform per Marker2D child of
# this node. Positions are configured entirely by placing/moving Marker2D
# children in the editor — no coordinates live in this script. Copy this
# node into a level, park it near whatever gap/ledge needs bridging, and
# add a Marker2D per landing spot.

@export var platform_size: Vector2 = Vector2(100, 20)
@export var platform_color: Color = Color(0.55, 0.5, 0.35, 1)
@export var drop_height: float = 60.0
@export var drop_duration: float = 0.4


func _ready() -> void:
	Sacrifice.concept_permanently_sacrificed.connect(_on_permanently_sacrificed)


func _on_permanently_sacrificed(id: String) -> void:
	if id == "hud":
		_spawn_platforms()


func _spawn_platforms() -> void:
	for marker in get_children():
		if marker is Marker2D:
			_spawn_platform_at(marker.global_position)


func _spawn_platform_at(target_position: Vector2) -> void:
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = platform_size

	var collision_shape: CollisionShape2D = CollisionShape2D.new()
	collision_shape.shape = shape

	var half: Vector2 = platform_size / 2.0
	var visual: Polygon2D = Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	visual.color = platform_color

	var body: StaticBody2D = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	body.add_child(collision_shape)
	body.add_child(visual)

	add_child(body)
	body.global_position = target_position + Vector2(0, -drop_height)
	var tween: Tween = create_tween()
	tween.tween_property(body, "global_position", target_position, drop_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
