class_name GameScene
extends Node2D

@export var grid_width: int = 6
@export var grid_height: int = 6
@export var cell_size: float = 80.0
@export var move_speed: float = 150.0

var grid_slots_count: int = 36

@onready var _path: Path2D = $PathContainer/LoopPath
@onready var _path_visual: Line2D = $PathContainer/PathVisual
@onready var _player: PathFollow2D = $PlayerContainer/Player
@onready var _grid_markers: Node2D = $PathContainer/GridMarkers
@onready var _tile_container: Node2D = $TileContainer
@onready var _loop_label: Label = $UI/TopBar/LoopCount
@onready var _progress_bar: ProgressBar = $UI/BossProgressUI/ProgressBar

var _grid_slots: Array = []
var _placed_modules: Dictionary = {}
var _is_moving: bool = true
var _current_loop: int = 0
var _boss_progress: int = 0
var _total_charge: int = 0
var _player_body: CharacterBody2D = null

func _ready() -> void:
	_setup_player_collision()
	_setup_path()
	_setup_grid_slots()
	_setup_initial_state()
	print("游戏场景初始化完成")

func _setup_player_collision() -> void:
	_player_body = CharacterBody2D.new()
	_player_body.name = "PlayerBody"
	_player_body.add_to_group("player")
	
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	_player_body.add_child(collision)
	
	var visual: Polygon2D = Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(0, -12), Vector2(10, 8), Vector2(-10, 8)
	])
	visual.color = Color(1, 1, 1, 1)
	_player_body.add_child(visual)
	
	_player.add_child(_player_body)

func _setup_path() -> void:
	var curve: Curve2D = Curve2D.new()
	
	var half_width: float = (grid_width * cell_size) / 2.0
	var half_height: float = (grid_height * cell_size) / 2.0
	
	for i in range(grid_width):
		var x: float = -half_width + i * cell_size
		var y: float = -half_height
		curve.add_point(Vector2(x, y))
	
	for i in range(grid_height):
		var x: float = half_width
		var y: float = -half_height + i * cell_size
		curve.add_point(Vector2(x, y))
	
	for i in range(grid_width):
		var x: float = half_width - i * cell_size
		var y: float = half_height
		curve.add_point(Vector2(x, y))
	
	for i in range(grid_height):
		var x: float = -half_width
		var y: float = half_height - i * cell_size
		curve.add_point(Vector2(x, y))
	
	_path.curve = curve
	
	var points: PackedVector2Array = []
	for i in range(curve.point_count):
		points.append(curve.get_point_position(i))
	_path_visual.points = points

func _setup_grid_slots() -> void:
	var half_width: float = (grid_width * cell_size) / 2.0
	var half_height: float = (grid_height * cell_size) / 2.0
	
	var slot_index: int = 0
	
	for i in range(grid_width):
		var x: float = -half_width + i * cell_size
		var y: float = -half_height
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1
	
	for i in range(grid_height):
		var x: float = half_width
		var y: float = -half_height + i * cell_size
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1
	
	for i in range(grid_width):
		var x: float = half_width - i * cell_size
		var y: float = half_height
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1
	
	for i in range(grid_height):
		var x: float = -half_width
		var y: float = half_height - i * cell_size
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1

func _create_grid_slot(index: int, pos: Vector2) -> void:
	var marker: Marker2D = Marker2D.new()
	marker.position = pos
	marker.name = "GridSlot_%d" % index
	
	var visual: Line2D = Line2D.new()
	visual.name = "Visual"
	visual.width = 2.0
	visual.default_color = Color(1, 1, 1, 0.5)
	
	var circle_points: PackedVector2Array = []
	for j in range(16):
		var circle_angle: float = TAU * float(j) / 16.0
		circle_points.append(Vector2(cos(circle_angle) * 15, sin(circle_angle) * 15))
	circle_points.append(circle_points[0])
	visual.points = circle_points
	
	marker.add_child(visual)
	_grid_markers.add_child(marker)
	_grid_slots.append(marker)
	
	print("创建格子 %d 在位置 %s" % [index, str(pos)])

func _setup_initial_state() -> void:
	_current_loop = 0
	_boss_progress = 0
	_total_charge = 10
	_setup_hand()
	_update_ui()

func _setup_hand() -> void:
	var hand_ui: Control = $UI/HandUI
	var card_list: HBoxContainer = hand_ui.get_node_or_null("VBoxContainer/CardList")
	if card_list == null:
		return
	
	for child in card_list.get_children():
		child.queue_free()
	
	var deck_cards: Array = []
	var save_data: Dictionary = SaveManager.get_data()
	var deck_data: Dictionary = save_data.get("deck", {})
	var cards: Array = deck_data.get("cards", [])
	
	if cards.is_empty():
		deck_cards = [
			{"module_id": "light_forest", "count": 2},
			{"module_id": "abandoned_lab", "count": 1},
			{"module_id": "lava_crack", "count": 2}
		]
	else:
		deck_cards = cards
	
	var card_index: int = 0
	for card in deck_cards:
		var module_id: String = card.get("module_id", "")
		var count: int = card.get("count", 1)
		
		for i in range(count):
			var btn: Button = Button.new()
			btn.custom_minimum_size = Vector2(60, 80)
			btn.text = _get_card_short_name(module_id)
			
			match module_id:
				"light_forest":
					btn.modulate = Color(0.176, 0.314, 0.086, 1)
				"abandoned_lab":
					btn.modulate = Color(0.29, 0.333, 0.408, 1)
				"lava_crack":
					btn.modulate = Color(0.773, 0.188, 0.188, 1)
				_:
					btn.modulate = Color(0.5, 0.5, 0.5, 1)
			
			btn.pressed.connect(_on_hand_card_pressed.bind(card_index))
			card_list.add_child(btn)
			card_index += 1
	
	print("手牌初始化完成，共 %d 张" % card_index)

func _get_card_short_name(module_id: String) -> String:
	match module_id:
		"light_forest": return "森林"
		"abandoned_lab": return "实验室"
		"lava_crack": return "熔岩"
		_: return module_id.left(2)

var _selected_card_index: int = -1

func _on_hand_card_pressed(index: int) -> void:
	_selected_card_index = index
	print("选中手牌: %d" % index)
	_highlight_available_slots()

func _highlight_available_slots() -> void:
	for i in range(_grid_slots.size()):
		var marker: Marker2D = _grid_slots[i]
		var visual: Line2D = marker.get_node_or_null("Visual")
		if visual != null:
			if not _placed_modules.has(i):
				visual.default_color = Color(1, 1, 0, 1)
			else:
				visual.default_color = Color(1, 1, 1, 0.3)

func _process(delta: float) -> void:
	if not _is_moving:
		return
	
	if _path and _path.curve:
		var path_length: float = _path.curve.get_baked_length()
		var move_distance: float = move_speed * delta
		_player.progress += move_distance
		
		if _player.progress >= path_length:
			_player.progress = 0.0
			_on_loop_completed()

func _on_loop_completed() -> void:
	_current_loop += 1
	print("完成第 %d 圈" % _current_loop)
	_update_ui()

func _update_ui() -> void:
	if _loop_label:
		_loop_label.text = "圈数: %d" % _current_loop
	
	if _progress_bar:
		_progress_bar.max_value = _total_charge
		_progress_bar.value = _boss_progress

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _selected_card_index >= 0:
			var mouse_pos: Vector2 = get_global_mouse_position()
			var grid_index: int = get_grid_index_at_position(mouse_pos)
			if grid_index >= 0 and not _placed_modules.has(grid_index):
				_place_selected_module_at(grid_index)

func _place_selected_module_at(grid_index: int) -> void:
	var hand_ui: Control = $UI/HandUI
	var card_list: HBoxContainer = hand_ui.get_node_or_null("VBoxContainer/CardList")
	if card_list == null or _selected_card_index >= card_list.get_child_count():
		return
	
	var btn: Button = card_list.get_child(_selected_card_index)
	var module_id: String = ""
	
	if btn.modulate.is_equal_approx(Color(0.176, 0.314, 0.086, 1)):
		module_id = "light_forest"
	elif btn.modulate.is_equal_approx(Color(0.29, 0.333, 0.408, 1)):
		module_id = "abandoned_lab"
	elif btn.modulate.is_equal_approx(Color(0.773, 0.188, 0.188, 1)):
		module_id = "lava_crack"
	else:
		module_id = "unknown"
	
	place_module(module_id, grid_index)
	
	btn.queue_free()
	_selected_card_index = -1
	
	for i in range(_grid_slots.size()):
		var marker: Marker2D = _grid_slots[i]
		var visual: Line2D = marker.get_node_or_null("Visual")
		if visual != null:
			visual.default_color = Color(1, 1, 1, 0.5)

func place_module(module_id: String, grid_index: int) -> void:
	if grid_index < 0 or grid_index >= _grid_slots.size():
		return
	
	if _placed_modules.has(grid_index):
		return
	
	var marker: Marker2D = _grid_slots[grid_index]
	
	var module: BaseTileModule = TileModuleFactory.create_module(module_id)
	if module == null:
		return
	
	var data: TileModuleData = TileModuleData.new()
	data.module_id = module_id
	match module_id:
		"light_forest":
			data.display_name = "微光森林"
			data.initial_charge = 3
			data.spawn_elements = [Enums.Element.GRASS, Enums.Element.BUG]
		"abandoned_lab":
			data.display_name = "废弃研究所"
			data.initial_charge = 2
			data.spawn_elements = [Enums.Element.ELECTRIC]
		"lava_crack":
			data.display_name = "熔岩裂隙"
			data.initial_charge = 5
			data.spawn_elements = [Enums.Element.FIRE]
		_:
			data.display_name = module_id
			data.initial_charge = 3
	
	module.initialize(data, grid_index)
	module.position = marker.position
	
	var collision: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 20.0
	collision.shape = shape
	module.add_child(collision)
	
	var visual: Polygon2D = Polygon2D.new()
	match module_id:
		"light_forest":
			visual.polygon = PackedVector2Array([
				Vector2(0, -12), Vector2(10, 8), Vector2(-10, 8)
			])
			visual.color = Color(0.176, 0.314, 0.086, 1)
		"abandoned_lab":
			visual.polygon = PackedVector2Array([
				Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)
			])
			visual.color = Color(0.29, 0.333, 0.408, 1)
		"lava_crack":
			visual.polygon = PackedVector2Array([
				Vector2(0, -10), Vector2(8, 0), Vector2(0, 10), Vector2(-8, 0)
			])
			visual.color = Color(0.773, 0.188, 0.188, 1)
		_:
			visual.polygon = PackedVector2Array([
				Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
			])
			visual.color = Color(0.5, 0.5, 0.5, 1)
	module.add_child(visual)
	
	_tile_container.add_child(module)
	_placed_modules[grid_index] = module
	
	print("放置模块 %s 在格子 %d" % [module_id, grid_index])

func get_grid_index_at_position(pos: Vector2) -> int:
	for i in range(_grid_slots.size()):
		if _grid_slots[i].position.distance_to(pos) < 30.0:
			return i
	return -1

func is_slot_occupied(grid_index: int) -> bool:
	return _placed_modules.has(grid_index)
