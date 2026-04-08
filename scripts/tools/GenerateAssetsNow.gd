extends SceneTree
## 独立占位资源生成器
## 直接运行此脚本即可生成所有占位PNG

func _init() -> void:
	print("\n" + "=" .repeat(60))
	print("🎨 Monster Loop - 占位资源生成器")
	print("=" .repeat(60) + "\n")

	var base_path: String = "res://assets/images/game/"

	# 创建目录结构
	DirAccess.make_dir_recursive_absolute(base_path + "track")
	DirAccess.make_dir_recursive_absolute(base_path + "slots")
	DirAccess.make_dir_recursive_absolute(base_path + "cards")
	DirAccess.make_dir_recursive_absolute(base_path + "modules")
	DirAccess.make_dir_recursive_absolute(base_path + "entities")

	print("📁 目录结构已准备\n")

	# 1. 生成跑道背景
	print("🔲 [1/6] 生成跑道背景...")
	_create_track_background(base_path + "track/track_background.png")

	# 2. 生成格子插槽 (3种状态)
	print("🔳 [2/6] 生成格子插槽...")
	_create_slot(base_path + "slots/slot_empty.png", 44, 44, Color(0.15, 0.12, 0.10, 0.8), Color(0.5, 0.2, 0.15, 0.9), "空格子")
	_create_slot(base_path + "slots/slot_highlight.png", 44, 44, Color(0.2, 0.18, 0.1, 0.9), Color(0.9, 0.75, 0.2, 1.0), "高亮格子")
	_create_slot(base_path + "slots/slot_occupied.png", 44, 44, Color(0.12, 0.10, 0.08, 0.7), Color(0.3, 0.15, 0.1, 0.6), "占用格子")

	# 3. 生成卡片 (4种类型)
	print("🃏 [3/6] 生成手牌卡片...")
	_create_card(base_path + "cards/card_forest.png", 60, 80, Color(0.176, 0.314, 0.086, 1), "森林卡")
	_create_card(base_path + "cards/card_lab.png", 60, 80, Color(0.29, 0.333, 0.408, 1), "实验室卡")
	_create_card(base_path + "cards/card_lava.png", 60, 80, Color(0.773, 0.188, 0.188, 1), "熔岩卡")
	_create_card(base_path + "cards/card_back.png", 60, 80, Color(0.3, 0.25, 0.2, 1), "卡背")

	# 4. 生成模块图标 (3种)
	print("🧩 [4/6] 生成模块图标...")
	_create_module_icon(base_path + "modules/module_forest.png", 32, 32, Color(0.176, 0.314, 0.086, 1), "森林模块")
	_create_module_icon(base_path + "modules/module_lab.png", 32, 32, Color(0.29, 0.333, 0.408, 1), "实验室模块")
	_create_module_icon(base_path + "modules/module_lava.png", 32, 32, Color(0.773, 0.188, 0.188, 1), "熔岩模块")

	# 5. 生成玩家角色
	print("👤 [5/6] 生成实体精灵...")
	_create_player(base_path + "entities/player.png", 24, 24)

	# 6. 生成BOSS
	_create_boss(base_path + "entities/boss.png", 50, 50)

	print("✅ [6/6] 完成!")

	print("\n" + "-".repeat(60))
	print("📊 资源统计:")
	print("-".repeat(60))

	var total_files: int = _count_files_in_dir(base_path)
	print("   ✓ 共生成 %d 个PNG文件" % total_files)
	print("   ✓ 存储位置: %s" % base_path)
	print("\n" + "=" .repeat(60))
	print("🎮 现在可以运行游戏查看效果!")
	print("💡 提示: 替换这些PNG即可更新美术资源")
	print("=" .repeat(60) + "\n")

	quit()

func _create_track_background(path: String) -> void:
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

	img.save_png(path)
	print("   ✓ track_background.png (620×420)")

func _create_slot(path: String, w: int, h: int, bg_color: Color, border_color: Color, name: String) -> void:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(bg_color)

	for i in range(2):
		for x in range(w):
			img.set_pixel(x, i, border_color)
			img.set_pixel(x, h - 1 - i, border_color)
		for y in range(h):
			img.set_pixel(i, y, border_color)
			img.set_pixel(w - 1 - i, y, border_color)

	img.save_png(path)
	print("   ✓ %s (%d×%d)" % [path.get_file(), w, h])

func _create_card(path: String, w: int, h: int, color: Color, name: String) -> void:
	var img: Image = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(color)

	for i in range(2):
		for x in range(w):
			img.set_pixel(x, i, Color(0.9, 0.85, 0.4, 1))
			img.set_pixel(x, h - 1 - i, Color(0.9, 0.85, 0.4, 1))
		for y in range(h):
			img.set_pixel(i, y, Color(0.9, 0.85, 0.4, 1))
			img.set_pixel(w - 1 - i, y, Color(0.9, 0.85, 0.4, 1))

	img.save_png(path)
	print("   ✓ %s (%d×%d)" % [path.get_file(), w, h])

func _create_module_icon(path: String, w: int, h: int, color: Color, name: String) -> void:
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

	img.save_png(path)
	print("   ✓ %s (%d×%d)" % [path.get_file(), w, h])

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

	img.save_png(path)
	print("   ✓ player.png (%d×%d)" % [w, h])

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

	img.save_png(path)
	print("   ✓ boss.png (%d×%d)" % [w, h])

func _count_files_in_dir(dir_path: String) -> int:
	var count: int = 0
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png"):
				count += 1
			file_name = dir.get_next()
		dir.list_dir_end()

		# 递归子目录
		dir.list_dir_begin()
		file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and not file_name.begins_with("."):
				count += _count_files_in_dir(dir_path + "/" + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()

	return count
