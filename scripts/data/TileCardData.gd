class_name TileCardData
extends Resource

enum CardRarity { COMMON, RARE, EPIC, LEGENDARY }

@export var card_id: String = ""
@export var module_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export_multiline var detailed_description: String = ""
@export var icon: Texture2D
@export var rarity: CardRarity = CardRarity.COMMON
@export var initial_charge: int = 3
@export var element_types: Array[Enums.Element] = []
@export var special_effects: Array[String] = []
@export var unlock_condition: Dictionary = {}

func get_summary() -> String:
	var elements_str := ""
	for e in element_types:
		elements_str += Enums.element_to_string(e) + ", "
	elements_str = elements_str.trim_suffix(", ")
	return "%s | Charge: %d | Elements: %s" % [display_name, initial_charge, elements_str]

func get_rarity_color() -> Color:
	match rarity:
		CardRarity.COMMON: return Color.WHITE
		CardRarity.RARE: return Color.CYAN
		CardRarity.EPIC: return Color.MAGENTA
		CardRarity.LEGENDARY: return Color.GOLD
	return Color.WHITE

func to_dictionary() -> Dictionary:
	return {
		"card_id": card_id,
		"module_id": module_id,
		"display_name": display_name,
		"description": description,
		"detailed_description": detailed_description,
		"rarity": rarity,
		"initial_charge": initial_charge,
		"element_types": element_types,
		"special_effects": special_effects,
		"unlock_condition": unlock_condition
	}

static func from_dictionary(data: Dictionary) -> TileCardData:
	var res := TileCardData.new()
	res.card_id = data.get("card_id", "")
	res.module_id = data.get("module_id", "")
	res.display_name = data.get("display_name", "")
	res.description = data.get("description", "")
	res.detailed_description = data.get("detailed_description", "")
	res.rarity = data.get("rarity", CardRarity.COMMON)
	res.initial_charge = data.get("initial_charge", 3)
	res.element_types = data.get("element_types", [])
	res.special_effects = data.get("special_effects", [])
	res.unlock_condition = data.get("unlock_condition", {})
	return res
