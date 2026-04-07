extends Node

const SAVE_PATH := "user://save_data.json"
const BACKUP_PATH := "user://save_data_backup.json"
const CURRENT_VERSION := "1.0.0"

var _data: Dictionary = {}
var _is_dirty: bool = false

func _ready():
	load_save_data()

func load_save_data() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		_data = get_default_data()
		return _data
	
	var json := JSON.new()
	var error := json.parse(FileAccess.get_file_as_string(SAVE_PATH))
	
	if error != OK:
		if FileAccess.file_exists(BACKUP_PATH):
			json.parse(FileAccess.get_file_as_string(BACKUP_PATH))
		else:
			_data = get_default_data()
			return _data
	
	_data = validate_and_migrate(json.data)
	return _data

func save_data() -> void:
	if not _is_dirty:
		return
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(_data, "  "))
	
	var backup := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
	backup.store_string(JSON.stringify(_data, "  "))
	
	_is_dirty = false

func mark_dirty() -> void:
	_is_dirty = true

func get_data() -> Dictionary:
	return _data

func get_default_data() -> Dictionary:
	return {
		"version": CURRENT_VERSION,
		"player": {
			"current_tier": 0,
			"currency": 0,
			"current_loop": 0
		},
		"monsters": [],
		"selected_monsters": [],
		"eggs": [],
		"inventory": {
			"pokeballs": GameConstants.INITIAL_POKEBALLS,
			"gene_fragments": 0,
			"evolution_stones": 0
		},
		"deck": {
			"cards": []
		},
		"unlocked_modules": ["light_forest", "abandoned_lab", "lava_crack"],
		"game_state": {
			"current_phase": Enums.GamePhase.PREPARATION,
			"boss_progress": 0,
			"total_charge": 0
		}
	}

func validate_and_migrate(data: Dictionary) -> Dictionary:
	if not data.has("version"):
		data["version"] = CURRENT_VERSION
	
	if not data.has("player"):
		data["player"] = get_default_data()["player"]
	
	if not data.has("monsters"):
		data["monsters"] = []
	
	if not data.has("selected_monsters"):
		data["selected_monsters"] = []
	
	if not data.has("eggs"):
		data["eggs"] = []
	
	if not data.has("inventory"):
		data["inventory"] = get_default_data()["inventory"]
	
	if not data.has("deck"):
		data["deck"] = get_default_data()["deck"]
	
	if not data.has("unlocked_modules"):
		data["unlocked_modules"] = get_default_data()["unlocked_modules"]
	
	if not data.has("game_state"):
		data["game_state"] = get_default_data()["game_state"]
	
	return data

func reset_to_default() -> void:
	_data = get_default_data()
	mark_dirty()
	save_data()

func get_player_monsters() -> Array:
	return _data.get("monsters", [])

func get_selected_monsters() -> Array:
	return _data.get("selected_monsters", [])

func add_monster(monster_data: Dictionary) -> void:
	if not _data.has("monsters"):
		_data["monsters"] = []
	_data["monsters"].append(monster_data)
	mark_dirty()

func get_inventory() -> Dictionary:
	return _data.get("inventory", {})

func add_item(item_id: String, count: int = 1) -> void:
	var inventory := get_inventory()
	var current: int = inventory.get(item_id, 0)
	inventory[item_id] = current + count
	mark_dirty()

func use_item(item_id: String, count: int = 1) -> bool:
	var inventory := get_inventory()
	var current: int = inventory.get(item_id, 0)
	if current < count:
		return false
	inventory[item_id] = current - count
	mark_dirty()
	return true

func get_player_tier() -> int:
	return _data.get("player", {}).get("current_tier", 0)

func increment_tier() -> void:
	var player: Dictionary = _data.get("player", {})
	player["current_tier"] = player.get("current_tier", 0) + 1
	mark_dirty()

func get_deck_cards() -> Array:
	return _data.get("deck", {}).get("cards", [])

func set_deck_cards(cards: Array) -> void:
	if not _data.has("deck"):
		_data["deck"] = {}
	_data["deck"]["cards"] = cards
	mark_dirty()
