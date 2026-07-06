@tool
extends StaticBody2D
# Reusable level geometry block (floor/ceiling/wall/ledge/platform): a solid
# rectangle whose size and color are Inspector-driven. The collision shape
# and the visual polygon are regenerated together from `size`, so level
# design only ever touches `size`/`color` here instead of hand-editing a
# RectangleShape2D and a matching Polygon2D separately (and risking the two
# drifting out of sync). Scale the node for a quick stretch, same as any
# other prefab in this project (e.g. BlueObject).

@export var size: Vector2 = Vector2(200, 40):
	set(value):
		size = value
		_apply()
@export var color: Color = Color(0.29, 0.29, 0.33, 1):
	set(value):
		color = value
		_apply()
@export var collision_shape_path: NodePath = ^"CollisionShape2D"
@export var visual_path: NodePath = ^"Visual"

var _collision_shape: CollisionShape2D
var _visual: Polygon2D


func _ready() -> void:
	_collision_shape = get_node_or_null(collision_shape_path) as CollisionShape2D
	_visual = get_node_or_null(visual_path) as Polygon2D
	_apply()


func _apply() -> void:
	if _collision_shape == null:
		_collision_shape = get_node_or_null(collision_shape_path) as CollisionShape2D
	if _visual == null:
		_visual = get_node_or_null(visual_path) as Polygon2D
	if _collision_shape == null or _visual == null:
		return

	# Always create a fresh shape rather than mutating `.shape` in place:
	# sub-resources loaded from a scene are shared across every instance of
	# that scene unless duplicated per-instance, so mutating a shared shape
	# would make every Ground instance in a level snap to whichever one
	# applied last.
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	_collision_shape.shape = shape

	var half: Vector2 = size / 2.0
	_visual.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y),
	])
	_visual.color = color
