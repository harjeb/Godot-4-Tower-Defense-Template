# 英雄系统集成指南

本指南将帮助您将完整的英雄系统集成到现有的塔防游戏中。

## 系统概述

英雄系统包含以下组件：
- **HeroBase.gd** - 核心英雄类
- **HeroSkill.gd** - 技能资源类
- **HeroManager.gd** - 英雄管理系统
- **LevelModifierSystem.gd** - 关卡词缀系统
- **HeroRangeIndicator.gd** - 范围指示器
- **HeroTalentSystem.gd** - 天赋系统
- **UI组件** - 英雄选择、信息面板、天赋选择界面

## 集成步骤

### 1. 添加系统节点到主场景

在 `Scenes/main/main.tscn` 中添加以下节点：

```gdscript
# 在 main 节点下添加：
HeroManager (Node)
LevelModifierSystem (Node)
HeroTalentSystem (Node)
HeroRangeIndicator (Node2D)

# 在 UI/CanvasLayer 下添加：
HeroSelection (Control)
HeroInfoPanel (Control)
HeroTalentSelection (Control)
```

### 2. 更新主场景脚本

在 `Scenes/main/main.gd` 中添加以下代码：

```gdscript
# 在 _ready() 函数中：
func _ready():
    # 现有代码...
    
    # 初始化英雄系统
    setup_hero_system()
    
    # 连接英雄系统信号
    connect_hero_signals()

func setup_hero_system():
    """初始化英雄系统"""
    var hero_manager = $HeroManager
    var level_modifier_system = $LevelModifierSystem
    var talent_system = $HeroTalentSystem
    var range_indicator = $HeroRangeIndicator
    
    # 设置UI组件
    var hero_selection = $UI/HeroSelection
    var hero_info_panel = $UI/HeroInfoPanel
    var talent_selection = $UI/HeroTalentSelection
    
    # 连接UI到系统
    hero_selection.setup_from_hero_manager(hero_manager)
    hero_info_panel.setup_from_hero_manager(hero_manager)
    talent_selection.setup_from_hero_manager(hero_manager)

func connect_hero_signals():
    """连接英雄系统信号"""
    var hero_manager = $HeroManager
    
    # 连接到现有游戏系统
    if hero_manager.has_signal("hero_deployed"):
        hero_manager.connect("hero_deployed", _on_hero_deployed)
    
    if hero_manager.has_signal("all_heroes_dead"):
        hero_manager.connect("all_heroes_dead", _on_all_heroes_dead)

func _on_hero_deployed(hero: HeroBase, position: Vector2):
    """处理英雄部署"""
    # 英雄部署后的逻辑
    pass

func _on_all_heroes_dead():
    """处理所有英雄死亡"""
    # 游戏结束逻辑
    pass
```

### 3. 连接到波次系统

确保英雄系统与波次系统集成：

```gdscript
# 在 WaveManager.gd 或主场景中连接波次信号
func _on_wave_started(wave_count: int, enemy_count: int):
    # 通知英雄系统波次开始
    if has_node("HeroManager"):
        $HeroManager.current_wave = wave_count
    
    # 通知关卡词缀系统
    if has_node("LevelModifierSystem"):
        # 波次开始会自动触发词缀生成
```

### 4. 连接到敌人系统

确保英雄能从敌人消灭中获得经验：

```gd_script
# 在敌人消灭处理中添加
func _on_enemy_destroyed(enemy):
    # 现有代码...
    
    # 通知英雄系统获得经验
    if has_node("HeroManager"):
        $HeroManager._on_enemy_destroyed(1) # 1表示剩余敌人数量
```

### 5. 添加英雄到游戏场景

英雄会自动部署到敌人路径附近的有效位置。确保：

1. 敌人路径节点有 `enemy_path` 组标签
2. 路径节点之间有合适的间距供英雄部署

### 6. 测试集成

运行游戏并测试以下功能：

1. **英雄选择** - 在指定波次应该出现英雄选择界面
2. **英雄部署** - 选择英雄后应该能部署到路径附近
3. **技能使用** - 英雄应该能使用A、B、C技能
4. **天赋系统** - 英雄在5、10、15级应该出现天赋选择
5. **关卡词缀** - 每3波应该出现随机词缀效果
6. **经验系统** - 击败敌人应该获得经验值

## 配置选项

### 英雄系统配置

在 `Data.gd` 中可以配置：

```gdscript
# 英雄数据
heroes = {
    "phantom_spirit": {
        "name": "幻影之灵",
        "base_stats": {...},
        "skills": ["shadow_strike", "flame_armor", "flame_phantom"]
    }
}

# 技能数据
hero_skills = {
    "shadow_strike": {
        "name": "无影拳",
        "type": "A",
        "charge_cost": 20,
        "cooldown": 5.0
    }
}

# 天赋数据
hero_talents = {
    "phantom_spirit": {
        "level_5": [...],
        "level_10": [...],
        "level_15": [...]
    }
}
```

### 波次配置

英雄选择默认配置：
- 每5波提供一次英雄选择
- 5选1的选择机制
- 最多部署5个英雄

### 词缀系统配置

```gdscript
level_modifiers = {
    "positive": [...],  # 正面效果
    "negative": [...],  # 负面效果  
    "neutral": [...]    # 中性效果
}
```

## 故障排除

### 常见问题

1. **英雄选择界面不出现**
   - 检查 HeroManager 是否正确连接到波次系统
   - 确认 Data.heroes 中有足够的英雄数据（至少5个）

2. **英雄无法部署**
   - 检查敌人路径节点是否有正确的组标签
   - 确认部署区域设置正确

3. **技能无法使用**
   - 检查充能系统是否正常工作
   - 确认技能冷却时间设置正确

4. **天赋选择不出现**
   - 检查 HeroTalentSystem 是否正确连接
   - 确认英雄在正确的等级（5、10、15级）

### 调试技巧

1. **启用调试输出**：
   ```gdscript
   # 在 HeroManager.gd 中
   func _ready():
       print("Hero Manager initialized")
   ```

2. **检查信号连接**：
   ```gdscript
   func _on_wave_started(wave_count, enemy_count):
       print("Wave started:", wave_count)
   ```

3. **验证数据加载**：
   ```gdscript
   func _ready():
       print("Available heroes:", Data.heroes.keys())
   ```

## 扩展系统

### 添加新英雄

1. 在 `Data.heroes` 中添加英雄数据
2. 在 `Data.hero_skills` 中添加技能数据
3. 在 `Data.hero_talents` 中添加天赋数据
4. 创建对应的英雄场景文件

### 添加新技能

1. 在 `Data.hero_skills` 中定义技能
2. 在 `HeroBase.gd` 中实现技能逻辑
3. 更新技能UI显示

### 自定义词缀

1. 在 `Data.level_modifiers` 中添加新词缀
2. 在 `LevelModifierSystem.gd` 中实现效果
3. 测试词缀平衡性

## 性能优化

1. **英雄更新优化** - HeroManager 使用定时更新而非每帧更新
2. **范围指示器优化** - 只在需要时显示范围指示器
3. **UI更新优化** - 使用定时更新而非实时更新

## 完成集成

完成以上步骤后，您的塔防游戏将拥有完整的英雄系统，包括：
- 波次基础英雄选择（5选1）
- 完整的技能系统（A/B/C技能）
- 天赋升级系统（5/10/15级）
- 关卡词缀系统（每3波）
- 视觉反馈系统（范围指示器、信息面板）

英雄系统与现有的塔防系统完美集成，为游戏增加了策略深度和可玩性。