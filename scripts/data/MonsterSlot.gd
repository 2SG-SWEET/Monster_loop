class_name MonsterSlot
extends RefCounted

enum SlotState { EMPTY, MONSTER, EGG }

var state: SlotState = SlotState.EMPTY
var monster_uuid: String = ""
var egg_uuid: String = ""

func is_empty() -> bool:
	return state == SlotState.EMPTY

func set_monster(uuid: String) -> void:
	state = SlotState.MONSTER
	monster_uuid = uuid
	egg_uuid = ""

func set_egg(uuid: String) -> void:
	state = SlotState.EGG
	egg_uuid = uuid
	monster_uuid = ""

func clear() -> void:
	state = SlotState.EMPTY
	monster_uuid = ""
	egg_uuid = ""

func get_uuid() -> String:
	match state:
		SlotState.MONSTER: return monster_uuid
		SlotState.EGG: return egg_uuid
	return ""

func to_dictionary() -> Dictionary:
	return {
		"state": state,
		"monster_uuid": monster_uuid,
		"egg_uuid": egg_uuid
	}

static func from_dictionary(data: Dictionary) -> MonsterSlot:
	var slot := MonsterSlot.new()
	slot.state = data.get("state", SlotState.EMPTY)
	slot.monster_uuid = data.get("monster_uuid", "")
	slot.egg_uuid = data.get("egg_uuid", "")
	return slot
