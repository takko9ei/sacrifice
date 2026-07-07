extends Node
# Maps input actions to concept toggles (GDD §3.1, §7.3). To add a new
# concept's key binding, add an entry here (and the input action in Project
# Settings) — no changes to Sacrifice or Player needed.

@export var bindings: Dictionary = {
	"sacrifice_gravity": "gravity",
	"sacrifice_blue": "blue",
	"sacrifice_red": "red",
	"sacrifice_green": "green",
}


func _unhandled_input(event: InputEvent) -> void:
	for action in bindings:
		if event.is_action_pressed(action):
			var concept_id: String = bindings[action]
			if Sacrifice.is_unlocked(concept_id):
				Sacrifice.toggle(concept_id)
