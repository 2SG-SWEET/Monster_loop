class_name Enums
extends RefCounted

enum Element { FIRE, WATER, GRASS, ELECTRIC, BUG, STEEL }

enum SkillType { PHYSICAL, SPECIAL, STATUS }

enum TargetType { SINGLE_ENEMY, ALL_ENEMY, SELF, ALLY }

enum UnitState { ACTIVE, DEFENDING, FAINTED }

enum GamePhase { PREPARATION, EXPLORATION, COMBAT, BOSS, RESULT }

enum TileState { EMPTY, OCCUPIED, CONSUMED }

static func element_to_string(element: Element) -> String:
	match element:
		Element.FIRE: return "fire"
		Element.WATER: return "water"
		Element.GRASS: return "grass"
		Element.ELECTRIC: return "electric"
		Element.BUG: return "bug"
		Element.STEEL: return "steel"
	return "unknown"

static func string_to_element(s: String) -> Element:
	match s.to_lower():
		"fire": return Element.FIRE
		"water": return Element.WATER
		"grass": return Element.GRASS
		"electric": return Element.ELECTRIC
		"bug": return Element.BUG
		"steel": return Element.STEEL
	return Element.FIRE
