class_name SkillDatabase
extends RefCounted

static var _skills: Dictionary = {}
static var _initialized: bool = false

static func initialize() -> void:
	if _initialized:
		return
	
	_register_basic_skills()
	_register_elemental_skills()
	_register_status_skills()
	_initialized = true

static func _register_basic_skills() -> void:
	_register_skill({
		"skill_id": "tackle",
		"display_name": "撞击",
		"description": "用身体撞击敌人",
		"skill_type": SkillData.SkillType.PHYSICAL,
		"target_type": SkillData.TargetType.SINGLE_ENEMY,
		"power": 10,
		"element": Enums.Element.FIRE,
		"accuracy": 100,
		"pp": 35
	})
	
	_register_skill({
		"skill_id": "defend",
		"display_name": "防御",
		"description": "进入防御姿态，本回合防御力翻倍",
		"skill_type": SkillData.SkillType.STATUS,
		"target_type": SkillData.TargetType.SELF,
		"power": 0,
		"element": Enums.Element.FIRE,
		"accuracy": 100,
		"pp": 10
	})

static func _register_elemental_skills() -> void:
	_register_skill({
		"skill_id": "fireball",
		"display_name": "火球",
		"description": "发射火球攻击敌人",
		"skill_type": SkillData.SkillType.SPECIAL,
		"target_type": SkillData.TargetType.SINGLE_ENEMY,
		"power": 25,
		"element": Enums.Element.FIRE,
		"accuracy": 100,
		"pp": 15
	})
	
	_register_skill({
		"skill_id": "water_jet",
		"display_name": "水流喷射",
		"description": "喷射水流攻击敌人",
		"skill_type": SkillData.SkillType.SPECIAL,
		"target_type": SkillData.TargetType.SINGLE_ENEMY,
		"power": 25,
		"element": Enums.Element.WATER,
		"accuracy": 100,
		"pp": 15
	})
	
	_register_skill({
		"skill_id": "vine_whip",
		"display_name": "藤鞭",
		"description": "用藤鞭抽打敌人",
		"skill_type": SkillData.SkillType.PHYSICAL,
		"target_type": SkillData.TargetType.SINGLE_ENEMY,
		"power": 25,
		"element": Enums.Element.GRASS,
		"accuracy": 100,
		"pp": 15
	})
	
	_register_skill({
		"skill_id": "thunder_shock",
		"display_name": "电击",
		"description": "释放电流攻击敌人",
		"skill_type": SkillData.SkillType.SPECIAL,
		"target_type": SkillData.TargetType.SINGLE_ENEMY,
		"power": 25,
		"element": Enums.Element.ELECTRIC,
		"accuracy": 100,
		"pp": 15
	})
	
	_register_skill({
		"skill_id": "bug_bite",
		"display_name": "虫咬",
		"description": "用牙齿撕咬敌人",
		"skill_type": SkillData.SkillType.PHYSICAL,
		"target_type": SkillData.TargetType.SINGLE_ENEMY,
		"power": 20,
		"element": Enums.Element.BUG,
		"accuracy": 100,
		"pp": 20
	})
	
	_register_skill({
		"skill_id": "iron_defense",
		"display_name": "铁壁",
		"description": "提升防御力",
		"skill_type": SkillData.SkillType.STATUS,
		"target_type": SkillData.TargetType.SELF,
		"power": 0,
		"element": Enums.Element.STEEL,
		"accuracy": 100,
		"pp": 15
	})

static func _register_status_skills() -> void:
	_register_skill({
		"skill_id": "quick_attack",
		"display_name": "先制攻击",
		"description": "速度优先的攻击",
		"skill_type": SkillData.SkillType.PHYSICAL,
		"target_type": SkillData.TargetType.SINGLE_ENEMY,
		"power": 15,
		"element": Enums.Element.FIRE,
		"accuracy": 100,
		"pp": 20,
		"priority": 1
	})
	
	_register_skill({
		"skill_id": "boss_attack",
		"display_name": "BOSS攻击",
		"description": "BOSS的强力攻击",
		"skill_type": SkillData.SkillType.PHYSICAL,
		"target_type": SkillData.TargetType.SINGLE_ENEMY,
		"power": 30,
		"element": Enums.Element.FIRE,
		"accuracy": 90,
		"pp": 99
	})
	
	_register_skill({
		"skill_id": "boss_skill",
		"display_name": "BOSS技能",
		"description": "BOSS的特殊技能",
		"skill_type": SkillData.SkillType.SPECIAL,
		"target_type": SkillData.TargetType.SINGLE_ENEMY,
		"power": 40,
		"element": Enums.Element.FIRE,
		"accuracy": 85,
		"pp": 99
	})

static func _register_skill(data: Dictionary) -> void:
	var skill := SkillData.new()
	skill.skill_id = data.get("skill_id", "")
	skill.display_name = data.get("display_name", "")
	skill.description = data.get("description", "")
	skill.skill_type = data.get("skill_type", SkillData.SkillType.PHYSICAL)
	skill.target_type = data.get("target_type", SkillData.TargetType.SINGLE_ENEMY)
	skill.power = data.get("power", 10)
	skill.element = data.get("element", Enums.Element.FIRE)
	skill.accuracy = data.get("accuracy", 100)
	skill.pp = data.get("pp", 10)
	skill.current_pp = skill.pp
	skill.priority = data.get("priority", 0)
	
	_skills[skill.skill_id] = skill

static func get_skill(skill_id: String) -> SkillData:
	if not _initialized:
		initialize()
	
	var skill: SkillData = _skills.get(skill_id, null)
	if skill != null:
		return skill.duplicate()
	return null

static func get_all_skills() -> Array:
	if not _initialized:
		initialize()
	
	var result: Array = []
	for skill in _skills.values():
		result.append(skill.duplicate())
	return result
