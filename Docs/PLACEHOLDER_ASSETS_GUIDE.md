# 占位资源生成说明

## 🎯 快速开始

### 方法1：自动生成（推荐）✨

**只需运行游戏，占位图会自动生成！**

我已经在 `GameScene.gd` 中实现了智能资源管理系统：

```gdscript
func _ready() -> void:
    _ensure_assets_exist()  # ← 自动检测并生成缺失的PNG
    # ... 其他初始化代码
```

**操作步骤：**
1. 在 Godot 编辑器中打开 `scenes/game/GameScene.tscn`
2. 按 **F5** 运行场景（或点击 ▶ 按钮）
3. 首次运行时会自动生成所有占位PNG到：
   ```
   res://assets/images/game/
   ├── track/     (跑道背景)
   ├── slots/     (格子插槽)
   ├── cards/     (手牌卡片)
   ├── modules/   (模块图标)
   └── entities/  (角色精灵)
   ```
4. 控制台会显示：`"游戏场景初始化完成 (图片资源版)"`
5. 🎉 所有占位图已生成！

---

### 方法2：使用编辑器脚本

如果你想在不运行完整游戏的情况下生成资源：

1. 打开 Godot 编辑器
2. 在编辑器顶部菜单：`场景` → `新脚本` → 选择 `EditorScript`
3. 将以下代码粘贴进去并运行：

```gdscript
@tool
extends EditorScript

func _run():
    # 复制 GeneratePlaceholderAssets.gd 的内容到这里
    pass
```

或者直接打开并运行：
- 📄 `scripts/tools/GeneratePlaceholderAssets.gd`

---

## 📁 生成的资源清单

### 跑道资源 (track/)
| 文件名 | 尺寸 | 用途 | 状态 |
|--------|------|------|------|
| `track_background.png` | 620×420 | 跑道底色背景 | ✅ 自动生成 |

### 格子插槽 (slots/)
| 文件名 | 尺寸 | 用途 | 说明 |
|--------|------|------|------|
| `slot_empty.png` | 44×44 | 空白格子 | 暗红色边框 |
| `slot_highlight.png` | 44×44 | 高亮格子 | 金黄色边框(可放置) |
| `slot_occupied.png` | 44×44 | 已占用格子 | 半透明暗色 |

### 手牌卡片 (cards/)
| 文件名 | 尺寸 | 类型 | 颜色 |
|--------|------|------|------|
| `card_forest.png` | 60×80 | 森林卡 | 绿色 |
| `card_lab.png` | 60×80 | 实验室卡 | 蓝灰色 |
| `card_lava.png` | 60×80 | 熔岩卡 | 红色 |
| `card_back.png` | 60×80 | 卡背 | 深棕色 |

### 模块图标 (modules/)
| 文件名 | 尺寸 | 类型 | 形状 |
|--------|------|------|------|
| `module_forest.png` | 32×32 | 森林模块 | 圆形绿色 |
| `module_lab.png` | 32×32 | 实验室模块 | 圆形蓝灰 |
| `module_lava.png` | 32×32 | 熔岩模块 | 圆形红色 |

### 实体精灵 (entities/)
| 文件名 | 尺寸 | 用途 | 外观 |
|--------|------|------|------|
| `player.png` | 24×24 | 玩家角色 | 蓝色椭圆 |
| `boss.png` | 50×50 | BOSS | 红色菱形 |

---

## 🎨 如何替换美术资源

### 步骤：

1. **准备你的PNG图片**
   - 保持相同尺寸（或调整代码中的常量）
   - 使用透明背景（推荐）
   - 像素风格建议使用最近邻插值

2. **替换文件**
   ```
   直接覆盖对应路径的文件即可：
   
   assets/images/game/
   ├── track/track_background.png      ← 替换跑道
   ├── slots/slot_empty.png            ← 替换空格
   ├── cards/card_forest.png           ← 替换森林卡
   ├── modules/module_forest.png       ← 替换森林模块
   └── entities/player.png             ← 替换玩家
   ```

3. **重启游戏或刷新**
   - Godot 会自动重新加载修改的资源
   - 如果没更新，尝试：`项目` → `重新加载当前项目`

4. **验证效果**
   - 运行游戏查看新的美术表现
   - 调整不满意的部分

---

## 🔧 高级配置

### 修改资源尺寸

编辑 `GameScene.gd` 中的常量（第8-15行）：

```gdscript
const SLOT_SIZE: float = 40.0        # 改为 48 或其他尺寸
# 注意：需要同时删除旧的占位图让它重新生成
```

### 自定义占位图样式

修改 `_create_placeholder_*()` 函数（第145-264行）中的颜色值：

```gdscript
func _create_placeholder_slots() -> void:
    # 修改这里的颜色来改变占位图外观
    img_empty.fill(Color(0.15, 0.12, 0.10, 0.8))  # 背景色
    # 边框颜色
    img_empty.set_pixel(x, i, Color(0.5, 0.2, 0.15, 0.9))
```

### 删除缓存强制重新生成

如果想重新生成所有占位图：

```powershell
# Windows PowerShell
Remove-Item -Recurse -Force "assets/images/game"

# 然后运行游戏，会自动重新生成
```

---

## ⚠️ 注意事项

1. **首次运行较慢**：因为需要生成PNG文件
2. **只生成一次**：之后检测到文件存在就跳过
3. **版本控制**：建议将生成的占位图提交到Git
4. **生产环境**：正式发布前替换为真实美术资源

---

## 📞 故障排查

### 问题：图片没有生成？
**解决方案：**
- 检查控制台是否有错误信息
- 确认 `assets/images/game/` 目录有写入权限
- 尝试手动删除该目录后重试

### 问题：替换图片后没有更新？
**解决方案：**
- 重启 Godot 编辑器
- 清理导入缓存：删除 `.import/` 目录下的对应缓存
- 使用 `项目` → `重新加载当前项目`

### 问题：图片显示模糊？
**解决方案：**
- 在文件系统选中PNG → 导入面板设置：
  - Filter: `Nearest` (像素风) 或 `Linear` (平滑)
  - 勾选 `Mipmaps` (如果需要)

---

## 🚀 下一步

- [ ] 运行游戏查看占位效果
- [ ] 准备真实的美术素材
- [ ] 替换占位图为最终资源
- [ ] 调整UI布局和间距
- [ ] 测试不同分辨率下的显示效果

---

**最后更新**: 2026-04-08  
**适用版本**: Monster Loop MVP 3+
