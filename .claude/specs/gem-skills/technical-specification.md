# 火元素宝石技能系统技术规范 (基于CSV准确分析)

## CSV文件准确分析

### 宝石等级定义
CSV第1行定义了火元素宝石的3个等级：
- **火焰宝石 1级** (初级)
- **炽热之心 2级** (中级) 
- **炎狱之魂 3级** (高级)

### DEBUFF定义 (CSV第14-18行)
- **灼烧**: 可叠加，无上限。每秒5点伤害，持续3S
- **炭化**: 完全无法移动和攻击
- **禁锢**: 单位无法移动
- **脆弱**: 受到的伤害增加

### 不同塔类型的火元素宝石技能效果

#### 1. 箭塔 (第2行)
- **1级**: 火箭 - 命中单位受到灼烧DEBUFF
- **2级**: 炽火箭 - 命中单位受到3层灼烧，对风属性伤害增加10%
- **3级**: 炙热火雨 - 单体攻击变为3目标攻击，命中单位受到5层灼烧，对风属性伤害增加30%

#### 2. 捕获塔 (第3行)
- **1级**: 火网 - 范围内所有敌方受到灼热
- **2级**: 焦油火网 - 受到灼热3层，移动速度降低30%，持续4秒
- **3级**: 炭化领域 - 施放焦油火网，同时在目标范围生成炭化地面，敌人在范围内停留超过2.5秒受到"炭化"，持续1.5秒

#### 3. 法师塔 (第4行)
- **1级**: 火球 - 伤害增加20%，命中单位受到灼烧
- **2级**: 天火炼狱 - 伤害增加30%，范围内造成火海持续4秒，所有目标受到3层灼烧
- **3级**: 超新星引爆 - 伤害增加50%，范围内造成火海持续4秒，火海内死亡的敌人爆炸，对周围敌人造成伤害并增加5层"灼热"

#### 4. 感应塔 (第5行)
- **1级**: 火捆 - 范围内的隐身单位受到2层灼烧，受到伤害增加5%
- **2级**: 火牢 - 范围内的隐身单位受到3层灼烧，受到伤害增加10%
- **3级**: 火狱 - 范围内的隐身单位立即受到2S禁锢和5层灼烧，受到伤害增加20%

#### 5. 末日塔 (第6行)
- **1级**: 痛楚 - 伤害间隔降低0.2
- **2级**: 窒息烟尘 - 伤害间隔降低0.25，持续时间增加10S
- **3级**: 热死病 - 持续时间无限，伤害间隔降低0.3

#### 6. 脉冲塔 (第7行)
- **1级**: 火焰脉冲 - 攻击范围内所有单位灼热
- **2级**: 震荡脉冲 - 攻击范围内所有单位3层灼热，打断技能引导，25%几率"禁锢"0.5秒
- **3级**: 地狱火风暴 - 每次脉冲将范围内所有敌人向外推开，70%炭化0.75秒，敌人变得"脆弱"受到伤害增加25%持续3秒

#### 7. 弹射塔 (第8行)
- **1级**: 火弹 - 被弹射目标灼热
- **2级**: 炎爆弹射 - 被弹射目标灼热3层，对单位造成0.1S炭化
- **3级**: 爆燃连锁 - 对单位造成0.5S炭化，弹射到的目标灼热层数越高伤害越高，倍率=1+(层数+25)/100

#### 8. 光环塔 (第9行)
- **1级**: 炽热光环 - 范围内所有塔的攻击速度+3%
- **2级**: 炎热光环 - 范围内所有塔的攻击速度+5%，充能速度加10%
- **3级**: 炙热光环 - 范围内所有塔的攻击速度+10%，充能速度加20%

#### 9. 虚弱塔 (第10行)
- **1级**: 高温 - 防御力降低5%，受到一层灼烧
- **2级**: 中暑 - 防御力降低10%，受到五层灼烧
- **3级**: 热射病 - 防御力降低15%，受到八层灼烧

## 技术实现方案

### 1. 数据结构设计

#### 1.1 扩展宝石数据 (Data.gd)
```godot
const gems := {
    "fire_basic": {
        "name": "火焰宝石 1级",
        "element": "fire",
        "level": 1,
        "tower_skills": {
            "arrow_tower": {
                "name": "火箭",
                "description": "命中单位受到灼烧DEBUFF",
                "effects": ["burn_debuff_1"]
            },
            "capture_tower": {
                "name": "火网", 
                "description": "范围内所有敌方受到灼热",
                "effects": ["burn_area_1"]
            },
            "mage_tower": {
                "name": "火球",
                "description": "伤害增加20%，命中单位受到灼烧", 
                "effects": ["damage_boost_20", "burn_debuff_1"]
            },
            # ... 其他塔类型
        }
    },
    "fire_intermediate": {
        "name": "炽热之心 2级",
        "element": "fire", 
        "level": 2,
        "tower_skills": {
            "arrow_tower": {
                "name": "炽火箭",
                "description": "命中单位受到3层灼烧，对风属性伤害增加10%",
                "effects": ["burn_debuff_3", "wind_damage_boost_10"]
            },
            # ... 其他塔类型
        }
    },
    "fire_advanced": {
        "name": "炎狱之魂 3级",
        "element": "fire",
        "level": 3,
        "tower_skills": {
            "arrow_tower": {
                "name": "炙热火雨", 
                "description": "单体攻击变为3目标攻击，命中单位受到5层灼烧，对风属性伤害增加30%",
                "effects": ["multi_target_3", "burn_debuff_5", "wind_damage_boost_30"]
            },
            # ... 其他塔类型
        }
    }
}
```

#### 1.2 效果定义 (Data.gd)
```godot
const effects := {
    "burn_debuff_1": {
        "type": "debuff",
        "debuff_type": "burn",
        "stacks": 1,
        "damage_per_second": 5.0,
        "duration": 3.0
    },
    "burn_debuff_3": {
        "type": "debuff", 
        "debuff_type": "burn",
        "stacks": 3,
        "damage_per_second": 5.0,
        "duration": 3.0
    },
    "burn_debuff_5": {
        "type": "debuff",
        "debuff_type": "burn", 
        "stacks": 5,
        "damage_per_second": 5.0,
        "duration": 3.0
    },
    "damage_boost_20": {
        "type": "stat_modifier",
        "stat": "damage",
        "operation": "multiply",
        "value": 1.20
    },
    "multi_target_3": {
        "type": "attack_modifier",
        "property": "target_count",
        "value": 3
    },
    "wind_damage_boost_10": {
        "type": "damage_modifier",
        "target_element": "wind",
        "multiplier": 1.10
    }
}
```

### 2. 效果管理系统

#### 2.1 EffectManager.gd
```godot
extends Node
class_name EffectManager

signal effect_applied(target: Node, effect_name: String, effect_data: Dictionary)
signal effect_removed(target: Node, effect_name: String)

var active_effects: Dictionary = {}  # target_id -> [effects]
var effect_timers: Dictionary = {}   # target_id -> Timer

func apply_effect(target: Node, effect_name: String, effect_data: Dictionary, source: Node = null):
    var target_id = target.get_instance_id()
    
    if not active_effects.has(target_id):
        active_effects[target_id] = []
    
    var effect = {
        "name": effect_name,
        "data": effect_data,
        "start_time": Time.get_ticks_msec(),
        "source": source,
        "stacks": effect_data.get("stacks", 1)
    }
    
    # 处理可叠加效果
    if effect_data.get("debuff_type") == "burn":
        _handle_burn_stacking(target, effect)
    else:
        active_effects[target_id].append(effect)
        _apply_single_effect(target, effect)
    
    # 设置持续时间计时器
    if effect_data.has("duration"):
        _setup_effect_timer(target, effect)
    
    effect_applied.emit(target, effect_name, effect_data)

func _handle_burn_stacking(target: Node, new_effect: Dictionary):
    var target_id = target.get_instance_id()
    
    if not active_effects.has(target_id):
        active_effects[target_id] = []
    
    # 查找现存的灼烧效果
    var existing_burn = null
    for effect in active_effects[target_id]:
        if effect.data.get("debuff_type") == "burn":
            existing_burn = effect
            break
    
    if existing_burn:
        # 叠加灼烧层数
        existing_burn.stacks += new_effect.stacks
        existing_burn.start_time = Time.get_ticks_msec()  # 刷新持续时间
    else:
        # 添加新的灼烧效果
        active_effects[target_id].append(new_effect)
        _apply_single_effect(target, new_effect)

func _apply_single_effect(target: Node, effect: Dictionary):
    var effect_data = effect.data
    
    match effect_data.type:
        "debuff":
            _apply_debuff(target, effect)
        "stat_modifier":
            _apply_stat_modifier(target, effect)
        "attack_modifier":
            _apply_attack_modifier(target, effect)
        "damage_modifier":
            _apply_damage_modifier(target, effect)

func _apply_debuff(target: Node, effect: Dictionary):
    var debuff_type = effect.data.get("debuff_type")
    
    match debuff_type:
        "burn":
            if target.has_method("apply_burn"):
                target.apply_burn(effect.stacks, effect.data.damage_per_second)
        "炭化":
            if target.has_method("apply_carbonization"):
                target.apply_carbonization()
        "禁锢":
            if target.has_method("apply_imprison"):
                target.apply_imprison()
        "脆弱":
            if target.has_method("apply_vulnerability"):
                target.apply_vulnerability()

func update_effects(delta: float):
    var current_time = Time.get_ticks_msec()
    var to_remove = []
    
    for target_id in active_effects:
        var effects = active_effects[target_id]
        var target = instance_from_id(target_id)
        
        if not target or not is_instance_valid(target):
            to_remove.append(target_id)
            continue
            
        for i in range(effects.size() - 1, -1, -1):
            var effect = effects[i]
            var elapsed = (current_time - effect.start_time) / 1000.0
            
            # 处理持续伤害效果
            if effect.data.has("damage_per_second"):
                if fmod(elapsed, 1.0) < delta:  # 每秒造成伤害
                    if target.has_method("take_damage"):
                        target.take_damage(effect.data.damage_per_second * effect.stacks)
```

### 3. 塔系统集成

#### 3.1 修改塔基类支持宝石技能
```godot
# 在turret_base.gd中添加
@export var equipped_gem: String = ""

func equip_gem(gem_id: String):
    equipped_gem = gem_id
    _apply_gem_skills()

func _apply_gem_skills():
    if equipped_gem == "":
        return
    
    var gem_data = Data.gems.get(equipped_gem, {})
    if gem_data.is_empty():
        return
    
    var tower_type = _get_tower_type()
    if tower_type == "":
        return
    
    var skills = gem_data.get("tower_skills", {}).get(tower_type, {})
    if skills.is_empty():
        return
    
    # 应用技能效果
    for effect_name in skills.effects:
        var effect_data = Data.effects.get(effect_name, {})
        if not effect_data.is_empty():
            _apply_tower_effect(effect_data)

func _get_tower_type() -> String:
    # 根据塔的类型返回对应的key
    # 例如: "arrow_tower", "mage_tower" 等
    return ""

func _apply_tower_effect(effect_data: Dictionary):
    match effect_data.type:
        "stat_modifier":
            _apply_stat_modifier(effect_data)
        "attack_modifier":
            _apply_attack_modifier(effect_data)
```

### 4. 子弹系统集成

#### 4.1 修改子弹支持效果传递
```godot
# 在bulletBase.gd中添加
var gem_effects: Array = []

func _on_body_entered(body: Node):
    if body.is_in_group("enemy"):
        # 造成基础伤害
        if body.has_method("take_damage"):
            body.take_damage(damage)
        
        # 应用宝石效果
        for effect_name in gem_effects:
            var effect_data = Data.effects.get(effect_name, {})
            if not effect_data.is_empty():
                var effect_manager = get_effect_manager()
                if effect_manager:
                    effect_manager.apply_effect(body, effect_name, effect_data, self)
```

## 实施计划

### 第一阶段: 核心系统 (1-2天)
1. 创建EffectManager.gd效果管理系统
2. 扩展Data.gd添加火元素宝石数据和效果定义
3. 实现基础的DEBUFF效果系统

### 第二阶段: 塔系统集成 (1-2天)  
1. 修改turret_base.gd支持宝石装备和技能应用
2. 为每种塔类型实现对应的火元素宝石技能
3. 测试塔与宝石的集成

### 第三阶段: 子弹和效果系统 (1天)
1. 修改bulletBase.gd支持效果传递
2. 实现多目标攻击机制
3. 完善效果的应用和移除逻辑

### 第四阶段: UI更新 (0.5天)
1. 更新塔详情UI显示宝石技能
2. 更新宝石拖拽UI显示技能描述
3. 测试UI显示效果

### 第五阶段: 测试和优化 (0.5天)
1. 全面测试各种塔类型的火元素宝石技能
2. 性能优化和bug修复
3. 确保与现有系统的兼容性

## 成功标准

1. **准确性**: 严格按照CSV文件定义实现所有技能效果
2. **完整性**: 实现9种塔类型的火元素宝石技能
3. **集成性**: 与现有塔防系统无缝集成
4. **稳定性**: 效果系统运行稳定，无内存泄漏
5. **可扩展性**: 代码结构便于后续添加其他元素宝石

## 注意事项

- 宝石只能装备在塔上，不支持其他装备方式
- 严格按照CSV文件中的技能描述实现，不添加额外功能
- 确保DEBUFF系统的正确叠加和持续时间管理
- 注意不同塔类型的特殊机制实现