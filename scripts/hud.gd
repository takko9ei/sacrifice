extends CanvasLayer
# Icon-based status indicator (GDD §4.1/§4.2): N slot boxes for capacity,
# one icon per unlocked concept — locked concepts simply have no icon yet
# (equivalent to "hidden"), unlocked-inactive icons are dim, active icons
# are bright. Icons are plain ColorRects — swap the colors/replace with real
# art later without touching this script. Driven only by Sacrifice's public
# signals and getters, same "reacts to Sacrifice" pattern as blue_object.gd.
# Also owns the lightweight whole-screen flash feedback on concept toggle
# (GDD §4.3).

@export var layout_path: NodePath = ^"Layout"
@export var slots_container_path: NodePath = ^"Layout/SlotsRow"
@export var icons_container_path: NodePath = ^"Layout/IconsRow"
@export var flash_overlay_path: NodePath = ^"FlashOverlay"
@export var flash_color: Color = Color(1, 1, 1, 0.5)
@export var flash_duration: float = 0.12
@export var dismantle_duration: float = 0.6
@export var slot_size: Vector2 = Vector2(28, 28)
@export var icon_size: Vector2 = Vector2(28, 28)
@export var slot_empty_color: Color = Color(1, 1, 1, 0.15)
@export var slot_filled_color: Color = Color(1, 1, 1, 0.85)
@export var icon_inactive_color: Color = Color(0.6, 0.6, 0.65, 1.0)
@export var icon_active_color: Color = Color(1, 0.85, 0.2, 1.0)

var _layout: Control
var _slots_container: Control
var _icons_container: Control
var _flash_overlay: ColorRect
var _slot_boxes: Array[ColorRect] = []
var _icon_by_concept: Dictionary = {}


func _ready() -> void:
	_layout = get_node(layout_path) as Control
	_slots_container = get_node(slots_container_path) as Control
	_icons_container = get_node(icons_container_path) as Control
	_flash_overlay = get_node(flash_overlay_path) as ColorRect
	_flash_overlay.color = flash_color
	_flash_overlay.modulate.a = 0.0

	Sacrifice.concept_unlocked.connect(_on_concept_unlocked)
	Sacrifice.concept_activated.connect(_on_toggled)
	Sacrifice.concept_deactivated.connect(_on_toggled)
	Sacrifice.slots_changed.connect(_on_slots_changed)
	Sacrifice.concept_permanently_sacrificed.connect(_on_permanently_sacrificed)

	for id in Sacrifice.get_unlocked():
		_add_icon(id)
	_rebuild_slots()
	_refresh_icons()


func _on_concept_unlocked(id: String) -> void:
	_add_icon(id)
	_refresh_icons()


func _on_toggled(_id: String) -> void:
	_refresh_icons()
	_refresh_slot_colors()
	_play_flash()


func _on_slots_changed(_new_slots: int) -> void:
	_rebuild_slots()


func _on_permanently_sacrificed(id: String) -> void:
	if id == "hud":
		_dismantle()


func _dismantle() -> void:
	# The flash overlay is left alone on purpose: GDD §5.5 wants the player to
	# fall back on "memory and screen feedback" after this, and the toggle
	# flash is that remaining feedback channel.
	var tween: Tween = create_tween()
	tween.tween_property(_layout, "modulate:a", 0.0, dismantle_duration)
	tween.tween_callback(_layout.hide)


func _add_icon(id: String) -> void:
	if _icon_by_concept.has(id):
		return
	var icon: ColorRect = ColorRect.new()
	icon.custom_minimum_size = icon_size
	icon.color = icon_inactive_color
	_icons_container.add_child(icon)
	_icon_by_concept[id] = icon


func _refresh_icons() -> void:
	var active: Array[String] = Sacrifice.get_active()
	for id in _icon_by_concept:
		var icon: ColorRect = _icon_by_concept[id]
		icon.color = icon_active_color if active.has(id) else icon_inactive_color


func _rebuild_slots() -> void:
	for box in _slot_boxes:
		box.queue_free()
	_slot_boxes.clear()
	for i in Sacrifice.max_slots:
		var box: ColorRect = ColorRect.new()
		box.custom_minimum_size = slot_size
		_slots_container.add_child(box)
		_slot_boxes.append(box)
	_refresh_slot_colors()


func _refresh_slot_colors() -> void:
	var active_count: int = Sacrifice.get_active().size()
	for i in _slot_boxes.size():
		_slot_boxes[i].color = slot_filled_color if i < active_count else slot_empty_color


func _play_flash() -> void:
	_flash_overlay.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(_flash_overlay, "modulate:a", 0.0, flash_duration)
