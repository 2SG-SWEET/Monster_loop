class_name TileModuleData
extends Resource

@export var module_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var initial_charge: int = 3
@export var spawn_elements: Array = []
@export var spawn_weights: Array = []
@export var special_effects: Dictionary = {}
@export var on_disappear_rewards: Dictionary = {}

func get_random_spawn_element() -> Enums.Element:
	if spawn_elements.is_empty():
		return Enums.Element.FIRE
	
	if spawn_weights.is_empty() or spawn_weights.size() != spawn_elements.size():
		return spawn_elements[randi() % spawn_elements.size()] as Enums.Element
	
	var total_weight: int = 0
	for w in spawn_weights:
		total_weight += w
	
	var roll := randi() % total_weight
	var current: int = 0
	
	for i in range(spawn_elements.size()):
		current += spawn_weights[i] as int
		if roll < current:
			return spawn_elements[i] as Enums.Element
	
	return spawn_elements[0] as Enums.Element

func to_dictionary() -> Dictionary:
	return {
		"module_id": module_id,
		"display_name": display_name,
		"description": description,
		"initial_charge": initial_charge,
		"spawn_elements": spawn_elements,
		"spawn_weights": spawn_weights,
		"special_effects": special_effects,
		"on_disappear_rewards": on_disappear_rewards
	}

static func from_dictionary(data: Dictionary) -> TileModuleData:
	var res := TileModuleData.new()
	res.module_id = data.get("module_id", "")
	res.display_name = data.get("display_name", "")
	res.description = data.get("description", "")
	res.initial_charge = data.get("initial_charge", 3)
	res.spawn_elements = data.get("spawn_elements", [])
	res.spawn_weights = data.get("spawn_weights", [])
	res.special_effects = data.get("special_effects", {})
	res.on_disappear_rewards = data.get("on_disappear_rewards", {})
	return res
