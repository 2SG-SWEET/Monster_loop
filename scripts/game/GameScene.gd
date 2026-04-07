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

var _grid_slots: Array[Marker2D] = []
var _placed_modules: Dictionary = {}
var _is_moving: bool = true
var _current_loop: int = 0
var _boss_progress: int = 0
var _total_charge: int = 0

func _ready() -> void:
	_setup_path()
	_setup_grid_slots()
	_setup_initial_state()
	print("游戏场景初始化完成")

func _setup_path() -> void:
	var curve := Curve2D.new()
	
	# 计算矩形边界
	var half_width := (grid_width * cell_size) / 2.0
	var half_height := (grid_height * cell_size) / 2.0
	
	# 创建矩形循环路径 (顺时针: 左上 -> 右上 -> 右下 -> 左下 -> 左上)
	# 上边 (从左到右)
	for i in range(grid_width):
		var x := -half_width + i * cell_size
		var y := -half_height
		curve.add_point(Vector2(x, y))
	
	# 右边 (从上到下)
	for i in range(grid_height):
		var x := half_width
		var y := -half_height + i * cell_size
		curve.add_point(Vector2(x, y))
	
	# 下边 (从右到左)
	for i in range(grid_width):
		var x := half_width - i * cell_size
		var y := half_height
		curve.add_point(Vector2(x, y))
	
	# 左边 (从下到上)
	for i in range(grid_height):
		var x := -half_width
		var y := half_height - i * cell_size
		curve.add_point(Vector2(x, y))
	
	_path.curve = curve
	
	# 设置路径可视化
	var points: PackedVector2Array = []
	for i in range(curve.point_count):
		points.append(curve.get_point_position(i))
	_path_visual.points = points

func _setup_grid_slots() -> void:
	var half_width := (grid_width * cell_size) / 2.0
	var half_height := (grid_height * cell_size) / 2.0
	
	var slot_index := 0
	
	# 上边 (从左到右)
	for i in range(grid_width):
		var x := -half_width + i * cell_size
		var y := -half_height
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1
	
	# 右边 (从上到下)
	for i in range(grid_height):
		var x := half_width
		var y := -half_height + i * cell_size
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1
	
	# 下边 (从右到左)
	for i in range(grid_width):
		var x := half_width - i * cell_size
		var y := half_height
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1
	
	# 左边 (从下到上)
	for i in range(grid_height):
		var x := -half_width
		var y := half_height - i * cell_size
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1

func _create_grid_slot(index: int, pos: Vector2) -> void:
	var marker := Marker2D.new()
	marker.position = pos
	marker.name = "GridSlot_%d" % index
	
	# 添加可视化圆环
	var visual := Line2D.new()
	visual.name = "Visual"
	visual.width = 2.0
	visual.default_color = Color(1, 1, 1, 0.5)
	
	# 创建圆形
	var circle_points: PackedVector2Array = []
	for j in range(16):
		var circle_angle := TAU * float(j) / 16.0
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
	# 获取手牌容器
	var hand_ui := $UI/HandUI
	var card_list := hand_ui.get_node_or_null("VBoxContainer/CardList")
	if card_list == null:
		return
	
	# 清除旧按钮
	for child in card_list.get_children():
		child.queue_free()
	
	# 从存档获取卡组，如果没有则使用默认卡组
	var deck_cards: Array = []
	var save_data := SaveManager.get_data()
	var deck_data: Dictionary = save_data.get("deck", {})
	var cards: Array = deck_data.get("cards", [])
	
	if cards.is_empty():
		# 默认卡组
		deck_cards = [
			{"module_id": "light_forest", "count": 2},
			{"module_id": "abandoned_lab", "count": 1},
			{"module_id": "lava_crack", "count": 2}
		]
	else:
		deck_cards = cards
	
	# 创建手牌按钮
	var card_index := 0
	for card in deck_cards:
		var module_id: String = card.get("module_id", "")
		var count: int = card.get("count", 1)
		
		for i in range(count):
			var btn := Button.new()
			btn.custom_minimum_size = Vector2(60, 80)
			btn.text = _get_card_short_name(module_id)
			
			# 设置按钮样式
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
	# 高亮显示可放置的格子
	for i in range(_grid_slots.size()):
		var marker := _grid_slots[i]
		var visual := marker.get_node_or_null("Visual")
		if visual != null:
			if not _placed_modules.has(i):
				visual.default_color = Color(1, 1, 0, 1)  # 黄色高亮
			else:
				visual.default_color = Color(1, 1, 1, 0.3)  # 半透明白色

func _process(delta: float) -> void:
	if not _is_moving:
		return
	
	# 玩家沿路径移动
	if _path and _path.curve:
		var path_length := _path.curve.get_baked_length()
		var move_distance := move_speed * delta
		_player.progress += move_distance
		
		# 检查是否完成一圈
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
			var mouse_pos := get_global_mouse_position()
			var grid_index := get_grid_index_at_position(mouse_pos)
			if grid_index >= 0 and not _placed_modules.has(grid_index):
				_place_selected_module_at(grid_index)

func _place_selected_module_at(grid_index: int) -> void:
	# 获取选中的手牌信息
	var hand_ui := $UI/HandUI
	var card_list := hand_ui.get_node_or_null("VBoxContainer/CardList")
	if card_list == null or _selected_card_index >= card_list.get_child_count():
		return
	
	var btn := card_list.get_child(_selected_card_index)
	var module_id := ""
	
	# 根据按钮颜色反推模块ID
	if btn.modulate.is_equal_approx(Color(0.176, 0.314, 0.086, 1)):
		module_id = "light_forest"
	elif btn.modulate.is_equal_approx(Color(0.29, 0.333, 0.408, 1)):
		module_id = "abandoned_lab"
	elif btn.modulate.is_equal_approx(Color(0.773, 0.188, 0.188, 1)):
		module_id = "lava_crack"
	else:
		module_id = "unknown"
	
	place_module(module_id, grid_index)
	
	# 移除使用的手牌
	btn.queue_free()
	_selected_card_index = -1
	
	# 重置格子高亮
	for i in range(_grid_slots.size()):
		var marker := _grid_slots[i]
		var visual := marker.get_node_or_null("Visual")
		if visual != null:
			visual.default_color = Color(1, 1, 1, 0.5)

func place_module(module_id: String, grid_index: int) -> void:
	if grid_index < 0 or grid_index >= _grid_slots.size():
		return
	
	if _placed_modules.has(grid_index):
		return
	
	var marker := _grid_slots[grid_index]
	
	# 创建模块可视化 (白模)
	var module_visual := Polygon2D.new()
	module_visual.name = "Module_%s" % module_id
	
	# 根据模块类型设置不同形状和颜色
	match module_id:
		"light_forest":
			module_visual.polygon = PackedVector2Array([
				Vector2(0, -12), Vector2(10, 8), Vector2(-10, 8)
			])
			module_visual.color = Color(0.176, 0.314, 0.086, 1)
		"abandoned_lab":
			module_visual.polygon = PackedVector2Array([
				Vector2(-12, -12), Vector2(12, -12), Vector2(12, 12), Vector2(-12, 12)
			])
			module_visual.color = Color(0.29, 0.333, 0.408, 1)
		"lava_crack":
			module_visual.polygon = PackedVector2Array([
				Vector2(0, -10), Vector2(8, 0), Vector2(0, 10), Vector2(-8, 0)
			])
			module_visual.color = Color(0.773, 0.188, 0.188, 1)
		_:
			module_visual.polygon = PackedVector2Array([
				Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)
			])
			module_visual.color = Color(0.5, 0.5, 0.5, 1)
	
	module_visual.position = marker.position
	_tile_container.add_child(module_visual)
	
	_placed_modules[grid_index] = module_visual
	print("放置模块 %s 在格子 %d" % [module_id, grid_index])

func get_grid_index_at_position(pos: Vector2) -> int:
	for i in range(_grid_slots.size()):
		if _grid_slots[i].position.distance_to(pos) < 30.0:
			return i
	return -1

func is_slot_occupied(grid_index: int) -> bool:
	return _placed_modules.has(grid_index)
