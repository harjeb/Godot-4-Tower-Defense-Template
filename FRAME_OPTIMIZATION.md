# 帧率优化方案：每10帧处理持续效果

## 🎯 性能提升分析

### 原方案 vs 优化方案对比

| 处理方式 | CPU占用 | 内存访问 | 适用场景 |
|---------|---------|----------|----------|
| **每帧处理** | 100% | 100% | 实时性要求极高的效果 |
| **每10帧处理** | ~10% | ~10% | 大部分持续效果 |
| **每30帧处理** | ~3% | ~3% | 缓慢变化的光环效果 |

### 🚀 性能提升效果
```gdscript
# 性能提升示例：
# 100个敌人 × 5种效果 × 60FPS = 30,000次/秒 计算
# 优化后：100个敌人 × 5种效果 × 6次/秒 = 3,000次/秒 计算
# 性能提升：90% ✨
```

## 🔧 实现方案

### 1. **分层处理系统**
```gdscript
class_name EffectProcessor

# 不同更新频率的效果分组
var high_frequency_effects: Array = []    # 每帧更新（关键效果）
var medium_frequency_effects: Array = []  # 每10帧更新（常规持续效果）
var low_frequency_effects: Array = []     # 每30帧更新（光环等）

var frame_counter: int = 0

func _process(delta):
    frame_counter += 1
    
    # 每帧：处理关键效果（移动、攻击打断等）
    process_effects(high_frequency_effects)
    
    # 每10帧：处理常规持续效果
    if frame_counter % 10 == 0:
        process_effects(medium_frequency_effects)
    
    # 每30帧：处理光环和缓慢变化效果
    if frame_counter % 30 == 0:
        process_effects(low_frequency_effects)
```

### 2. **效果分类策略**

#### 🔴 高频率（每帧）- 影响游戏手感
```gdscript
HIGH_FREQUENCY_EFFECTS = [
    "冻结",      # 硬控，需要立即生效
    "石化",      # 硬控，影响移动
    "麻痹",      # 打断技能
    "吹飞",      # 位移效果
]
```

#### 🟡 中频率（每10帧）- 持续伤害和状态
```gdscript
MEDIUM_FREQUENCY_EFFECTS = [
    "灼烧",      # 持续伤害
    "腐蚀",      # 持续伤害
    "感电",      # 叠加伤害
    "冰霜",      # 减速效果
    "重压",      # 移速减少
    "生命虹吸",  # 生命吸取
]
```

#### 🟢 低频率（每30帧）- 光环和被动
```gdscript
LOW_FREQUENCY_EFFECTS = [
    "范围光环",   # 光环塔效果
    "被动增益",   # 被动技能
    "环境效果",   # 地面持续效果
]
```

### 3. **具体实现代码**

```gdscript
class_name OptimizedEffectSystem
extends Node

var effect_groups: Dictionary = {
    "high": [],     # 每帧
    "medium": [],   # 每10帧  
    "low": []       # 每30帧
}

var frame_count: int = 0

func _ready():
    # 设置效果分组
    setup_effect_groups()

func _process(delta):
    frame_count += 1
    
    # 高频率效果 - 每帧
    process_effect_group("high", delta)
    
    # 中频率效果 - 每10帧
    if frame_count % 10 == 0:
        process_effect_group("medium", delta * 10)  # 补偿时间差
    
    # 低频率效果 - 每30帧  
    if frame_count % 30 == 0:
        process_effect_group("low", delta * 30)     # 补偿时间差

func process_effect_group(group_name: String, delta_time: float):
    for effect in effect_groups[group_name]:
        if effect.is_valid():
            effect.update(delta_time)

# 智能分组：根据效果类型自动分配频率
func add_effect(effect: StatusEffect, target: Node):
    var group = determine_effect_group(effect.type)
    effect_groups[group].append(effect)

func determine_effect_group(effect_type: String) -> String:
    match effect_type:
        "freeze", "stun", "knockback", "silence":
            return "high"    # 影响操作的效果
        "burn", "poison", "slow", "armor_break":
            return "medium"  # 持续伤害和状态
        "aura", "passive", "environment":
            return "low"     # 光环和环境效果
        _:
            return "medium"  # 默认中频率
```

## 🎮 游戏体验优化

### 1. **时间补偿机制**
```gdscript
# 确保效果持续时间准确
func apply_burn_damage(target: Node, base_damage: float, delta_time: float):
    # delta_time在10帧处理时会是：1/6秒而不是1/60秒
    var actual_damage = base_damage * delta_time  # 自动补偿时间差
    target.take_damage(actual_damage)
```

### 2. **视觉效果保持流畅**
```gdscript
# 视觉效果仍然每帧更新，只有逻辑计算降频
func update_visual_effects():
    for effect in visual_effects:
        effect.update_animation()  # 保持60FPS动画
        
        # 但数值计算可以降频
        if should_update_logic(effect):
            effect.update_logic()
```

### 3. **智能调度**
```gdscript
# 避免所有效果在同一帧集中处理
func distribute_processing():
    var offset = hash(target.get_instance_id()) % 10
    return (frame_count + offset) % 10 == 0
```

## 📊 实际效果测试

### 测试场景：100敌人，每个5种效果
```gdscript
# 原方案：每帧处理
# 计算量：100 × 5 × 60 = 30,000 次/秒

# 优化方案：每10帧处理  
# 计算量：100 × 5 × 6 = 3,000 次/秒
# 性能提升：90%

# 玩家感知：几乎无差别
# - 持续伤害：0.16秒延迟 (人眼难以察觉)
# - 减速效果：视觉平滑，逻辑优化
# - 控制效果：保持每帧处理，手感不变
```

## ✅ 推荐的最终方案

```gdscript
# 效果更新频率分配
EFFECT_FREQUENCIES = {
    # 每帧（60FPS）- 关键交互
    "freeze": 1,
    "stun": 1,
    "knockback": 1,
    
    # 每10帧（6FPS）- 常规持续效果  
    "burn": 10,
    "poison": 10,
    "slow": 10,
    "armor_break": 10,
    
    # 每30帧（2FPS）- 光环和被动
    "aura_effects": 30,
    "passive_regen": 30,
    "environmental": 30,
}
```

这样既保证了游戏手感，又大幅提升了性能！对于塔防这种有大量单位的游戏来说，这是非常必要的优化。