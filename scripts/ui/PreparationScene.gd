class_name PreparationScene
extends Control

@onready var _monster_list: VBoxContainer = $VBoxContainer/MonsterList
@onready var _deck_list: VBoxContainer = $VBoxContainer/DeckList
@onready var _start_button: Button = $VBoxContainer/StartButton

var _selected_monsters: Array = []
var _selected_deck: Array = []

func _ready() -> void:
	_load_available_monsters()
	_load_available_modules()
	_setup_deck_defaults()
	_start_button.pressed.connect(_on_start_button_pressed)

func _load_available_monsters() -> void:
	for child in _monster_list.get_children():
		child.queue_free()
	
	var monsters := SaveManager.get_player_monsters()
	
	if monsters.is_empty():
		monsters = [
			{
				"uuid": "starter_1",
				"display_name": "初始火精灵",
				"element": Enums.Element.FIRE,
				"level": 5,
				"base_hp": 100,
				"base_atk": 30,
				"base_def": 20,
				"base_spd": 20,
				"skills": ["tackle", "fireball"]
			}
		]
		for m in monsters:
			SaveManager.add_monster(m)
	
	for monster in monsters:
		var checkbox := CheckBox.new()
		checkbox.text = "%s Lv.%d" % [monster.display_name, monster.level]
		checkbox.toggled.connect(_on_monster_toggled.bind(monster, checkbox))
		_monster_list.add_child(checkbox)

func _load_available_modules() -> void:
	for child in _deck_list.get_children():
		child.queue_free()
	
	var unlocked: Array = SaveManager.get_data().get("unlocked_modules", [])
	
	var modules := {
		"light_forest": {"name": "微光森林", "charge": 3},
		"abandoned_lab": {"name": "废弃研究所", "charge": 2},
		"lava_crack": {"name": "熔岩裂隙", "charge": 5}
	}
	
	for module_id: String in unlocked:
		var info: Dictionary = modules.get(module_id, {})
		var hbox := HBoxContainer.new()
		
		var label := Label.new()
		label.text = "%s (Charge: %d)" % [info.get("name", module_id), info.get("charge", 3)]
		label.custom_minimum_size.x = 150
		hbox.add_child(label)
		
		var spinbox := SpinBox.new()
		spinbox.min_value = 0
		spinbox.max_value = 5
		spinbox.value = _get_default_count(module_id)
		spinbox.value_changed.connect(_on_deck_count_changed.bind(module_id))
		hbox.add_child(spinbox)
		
		_deck_list.add_child(hbox)
		_selected_deck.append({"module_id": module_id, "count": spinbox.value})

func _get_default_count(module_id: String) -> int:
	match module_id:
		"light_forest": return 2
		"abandoned_lab": return 1
		"lava_crack": return 2
	return 1

func _setup_deck_defaults() -> void:
	_selected_deck = [
		{"module_id": "light_forest", "count": 2},
		{"module_id": "abandoned_lab", "count": 1},
		{"module_id": "lava_crack", "count": 2}
	]

func _on_monster_toggled(is_pressed: bool, monster: Dictionary, checkbox: CheckBox) -> void:
	if is_pressed:
		if _selected_monsters.size() >= GameConstants.MAX_PLAYER_MONSTERS:
			checkbox.button_pressed = false
			return
		_selected_monsters.append(monster)
	else:
		_selected_monsters.erase(monster)

func _on_deck_count_changed(value: float, module_id: String) -> void:
	for item in _selected_deck:
		if item.module_id == module_id:
			item.count = int(value)
			return
	_selected_deck.append({"module_id": module_id, "count": int(value)})

func _on_start_button_pressed() -> void:
	print("开始游戏按钮被点击")
	
	if _selected_monsters.is_empty():
		print("错误：未选择任何怪物")
		return
	
	var total_cards := 0
	for item in _selected_deck:
		total_cards += item.count
	
	if total_cards == 0:
		print("错误：卡组中没有卡片")
		return
	
	print("选择的怪物: %d" % _selected_monsters.size())
	print("卡组卡片总数: %d" % total_cards)
	
	SaveManager.get_data()["selected_monsters"] = _selected_monsters
	
	var deck_cards: Array = []
	for item in _selected_deck:
		if item.count > 0:
			deck_cards.append({"module_id": item.module_id, "count": item.count})
	SaveManager.set_deck_cards(deck_cards)
	SaveManager.save_data()
	
	print("正在切换到 EXPLORATION 阶段...")
	GameManager.set_phase(Enums.GamePhase.EXPLORATION)
	print("阶段切换完成")
