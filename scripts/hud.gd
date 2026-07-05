extends CanvasLayer
# Minimal text status indicator (GDD §4.1/§4.2): shows Slots / Active /
# Unlocked, driven only by Sacrifice's signals and public getters — never
# reads its private fields (CLAUDE.md rule 3 applies to HUD too, since it is
# itself a "reacts to sacrifice" object). Also owns the lightweight
# whole-screen flash feedback on concept toggle (GDD §4.3); kept here rather
# than as a separate global system per the step's scope.

@export var label_path: NodePath = ^"Label"
@export var flash_overlay_path: NodePath = ^"FlashOverlay"
@export var flash_color: Color = Color(1, 1, 1, 0.5)
@export var flash_duration: float = 0.12

var _label: Label
var _flash_overlay: ColorRect


func _ready() -> void:
	_label = get_node(label_path) as Label
	_flash_overlay = get_node(flash_overlay_path) as ColorRect
	_flash_overlay.color = flash_color
	_flash_overlay.modulate.a = 0.0

	Sacrifice.concept_activated.connect(_on_toggled)
	Sacrifice.concept_deactivated.connect(_on_toggled)
	Sacrifice.concept_unlocked.connect(_on_state_changed)
	Sacrifice.slots_changed.connect(_on_state_changed)
	Sacrifice.concept_permanently_sacrificed.connect(_on_state_changed)

	_refresh_label()


func _on_toggled(_id: String) -> void:
	_refresh_label()
	_play_flash()


func _on_state_changed(_value = null) -> void:
	_refresh_label()


func _refresh_label() -> void:
	var active: Array[String] = Sacrifice.get_active()
	var unlocked: Array[String] = Sacrifice.get_unlocked()
	_label.text = "Slots: %d/%d\nActive: %s\nUnlocked: %s" % [
		active.size(), Sacrifice.max_slots, ", ".join(active), ", ".join(unlocked)
	]


func _play_flash() -> void:
	_flash_overlay.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(_flash_overlay, "modulate:a", 0.0, flash_duration)
	_play_toggle_sfx_hook()


func _play_toggle_sfx_hook() -> void:
	pass # Hook for a toggle sound effect once audio is wired up (later step).
