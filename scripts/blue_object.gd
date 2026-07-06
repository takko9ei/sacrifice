extends StaticBody2D
# Generic reactive-object template (GDD §7.6): listens to Sacrifice for its
# own concept_id, disables collision + fades when that concept is active,
# restores when it is not. To add a new reactive concept, copy this file,
# change concept_id (and the color/shape in the matching .tscn) — do not
# add per-object branches to sacrifice_manager.gd.

@export var concept_id: String = "blue"
@export var solid_alpha: float = 1.0
@export var passable_alpha: float = 0.35
@export var collision_shape_path: NodePath = ^"CollisionShape2D"
@export var visual_path: NodePath = ^"Visual"

var _collision_shape: CollisionShape2D
var _visual: CanvasItem


func _ready() -> void:
	_collision_shape = get_node_or_null(collision_shape_path) as CollisionShape2D
	_visual = get_node_or_null(visual_path) as CanvasItem
	Sacrifice.concept_activated.connect(_on_concept_activated)
	Sacrifice.concept_deactivated.connect(_on_concept_deactivated)
	_apply_state(Sacrifice.is_active(concept_id))


func _on_concept_activated(id: String) -> void:
	if id == concept_id:
		_apply_state(true)


func _on_concept_deactivated(id: String) -> void:
	if id == concept_id:
		_apply_state(false)


func _apply_state(passable: bool) -> void:
	if _collision_shape:
		_collision_shape.set_deferred("disabled", passable)
	if _visual:
		var c: Color = _visual.modulate
		c.a = passable_alpha if passable else solid_alpha
		_visual.modulate = c
