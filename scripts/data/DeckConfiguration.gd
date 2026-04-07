class_name DeckConfiguration
extends RefCounted

var cards: Array = []
var max_cards: int = 5

func add_card(module_id: String, count: int = 1) -> bool:
	if get_total_count() + count > max_cards:
		return false
	
	var existing := get_entry_by_module(module_id)
	if existing != null:
		existing.count += count
	else:
		var entry := {"module_id": module_id, "count": count}
		cards.append(entry)
	
	return true

func remove_card(module_id: String, count: int = 1) -> bool:
	var entry := get_entry_by_module(module_id)
	if entry == null or entry.count < count:
		return false
	
	entry.count -= count
	if entry.count <= 0:
		cards.erase(entry)
	
	return true

func get_total_count() -> int:
	var total := 0
	for entry in cards:
		total += entry.count
	return total

func get_entry_by_module(module_id: String) -> Dictionary:
	for entry in cards:
		if entry.module_id == module_id:
			return entry
	return {}

func get_all_module_ids() -> Array:
	var result: Array = []
	for entry in cards:
		for i in range(entry.count):
			result.append(entry.module_id)
	return result

func clear() -> void:
	cards.clear()

func to_dictionary() -> Dictionary:
	var result: Array = []
	for entry in cards:
		result.append({
			"module_id": entry.module_id,
			"count": entry.count
		})
	return {"cards": result}

static func from_dictionary(data: Dictionary) -> DeckConfiguration:
	var deck := DeckConfiguration.new()
	for card_data in data.get("cards", []):
		deck.add_card(card_data.get("module_id", ""), card_data.get("count", 1))
	return deck
