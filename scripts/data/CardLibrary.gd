class_name CardLibrary
extends RefCounted

static var _cards: Dictionary = {}
static var _initialized: bool = false

static func initialize() -> void:
	if _initialized:
		return
	
	_register_default_cards()
	_initialized = true

static func _register_default_cards() -> void:
	_register_card(_create_light_forest_card())
	_register_card(_create_abandoned_lab_card())
	_register_card(_create_lava_crack_card())

static func _create_light_forest_card() -> TileCardData:
	var card := TileCardData.new()
	card.card_id = "card_light_forest"
	card.module_id = "light_forest"
	card.display_name = "微光森林"
	card.description = "充满生机的森林，草系和虫系精灵出没"
	card.detailed_description = "战斗胜利30%概率掉落果实\n消失时获得生机碎片×1"
	card.rarity = TileCardData.CardRarity.COMMON
	card.initial_charge = 3
	card.element_types = [Enums.Element.GRASS, Enums.Element.BUG]
	card.special_effects = ["fruit_drop_30"]
	return card

static func _create_abandoned_lab_card() -> TileCardData:
	var card := TileCardData.new()
	card.card_id = "card_abandoned_lab"
	card.module_id = "abandoned_lab"
	card.display_name = "废弃研究所"
	card.description = "废弃的研究设施，电系和钢系精灵出没"
	card.detailed_description = "偷窃成功率+20%\n消失时获得科技模组×1"
	card.rarity = TileCardData.CardRarity.RARE
	card.initial_charge = 2
	card.element_types = [Enums.Element.ELECTRIC, Enums.Element.STEEL]
	card.special_effects = ["steal_bonus_20"]
	return card

static func _create_lava_crack_card() -> TileCardData:
	var card := TileCardData.new()
	card.card_id = "card_lava_crack"
	card.module_id = "lava_crack"
	card.display_name = "熔岩裂隙"
	card.description = "炽热的熔岩地带，火系精灵出没"
	card.detailed_description = "每圈敌我ATK+5\n消失时获得核心火种×1"
	card.rarity = TileCardData.CardRarity.COMMON
	card.initial_charge = 5
	card.element_types = [Enums.Element.FIRE]
	card.special_effects = ["atk_bonus_per_loop"]
	return card

static func _register_card(card: TileCardData) -> void:
	_cards[card.module_id] = card

static func get_card(module_id: String) -> TileCardData:
	if not _initialized:
		initialize()
	
	return _cards.get(module_id, null)

static func get_all_cards() -> Array:
	if not _initialized:
		initialize()
	
	var result: Array = []
	for card in _cards.values():
		result.append(card)
	return result

static func get_unlocked_cards(unlocked_modules: Array) -> Array:
	if not _initialized:
		initialize()
	
	var result: Array = []
	for module_id: String in unlocked_modules:
		var card: TileCardData = _cards.get(module_id, null)
		if card != null:
			result.append(card)
	return result
