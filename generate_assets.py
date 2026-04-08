#!/usr/bin/env python3
"""
Monster Loop - 占位资源生成器
使用 PIL 生成游戏所需的占位PNG图片
"""

import os
from PIL import Image, ImageDraw
import math

def ensure_dir(path):
    """确保目录存在"""
    os.makedirs(os.path.dirname(path), exist_ok=True)

def create_track_background(path):
    """生成跑道背景"""
    w, h = 620, 420
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 绘制圆角矩形背景
    margin = 20
    draw.rounded_rectangle(
        [margin, margin, w - margin, h - margin],
        radius=40,
        fill=(38, 46, 31, 255)  # 暗绿色
    )
    
    img.save(path)
    print(f"   [OK] track_background.png ({w}x{h})")

def create_slot(path, w, h, bg_color, border_color, name):
    """生成格子插槽"""
    img = Image.new('RGBA', (w, h), bg_color)
    draw = ImageDraw.Draw(img)
    
    # 绘制边框
    border_width = 2
    draw.rectangle([0, 0, w-1, h-1], outline=border_color, width=border_width)
    
    img.save(path)
    print(f"   [OK] {os.path.basename(path)} ({w}x{h}) - {name}")

def create_card(path, w, h, color, name):
    """生成手牌卡片"""
    img = Image.new('RGBA', (w, h), color)
    draw = ImageDraw.Draw(img)
    
    # 金色边框
    border_color = (230, 217, 102, 255)
    border_width = 2
    draw.rectangle([0, 0, w-1, h-1], outline=border_color, width=border_width)
    
    img.save(path)
    print(f"   [OK] {os.path.basename(path)} ({w}x{h}) - {name}")

def create_module_icon(path, w, h, color, name):
    """生成模块图标（圆形）"""
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 绘制圆形
    cx, cy = w // 2, h // 2
    radius = w // 2 - 2
    draw.ellipse([cx - radius, cy - radius, cx + radius, cy + radius], fill=color)
    
    img.save(path)
    print(f"   [OK] {os.path.basename(path)} ({w}x{h}) - {name}")

def create_player(path, w, h):
    """生成玩家精灵（椭圆）"""
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 绘制蓝色椭圆
    color = (77, 153, 230, 255)
    margin = 2
    draw.ellipse([margin, margin, w - margin, h - margin], fill=color)
    
    img.save(path)
    print(f"   [OK] player.png ({w}x{h})")

def create_boss(path, w, h):
    """生成BOSS精灵（菱形）"""
    img = Image.new('RGBA', (w, h), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # 绘制红色菱形
    color = (204, 38, 38, 255)
    cx, cy = w // 2, h // 2
    size = w // 2 - 2
    
    points = [
        (cx, cy - size),  # 上
        (cx + size, cy),  # 右
        (cx, cy + size),  # 下
        (cx - size, cy),  # 左
    ]
    draw.polygon(points, fill=color)
    
    img.save(path)
    print(f"   [OK] boss.png ({w}x{h})")

def main():
    print("\n" + "=" * 60)
    print("Monster Loop - Placeholder Asset Generator")
    print("=" * 60 + "\n")
    
    base_path = "assets/images/game/"
    
    # 创建目录结构
    os.makedirs(base_path + "track", exist_ok=True)
    os.makedirs(base_path + "slots", exist_ok=True)
    os.makedirs(base_path + "cards", exist_ok=True)
    os.makedirs(base_path + "modules", exist_ok=True)
    os.makedirs(base_path + "entities", exist_ok=True)
    
    print("[DIR] Directory structure prepared\n")
    
    # 1. 生成跑道背景
    print("[1/6] Generating track background...")
    create_track_background(base_path + "track/track_background.png")
    
    # 2. 生成格子插槽 (3种状态)
    print("\n[2/6] Generating slot placeholders...")
    create_slot(base_path + "slots/slot_empty.png", 44, 44, 
                (38, 31, 26, 204), (128, 51, 38, 230), "empty")
    create_slot(base_path + "slots/slot_highlight.png", 44, 44,
                (51, 46, 26, 230), (230, 191, 51, 255), "highlight")
    create_slot(base_path + "slots/slot_occupied.png", 44, 44,
                (31, 26, 20, 179), (77, 38, 26, 153), "occupied")
    
    # 3. 生成卡片 (4种类型)
    print("\n[3/6] Generating card placeholders...")
    create_card(base_path + "cards/card_forest.png", 60, 80,
                (45, 80, 22, 255), "forest")
    create_card(base_path + "cards/card_lab.png", 60, 80,
                (74, 85, 104, 255), "lab")
    create_card(base_path + "cards/card_lava.png", 60, 80,
                (197, 48, 48, 255), "lava")
    create_card(base_path + "cards/card_back.png", 60, 80,
                (77, 64, 51, 255), "back")
    
    # 4. 生成模块图标 (3种)
    print("\n[4/6] Generating module icons...")
    create_module_icon(base_path + "modules/module_forest.png", 32, 32,
                       (45, 80, 22, 255), "forest")
    create_module_icon(base_path + "modules/module_lab.png", 32, 32,
                       (74, 85, 104, 255), "lab")
    create_module_icon(base_path + "modules/module_lava.png", 32, 32,
                       (197, 48, 48, 255), "lava")
    
    # 5. 生成玩家角色
    print("\n[5/6] Generating entity sprites...")
    create_player(base_path + "entities/player.png", 24, 24)
    
    # 6. 生成BOSS
    create_boss(base_path + "entities/boss.png", 50, 50)
    
    print("\n" + "-" * 60)
    print("Asset Statistics:")
    print("-" * 60)
    
    # 统计生成的文件
    total_files = 0
    for root, dirs, files in os.walk(base_path):
        for file in files:
            if file.endswith('.png'):
                total_files += 1
    
    print(f"   [OK] Generated {total_files} PNG files")
    print(f"   [OK] Location: {base_path}")
    print("\n" + "=" * 60)
    print("Ready to run the game!")
    print("Tip: Replace these PNGs to update art assets")
    print("=" * 60 + "\n")

if __name__ == "__main__":
    main()
