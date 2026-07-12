extends Node
# Demo restart: pressing "restart" wipes Sacrifice state and reloads the
# current scene. Sacrifice is an autoload and get_tree().paused is a
# SceneTree-level flag — neither resets on scene reload, so both must be
# cleared explicitly here or the "fresh" reloaded scene would inherit stale
# unlocked/active/permanent concepts and could still be frozen mid-ending.
# process_mode is Always (see Level1.tscn) so restart still works
# mid-ending.

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		Sacrifice.reset()
		get_tree().paused = false
		get_tree().reload_current_scene()
