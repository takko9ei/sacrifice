extends Node2D
# TEMPORARY step-2 test scaffold: unlocks gravity/blue directly so they can
# be play-tested before altars exist. Step 3 adds real Altar-driven unlocking
# — delete this script (and its `script =` reference on TestRoom.tscn) once
# that lands.

func _ready() -> void:
	Sacrifice.unlock("gravity")
	Sacrifice.unlock("blue")
