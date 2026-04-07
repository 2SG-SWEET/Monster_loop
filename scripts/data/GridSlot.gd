class_name GridSlot
extends RefCounted

var slot_index: int = -1
var position: Vector2 = Vector2.ZERO
var is_occupied: bool = false
var module_instance: BaseTileModule = null

func _init(index: int = -1, pos: Vector2 = Vector2.ZERO):
	slot_index = index
	position = pos

func set_module(module: BaseTileModule) -> void:
	module_instance = module
	is_occupied = true

func clear_module() -> void:
	module_instance = null
	is_occupied = false

func has_module() -> bool:
	return module_instance != null and is_instance_valid(module_instance)

func get_charge() -> int:
	if module_instance == null:
		return 0
	return module_instance.get_charge()

func to_dictionary() -> Dictionary:
	return {
		"slot_index": slot_index,
		"position": {"x": position.x, "y": position.y},
		"is_occupied": is_occupied
	}
