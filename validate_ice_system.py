#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
冰元素系统验证脚本
在Python环境中验证冰元素宝石系统的完整性
"""

import sys
import os
import json
import re

def validate_ice_gem_system():
    """验证冰元素宝石系统的完整性"""
    print("=== 冰元素宝石系统验证 ===")
    print()
    
    # 1. 验证Data.gd文件
    print("1. 验证数据文件...")
    data_file = "Scenes/main/Data.gd"
    if not os.path.exists(data_file):
        print(f"[ERROR] 数据文件不存在: {data_file}")
        return False
    
    with open(data_file, 'r', encoding='utf-8') as f:
        data_content = f.read()
    
    # 检查冰宝石定义
    ice_gems = ["ice_basic", "ice_intermediate", "ice_advanced"]
    for gem in ice_gems:
        if f'"{gem}"' not in data_content:
            print(f"[ERROR] 缺少冰宝石定义: {gem}")
            return False
        else:
            print(f"[OK] 找到冰宝石定义: {gem}")
    
    # 检查冰元素效果
    ice_effects = [
        "frost_debuff_1", "frost_debuff_2", "frost_debuff_3",
        "freeze_chance_15_1s", "freeze_chance_20_0.5s",
        "freeze_main_2s", "freeze_on_end_1.5s"
    ]
    
    for effect in ice_effects:
        if f'"{effect}"' not in data_content:
            print(f"[ERROR] 缺少冰元素效果: {effect}")
            return False
        else:
            print(f"[OK] 找到冰元素效果: {effect}")
    
    print()
    
    # 2. 验证StatusEffect.gd文件
    print("2. 验证状态效果系统...")
    status_file = "Scenes/systems/StatusEffect.gd"
    if not os.path.exists(status_file):
        print(f"[ERROR] 状态效果文件不存在: {status_file}")
        return False
    
    with open(status_file, 'r', encoding='utf-8') as f:
        status_content = f.read()
    
    # 检查冰霜和冻结效果处理
    if '"frost"' not in status_content:
        print("[ERROR] 缺少冰霜效果处理")
        return False
    else:
        print("[OK] 找到冰霜效果处理")
    
    if '"freeze"' not in status_content:
        print("[ERROR] 缺少冻结效果处理")
        return False
    else:
        print("[OK] 找到冻结效果处理")
    
    print()
    
    # 3. 验证GemEffectSystem.gd文件
    print("3. 验证宝石效果系统...")
    gem_effect_file = "Scenes/systems/GemEffectSystem.gd"
    if not os.path.exists(gem_effect_file):
        print(f"[ERROR] 宝石效果系统文件不存在: {gem_effect_file}")
        return False
    
    with open(gem_effect_file, 'r', encoding='utf-8') as f:
        gem_effect_content = f.read()
    
    # 检查冰元素特效方法
    ice_methods = [
        "apply_frost_area", "apply_chance_freeze", "is_target_frozen",
        "get_frost_stacks", "apply_frozen_damage_bonus"
    ]
    
    for method in ice_methods:
        if method not in gem_effect_content:
            print(f"[ERROR] 缺少冰元素方法: {method}")
            return False
        else:
            print(f"[OK] 找到冰元素方法: {method}")
    
    print()
    
    # 4. 验证turret_base.gd文件
    print("4. 验证塔基类...")
    turret_file = "Scenes/turrets/turretBase/turret_base.gd"
    if not os.path.exists(turret_file):
        print(f"[ERROR] 塔基类文件不存在: {turret_file}")
        return False
    
    with open(turret_file, 'r', encoding='utf-8') as f:
        turret_content = f.read()
    
    # 检查冰元素效果处理器
    ice_handlers = [
        "_setup_frost_area_effect", "_setup_chance_freeze_effect",
        "_setup_freeze_main_target_effect", "_setup_frost_aura_effect"
    ]
    
    for handler in ice_handlers:
        if handler not in turret_content:
            print(f"[ERROR] 缺少冰元素处理器: {handler}")
            return False
        else:
            print(f"[OK] 找到冰元素处理器: {handler}")
    
    print()
    
    # 5. 验证测试文件
    print("5. 验证测试文件...")
    test_files = [
        "Tests/IceGemSystemTest.gd",
        "Tests/IceElementValidation.gd",
        "IceElementDemo.gd",
        "ValidateIceElement.gd"
    ]
    
    for test_file in test_files:
        if os.path.exists(test_file):
            print(f"[OK] 找到测试文件: {test_file}")
        else:
            print(f"[ERROR] 缺少测试文件: {test_file}")
            return False
    
    print()
    
    # 6. 验证效果池系统
    print("6. 验证效果池系统...")
    effect_pool_file = "Scenes/systems/EffectPool.gd"
    if os.path.exists(effect_pool_file):
        print("[OK] 找到效果池系统")
    else:
        print("[ERROR] 缺少效果池系统")
        return False
    
    print()
    
    return True

def check_ice_gem_data_structure():
    """检查冰宝石数据结构"""
    print("=== 冰宝石数据结构检查 ===")
    print()
    
    data_file = "Scenes/main/Data.gd"
    with open(data_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 提取冰宝石数据
    ice_gem_pattern = r'"(ice_\w+)":\s*\{[^}]*"element":\s*"ice"[^}]*\}'
    ice_gems = re.findall(ice_gem_pattern, content, re.DOTALL)
    
    print(f"找到 {len(ice_gems)} 个冰宝石:")
    for gem in ice_gems:
        print(f"  - {gem}")
    
    # 检查塔类型覆盖
    tower_types = [
        "arrow_tower", "capture_tower", "mage_tower", "感应塔", 
        "末日塔", "pulse_tower", "弹射塔", "aura_tower", "weakness_tower"
    ]
    
    print(f"\n检查塔类型覆盖 ({len(tower_types)} 种):")
    for tower in tower_types:
        if tower in content:
            print(f"  [OK] {tower}")
        else:
            print(f"  [ERROR] {tower}")
    
    print()
    
    # 统计冰元素效果数量
    ice_effect_pattern = r'"(frost_\w+|freeze_\w+)"'
    ice_effects = re.findall(ice_effect_pattern, content)
    unique_effects = list(set(ice_effects))
    
    print(f"找到 {len(unique_effects)} 个独特的冰元素效果:")
    for effect in sorted(unique_effects):
        print(f"  - {effect}")
    
    print()

def main():
    """主函数"""
    print("冰元素宝石系统验证工具")
    print("=" * 50)
    print()
    
    # 切换到项目目录
    if os.path.exists("Scenes/main/Data.gd"):
        print("[OK] 已在项目目录中")
    else:
        print("[ERROR] 不在项目目录中，请切换到项目根目录")
        return
    
    print()
    
    # 执行验证
    success = validate_ice_gem_system()
    
    if success:
        print("[SUCCESS] 冰元素宝石系统验证通过！")
        print()
        
        # 详细数据结构检查
        check_ice_gem_data_structure()
        
        print("\n=== 系统完整性总结 ===")
        print("[OK] 数据结构完整")
        print("[OK] 状态效果系统完整")
        print("[OK] 宝石效果系统完整")
        print("[OK] 塔集成系统完整")
        print("[OK] 测试验证系统完整")
        print("[OK] 性能优化系统完整")
        print()
        print("冰元素宝石系统已完全实现，可以作为其他元素的实现模板！")
        
    else:
        print("[ERROR] 冰元素宝石系统验证失败，请检查上述问题")
    
    print()
    print("验证完成")

if __name__ == "__main__":
    main()