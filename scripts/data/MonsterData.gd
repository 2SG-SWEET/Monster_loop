class_name MonsterData
extends Resource

@export var monster_id: String = ""
@export var display_name: String = ""
@export var species: String = ""
@export var element: Enums.Element = Enums.Element.FIRE
@export var level: int = 1
@export var base_hp: int = 100
@export var base_atk: int = 30
@export var base_def: int = 20
@export var base_spd: int = 20
@export var skills: Array = []
@export var traits: Array = []
@export var capture_rate: float = 0.4
@export var sprite_path: String = ""
@export var rarity: int = 0

func get_scaled_stats(level_offset: int = 0) -> Dictionary:
	var actual_level := level + level_offset
	return {
		"hp": base_hp + actual_level * 10,
		"atk": base_atk + actual_level * 3,
		"def": base_def + actual_level * 2,
		"spd": base_spd + actual_level
	}

func to_dictionary() -> Dictionary:
	return {
		"monster_id": monster_id,
		"display_name": display_name,
		"species": species,
		"element": element,
		"level": level,
		"base_hp": base_hp,
		"base_atk": base_atk,
		"base_def": base_def,
		"base_spd": base_spd,
		"skills": skills,
		"traits": traits,
		"capture_rate": capture_rate,
		"sprite_path": sprite_path,
		"rarity": rarity
	}

static func from_dictionary(data: Dictionary) -> MonsterData:
	var res := MonsterData.new()
	res.monster_id = data.get("monster_id", "")
	res.display_name = data.get("display_name", "")
	res.species = data.get("species", "")
	res.element = data.get("element", Enums.Element.FIRE)
	res.level = data.get("level", 1)
	res.base_hp = data.get("base_hp", 100)
	res.base_atk = data.get("base_atk", 30)
	res.base_def = data.get("base_def", 20)
	res.base_spd = data.get("base_spd", 20)
	res.skills = data.get("skills", [])
	res.traits = data.get("traits", [])
	res.capture_rate = data.get("capture_rate", 0.4)
	res.sprite_path = data.get("sprite_path", "")
	res.rarity = data.get("rarity", 0)
	return res
