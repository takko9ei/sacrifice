extends Area2D
class_name Altar
# Generic altar trigger (GDD §2.6 concept table, §5.2, §8.3, §9.1). Entering
# only shows the hint; the player must press "interact" while inside to fire
# one Sacrifice command. All behavior is Inspector-driven — never hardcode a
# specific concept here. Stack multiple Altar instances at the same spot to
# fire several actions from one confirm (e.g. the double-slot shrine:
# SET_SLOTS + PERMANENT_SACRIFICE together).

enum Action { UNLOCK, SET_SLOTS, PERMANENT_SACRIFICE }

@export var action: Action = Action.UNLOCK
@export var concept_id: String = ""
@export var slot_count: int = 2
@export var one_shot: bool = true
@export var message: String = ""
@export var hint_path: NodePath = ^"Hint"

signal triggered

var _fired: bool = false
var _player_inside: bool = false
var _hint: Label


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_hint = get_node_or_null(hint_path) as Label
	if _hint:
		_hint.text = message
		_hint.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		_trigger()


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	_player_inside = true
	if not (one_shot and _fired):
		_set_hint_visible(true)


func _on_body_exited(body: Node2D) -> void:
	if not (body is Player):
		return
	_player_inside = false
	_set_hint_visible(false)


func _trigger() -> void:
	if one_shot and _fired:
		return
	match action:
		Action.UNLOCK:
			Sacrifice.unlock(concept_id)
		Action.SET_SLOTS:
			Sacrifice.set_max_slots(slot_count)
		Action.PERMANENT_SACRIFICE:
			Sacrifice.permanently_sacrifice(concept_id)
	_fired = true
	_set_hint_visible(false)
	triggered.emit()


func _set_hint_visible(show_hint: bool) -> void:
	if _hint:
		_hint.visible = show_hint
