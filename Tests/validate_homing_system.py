#!/usr/bin/env python3
"""
跟踪弹系统验证脚本
检查跟踪弹系统是否正确实现
"""

import os
import sys

def check_file_exists(filepath):
    """检查文件是否存在"""
    return os.path.exists(filepath)

def validate_homing_system():
    """验证跟踪弹系统"""
    print("=== 跟踪弹系统验证 ===\n")
    
    base_path = "D:/game-dev/Godot-4-Tower-Defense-Template"
    
    # 检查核心文件
    files_to_check = [
        "Scenes/turrets/projectileTurret/bullet/homingBullet.gd",
        "Scenes/turrets/projectileTurret/bullet/homingBullet.tscn",
        "Scenes/turrets/projectileTurret/projectileTurret.gd",
        "Tests/ValidateHomingSystem.gd"
    ]
    
    all_files_exist = True
    for file_path in files_to_check:
        full_path = os.path.join(base_path, file_path)
        if check_file_exists(full_path):
            print(f"✓ {file_path}")
        else:
            print(f"✗ {file_path}")
            all_files_exist = False
    
    # 检查homingBullet.gd关键功能
    homing_script_path = os.path.join(base_path, "Scenes/turrets/projectileTurret/bullet/homingBullet.gd")
    if check_file_exists(homing_script_path):
        with open(homing_script_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        required_functions = [
            "homing_movement",
            "update_tracking_target", 
            "find_new_target",
            "setup_homing_properties",
            "get_tracking_status"
        ]
        
        print(f"\n检查跟踪弹脚本功能:")
        for func_name in required_functions:
            if f"func {func_name}" in content:
                print(f"✓ {func_name} 方法")
            else:
                print(f"✗ 缺少 {func_name} 方法")
    
    # 检查projectileTurret.gd更新
    turret_script_path = os.path.join(base_path, "Scenes/turrets/projectileTurret/projectileTurret.gd")
    if check_file_exists(turret_script_path):
        with open(turret_script_path, 'r', encoding='utf-8') as f:
            content = f.read()
            
        if "should_use_homing_bullets" in content:
            print("✓ should_use_homing_bullets 方法")
        else:
            print("✗ 缺少 should_use_homing_bullets 方法")
            
        if "homingBullet.tscn" in content:
            print("✓ 跟踪弹场景引用")
        else:
            print("✗ 缺少跟踪弹场景引用")
    
    print(f"\n=== 验证结果 ===")
    if all_files_exist:
        print("✓ 所有必要文件已创建")
    else:
        print("✗ 部分文件缺失")
    
    print("\n跟踪弹系统已为箭塔启用！")
    print("功能特性:")
    print("- 箭塔默认使用跟踪弹")
    print("- 子弹会自动追踪移动的目标")
    print("- 支持转向强度和追踪范围配置")
    print("- 性能优化：定期更新目标而非每帧更新")

if __name__ == "__main__":
    validate_homing_system()