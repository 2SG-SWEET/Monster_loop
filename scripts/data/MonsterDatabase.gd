class_name MonsterDatabase
extends RefCounted

static var _monsters: Dictionary = {}
static var _initialized: bool = false

static func initialize() -> void:
	if _initialized:
		return
	
	_register_all_monsters()
	_initialized = true

static func _register_all_monsters() -> void:
	_register_monster({
		"monster_id": "eye_spawn",
		"display_name": "眼魔侍从",
		"species": "eye_spawn",
		"element": Enums.Element.ELECTRIC,
		"base_hp": 90,
		"base_atk": 25,
		"base_def": 25,
		"base_spd": 22,
		"skills": ["tackle", "thunder_shock"],
		"traits": [],
		"capture_rate": 0.45,
		"sprite_path": "res://assets/images/monsters/eye_spawn.png",
		"rarity": 1
	})
	
	_register_monster({
		"monster_id": "tentacle_mew",
		"display_name": "触手猫",
		"species": "tentacle_mew",
		"element": Enums.Element.BUG,
		"base_hp": 85,
		"base_atk": 35,
		"base_def": 18,
		"base_spd": 30,
		"skills": ["tackle", "bug_bite"],
		"traits": ["quick"],
		"capture_rate": 0.40,
		"sprite_path": "res://assets/images/monsters/tentacle_mew.png",
		"rarity": 2
	})
	
	_register_monster({
		"monster_id": "ichor_slime",
		"display_name": "脓液史莱姆",
		"species": "ichor_slime",
		"element": Enums.Element.GRASS,
		"base_hp": 120,
		"base_atk": 20,
		"base_def": 35,
		"base_spd": 15,
		"skills": ["tackle", "vine_whip"],
		"traits": ["tank"],
		"capture_rate": 0.50,
		"sprite_path": "res://assets/images/monsters/ichor_slime.png",
		"rarity": 1
	})
	
	_register_monster({
		"monster_id": "abyss_pup",
		"display_name": "深渊幼犬",
		"species": "abyss_pup",
		"element": Enums.Element.FIRE,
		"base_hp": 100,
		"base_atk": 40,
		"base_def": 22,
		"base_spd": 25,
		"skills": ["tackle", "fireball"],
		"traits": ["fierce"],
		"capture_rate": 0.35,
		"sprite_path": "res://assets/images/monsters/abyss_pup.png",
		"rarity": 3
	})
	
	_register_monster({
		"monster_id": "messenger_corvus",
		"display_name": "信使乌鸦",
		"species": "messenger_corvus",
		"element": Enums.Element.WATER,
		"base_hp": 80,
		"base_atk": 28,
		"base_def": 20,
		"base_spd": 35,
		"skills": ["tackle", "water_jet"],
		"traits": ["swift"],
		"capture_rate": 0.40,
		"sprite_path": "res://assets/images/monsters/messenger_corvus.png",
		"rarity": 2
	})
	
	_register_monster({
		"monster_id": "void_larva",
		"display_name": "虚空幼虫",
		"species": "void_larva",
		"element": Enums.Element.ELECTRIC,
		"base_hp": 95,
		"base_atk": 45,
		"base_def": 15,
		"base_spd": 20,
		"skills": ["tackle", "thunder_shock"],
		"traits": ["mage"],
		"capture_rate": 0.25,
		"sprite_path": "res://assets/images/monsters/void_larva.png",
		"rarity": 4
	})
	
	_register_monster({
		"monster_id": "drowned_grasp",
		"display_name": "溺亡者之握",
		"species": "drowned_grasp",
		"element": Enums.Element.WATER,
		"base_hp": 110,
		"base_atk": 30,
		"base_def": 28,
		"base_spd": 18,
		"skills": ["tackle", "water_jet"],
		"traits": ["control"],
		"capture_rate": 0.30,
		"sprite_path": "res://assets/images/monsters/drowned_grasp.png",
		"rarity": 3
	})
	
	_register_monster({
		"monster_id": "old_god_sprout",
		"display_name": "古神之种",
		"species": "old_god_sprout",
		"element": Enums.Element.GRASS,
		"base_hp": 130,
		"base_atk": 38,
		"base_def": 30,
		"base_spd": 22,
		"skills": ["tackle", "vine_whip", "fireball"],
		"traits": ["legendary"],
		"capture_rate": 0.15,
		"sprite_path": "res://assets/images/monsters/old_god_sprout.png",
		"rarity": 5
	})

static func _register_monster(data: Dictionary) -> void:
	var monster := MonsterData.new()
	monster.monster_id = data.get("monster_id", "")
	monster.display_name = data.get("display_name", "")
	monster.species = data.get("species", "")
	monster.element = data.get("element", Enums.Element.FIRE)
	monster.base_hp = data.get("base_hp", 100)
	monster.base_atk = data.get("base_atk", 30)
	monster.base_def = data.get("base_def", 20)
	monster.base_spd = data.get("base_spd", 20)
	monster.skills = data.get("skills", [])
	monster.traits = data.get("traits", [])
	monster.capture_rate = data.get("capture_rate", 0.4)
	monster.sprite_path = data.get("sprite_path", "")
	monster.rarity = data.get("rarity", 1)
	
	_monsters[monster.monster_id] = monster

static func get_monster(monster_id: String) -> MonsterData:
	if not _initialized:
		initialize()
	
	return _monsters.get(monster_id, null)

static func get_monster_by_element(element: Enums.Element) -> MonsterData:
	if not _initialized:
		initialize()
	
	var candidates: Array = []
	for monster in _monsters.values():
		if monster.element == element:
			candidates.append(monster)
	
	if candidates.is_empty():
		return null
	
	return candidates[randi() % candidates.size()]

static func get_all_monsters() -> Array:
	if not _initialized:
		initialize()
	
	return _monsters.values()

static func get_monsters_by_rarity(rarity: int) -> Array:
	if not _initialized:
		initialize()
	
	var result: Array = []
	for monster in _monsters.values():
		if monster.rarity == rarity:
			result.append(monster)
	return result

static func get_random_monster(weighted: bool = true) -> MonsterData:
	if not _initialized:
		initialize()
	
	if not weighted:
		var all := _monsters.values()
		return all[randi() % all.size()]
	
	var total_weight := 0
	var weights: Dictionary = {}
	
	for monster_id in _monsters:
		var monster: MonsterData = _monsters[monster_id]
		var weight := 6 - monster.rarity
		weights[monster_id] = weight
		total_weight += weight
	
	var roll := randi() % total_weight
	var current := 0
	
	for monster_id in weights:
		current += weights[monster_id]
		if roll < current:
			return _monsters[monster_id]
	
	return _monsters.values()[0]

static func create_instance(monster_id: String, level: int = 1) -> Dictionary:
	var base := get_monster(monster_id)
	if base == null:
		return {}
	
	return {
		"uuid": "monster_%d" % Time.get_ticks_msec(),
		"monster_id": monster_id,
		"display_name": base.display_name,
		"species": base.species,
		"element": base.element,
		"level": level,
		"hp": base.base_hp + level * 10,
		"max_hp": base.base_hp + level * 10,
		"atk": base.base_atk + level * 3,
		"def": base.base_def + level * 2,
		"spd": base.base_spd + level,
		"skills": base.skills.duplicate(),
		"traits": base.traits.duplicate(),
		"capture_rate": base.capture_rate,
		"sprite_path": base.sprite_path,
		"rarity": base.rarity
	}
