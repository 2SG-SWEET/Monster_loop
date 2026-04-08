class_name GameScene
extends Node2D

## 大富翁式矩形跑道关卡场景 (基于图片资源版本)
## 所有视觉元素均使用PNG切图，方便美术替换

#region 常量
# 跑道参数
const TRACK_WIDTH: float = 300.0
const TRACK_HEIGHT: float = 200.0
const LANE_WIDTH: float = 80.0
const CORNER_RADIUS: float = 40.0
const SLOT_SIZE: float = 40.0
const SLOTS_PER_SIDE: int = 3
const TOTAL_SLOTS: int = 12

# 资源路径常量 (美术可直接替换这些图片)
const ASSETS_BASE: String = "res://assets/images/game/"
const TRACK_BG_PATH: String = ASSETS_BASE + "track/track_background.png"
const TRACK_STROKE_PATH: String = ASSETS_BASE + "track/track_stroke.png"
const SLOT_EMPTY_PATH: String = ASSETS_BASE + "slots/slot_empty.png"
const SLOT_HIGHLIGHT_PATH: String = ASSETS_BASE + "slots/slot_highlight.png"
const SLOT_OCCUPIED_PATH: String = ASSETS_BASE + "slots/slot_occupied.png"
const CARD_FOREST_PATH: String = ASSETS_BASE + "cards/card_forest.png"
const CARD_LAB_PATH: String = ASSETS_BASE + "cards/card_lab.png"
const CARD_LAVA_PATH: String = ASSETS_BASE + "cards/card_lava.png"
const CARD_BACK_PATH: String = ASSETS_BASE + "cards/card_back.png"
const MODULE_FOREST_PATH: String = ASSETS_BASE + "modules/module_forest.png"
const MODULE_LAB_PATH: String = ASSETS_BASE + "modules/module_lab.png"
const MODULE_LAVA_PATH: String = ASSETS_BASE + "modules/module_lava.png"
const PLAYER_PATH: String = ASSETS_BASE + "entities/player.png"
const BOSS_PATH: String = ASSETS_BASE + "entities/boss.png"
#endregion

#region 导出变量
@export var move_speed: float = 150.0
#endregion

#region 节点引用
@onready var _path: Path2D = $PathContainer/LoopPath
@onready var _player: PathFollow2D = $PlayerContainer/Player
@onready var _tile_container: Node2D = $TileContainer
@onready var _loop_label: Label = $UI/TopBar/LoopCount
@onready var _progress_bar: ProgressBar = $UI/BossProgressUI/ProgressBar

# 图片资源节点
var _track_bg_sprite: Sprite2D = null
var _player_sprite: Sprite2D = null
var _boss_sprite: Sprite2D = null
#endregion

#region 变量
var _grid_slots: Array = []
var _slot_visuals: Array = []
var _placed_modules: Dictionary = {}
var _is_moving: bool = true
var _current_loop: int = 0
var _boss_progress: int = 0
var _total_charge: int = 10
var _selected_card_index: int = -1

# 拖动相关
var _is_dragging: bool = false
var _drag_card_index: int = -1
var _drag_card_sprite: TextureRect = null
var _drag_original_btn: TextureButton = null
var _drag_module_id: String = ""

# 碰撞检测
var _player_last_grid_index: int = -1

# 动画
var _animation_time: float = 0.0
const SYMBOL_BLINK_INTERVAL: float = 2.0

# BOSS
var _boss_spawned: bool = false
var _boss_entity: Node2D = null
#endregion

#region 内置虚函数
func _ready() -> void:
	_ensure_assets_exist()
	_setup_track_visuals()
	_setup_path()
	_setup_grid_slots()
	_setup_player_visual()
	_setup_initial_state()
	print("游戏场景初始化完成 (图片资源版)")

func _process(delta: float) -> void:
	_animation_time += delta

	if _is_dragging and _drag_card_sprite:
		_drag_card_sprite.position = get_global_mouse_position() - Vector2(28, 36)
		_update_drag_highlight()

	if not _is_moving:
		return

	if _path and _path.curve:
		var path_length: float = _path.curve.get_baked_length()
		var move_distance: float = move_speed * delta
		_player.progress += move_distance
		_check_module_collision()

		if _player.progress >= path_length:
			_player.progress = 0.0
			_on_loop_completed()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_handle_drag_start(event)
			else:
				_handle_drag_end()

		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT and _is_dragging:
			_cancel_drag()
#endregion

#region 资源管理
func _ensure_assets_exist() -> void:
	var base_dir: String = ASSETS_BASE
	DirAccess.make_dir_recursive_absolute(base_dir + "track")
	DirAccess.make_dir_recursive_absolute(base_dir + "slots")
	DirAccess.make_dir_recursive_absolute(base_dir + "cards")
	DirAccess.make_dir_recursive_absolute(base_dir + "modules")
	DirAccess.make_dir_recursive_absolute(base_dir + "entities")

	if not ResourceLoader.exists(TRACK_BG_PATH):
		_create_placeholder_track_bg()
	if not ResourceLoader.exists(SLOT_EMPTY_PATH):
		_create_placeholder_slots()
	if not ResourceLoader.exists(CARD_FOREST_PATH):
		_create_placeholder_cards()
	if not ResourceLoader.exists(MODULE_FOREST_PATH):
		_create_placeholder_modules()
	if not ResourceLoader.exists(PLAYER_PATH):
		_create_placeholder_player()
	if not ResourceLoader.exists(BOSS_PATH):
		_create_placeholder_boss()

func _create_placeholder_track_bg() -> void:
	var img: Image = Image.create(620, 420, true, Image.FORMAT_RGBA8)
	var w: int = 620
	var h: int = 420

	for y in range(h):
		for x in range(w):
			var nx: float = (float(x) / w - 0.5) * 2.0
			var ny: float = (float(y) / h - 0.5) * 2.0
			if abs(nx) < 0.95 and abs(ny) < 0.95:
				img.set_pixel(x, y, Color(0.15, 0.18, 0.12, 1))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	img.save_png(TRACK_BG_PATH)

func _create_placeholder_slots() -> void:
	# 空格子
	var img_empty: Image = Image.create(44, 44, false, Image.FORMAT_RGBA8)
	img_empty.fill(Color(0.15, 0.12, 0.10, 0.8))
	for i in range(2):
		for x in range(44):
			img_empty.set_pixel(x, i, Color(0.5, 0.2, 0.15, 0.9))
			img_empty.set_pixel(x, 43 - i, Color(0.5, 0.2, 0.15, 0.9))
		for y in range(44):
			img_empty.set_pixel(i, y, Color(0.5, 0.2, 0.15, 0.9))
			img_empty.set_pixel(43 - i, y, Color(0.5, 0.2, 0.15, 0.9))
	img_empty.save_png(SLOT_EMPTY_PATH)

	# 高亮格子
	var img_highlight: Image = Image.create(44, 44, false, Image.FORMAT_RGBA8)
	img_highlight.fill(Color(0.2, 0.18, 0.1, 0.9))
	for i in range(2):
		for x in range(44):
			img_highlight.set_pixel(x, i, Color(0.9, 0.75, 0.2, 1.0))
			img_highlight.set_pixel(x, 43 - i, Color(0.9, 0.75, 0.2, 1.0))
		for y in range(44):
			img_highlight.set_pixel(i, y, Color(0.9, 0.75, 0.2, 1.0))
			img_highlight.set_pixel(43 - i, y, Color(0.9, 0.75, 0.2, 1.0))
	img_highlight.save_png(SLOT_HIGHLIGHT_PATH)

	# 占用格子
	var img_occupied: Image = Image.create(44, 44, false, Image.FORMAT_RGBA8)
	img_occupied.fill(Color(0.12, 0.10, 0.08, 0.7))
	for i in range(2):
		for x in range(44):
			img_occupied.set_pixel(x, i, Color(0.3, 0.15, 0.1, 0.6))
			img_occupied.set_pixel(x, 43 - i, Color(0.3, 0.15, 0.1, 0.6))
		for y in range(44):
			img_occupied.set_pixel(i, y, Color(0.3, 0.15, 0.1, 0.6))
			img_occupied.set_pixel(43 - i, y, Color(0.3, 0.15, 0.1, 0.6))
	img_occupied.save_png(SLOT_OCCUPIED_PATH)

func _create_placeholder_cards() -> void:
	var card_configs: Array = [
		{"path": CARD_FOREST_PATH, "color": Color(0.176, 0.314, 0.086, 1)},
		{"path": CARD_LAB_PATH, "color": Color(0.29, 0.333, 0.408, 1)},
		{"path": CARD_LAVA_PATH, "color": Color(0.773, 0.188, 0.188, 1)},
		{"path": CARD_BACK_PATH, "color": Color(0.3, 0.25, 0.2, 1)}
	]

	for config in card_configs:
		var img: Image = Image.create(60, 80, false, Image.FORMAT_RGBA8)
		var color: Color = config["color"]
		img.fill(color)
		for i in range(2):
			for x in range(60):
				img.set_pixel(x, i, Color(0.9, 0.85, 0.4, 1))
				img.set_pixel(x, 79 - i, Color(0.9, 0.85, 0.4, 1))
			for y in range(80):
				img.set_pixel(i, y, Color(0.9, 0.85, 0.4, 1))
				img.set_pixel(59 - i, y, Color(0.9, 0.85, 0.4, 1))
		img.save_png(config["path"])

func _create_placeholder_modules() -> void:
	var module_configs: Array = [
		{"path": MODULE_FOREST_PATH, "color": Color(0.176, 0.314, 0.086, 1)},
		{"path": MODULE_LAB_PATH, "color": Color(0.29, 0.333, 0.408, 1)},
		{"path": MODULE_LAVA_PATH, "color": Color(0.773, 0.188, 0.188, 1)}
	]

	for config in module_configs:
		var img: Image = Image.create(32, 32, true, Image.FORMAT_RGBA8)
		var cx: float = 16.0
		var cy: float = 16.0
		var color: Color = config["color"]
		for y in range(32):
			for x in range(32):
				var dx: float = x - cx
				var dy: float = y - cy
				var dist: float = sqrt(dx * dx + dy * dy)
				if dist < 14.0:
					img.set_pixel(x, y, color)
		img.save_png(config["path"])

func _create_placeholder_player() -> void:
	var img: Image = Image.create(24, 24, true, Image.FORMAT_RGBA8)
	var cx: float = 12.0
	var cy: float = 12.0
	for y in range(24):
		for x in range(24):
			var dx: float = x - cx
			var dy: float = y - cy
			var dist: float = sqrt(dx * dx + dy * 1.2)
			if dist < 11.0:
				img.set_pixel(x, y, Color(0.3, 0.6, 0.9, 1))
	img.save_png(PLAYER_PATH)

func _create_placeholder_boss() -> void:
	var img: Image = Image.create(50, 50, true, Image.FORMAT_RGBA8)
	var cx: float = 25.0
	var cy: float = 25.0
	for y in range(50):
		for x in range(50):
			var dx: float = (x - cx) / 25.0
			var dy: float = (y - cy) / 25.0
			var dist: float = abs(dx) + abs(dy)
			if dist < 1.0:
				img.set_pixel(x, y, Color(0.8, 0.15, 0.15, 1))
	img.save_png(BOSS_PATH)

func _load_texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		return load(path)
	return null
#endregion

#region 场景设置
func _setup_track_visuals() -> void:
	# 跑道背景 (使用Sprite2D显示图片)
	_track_bg_sprite = Sprite2D.new()
	_track_bg_sprite.name = "TrackBackground"
	_track_bg_sprite.texture = _load_texture(TRACK_BG_PATH)
	_track_bg_sprite.centered = true
	add_child(_track_bg_sprite)

func _setup_path() -> void:
	var curve: Curve2D = Curve2D.new()
	var hw: float = TRACK_WIDTH
	var hh: float = TRACK_HEIGHT
	var cr: float = CORNER_RADIUS

	curve.add_point(Vector2(-hw + cr, -hh))
	curve.add_point(Vector2(hw - cr, -hh))
	curve.add_point(Vector2(hw, -hh + cr))
	curve.add_point(Vector2(hw, hh - cr))
	curve.add_point(Vector2(hw - cr, hh))
	curve.add_point(Vector2(-hw + cr, hh))
	curve.add_point(Vector2(-hw, hh - cr))
	curve.add_point(Vector2(-hw, -hh + cr))

	_path.curve = curve

func _setup_grid_slots() -> void:
	var slot_index: int = 0

	# 上边 3 格
	for i in range(SLOTS_PER_SIDE):
		var x: float = -TRACK_WIDTH + (i + 1) * (TRACK_WIDTH * 2) / (SLOTS_PER_SIDE + 1)
		var y: float = -TRACK_HEIGHT
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1

	# 右边 2 格
	for i in range(SLOTS_PER_SIDE - 1):
		var x: float = TRACK_WIDTH
		var y: float = -TRACK_HEIGHT + (i + 1) * (TRACK_HEIGHT * 2) / SLOTS_PER_SIDE
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1

	# 下边 3 格
	for i in range(SLOTS_PER_SIDE):
		var x: float = TRACK_WIDTH - (i + 1) * (TRACK_WIDTH * 2) / (SLOTS_PER_SIDE + 1)
		var y: float = TRACK_HEIGHT
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1

	# 左边 2 格
	for i in range(SLOTS_PER_SIDE - 1):
		var x: float = -TRACK_WIDTH
		var y: float = TRACK_HEIGHT - (i + 1) * (TRACK_HEIGHT * 2) / SLOTS_PER_SIDE
		_create_grid_slot(slot_index, Vector2(x, y))
		slot_index += 1

	print("创建 %d 个放置格子" % slot_index)

func _create_grid_slot(index: int, pos: Vector2) -> void:
	var marker: Marker2D = Marker2D.new()
	marker.position = pos
	marker.name = "GridSlot_%d" % index

	# 使用 TextureRect 显示格子图片
	var slot_visual: TextureRect = TextureRect.new()
	slot_visual.name = "SlotVisual"
	slot_visual.texture = _load_texture(SLOT_EMPTY_PATH)
	slot_visual.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
	slot_visual.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	slot_visual.position = pos - Vector2(SLOT_SIZE / 2, SLOT_SIZE / 2)
	slot_visual.mouse_filter = Control.MOUSE_FILTER_PASS

	marker.add_child(slot_visual)
	add_child(marker)
	_grid_slots.append(marker)
	_slot_visuals.append(slot_visual)

func _setup_player_visual() -> void:
	# 移除旧的 Polygon2D 视觉
	if _player.get_node_or_null("PlayerVisual"):
		_player.get_node("PlayerVisual").queue_free()

	# 创建新的 Sprite2D
	_player_sprite = Sprite2D.new()
	_player_sprite.name = "PlayerVisual"
	_player_sprite.texture = _load_texture(PLAYER_PATH)
	_player_sprite.centered = true
	_player.add_child(_player_sprite)
#endregion

#region 初始化与UI
func _setup_initial_state() -> void:
	_current_loop = 0
	_boss_progress = 0
	_total_charge = 10
	_setup_hand()
	_update_ui()

func _setup_hand() -> void:
	var hand_ui: Control = $UI/HandUI
	var card_list: Container = hand_ui.get_node_or_null("VBoxContainer/CardList")
	if card_list == null:
		return

	for child in card_list.get_children():
		child.queue_free()

	var deck_cards: Array = [
		{"module_id": "light_forest", "count": 2},
		{"module_id": "abandoned_lab", "count": 1},
		{"module_id": "lava_crack", "count": 2}
	]

	var card_index: int = 0
	for card in deck_cards:
		var module_id: String = card.get("module_id", "")
		var count: int = card.get("count", 1)

		for i in range(count):
			var btn: TextureButton = TextureButton.new()
			btn.custom_minimum_size = Vector2(56, 72)
			btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

			match module_id:
				"light_forest":
					btn.texture_normal = _load_texture(CARD_FOREST_PATH)
				"abandoned_lab":
					btn.texture_normal = _load_texture(CARD_LAB_PATH)
				"lava_crack":
					btn.texture_normal = _load_texture(CARD_LAVA_PATH)
				_:
					btn.texture_normal = _load_texture(CARD_BACK_PATH)

			btn.pressed.connect(_on_hand_card_pressed.bind(card_index))
			card_list.add_child(btn)
			card_index += 1

	print("手牌初始化完成，共 %d 张" % card_index)

func _update_ui() -> void:
	if _loop_label:
		_loop_label.text = "圈数: %d" % _current_loop

	if _progress_bar:
		_progress_bar.max_value = _total_charge
		_progress_bar.value = _boss_progress
#endregion

#region 事件处理
func _on_loop_completed() -> void:
	_current_loop += 1
	print("完成第 %d 圈" % _current_loop)
	_update_ui()

func _on_hand_card_pressed(index: int) -> void:
	_selected_card_index = index
	print("选中手牌: %d" % index)
	_highlight_available_slots()

func _highlight_available_slots() -> void:
	for i in range(_slot_visuals.size()):
		var visual: TextureRect = _slot_visuals[i]
		if visual != null:
			if not _placed_modules.has(i):
				visual.texture = _load_texture(SLOT_HIGHLIGHT_PATH)
			else:
				visual.texture = _load_texture(SLOT_OCCUPIED_PATH)

func _place_selected_module_at(grid_index: int) -> void:
	var hand_ui: Control = $UI/HandUI
	var card_list: Container = hand_ui.get_node_or_null("VBoxContainer/CardList")
	if card_list == null or _selected_card_index >= card_list.get_child_count():
		return

	var btn: TextureButton = card_list.get_child(_selected_card_index)
	var module_id: String = ""

	if btn.texture_normal == _load_texture(CARD_FOREST_PATH):
		module_id = "light_forest"
	elif btn.texture_normal == _load_texture(CARD_LAB_PATH):
		module_id = "abandoned_lab"
	elif btn.texture_normal == _load_texture(CARD_LAVA_PATH):
		module_id = "lava_crack"
	else:
		module_id = "unknown"

	place_module(module_id, grid_index)

	btn.queue_free()
	_selected_card_index = -1

	for i in range(_slot_visuals.size()):
		var visual: TextureRect = _slot_visuals[i]
		if visual != null:
			visual.texture = _load_texture(SLOT_EMPTY_PATH)
#endregion

#region 公共函数
func place_module(module_id: String, grid_index: int) -> void:
	if grid_index < 0 or grid_index >= _grid_slots.size():
		return

	if _placed_modules.has(grid_index):
		return

	var marker: Marker2D = _grid_slots[grid_index]
	var module_sprite: Sprite2D = Sprite2D.new()
	module_sprite.name = "Module_%s_%d" % [module_id, grid_index]
	module_sprite.position = marker.position
	module_sprite.centered = true

	match module_id:
		"light_forest":
			module_sprite.texture = _load_texture(MODULE_FOREST_PATH)
		"abandoned_lab":
			module_sprite.texture = _load_texture(MODULE_LAB_PATH)
		"lava_crack":
			module_sprite.texture = _load_texture(MODULE_LAVA_PATH)
		_:
			module_sprite.texture = _load_texture(MODULE_FOREST_PATH)

	_tile_container.add_child(module_sprite)
	_placed_modules[grid_index] = module_sprite

	# 更新格子视觉为占用状态
	if grid_index < _slot_visuals.size():
		_slot_visuals[grid_index].texture = _load_texture(SLOT_OCCUPIED_PATH)

	print("放置模块 %s 在格子 %d" % [module_id, grid_index])

func get_grid_index_at_position(pos: Vector2) -> int:
	for i in range(_grid_slots.size()):
		if _grid_slots[i].position.distance_to(pos) < SLOT_SIZE:
			return i
	return -1

func is_slot_occupied(grid_index: int) -> bool:
	return _placed_modules.has(grid_index)
#endregion

#region 拖动放置系统
func _handle_drag_start(event: InputEventMouseButton) -> void:
	var mouse_pos: Vector2 = get_global_mouse_position()

	var hand_ui: Control = $UI/HandUI
	var card_list: Container = hand_ui.get_node_or_null("VBoxContainer/CardList")
	if card_list != null:
		for i in range(card_list.get_child_count()):
			var btn: TextureButton = card_list.get_child(i)
			var btn_rect: Rect2 = Rect2(btn.global_position, btn.size)
			if btn_rect.has_point(mouse_pos):
				_start_drag(i, btn, mouse_pos)
				return

	if _selected_card_index >= 0 and not _is_dragging:
		var grid_index: int = get_grid_index_at_position(mouse_pos)
		if grid_index >= 0 and not _placed_modules.has(grid_index):
			_place_selected_module_at(grid_index)

func _start_drag(card_index: int, btn: TextureButton, mouse_pos: Vector2) -> void:
	_is_dragging = true
	_drag_card_index = card_index
	_drag_original_btn = btn

	_drag_module_id = _get_module_id_from_button(btn)

	# 创建拖动精灵 (使用 TextureRect)
	_drag_card_sprite = TextureRect.new()
	_drag_card_sprite.name = "DragSprite"
	_drag_card_sprite.texture = btn.texture_normal
	_drag_card_sprite.custom_minimum_size = Vector2(56, 72)
	_drag_card_sprite.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_drag_card_sprite.position = mouse_pos - Vector2(28, 36)
	add_child(_drag_card_sprite)

	btn.modulate.a = 0.3

	print("开始拖动卡牌 %d (%s)" % [card_index, _drag_module_id])

func _handle_drag_end() -> void:
	if not _is_dragging or _drag_card_sprite == null:
		return

	var mouse_pos: Vector2 = get_global_mouse_position()
	var grid_index: int = get_grid_index_at_position(mouse_pos)

	if grid_index >= 0 and not _placed_modules.has(grid_index):
		_place_dragged_module_at(grid_index)
	else:
		_cancel_drag()

func _cancel_drag() -> void:
	if _drag_card_sprite != null:
		_drag_card_sprite.queue_free()
		_drag_card_sprite = null

	if _drag_original_btn != null:
		_drag_original_btn.modulate.a = 1.0
		_drag_original_btn = null

	_is_dragging = false
	_drag_card_index = -1
	_drag_module_id = ""

	print("取消拖动")

func _place_dragged_module_at(grid_index: int) -> void:
	place_module(_drag_module_id, grid_index)

	if _drag_original_btn != null:
		_drag_original_btn.queue_free()
		_drag_original_btn = null

	if _drag_card_sprite != null:
		_drag_card_sprite.queue_free()
		_drag_card_sprite = null

	_is_dragging = false
	_drag_card_index = -1
	_drag_module_id = ""
	_selected_card_index = -1

	_reset_all_slot_highlights()

	print("拖动放置模块 %s 在格子 %d" % [_drag_module_id, grid_index])

func _update_drag_highlight() -> void:
	if not _is_dragging:
		return

	var mouse_pos: Vector2 = get_global_mouse_position()

	for i in range(_grid_slots.size()):
		var marker: Marker2D = _grid_slots[i]
		var dist: float = marker.position.distance_to(mouse_pos)
		var visual: TextureRect = _slot_visuals[i]

		if visual != null:
			if dist < SLOT_SIZE * 1.2:
				if not _placed_modules.has(i):
					visual.texture = _load_texture(SLOT_HIGHLIGHT_PATH)
				else:
					visual.texture = _load_texture(SLOT_OCCUPIED_PATH)
			else:
				visual.texture = _load_texture(SLOT_EMPTY_PATH)

func _get_module_id_from_button(btn: TextureButton) -> String:
	if btn.texture_normal == _load_texture(CARD_FOREST_PATH):
		return "light_forest"
	elif btn.texture_normal == _load_texture(CARD_LAB_PATH):
		return "abandoned_lab"
	elif btn.texture_normal == _load_texture(CARD_LAVA_PATH):
		return "lava_crack"
	return "unknown"

func _reset_all_slot_highlights() -> void:
	for i in range(_slot_visuals.size()):
		var visual: TextureRect = _slot_visuals[i]
		if visual != null:
			visual.texture = _load_texture(SLOT_EMPTY_PATH)
#endregion

#region 碰撞检测系统
func _check_module_collision() -> void:
	if _path == null:
		return

	var player_pos: Vector2 = _player.global_position
	var current_grid_index: int = get_grid_index_at_position(player_pos)

	if current_grid_index >= 0 and current_grid_index != _player_last_grid_index:
		if _placed_modules.has(current_grid_index):
			_trigger_module_effect(current_grid_index)
		_player_last_grid_index = current_grid_index

func _trigger_module_effect(grid_index: int) -> void:
	if not _placed_modules.has(grid_index):
		return

	var module_sprite: Sprite2D = _placed_modules[grid_index]
	print("玩家经过模块: %s (格子 %d)" % [module_sprite.name, grid_index])

	_boss_progress += 1
	_update_ui()

	if _boss_progress >= _total_charge and not _boss_spawned:
		_spawn_boss()

	_play_module_collision_effect(module_sprite)

func _play_module_collision_effect(module_sprite: Sprite2D) -> void:
	if module_sprite == null:
		return

	var tween: Tween = create_tween()
	tween.tween_property(module_sprite, "modulate", Color(2, 2, 2, 1), 0.1)
	tween.tween_property(module_sprite, "modulate", Color(1, 1, 1, 1), 0.2)
#endregion

#region BOSS系统
func _spawn_boss() -> void:
	if _boss_spawned:
		return

	_boss_spawned = true

	_boss_entity = Node2D.new()
	_boss_entity.name = "BossEntity"

	_boss_sprite = Sprite2D.new()
	_boss_sprite.name = "BossVisual"
	_boss_sprite.texture = _load_texture(BOSS_PATH)
	_boss_sprite.centered = true
	_boss_entity.add_child(_boss_sprite)

	var boss_label: Label = Label.new()
	boss_label.text = "BOSS"
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	boss_label.offset_top = -35
	boss_label.add_theme_font_size_override("font_size", 16)
	boss_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
	_boss_entity.add_child(boss_label)

	_boss_entity.position = Vector2(-TRACK_WIDTH, TRACK_HEIGHT)
	add_child(_boss_entity)

	print("⚠️ BOSS 已觉醒！")
#endif
