class_name TilePlacementManager
extends RefCounted

signal tile_placed(module_id: String, grid_index: int)
signal placement_cancelled

var is_placing: bool = false
var selected_card_index: int = -1
var selected_module_id: String = ""
var hand_cards: Array = []

var _game_scene_manager: GameSceneManager
var _grid_overlay: Control

func initialize(manager: GameSceneManager, overlay: Control = null) -> void:
	_game_scene_manager = manager
	_grid_overlay = overlay
	_connect_hand_ui()

func _connect_hand_ui() -> void:
	HandUIManager.card_selected.connect(_on_card_selected)

func set_hand_cards(cards: Array) -> void:
	hand_cards = cards

func _on_card_selected(card_index: int) -> void:
	if card_index < 0 or card_index >= hand_cards.size():
		return
	
	selected_card_index = card_index
	selected_module_id = hand_cards[card_index]
	is_placing = true
	
	_highlight_available_slots()

func _highlight_available_slots() -> void:
	if _grid_overlay == null or _game_scene_manager == null:
		return

func place_tile(slot_index: int) -> bool:
	if not is_placing:
		return false
	
	if _game_scene_manager == null:
		return false
	
	var slot := _game_scene_manager.get_grid_slot_at_index(slot_index)
	if slot == null or slot.is_occupied:
		return false
	
	tile_placed.emit(selected_module_id, slot_index)
	EventBus.tile_placed.emit(selected_module_id, slot_index)
	
	HandUIManager.remove_card(selected_card_index)
	hand_cards.remove_at(selected_card_index)
	
	_cancel_placement()
	return true

func place_at_nearest_empty() -> bool:
	if _game_scene_manager == null:
		return false
	
	var nearest := _game_scene_manager.get_nearest_empty_slot()
	if nearest >= 0:
		return place_tile(nearest)
	return false

func _cancel_placement() -> void:
	is_placing = false
	selected_card_index = -1
	selected_module_id = ""
	placement_cancelled.emit()

func get_selected_module_id() -> String:
	return selected_module_id

func is_placing_mode() -> bool:
	return is_placing
