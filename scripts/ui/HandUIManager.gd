class_name HandUIManager
extends RefCounted

signal card_selected(card_index: int)
signal hand_updated(cards: Array)

static var _instance: HandUIManager = null
static var _hand_cards: Array = []
static var _selected_index: int = -1

static func get_instance() -> HandUIManager:
	if _instance == null:
		_instance = HandUIManager.new()
	return _instance

static func set_hand_cards(cards: Array) -> void:
	_hand_cards = cards.duplicate()
	_selected_index = -1
	get_instance().hand_updated.emit(_hand_cards)

static func get_hand_cards() -> Array:
	return _hand_cards.duplicate()

static func get_card_at(index: int) -> String:
	if index >= 0 and index < _hand_cards.size():
		return _hand_cards[index]
	return ""

static func select_card(index: int) -> void:
	if index >= 0 and index < _hand_cards.size():
		_selected_index = index
		get_instance().card_selected.emit(index)

static func get_selected_index() -> int:
	return _selected_index

static func remove_card(index: int) -> bool:
	if index >= 0 and index < _hand_cards.size():
		_hand_cards.remove_at(index)
		if _selected_index == index:
			_selected_index = -1
		elif _selected_index > index:
			_selected_index -= 1
		get_instance().hand_updated.emit(_hand_cards)
		return true
	return false

static func remove_card_by_id(module_id: String) -> bool:
	for i in range(_hand_cards.size()):
		if _hand_cards[i] == module_id:
			return remove_card(i)
	return false

static func get_hand_size() -> int:
	return _hand_cards.size()

static func is_empty() -> bool:
	return _hand_cards.is_empty()

static func clear_hand() -> void:
	_hand_cards.clear()
	_selected_index = -1
	get_instance().hand_updated.emit(_hand_cards)
