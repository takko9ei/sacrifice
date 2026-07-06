extends Node
# Sacrifice singleton (autoload name must be exactly "Sacrifice", see CLAUDE.md).
# The single source of truth for all sacrifice-related state. Every other
# system must talk to it only through these signals/queries/commands —
# never build a second global state holder (GDD §7.2, CLAUDE.md rule 1).

signal concept_activated(id: String)
signal concept_deactivated(id: String)
signal concept_unlocked(id: String)
signal slots_changed(new_slots: int)
signal concept_permanently_sacrificed(id: String)

var max_slots: int = 1

# Activation order matters: index 0 is the earliest-activated concept, which
# is what gets evicted first when a new activation would exceed max_slots.
var _active: Array[String] = []
var _unlocked: Dictionary = {}
var _permanently_sacrificed: Dictionary = {}


func is_unlocked(id: String) -> bool:
	return _unlocked.has(id)


func is_active(id: String) -> bool:
	return _active.has(id)


func is_permanently_sacrificed(id: String) -> bool:
	return _permanently_sacrificed.has(id)


func get_active() -> Array[String]:
	return _active.duplicate()


func get_unlocked() -> Array[String]:
	var ids: Array[String] = []
	for id in _unlocked.keys():
		ids.append(id)
	return ids


func unlock(id: String) -> void:
	if is_unlocked(id):
		return
	_unlocked[id] = true
	concept_unlocked.emit(id)


func activate(id: String) -> void:
	if is_permanently_sacrificed(id) or not is_unlocked(id) or is_active(id):
		return
	# Single/double-slot constraint: evict the earliest-activated concept(s)
	# until there is room. This is the only place this rule is implemented.
	while _active.size() >= max_slots:
		var oldest: String = _active.pop_front()
		concept_deactivated.emit(oldest)
	_active.append(id)
	concept_activated.emit(id)


func deactivate(id: String) -> void:
	if not is_active(id):
		return
	_active.erase(id)
	concept_deactivated.emit(id)


func toggle(id: String) -> void:
	if is_active(id):
		deactivate(id)
	else:
		activate(id)


func set_max_slots(n: int) -> void:
	if n == max_slots:
		return
	max_slots = n
	while _active.size() > max_slots:
		var oldest: String = _active.pop_front()
		concept_deactivated.emit(oldest)
	slots_changed.emit(max_slots)


func permanently_sacrifice(id: String) -> void:
	if is_permanently_sacrificed(id):
		return
	if is_active(id):
		deactivate(id)
	_permanently_sacrificed[id] = true
	concept_permanently_sacrificed.emit(id)


func reset() -> void:
	for id in _active.duplicate():
		concept_deactivated.emit(id)
	_active.clear()
	_unlocked.clear()
	_permanently_sacrificed.clear()
	if max_slots != 1:
		max_slots = 1
		slots_changed.emit(max_slots)
