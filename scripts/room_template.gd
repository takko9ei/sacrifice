extends Node2D
# ROOM TEMPLATE — copy this whole scene to start a new room.
#
# A room is just: a ground/terrain layer (Ground.tscn instances, Layer 1) +
# whichever prefabs react to the player (Altar.tscn, BlueObject.tscn, and
# friends). Nothing here is bespoke code — every piece is an existing
# reusable prefab configured entirely from the Inspector.
#
# How to use:
# 1. Duplicate this .tscn (or instance it and un-pack/"Editable Children" it)
#    into your own scene file, then reposition/resize the pieces.
# 2. "Ground" is a Ground.tscn instance: a StaticBody2D (Layer 1) with a
#    `size` and `color` export that keep its collision shape and visual
#    polygon in sync automatically — just change `size`, no manual shape or
#    polygon editing needed. Use the node's own `scale` for a quick stretch
#    instead. Copy/paste more instances for more terrain.
# 3. "ExampleAltar" is an Altar.tscn instance. Set `action` (UNLOCK /
#    SET_SLOTS / PERMANENT_SACRIFICE), `concept_id`, and `message` in the
#    Inspector — that's the whole job, no script edits. Its Hint label (a
#    child of the Altar) is the world-in-diegetic control prompt; you don't
#    need to add a separate hint node, it's built in and driven by
#    `message`. Stack two Altar instances at the same position if one spot
#    needs to do two things at once (see the double-slot shrine pattern).
# 4. "ExampleMechanism" is a BlueObject.tscn instance — the generic
#    reactive-object template (GDD §7.6). It goes solid/transparent based on
#    whichever `concept_id` you set on it; scale the node to resize it
#    (both its collision shape and visual scale together). Copy this file to
#    react to a different concept, or see hud_collapse_platforms.gd for a
#    different reactive shape (spawning geometry instead of toggling it).
# 5. Never touch sacrifice_manager.gd, altar.gd, or blue_object.gd to make a
#    new room — if you find yourself wanting to, something's off; ask.
