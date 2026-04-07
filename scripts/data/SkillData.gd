class_name SkillData
extends Resource

enum SkillType { PHYSICAL, SPECIAL, STATUS }
enum TargetType { SINGLE_ENEMY, ALL_ENEMY, SELF, ALLY }

@export var skill_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var skill_type: SkillType = SkillType.PHYSICAL
@export var target_type: TargetType = TargetType.SINGLE_ENEMY
@export var power: int = 10
@export var element: Enums.Element = Enums.Element.FIRE
@export var accuracy: int = 100
@export var pp: int = 10
@export var current_pp: int = 10
@export var priority: int = 0
@export var effect: Dictionary = {}

func can_use() -> bool:
	return current_pp > 0

func use() -> void:
	if current_pp > 0:
		current_pp -= 1

func restore_pp(amount: int = -1) -> void:
	if amount < 0:
		current_pp = pp
	else:
		current_pp = mini(pp, current_pp + amount)

func to_dictionary() -> Dictionary:
	return {
		"skill_id": skill_id,
		"display_name": display_name,
		"description": description,
		"skill_type": skill_type,
		"target_type": target_type,
		"power": power,
		"element": element,
		"accuracy": accuracy,
		"pp": pp,
		"current_pp": current_pp,
		"priority": priority,
		"effect": effect
	}

static func from_dictionary(data: Dictionary) -> SkillData:
	var res := SkillData.new()
	res.skill_id = data.get("skill_id", "")
	res.display_name = data.get("display_name", "")
	res.description = data.get("description", "")
	res.skill_type = data.get("skill_type", SkillType.PHYSICAL)
	res.target_type = data.get("target_type", TargetType.SINGLE_ENEMY)
	res.power = data.get("power", 10)
	res.element = data.get("element", Enums.Element.FIRE)
	res.accuracy = data.get("accuracy", 100)
	res.pp = data.get("pp", 10)
	res.current_pp = data.get("current_pp", res.pp)
	res.priority = data.get("priority", 0)
	res.effect = data.get("effect", {})
	return res
