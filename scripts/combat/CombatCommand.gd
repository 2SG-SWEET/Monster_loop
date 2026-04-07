class_name CombatCommand
extends RefCounted

enum CommandType { 
	ATTACK, 
	SKILL, 
	CAPTURE, 
	STEAL, 
	DEFEND,
	SWITCH,
	ITEM
}

var actor: CombatUnit = null
var command_type: CommandType = CommandType.ATTACK
var target: CombatUnit = null
var skill_index: int = -1
var skill_id: String = ""
var item_id: String = ""
var priority: int = 0
var is_valid: bool = true

func _init(p_actor: CombatUnit = null, p_type: CommandType = CommandType.ATTACK, p_target: CombatUnit = null) -> void:
	actor = p_actor
	command_type = p_type
	target = p_target
	
	if actor != null:
		priority = actor.get_effective_spd()
	
	_validate()

func _validate() -> void:
	if actor == null:
		is_valid = false
		return
	
	if actor.is_fainted():
		is_valid = false
		return
	
	match command_type:
		CommandType.ATTACK:
			is_valid = target != null and not target.is_fainted()
		CommandType.SKILL:
			is_valid = target != null and not target.is_fainted() and skill_index >= 0
		CommandType.CAPTURE:
			is_valid = target != null and not target.is_fainted()
		CommandType.STEAL:
			is_valid = target != null and not target.is_fainted()
		CommandType.DEFEND:
			is_valid = true
		CommandType.SWITCH:
			is_valid = false
		CommandType.ITEM:
			is_valid = item_id != ""

func get_display_name() -> String:
	match command_type:
		CommandType.ATTACK: return "攻击"
		CommandType.SKILL: return "技能"
		CommandType.CAPTURE: return "捕获"
		CommandType.STEAL: return "偷窃"
		CommandType.DEFEND: return "防御"
		CommandType.SWITCH: return "切换"
		CommandType.ITEM: return "道具"
	return "未知"

func to_dictionary() -> Dictionary:
	return {
		"actor_uuid": actor.uuid if actor else "",
		"command_type": command_type,
		"target_uuid": target.uuid if target else "",
		"skill_index": skill_index,
		"skill_id": skill_id,
		"item_id": item_id,
		"priority": priority,
		"is_valid": is_valid
	}
