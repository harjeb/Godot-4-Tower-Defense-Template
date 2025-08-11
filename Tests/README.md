# 塔防增强系统测试框架

## 概述
此目录包含塔防游戏增强系统的测试文件，用于验证各个功能模块的正确性。

## 测试文件说明

### 核心测试
- `SimpleTest.gd` - 基础系统验证脚本
- `TestFramework.gd` - 测试框架基础工具
- `TestRunner.gd` - 测试运行器（自动化）

### 专项测试套件
- `ElementSystemTests.gd` - 元素系统和克制关系测试
- `EnemyAbilitiesTests.gd` - 敌人特殊能力测试
- `GemSystemTests.gd` - 宝石系统和合成机制测试
- `InventoryUISystemTests.gd` - 物品和UI系统测试
- `CombatIntegrationTests.gd` - 战斗系统集成测试
- `ManualTestingGuide.gd` - 手动测试指南

### 测试场景
- `TestScene.tscn/.gd` - 可视化测试界面

## 运行方式

### 1. 简单验证
```bash
godot --headless --script Tests/SimpleTest.gd
```

### 2. 游戏内验证
主游戏启动时会自动进行基础系统验证，确保核心功能正常加载。

### 3. 完整测试套件
在Godot编辑器中打开 `Tests/TestScene.tscn` 运行完整测试。

## 测试覆盖范围
- ✅ 元素克制关系计算
- ✅ 宝石合成逻辑
- ✅ 敌人特殊能力行为
- ✅ 伤害计算公式
- ✅ UI界面交互
- ✅ 物品管理功能

## 注意事项
- 测试文件仅用于开发验证，不影响游戏运行
- 可根据需要删除Tests目录以减小发布体积
- 测试数据与实际游戏数据分离，确保不影响正常游戏体验