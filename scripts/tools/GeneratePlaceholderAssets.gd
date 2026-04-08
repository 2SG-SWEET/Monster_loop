@tool
extends EditorScript
## 占位资源生成器
## 生成游戏场景所需的所有占位PNG图片

func _run() -> void:
	var base_path: String = "res://assets/images/game/"
	DirAccess.make_dir_recursive_absolute(base_path + "track")
	DirAccess.make_dir_recursive_absolute(base_path + "slots")
	DirAccess.make_dir_recursive_absolute(base_path + "cards")
	DirAccess.make_dir_recursive_absolute(base_path + "modules")
	DirAccess.make_dir_recursive_absolute(base_path + "entities")
	DirAccess.make_dir_recursive_absolute(base_path + "ui")

	print("开始生成占位资源...")

	# 1. 跑道相关
	_create_track_background(base_path + "track/track_background.png", 620, 420)
	_create_track_stroke(base_path + "track/track_stroke.png", 620, 420)

	# 2. 格子插槽
	_create_slot(base_path + "slots/slot_empty.png", 44, 44, Color(0.15, 0.12, 0.10, 0.8), Color(0.5, 0.2, 0.15, 0.9))
	_create_slot(base_path + "slots/slot_highlight.png", 44, 44, Color(0.2, 0.18, 0.1, 0.9), Color(0.9, 0.75, 0.2, 1.0))
	_create_slot(base_path + "slots/slot_occupied.png", 44, 44, Color(0.12, 0.10, 0.08, 0.7), Color(0.3, 0.15, 0.1, 0.6))

	# 3. 手牌卡片
	_create_card(base_path + "cards/card_forest.png", 60, 80, Color(0.176, 0.314, 0.086, 1), "森林")
	_create_card(base_path + "cards/card_lab.png", 60, 80, Color(0.29, 0.333, 0.408, 1), "实验室")
	_create_card(base_path + "cards/card_lava.png", 60, 80, Color(0.773, 0.188, 0.188, 1), "熔岩")
	_create_card(base_path + "cards/card_back.png", 60, 80, Color(0.3, 0.25, 0.2, 1), "?")

	# 4. 模块图标
	_create_module_icon(base_path + "modules/module_forest.png", 32, 32, Color(0.176, 0.314, 0.086, 1))
	_create_module_icon(base_path + "modules/module_lab.png", 32, 32, Color(0.29, 0.333, 0.408, 1))
	_create_module_icon(base_path + "modules/module_lava.png", 32, 32, Color(0.773, 0.188, 0.188, 1))

	# 5. 实体
	_create_player(base_path + "entities/player.png", 24, 24)
	_create_boss(base_path + "entities/boss.png", 50, 50)

	# 6. UI元素
	_create_progress_bar(base_path + "ui/progress_bar_bg.png", 200, 20, Color(0.2, 0.18, 0.15, 0.9))
	_create_progress_bar(base_path + "ui/progress_bar_fill.png", 200, 20, Color(0.8, 0.3, 0.2, 1))
	_create_panel(base_path + "ui/panel_dark.png", 200, 100, Color(0.15, 0.13, 0.1, 0.95))
	_create_button(base_path + "ui/button_normal.png", 120, 40, Color(0.25, 0.22, 0.18, 0.95))
	_create_button(base_path + "ui/button_hover.png", 120, 40, Color(0.35, 0.30, 0.22, 0.95))

	print("✅ 所有占位资源生成完成！")

func _create_track_background(path: String, w: int, h: int) -> void:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.15, 0.18, 0.12, 1))

	var cr: int = 16

	for y in range(h):
		for x in range(w):
			var nx: float = (float(x) / w - 0.5) * 2.0
			var ny: float = (float(y) / h - 0.5) * 2.0

			if abs(nx) < 0.95 and abs(ny) < 0.95:
				var dist: float = max(abs(abs(nx) - 0.9), abs(abs(ny) - 0.85))
				if dist < 0.08:
					img.set_pixel(x, y, Color(0.2, 0.17, 0.13, 1))
				else:
					img.set_pixel(x, y, Color(0.15, 0.18, 0.12, 1))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	_save_image(img, path)

func _create_track_stroke(path: String, w: int, h: int) -> void:
	var img: Image = Image.create(w, h, true, Image.FORMAT_RGBA8)

	for y in range(h):
		for x in range(w):
			var nx: float = (float(x) / w - 0.5) * 2.0
			var ny: float = (float(y) / h - 0.5) * 2.0

			if abs(nx) < 0.92 and abs(ny) < 0.92:
				var edge_dist: float = min(min(abs(nx + 0.88), abs(nx - 0.88)), min(abs(ny + 0.83), abs(ny - 0.83)))
				if edge_dist < 0.03:
					img.set_pixel(x, y, Color(0.5, 0.35, 0.25, 0.8))
				else:
					img.set_pixel(x, y, Color(0, 0, 0, 0))

	_save_image(img, path)

func _create_slot(path: String, w: int, h: int, bg_color: Color, border_color: Color) -> void:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(bg_color)

	for i in range(2):
		for x in range(w):
			img.set_pixel(x, i, border_color)
			img.set_pixel(x, h - 1 - i, border_color)
		for y in range(h):
			img.set_pixel(i, y, border_color)
			img.set_pixel(w - 1 - i, y, border_color)

	_save_image(img, path)

func _create_card(path: String, w: int, h: int, color: Color, text: String) -> void:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)

	for i in range(2):
		for x in range(w):
			img.set_pixel(x, i, Color(0.9, 0.85, 0.4, 1))
			img.set_pixel(x, h - 1 - i, Color(0.9, 0.85, 0.4, 1))
		for y in range(h):
			img.set_pixel(i, y, Color(0.9, 0.85, 0.4, 1))
			img.set_pixel(w - 1 - i, y, Color(0.9, 0.85, 0.4, 1))

	var center_x: int = w / 2
	var center_y: int = h / 2

	_save_image(img, path)

func _create_module_icon(path: String, w: int, h: int, color: Color) -> void:
	var img: Image = Image.create(w, h, true, Image.FORMAT_RGBA8)
	var cx: float = w / 2.0
	var cy: float = h / 2.0

	for y in range(h):
		for x in range(w):
			var dx: float = x - cx
			var dy: float = y - cy
			var dist: float = sqrt(dx * dx + dy * dy)
			if dist < w / 2.0 - 2:
				img.set_pixel(x, y, color)

	_save_image(img, path)

func _create_player(path: String, w: int, h: int) -> void:
	var img: Image = Image.create(w, h, true, Image.FORMAT_RGBA8)
	var cx: float = w / 2.0
	var cy: float = h / 2.0

	for y in range(h):
		for x in range(w):
			var dx: float = x - cx
			var dy: float = y - cy
			var dist: float = sqrt(dx * dx + dy * 1.2)
			if dist < w / 2.0 - 1:
				img.set_pixel(x, y, Color(0.3, 0.6, 0.9, 1))

	_save_image(img, path)

func _create_boss(path: String, w: int, h: int) -> void:
	var img: Image = Image.create(w, h, true, Image.FORMAT_RGBA8)
	var cx: float = w / 2.0
	var cy: float = h / 2.0

	for y in range(h):
		for x in range(w):
			var dx: float = (x - cx) / (w / 2.0)
			var dy: float = (y - cy) / (h / 2.0)
			var dist: float = abs(dx) + abs(dy)
			if dist < 1.0:
				img.set_pixel(x, y, Color(0.8, 0.15, 0.15, 1))

	_save_image(img, path)

func _create_progress_bar(path: String, w: int, h: int, color: Color) -> void:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)

	for i in range(1):
		for x in range(w):
			img.set_pixel(x, i, Color(0.4, 0.35, 0.3, 1))
			img.set_pixel(x, h - 1 - i, Color(0.4, 0.35, 0.3, 1))
		for y in range(h):
			img.set_pixel(i, y, Color(0.4, 0.35, 0.3, 1))
			img.set_pixel(w - 1 - i, y, Color(0.4, 0.35, 0.3, 1))

	_save_image(img, path)

func _create_panel(path: String, w: int, h: int, color: Color) -> void:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)

	for i in range(2):
		for x in range(w):
			img.set_pixel(x, i, Color(0.5, 0.45, 0.35, 1))
			img.set_pixel(x, h - 1 - i, Color(0.5, 0.45, 0.35, 1))
		for y in range(h):
			img.set_pixel(i, y, Color(0.5, 0.45, 0.35, 1))
			img.set_pixel(w - 1 - i, y, Color(0.5, 0.45, 0.35, 1))

	_save_image(img, path)

func _create_button(path: String, w: int, h: int, color: Color) -> void:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)

	for i in range(2):
		for x in range(w):
			img.set_pixel(x, i, Color(0.7, 0.65, 0.5, 1))
			img.set_pixel(x, h - 1 - i, Color(0.7, 0.65, 0.5, 1))
		for y in range(h):
			img.set_pixel(i, y, Color(0.7, 0.65, 0.5, 1))
			img.set_pixel(w - 1 - i, y, Color(0.7, 0.65, 0.5, 1))

	_save_image(img, path)

func _save_image(img: Image, path: String) -> void:
	img.save_png(path)
	print("  ✓ %s" % path)
