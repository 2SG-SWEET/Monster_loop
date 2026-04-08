extends SceneTree
## GameScene 初始化测试脚本
## 用于诊断为什么控制台没有输出

func _init() -> void:
	print("\n" + "=" .repeat(70))
	print("🔍 GameScene 诊断工具")
	print("=" .repeat(70) + "\n")

	# 1. 检查场景文件是否存在
	print("[1/5] 检查场景文件...")
	var scene_path: String = "res://scenes/game/GameScene.tscn"
	if ResourceLoader.exists(scene_path):
		print("  ✅ 场景文件存在: %s" % scene_path)
	else:
		print("  ❌ 场景文件不存在: %s" % scene_path)
		quit()
		return

	# 2. 检查脚本文件
	print("\n[2/5] 检查脚本文件...")
	var script_path: String = "res://scripts/game/GameScene.gd"
	if ResourceLoader.exists(script_path):
		print("  ✅ 脚本文件存在: %s" % script_path)

		# 尝试加载脚本检查语法错误
		var script: GDScript = load(script_path) as GDScript
		if script:
			print("  ✅ 脚本加载成功（无语法错误）")
		else:
			print("  ❌ 脚本加载失败（可能有语法错误）")
			quit()
			return
	else:
		print("  ❌ 脚本文件不存在: %s" % script_path)
		quit()
		return

	# 3. 检查场景能否加载
	print("\n[3/5] 尝试加载场景...")
	var scene: PackedScene = load(scene_path)
	if scene == null:
		print("  ❌ 场景加载失败！")
		print("  可能原因：")
		print("    - 场景文件损坏")
		print("    - 引用了不存在的资源或脚本")
		quit()
		return

	print("  ✅ 场景加载成功")

	# 4. 实例化场景并检查节点
	print("\n[4/5] 实例化场景并检查节点结构...")
	var game_scene: Node2D = scene.instantiate() as Node2D
	if game_scene == null:
		print("  ❌ 场景实例化失败！")
		quit()
		return

	print("  ✅ 场景实例化成功")

	# 检查关键节点
	var required_nodes: Array[String] = [
		"PathContainer/LoopPath",
		"PlayerContainer/Player",
		"TileContainer",
		"UI/TopBar/LoopCount",
		"UI/BossProgressUI/ProgressBar",
		"UI/HandUI/VBoxContainer/CardList"
	]

	var all_nodes_exist: bool = true
	for node_path in required_nodes:
		var node: Node = game_scene.get_node_or_null(node_path)
		if node:
			print("  ✓ 节点存在: %s (类型: %s)" % [node_path, node.get_class()])
		else:
			print("  ✗ 节点缺失: %s" % node_path)
			all_nodes_exist = false

	if not all_nodes_exist:
		print("\n  ⚠️  警告：部分必需节点缺失，可能导致初始化失败！")

	# 5. 测试资源目录
	print("\n[5/5] 检查资源目录...")
	var assets_base: String = "res://assets/images/game/"
	var dir: DirAccess = DirAccess.open(assets_base)
	if dir:
		print("  ✅ 资源基础目录存在: %s" % assets_base)

		# 列出已存在的资源
		var subdirs: Array[String] = ["track", "slots", "cards", "modules", "entities"]
		for subdir in subdirs:
			var subdir_path: String = assets_base + subdir
			var subdir_dir: DirAccess = DirAccess.open(subdir_path)
			if subdir_dir:
				subdir_dir.list_dir_begin()
				var file_count: int = 0
				var file_name: String = subdir_dir.get_next()
				while file_name != "":
					if not subdir_dir.current_is_dir() and file_name.ends_with(".png"):
						file_count += 1
					file_name = subdir_dir.get_next()
				subdir_dir.list_dir_end()

				if file_count > 0:
					print("    ✓ %s/ - 已有 %d 个PNG文件" % [subdir, file_count])
				else:
					print("    ○ %s/ - 空目录（将自动生成占位图）" % subdir)
			else:
				print("    ⬜ %s/ - 目录不存在（将自动创建）" % subdir)
	else:
		print("  ⬜ 资源目录不存在（首次运行时会自动创建）")

	# 清理
	game_scene.free()

	# 输出总结
	print("\n" + "-".repeat(70))
	print("📊 诊断结果:")
	print("-".repeat(70))

	if all_nodes_exist:
		print("✅ 所有检查通过！场景应该能正常初始化。")
		print("")
		print("如果运行时仍然没有输出，请检查：")
		print("  1. 是否真的运行了 GameScene.tscn（而不是其他场景）")
		print("  2. 控制台是否有红色错误信息？")
		print("  3. 是否有其他脚本在 GameScene 之前报错？")
		print("  4. 尝试在编辑器中直接打开 GameScene.tscn 并按 F5 运行")
	else:
		print("⚠️  发现问题！需要修复缺失的节点。")

	print("")
	print("💡 建议：现在重新运行游戏，查看详细的初始化日志")
	print("=" .repeat(70) + "\n")

	quit()
