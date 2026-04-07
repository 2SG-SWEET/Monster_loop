# Monster Loop - 宠物精灵图片获取指南

## 📋 概述

由于 API 访问限制，本指南将帮助你手动获取 8 个克苏鲁风格的宠物精灵图片。

## 🎨 宠物精灵列表

| 序号 | 中文名称 | 英文名称 | 稀有度 | 文件名 |
|------|----------|----------|--------|--------|
| 1 | 眼魔侍从 | Eye Spawn | ★☆☆☆☆ 普通 | Pet_EyeSpawn_Idle.png |
| 2 | 触手猫 | Tentacle Mew | ★★☆☆☆ 常见 | Pet_TentacleMew_Idle.png |
| 3 | 脓液史莱姆 | Ichor Slime | ★☆☆☆☆ 普通 | Pet_IchorSlime_Idle.png |
| 4 | 深渊幼犬 | Abyss Pup | ★★★☆☆ 稀有 | Pet_AbyssPup_Idle.png |
| 5 | 信使乌鸦 | Messenger Corvus | ★★☆☆☆ 常见 | Pet_MessengerCorvus_Idle.png |
| 6 | 虚空幼虫 | Void Larva | ★★★★☆ 史诗 | Pet_VoidLarva_Idle.png |
| 7 | 溺亡者之握 | Drowned Grasp | ★★★☆☆ 稀有 | Pet_DrownedGrasp_Idle.png |
| 8 | 古神之种 | Old God Sprout | ★★★★★ 传说 | Pet_OldGodSprout_Idle.png |

## 📝 生成提示词（Prompts）

### 1. 眼魔侍从 (Eye Spawn)
```
pixel art, 32x32 pixels, cute but eerie floating eyeball creature, dark purple flesh ball with vein textures, one giant central eye with yellow-green iris and vertical pupil, 3-4 small secondary eyes around, 3 tiny tentacles hanging from bottom with small suckers, wearing tattered monk hood on top, rusty small bell around neck, ancient runes faintly visible in pupil, medieval manuscript illustration style, lovecraftian, darkest dungeon style, dark color palette, thick black outlines
```

### 2. 触手猫 (Tentacle Mew)
```
pixel art, 32x32 pixels, cute but eerie black cat with unnatural oily fur, tail is a complete tentacle with eye pattern at end, 2-3 small tentacles on back that can stand up, vertical pupil eyes with faint phosphorescent glow, slightly transparent claws showing internal blood vessels, faded red ribbon around neck, small rusty silver bells on ears, branded heretic mark on body, medieval manuscript illustration style, lovecraftian, darkest dungeon style, dark color palette, thick black outlines
```

### 3. 脓液史莱姆 (Ichor Slime)
```
pixel art, 32x32 pixels, irregular blob shape, yellow-green translucent slime with bubbles inside, various debris floating inside (bones, teeth, trinkets), bubbles constantly forming and bursting on surface, occasional faint human face silhouette appearing and dissolving, fake feet made of solidified slime at bottom, rusty knight badge inside, half-digested parchment scroll, small broken chain link, medieval manuscript illustration style, lovecraftian, darkest dungeon style, dark color palette, thick black outlines
```

### 4. 深渊幼犬 (Abyss Pup)
```
pixel art, 32x32 pixels, scrawny black hound, three fused dog heads with only one conscious, two dead heads with hollow eyes and slightly open mouths, six extra legs on body sides, tail splits into two tentacles, glowing crack on chest like third eye, broken iron collar around neck, holy water burn scars on body, inquisition tag hanging from one ear, medieval manuscript illustration style, lovecraftian, darkest dungeon style, dark color palette, thick black outlines
```

### 5. 信使乌鸦 (Messenger Corvus)
```
pixel art, 32x32 pixels, slightly larger than normal crow with unhealthy sheen on feathers, three eyes - third eye on forehead always open, small tentacle-like feathers on wing edges, abnormally long and curved claws like human fingers, tiny runes engraved on beak, small parchment scroll tied to leg, messenger whistle around neck, dried herbs mixed in feathers, medieval manuscript illustration style, lovecraftian, darkest dungeon style, dark color palette, thick black outlines
```

### 6. 虚空幼虫 (Void Larva)
```
pixel art, 32x32 pixels, large caterpillar shape, translucent pale purple body with starry void inside, segmented body with false eye patterns on each segment, giant mouthparts with spiral teeth on head, small void tentacles on body sides, faint prayer bandages wrapped around body, tiny crown of thorns on head, corroded holy emblem embedded on one segment, medieval manuscript illustration style, lovecraftian, darkest dungeon style, dark color palette, thick black outlines
```

### 7. 溺亡者之握 (Drowned Grasp)
```
pixel art, 32x32 pixels, giant swollen pale translucent drowned hand crawling on fingers, tiny moving human face in center of palm, constantly dripping black water/slime, broken wrist showing internal bones and tentacles, rusty wedding ring on ring finger, water-soaked hemp rope wrapped around wrist, ancient divination symbols on palm lines, medieval manuscript illustration style, lovecraftian, darkest dungeon style, dark color palette, thick black outlines
```

### 8. 古神之种 (Old God Sprout)
```
pixel art, 32x32 pixels, small potted plant with eerie details, flower pot is tiny skull of unknown material, twisted humanoid plant stem with tiny limbs, flower is closed eyeball that slowly blinks, roots extending from bottom of pot wriggling like tentacles, slight air distortion around it, alchemy symbols on skull pot, gold thread wrapped around stem, small holy bone fragments in soil, medieval manuscript illustration style, lovecraftian, darkest dungeon style, dark color palette, thick black outlines
```

## 🚀 获取图片的方法

### 方法一：使用在线 AI 图片生成工具

1. 访问任意 AI 图片生成网站（如 Midjourney、DALL-E、Stable Diffusion 等）
2. 复制上面的提示词
3. 设置参数：
   - 尺寸：1024x1024 或 512x512
   - 风格：像素艺术 (pixel art)
4. 生成图片后，保存到 `assets/images/pets/` 目录

### 方法二：使用像素艺术编辑器

1. 使用 Aseprite、Piskel 或其他像素艺术编辑器
2. 根据设计文档中的描述手动绘制
3. 参考配色方案：
   - 深紫：#4A3A5C
   - 暗绿：#6B8E23
   - 铁锈红：#8B3A3A
   - 腐尸绿：#9ACD32

### 方法三：委托画师

根据 `MonsterLoop_Creature_Design_CthulhuPets.md` 中的详细设计文档，找像素艺术画师定制。

## 📁 保存位置

所有图片应保存到：
```
assets/images/pets/
```

## 🎯 下一步

获取图片后，你可以：
1. 在 Godot 中导入这些图片
2. 设置纹理过滤为 Nearest（像素风）
3. 创建 Sprite2D 节点使用这些图片

---
**文档版本**: 1.0  
**创建日期**: 2026-04-07
