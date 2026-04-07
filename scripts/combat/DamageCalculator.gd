class_name DamageCalculator
extends RefCounted

const ELEMENT_CHART := {
	Enums.Element.FIRE: {
		"strong": [Enums.Element.GRASS, Enums.Element.BUG],
		"weak": [Enums.Element.WATER],
		"immune": []
	},
	Enums.Element.WATER: {
		"strong": [Enums.Element.FIRE],
		"weak": [Enums.Element.GRASS, Enums.Element.ELECTRIC],
		"immune": []
	},
	Enums.Element.GRASS: {
		"strong": [Enums.Element.WATER],
		"weak": [Enums.Element.FIRE, Enums.Element.BUG],
		"immune": []
	},
	Enums.Element.ELECTRIC: {
		"strong": [Enums.Element.WATER],
		"weak": [],
		"immune": []
	},
	Enums.Element.BUG: {
		"strong": [Enums.Element.GRASS],
		"weak": [Enums.Element.FIRE],
		"immune": []
	},
	Enums.Element.STEEL: {
		"strong": [],
		"weak": [Enums.Element.FIRE],
		"immune": []
	}
}

static func calculate_damage(attacker: CombatUnit, defender: CombatUnit, power: int, skill_element: Enums.Element = Enums.Element.FIRE) -> Dictionary:
	var level_factor := (float(attacker.level) / 5.0) + 1.0
	
	var atk := float(attacker.get_effective_atk())
	var def := float(defender.get_effective_def())
	
	if def <= 0:
		def = 1.0
	
	var base_damage := level_factor * (float(power) * atk) / (def * 2.0)
	
	var element_multiplier := get_element_multiplier(skill_element, defender.element)
	
	var critical := 1.0
	if randf() < GameConstants.CRITICAL_CHANCE:
		critical = GameConstants.CRITICAL_MULTIPLIER
	
	var random_factor := randf_range(0.85, 1.0)
	
	var final_damage := int(round(base_damage * element_multiplier * critical * random_factor))
	final_damage = maxi(1, final_damage)
	
	return {
		"damage": final_damage,
		"is_critical": critical > 1.0,
		"element_multiplier": element_multiplier,
		"element_effect": _get_element_effect_name(element_multiplier)
	}

static func get_element_multiplier(attack_element: Enums.Element, defense_element: Enums.Element) -> float:
	if not ELEMENT_CHART.has(attack_element):
		return 1.0
	
	var chart: Dictionary = ELEMENT_CHART[attack_element]
	
	if chart.strong.has(defense_element):
		return 2.0
	
	if chart.weak.has(defense_element):
		return 0.5
	
	if chart.immune.has(defense_element):
		return 0.0
	
	return 1.0

static func _get_element_effect_name(multiplier: float) -> String:
	if multiplier >= 2.0:
		return "效果拔群"
	elif multiplier <= 0.5:
		return "效果不佳"
	elif multiplier <= 0.0:
		return "无效"
	return ""

static func calculate_skill_damage(attacker: CombatUnit, defender: CombatUnit, skill: SkillData) -> Dictionary:
	return calculate_damage(attacker, defender, skill.power, skill.element)
