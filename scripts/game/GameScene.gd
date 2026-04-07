class_name GameScene
extends Node2D

@export var path_radius: float = GameConstants.PATH_RADIUS
@export var move_speed: float = GameConstants.MOVE_SPEED
@export var grid_slots_count: int = GameConstants.MAX_GRID_SLOTS

@onready var _path: Path2D = $Path2D
@onready var _player: PathFollow2D = $Path2D/Player
@onready var _grid_container: Node2D = $GridContainer
@onready var _hand_ui: Control = $UI/HandUI
@onready var _progress_ui: Control = $UI/BossProgressUI
@onready var _progress_bar: ProgressBar = $UI/BossProgressUI/ProgressBar if has_node("UI/BossProgressUI/ProgressBar") else null
@onready var _loop_label: Label = $UI/TopBar/LoopCount if has_node("UI/TopBar/LoopCount") else null

var _game_scene_manager: GameSceneManager
var _tile_placement_manager: TilePlacementManager
var _boss_progress_manager: BossProgressManager
var _grid_slots: Array = []
var _placed_modules: Dictionary = {}
var _is_moving: bool = true

func _ready():
	_setup_path()
	_setup_managers()
	_setup_grid_slots()
	_setup_hand()
	_connect_signals()
	
	GameManager.start_new_game()
	_game_scene_manager.start_game()

func _setup_path() -> void:
	var curve := Curve2D.new()
	var segments := 60
	
	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		var x := cos(angle) * path_radius
		var y := sin(angle) * path_radius
		curve.add_point(Vector2(x, y))
	
	_path.curve = curve

func _setup_managers() -> void:
	_game_scene_manager = GameSceneManager.new()
	_game_scene_manager.initialize(_path, _player, _grid_container, null)
	
	_tile_placement_manager = TilePlacementManager.new()
	_tile_placement_manager.initialize(_game_scene_manager, null)
	
	_boss_progress_manager = BossProgressManager.new()
	_boss_progress_manager.initialize()
	
	_boss_progress_manager.progress_updated.connect(_on_progress_updated)
	_boss_progress_manager.progress_completed.connect(_on_progress_completed)

func _setup_grid_slots() -> void:
	for i in range(grid_slots_count):
		var angle := TAU * float(i) / float(grid_slots_count)
		var pos := Vector2(cos(angle) * path_radius, sin(angle) * path_radius)
		
		var slot := _create_grid_slot(i, pos)
		_grid_container.add_child(slot)
		_grid_slots.append(slot)

func _create_grid_slot(index: int, position: Vector2) -> Area2D:
	var slot := Area2D.new()
	slot.position = position
	slot.set_meta("slot_index", index)
	
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 30.0
	collision.shape = shape
	slot.add_child(collision)
	
	slot.input_event.connect(_on_slot_input_event.bind(slot))
	
	return slot

func _setup_hand() -> void:
	var deck_cards := SaveManager.get_deck_cards()
	
	if deck_cards.is_empty():
		deck_cards = [
			{"module_id": "light_forest", "count": 2},
			{"module_id": "abandoned_lab", "count": 1},
			{"module_id": "lava_crack", "count": 2}
		]
		SaveManager.set_deck_cards(deck_cards)
	
	var hand_cards: Array = []
	var total_charge := 0
	
	for card in deck_cards:
		var module_id: String = card.get("module_id", "")
		var count: int = card.get("count", 1)
		var card_data := CardLibrary.get_card(module_id)
		if card_data != null:
			total_charge += card_data.initial_charge * count
		for i in range(count):
			hand_cards.append(module_id)
	
	HandUIManager.set_hand_cards(hand_cards)
	_boss_progress_manager.set_total_charge(total_charge)
	GameManager.set_total_charge(total_charge)
	
	_update_hand_ui()

func _connect_signals() -> void:
	EventBus.tile_placed.connect(_on_tile_placed)
	EventBus.tile_consumed.connect(_on_tile_consumed)
	EventBus.tile_disappeared.connect(_on_tile_disappeared)
	EventBus.loop_completed.connect(_on_loop_completed)
	EventBus.combat_triggered.connect(_on_combat_triggered)
	EventBus.combat_ended.connect(_on_combat_ended)
	EventBus.boss_spawned.connect(_on_boss_spawned)
	
	HandUIManager.card_selected.connect(_on_card_selected)
	HandUIManager.hand_updated.connect(_on_hand_updated)
	
	_game_scene_manager.tile_placed.connect(_on_manager_tile_placed)

func _process(delta: float) -> void:
	if not _is_moving:
		return
	
	_game_scene_manager.update(delta)
	
	if _player and _path and _path.curve:
		_player.progress = _game_scene_manager._player_follow.progress if _game_scene_manager._player_follow else _player.progress + move_speed * delta

func _on_slot_input_event(_viewport: Node, event: InputEvent, _shape_idx: int, slot: Area2D) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var index: int = slot.get_meta("slot_index", -1)
		if index >= 0 and not _placed_modules.has(index):
			_place_selected_module(index)

func _place_selected_module(grid_index: int) -> void:
	var selected_id := HandUIManager.get_card_at(HandUIManager.get_selected_index())
	if selected_id == "":
		return
	
	var module := TileModuleFactory.create_module(selected_id)
	if module == null:
		return
	
	var slot: Area2D = _grid_slots[grid_index]
	module.position = slot.position
	module.initialize(module.module_data, grid_index)
	
	add_child(module)
	_placed_modules[grid_index] = module
	slot.set_meta("placed_module", module)
	
	var card_data := CardLibrary.get_card(selected_id)
	if card_data != null:
		_boss_progress_manager.add_total_charge(card_data.initial_charge)
	
	EventBus.tile_placed.emit(selected_id, grid_index)
	HandUIManager.remove_card(HandUIManager.get_selected_index())
	_update_hand_ui()

func _on_card_selected(card_index: int) -> void:
	_tile_placement_manager._on_card_selected(card_index)

func _on_hand_updated(_cards: Array) -> void:
	_update_hand_ui()

func _update_hand_ui() -> void:
	if _hand_ui == null:
		return
	
	var card_list: VBoxContainer = _hand_ui.get_node_or_null("VBoxContainer/CardList")
	if card_list == null:
		return
	
	for child in card_list.get_children():
		child.queue_free()
	
	var cards := HandUIManager.get_hand_cards()
	for i in range(cards.size()):
		var module_id: String = cards[i]
		var card_data := CardLibrary.get_card(module_id)
		
		var btn := Button.new()
		if card_data != null:
			btn.text = card_data.display_name
		else:
			btn.text = module_id
		
		btn.pressed.connect(_on_hand_card_pressed.bind(i))
		card_list.add_child(btn)

func _on_hand_card_pressed(index: int) -> void:
	HandUIManager.select_card(index)

func _on_tile_placed(module_id: String, grid_index: int) -> void:
	pass

func _on_manager_tile_placed(module_id: String, grid_index: int) -> void:
	pass

func _on_tile_consumed(module_id: String, grid_index: int, remaining_charge: int) -> void:
	_boss_progress_manager.update_progress(1)
	
	if remaining_charge <= 0:
		_on_tile_disappeared(module_id, grid_index)

func _on_tile_disappeared(_module_id: String, grid_index: int) -> void:
	if _placed_modules.has(grid_index):
		_placed_modules.erase(grid_index)
		
		if grid_index < _grid_slots.size():
			var slot: Area2D = _grid_slots[grid_index]
			slot.remove_meta("placed_module")

func _on_loop_completed(loop_count: int) -> void:
	if _loop_label:
		_loop_label.text = "圈数: %d" % loop_count

func _on_progress_updated(current: int, total: int) -> void:
	if _progress_bar:
		_progress_bar.max_value = total
		_progress_bar.value = current
	
	EventBus.boss_progress_updated.emit(current, total)

func _on_progress_completed() -> void:
	_is_moving = false

func _on_combat_triggered(_module_id: String, _enemy_data: Dictionary) -> void:
	_is_moving = false
	_game_scene_manager.pause_game()

func _on_combat_ended(_result: Dictionary) -> void:
	_is_moving = true
	_game_scene_manager.resume_game()

func _on_boss_spawned(_boss_data: Dictionary) -> void:
	_is_moving = false
