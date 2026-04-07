class_name CombatUnit
extends RefCounted

enum UnitType { PLAYER, ENEMY, BOSS }
enum UnitState { ACTIVE, DEFENDING, FAINTED }

var unit_type: UnitType = UnitType.ENEMY
var uuid: String = ""
var display_name: String = ""
var level: int = 1
var element: Enums.Element = Enums.Element.FIRE

var base_atk: int = 30
var base_def: int = 20
var base_hp: int = 100
var base_spd: int = 20

var current_hp: int = 100
var max_hp: int = 100

var skills: Array[String] = []
var traits: Array[String] = []

var state: UnitState = UnitState.ACTIVE
var status_effects: Dictionary = {}
var consecutive_attacks: int = 0
var is_weakened: bool = false
var weaken_turns: int = 0

var atk_modifier: float = 1.0
var def_modifier: float = 1.0
var spd_modifier: float = 1.0

func _init(data: Dictionary = {}) -> void:
	if data.is_empty():
		return
	
	uuid = data.get("uuid", "")
	display_name = data.get("display_name", "Unknown")
	level = data.get("level", 1)
	element = data.get("element", Enums.Element.FIRE)
	
	base_atk = data.get("atk", data.get("base_atk", 30))
	base_def = data.get("def", data.get("base_def", 20))
	base_hp = data.get("hp", data.get("base_hp", 100))
	base_spd = data.get("spd", data.get("base_spd", 20))
	
	max_hp = base_hp
	current_hp = data.get("current_hp", max_hp)
	
	skills = data.get("skills", [])
	traits = data.get("traits", [])
	
	if data.get("is_player", false):
		unit_type = UnitType.PLAYER
	elif data.get("is_boss", false):
		unit_type = UnitType.BOSS
	else:
		unit_type = UnitType.ENEMY

func get_effective_atk() -> int:
	var atk := float(base_atk) * atk_modifier
	
	if is_weakened:
		atk *= GameConstants.WEAKEN_ATK_MODIFIER
	
	if state == UnitState.DEFENDING:
		atk *= GameConstants.DEFEND_ATK_MODIFIER
	
	for effect in status_effects.values():
		if effect is Dictionary and effect.has("atk_modifier"):
			atk *= effect.atk_modifier
	
	return int(round(atk))

func get_effective_def() -> int:
	var def := float(base_def) * def_modifier
	
	if is_weakened:
		def *= GameConstants.WEAKEN_DEF_MODIFIER
	
	if state == UnitState.DEFENDING:
		def *= GameConstants.DEFEND_DEF_MODIFIER
	
	for effect in status_effects.values():
		if effect is Dictionary and effect.has("def_modifier"):
			def *= effect.def_modifier
	
	return int(round(def))

func get_effective_spd() -> int:
	var spd := float(base_spd) * spd_modifier
	
	if is_weakened:
		spd *= GameConstants.WEAKEN_SPD_MODIFIER
	
	for effect in status_effects.values():
		if effect is Dictionary and effect.has("spd_modifier"):
			spd *= effect.spd_modifier
	
	return int(round(spd))

func take_damage(amount: int) -> int:
	var old_hp := current_hp
	current_hp = maxi(0, current_hp - amount)
	
	EventBus.hp_changed.emit(uuid, old_hp, current_hp)
	
	if current_hp <= 0:
		_on_faint()
	
	return current_hp

func heal(amount: int) -> int:
	var old_hp := current_hp
	current_hp = mini(max_hp, current_hp + amount)
	EventBus.hp_changed.emit(uuid, old_hp, current_hp)
	return current_hp

func get_hp_percent() -> float:
	if max_hp <= 0:
		return 0.0
	return float(current_hp) / float(max_hp)

func is_fainted() -> bool:
	return state == UnitState.FAINTED or current_hp <= 0

func set_defending(is_defending: bool) -> void:
	if is_defending:
		state = UnitState.DEFENDING
	else:
		state = UnitState.ACTIVE

func apply_weaken(duration: int = 1) -> void:
	is_weakened = true
	weaken_turns = duration

func tick_weaken() -> void:
	if is_weakened:
		weaken_turns -= 1
		if weaken_turns <= 0:
			is_weakened = false
			weaken_turns = 0

func reset_turn_state() -> void:
	if state == UnitState.DEFENDING:
		state = UnitState.ACTIVE
	
	tick_weaken()
	_tick_status_effects()

func _tick_status_effects() -> void:
	var expired: Array[String] = []
	
	for effect_name in status_effects:
		var effect: Dictionary = status_effects[effect_name]
		if effect.has("duration"):
			effect.duration -= 1
			if effect.duration <= 0:
				expired.append(effect_name)
	
	for effect_name in expired:
		status_effects.erase(effect_name)

func _on_faint() -> void:
	state = UnitState.FAINTED
	EventBus.unit_fainted.emit(to_dictionary())

func to_dictionary() -> Dictionary:
	return {
		"uuid": uuid,
		"display_name": display_name,
		"level": level,
		"element": element,
		"unit_type": unit_type,
		"current_hp": current_hp,
		"max_hp": max_hp,
		"base_atk": base_atk,
		"base_def": base_def,
		"base_spd": base_spd,
		"skills": skills,
		"traits": traits,
		"state": state,
		"is_weakened": is_weakened
	}

static func from_monster_data(data: MonsterData, is_player: bool = false) -> CombatUnit:
	var unit := CombatUnit.new()
	unit.uuid = "unit_%d" % Time.get_ticks_msec()
	unit.display_name = data.display_name
	unit.level = data.level
	unit.element = data.element
	unit.base_atk = data.base_atk
	unit.base_def = data.base_def
	unit.base_hp = data.base_hp
	unit.base_spd = data.base_spd
	unit.max_hp = data.base_hp
	unit.current_hp = data.base_hp
	unit.skills = data.skills
	unit.traits = data.traits
	unit.unit_type = UnitType.PLAYER if is_player else UnitType.ENEMY
	return unit
