extends CanvasLayer
# Fourthwall ending sequence (GDD §2.6 fourthwall, §5.6): fade the HUD,
# darken the screen, show one line of text, then hold on black. Purely
# visual — never touches the OS window (no fullscreen toggle, no quit).
# Fires once when "fourthwall" is permanently sacrificed. process_mode is
# Always (see EndingSequence.tscn) and _play_sequence() pauses the tree
# itself so the rest of the game freezes while this keeps animating.
# Decoupled from HUD — only listens for Sacrifice.concept_permanently_sacrificed,
# and hud_fade_target_path is a plain Inspector-wired reference, not a
# hardcoded scene path.

@export var hud_fade_target_path: NodePath = ^""
@export var ending_text: String = "Thank you for playing."
@export var hud_fade_duration: float = 0.8
@export var dissolve_duration: float = 1.5
@export var dissolve_alpha: float = 0.85
@export var text_fade_duration: float = 1.0
@export var text_hold_duration: float = 2.0
@export var final_fade_duration: float = 1.0
@export var return_to_title_delay: float = 1.0
@export_file("*.tscn") var title_scene_path: String = "res://scenes/TitleScreen.tscn"
@export var skip_sequence: bool = false

@export var overlay_path: NodePath = ^"Overlay"
@export var label_path: NodePath = ^"Label"

var _overlay: ColorRect
var _label: Label


func _ready() -> void:
	_overlay = get_node(overlay_path) as ColorRect
	_label = get_node(label_path) as Label
	_label.text = ending_text
	_label.modulate.a = 0.0
	_overlay.modulate.a = 0.0
	Sacrifice.concept_permanently_sacrificed.connect(_on_permanently_sacrificed)


func _on_permanently_sacrificed(id: String) -> void:
	if id == "fourthwall":
		_play_sequence()


func _play_sequence() -> void:
	if skip_sequence:
		_return_to_title()
		return

	get_tree().paused = true
	var hud_target: CanvasItem = get_node_or_null(hud_fade_target_path) as CanvasItem
	var tween: Tween = create_tween()
	if hud_target:
		tween.tween_property(hud_target, "modulate:a", 0.0, hud_fade_duration)
	tween.tween_property(_overlay, "modulate:a", dissolve_alpha, dissolve_duration)
	tween.tween_property(_label, "modulate:a", 1.0, text_fade_duration)
	tween.tween_interval(text_hold_duration)
	tween.tween_property(_label, "modulate:a", 0.0, final_fade_duration)
	tween.parallel().tween_property(_overlay, "modulate:a", 1.0, final_fade_duration)
	tween.tween_interval(return_to_title_delay)
	tween.tween_callback(_return_to_title)


func _return_to_title() -> void:
	Sacrifice.reset()
	get_tree().paused = false
	get_tree().change_scene_to_file(title_scene_path)
