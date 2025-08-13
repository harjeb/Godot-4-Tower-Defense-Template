# 英雄系统技术规格说明书

## 问题陈述

### 业务问题
- **当前状态**: 游戏缺少英雄单位系统，仅有常规塔防机制
- **核心需求**: 实现可放置在路径中的强力英雄单位，具备阻挡、技能、升级等完整功能
- **预期结果**: 完整的英雄系统替代近战塔概念，提供深度策略玩法

### 技术挑战
- **路径阻挡**: 英雄需要放置在敌人路径中并具有碰撞体积
- **技能系统**: A/B/C三类技能的充能机制和优先级释放
- **系统整合**: 与现有宝石效果、波次、塔防系统的无缝集成
- **性能考虑**: 多英雄单位的状态管理和实时更新优化

## 解决方案概述

### 核心架构
- **继承体系**: HeroBase 继承自 Node2D，而非塔基类（避免冲突）
- **组件化设计**: 分离技能、天赋、UI、管理等独立模块
- **事件驱动**: 使用信号系统实现松耦合的组件间通信
- **数据驱动**: 英雄数据、技能配置、天赋树均使用数据文件配置

### 实现策略
- **分阶段开发**: 先实现核心英雄类，再添加选择系统，最后完善UI和特效
- **向后兼容**: 保持现有塔防系统不受影响，英雄作为新增系统
- **性能优化**: 使用对象池、缓存系统和分层更新机制

## 技术实现

### 1. 核心英雄系统

#### HeroBase 类结构
```gdscript
# Scenes/heroes/HeroBase.gd (已存在，需完善)
class_name HeroBase extends Node2D

# 核心属性
@export var hero_type: String = ""
@export var hero_name: String = ""
@export var element: String = "neutral"

# 状态系统
var current_level: int = 1
var experience_points: int = 0
var is_alive: bool = true
var is_respawning: bool = false

# 属性系统
var base_stats: Dictionary = {}
var current_stats: Dictionary = {}
var stat_modifiers: Dictionary = {}

# 技能系统
var skills: Array[HeroSkill] = []
var current_charge: float = 0.0
var max_charge: int = 100
var charge_generation_rate: float = 2.0

# 天赋系统
var talent_selections: Dictionary = {}
var pending_talent_selection: bool = false

# 战斗系统
var attack_target: Node = null
var attack_timer: float = 0.0
var last_attack_time: float = 0.0

# 复活系统
var respawn_timer: float = 0.0
var respawn_duration: float = 10.0

# 系统集成
var gem_effect_system: GemEffectSystem
var da_bonus: float = 0.0
var ta_bonus: float = 0.0
```

#### 必需的节点结构
```
HeroBase (Node2D)
├── Sprite2D (英雄精灵)
├── CollisionShape2D (碰撞体积)
├── Area2D (攻击范围检测)
│   └── CollisionShape2D
├── UI (UI容器)
│   ├── HealthBar (ProgressBar)
│   ├── ChargeBar (ProgressBar)
│   ├── LevelLabel (Label)
│   ├── CastingIndicator (Control)
│   └── RespawnIndicator (Control)
└── AudioStreamPlayer2D (音效)
```

#### 核心方法实现
```gdscript
# 生命循环方法
func _ready() -> void:
    setup_hero_data()
    setup_gem_effect_system()
    setup_ui_components()
    setup_collision_system()
    connect_to_global_signals()

func _process(delta: float) -> void:
    if is_respawning:
        process_respawn(delta)
        return
    
    if not is_alive:
        return
    
    process_charge_generation(delta)
    process_skill_system(delta)
    process_combat_targeting(delta)
    update_ui_components()

# 战斗系统
func process_combat_targeting(delta: float) -> void:
    attack_timer += delta
    
    if not attack_target or not is_instance_valid(attack_target):
        find_attack_target()
    
    if attack_target and attack_timer >= get_attack_cooldown():
        perform_basic_attack()
        attack_timer = 0.0

func find_attack_target() -> void:
    if not gem_effect_system:
        return
    
    var attack_range = current_stats.get("attack_range", 150.0)
    var nearest_enemy = gem_effect_system.get_nearest_enemy(global_position, attack_range)
    
    if nearest_enemy and is_instance_valid(nearest_enemy):
        attack_target = nearest_enemy

func perform_basic_attack() -> void:
    if not attack_target or not is_instance_valid(attack_target):
        return
    
    var damage = current_stats.get("damage", 0)
    damage *= (1.0 + da_bonus + ta_bonus)
    
    if attack_target.has_method("take_damage"):
        attack_target.take_damage(damage, element)
        last_attack_time = Time.get_time_dict_from_system()["unix"]

# 复活系统
func die() -> void:
    if not is_alive:
        return
    
    is_alive = false
    is_respawning = true
    respawn_timer = respawn_duration
    
    # 清理状态
    current_casting_skill = null
    attack_target = null
    skill_queue.clear()
    
    # 视觉反馈
    if sprite:
        sprite.modulate.a = 0.5
    
    if respawn_indicator:
        respawn_indicator.visible = true
    
    # 清理效果
    if gem_effect_system:
        gem_effect_system.clear_all_effects(self)
    
    hero_died.emit(self)

func process_respawn(delta: float) -> void:
    respawn_timer -= delta
    
    if respawn_indicator:
        var time_left = ceil(respawn_timer)
        respawn_indicator.get_child(0).text = "Respawn: " + str(time_left) + "s"
    
    if respawn_timer <= 0:
        respawn()

func respawn() -> void:
    is_alive = true
    is_respawning = false
    respawn_timer = 0.0
    
    # 恢复生命值
    var max_hp = current_stats.get("max_hp", 100)
    if health_bar:
        health_bar.value = max_hp
    
    # 恢复视觉
    if sprite:
        sprite.modulate.a = 1.0
    
    if respawn_indicator:
        respawn_indicator.visible = false
    
    hero_respawned.emit(self)

# 碰撞系统
func setup_collision_system() -> void:
    # 设置碰撞体积用于阻挡敌人
    var collision_shape = CollisionShape2D.new()
    var shape = CircleShape2D.new()
    shape.radius = 30.0
    collision_shape.shape = shape
    add_child(collision_shape)
    
    # 设置碰撞层
    collision_layer = 1 << 2  # 英雄层
    collision_mask = 1 << 1   # 敌人层

# 经验系统
func gain_experience(amount: int) -> void:
    experience_points += amount
    experience_gained.emit(self, amount, experience_points)
    check_level_up()

func check_level_up() -> void:
    if current_level >= experience_required.size():
        return
    
    var required_exp = experience_required[current_level]
    if experience_points >= required_exp:
        level_up()

func level_up() -> void:
    current_level += 1
    apply_level_stat_bonuses()
    
    if should_offer_talent_selection():
        pending_talent_selection = true
        available_talents = get_talent_options_for_level()
    
    if level_label:
        level_label.text = "Lv." + str(current_level)
    
    hero_leveled_up.emit(self, current_level)
```

### 2. 英雄技能系统

#### HeroSkill 类结构
```gdscript
# Scenes/heroes/HeroSkill.gd (需要创建)
class_name HeroSkill extends Resource

# 技能基础属性
@export var skill_id: String = ""
@export var skill_name: String = ""
@export var skill_type: String = "A"  # A/B/C
@export var skill_description: String = ""
@export var element: String = "neutral"

# 技能机制
@export var charge_cost: int = 20
@export var cooldown: float = 5.0
@export var cast_time: float = 0.0
@export var range: float = 150.0

# 技能数据
var skill_data: Dictionary = {}
var cooldown_remaining: float = 0.0
var is_on_cooldown: bool = false

# 优先级系统 (C > B > A)
func get_skill_priority() -> int:
    match skill_type:
        "C": return 3
        "B": return 2
        "A": return 1
        _: return 0

func can_cast(hero: HeroBase) -> bool:
    if is_on_cooldown:
        return false
    if hero.current_charge < charge_cost:
        return false
    if not hero.is_alive:
        return false
    return true

func start_cooldown() -> void:
    is_on_cooldown = true
    cooldown_remaining = cooldown

func update_cooldown(delta: float) -> void:
    if is_on_cooldown:
        cooldown_remaining -= delta
        if cooldown_remaining <= 0:
            is_on_cooldown = false
            cooldown_remaining = 0.0

func get_area_of_effect() -> float:
    return skill_data.get("effect_radius", range)

func initialize_from_data(skill_id: String, skill_data_dict: Dictionary) -> void:
    skill_id = skill_id
    skill_data = skill_data_dict.duplicate(true)
    
    # 从数据中加载属性
    skill_name = skill_data.get("name", skill_id)
    skill_type = skill_data.get("type", "A")
    skill_description = skill_data.get("description", "")
    element = skill_data.get("element", "neutral")
    charge_cost = skill_data.get("charge_cost", 20)
    cooldown = skill_data.get("cooldown", 5.0)
    cast_time = skill_data.get("cast_time", 0.0)
    range = skill_data.get("range", 150.0)
```

#### 技能释放系统
```gdscript
# 在 HeroBase 中添加的技能释放方法
func process_skill_system(delta: float) -> void:
    # 更新技能冷却
    for skill in skills:
        skill.update_cooldown(delta)
    
    # 处理当前施法技能
    if current_casting_skill:
        skill_cast_timer -= delta
        if skill_cast_timer <= 0:
            finish_skill_cast()
    
    # 处理技能队列
    if skill_queue.size() > 0 and not current_casting_skill:
        var next_skill_id = skill_queue[0]
        skill_queue.remove_at(0)
        
        var skill = get_skill_by_id(next_skill_id)
        if skill and skill.can_cast(self):
            start_skill_cast(skill)

func attempt_skill_cast() -> void:
    if current_casting_skill:
        return
    
    var available_skills = skills.filter(func(s): return s.can_cast(self))
    if available_skills.is_empty():
        return
    
    # 技能已按优先级排序
    var best_skill = available_skills[0]
    start_skill_cast(best_skill)

func start_skill_cast(skill: HeroSkill) -> void:
    if not skill or not skill.can_cast(self):
        return
    
    # 消耗充能
    current_charge -= skill.charge_cost
    current_charge = max(0, current_charge)
    
    # 设置施法状态
    current_casting_skill = skill
    skill_cast_timer = skill.cast_time
    
    # 视觉反馈
    if casting_indicator:
        casting_indicator.visible = true
        casting_indicator.get_child(0).text = skill.skill_name
    
    # 开始冷却
    skill.start_cooldown()
    
    # 立即执行或等待施法时间
    if skill_cast_timer <= 0:
        finish_skill_cast()
    
    skill_cast.emit(self, skill)

func finish_skill_cast() -> void:
    if not current_casting_skill:
        return
    
    var skill = current_casting_skill
    
    # 执行技能效果
    execute_skill_effects(skill)
    
    # 清理施法状态
    current_casting_skill = null
    skill_cast_timer = 0.0
    
    if casting_indicator:
        casting_indicator.visible = false

func execute_skill_effects(skill: HeroSkill) -> void:
    var target_position = global_position
    
    match skill.skill_id:
        "shadow_strike":
            execute_shadow_strike(skill, target_position)
        "flame_armor":
            execute_flame_armor(skill)
        "flame_phantom":
            execute_flame_phantom(skill)
        _:
            push_warning("Unknown skill: " + skill.skill_id)

# 具体技能实现
func execute_shadow_strike(skill: HeroSkill, target_pos: Vector2) -> void:
    var skill_data = Data.hero_skills.get("shadow_strike", {})
    var damage_base = skill_data.get("damage_base", 70)
    var damage_scaling = skill_data.get("damage_scaling", 1.0)
    var effect_radius = skill_data.get("effect_radius", 150.0)
    var attack_count = skill_data.get("attack_count", 5)
    var attack_interval = skill_data.get("attack_interval", 0.3)
    var invulnerable_duration = skill_data.get("invulnerable_duration", 0.3)
    
    # 应用无敌
    if gem_effect_system:
        gem_effect_system.apply_effect(self, "invulnerable", invulnerable_duration)
    
    # 计算总伤害
    var total_damage = damage_base + (current_stats.get("damage", 0) * damage_scaling)
    
    # 执行多次攻击
    for i in attack_count:
        call_deferred("perform_shadow_strike_attack", target_pos, effect_radius, total_damage / attack_count)
        await get_tree().create_timer(attack_interval).timeout

func perform_shadow_strike_attack(center: Vector2, radius: float, damage: float) -> void:
    if not gem_effect_system:
        return
    
    var enemies = gem_effect_system.get_enemies_in_area(center, radius)
    for enemy in enemies:
        if enemy.has_method("take_damage"):
            enemy.take_damage(damage, element)
```

### 3. 英雄管理系统

#### HeroManager 类结构
```gdscript
# Scenes/systems/HeroManager.gd (已存在，需完善)
class_name HeroManager extends Node

# 管理状态
var deployed_heroes: Array[HeroBase] = []
var hero_selection_queue: Array[String] = []
var max_deployed_heroes: int = 5
var current_wave: int = 0

# 选择系统
var selection_cooldown_waves: int = 5
var last_selection_wave: int = 0
var pending_hero_selection: bool = false
var available_hero_pool: Array[String] = []

# 部署系统
var deployment_zones: Array[Dictionary] = []
var deployment_range_from_path: float = 50.0

# 性能优化
var heroes_update_timer: float = 0.0
var heroes_update_interval: float = 0.1

# 波次集成
var wave_manager: WaveManager

func _ready() -> void:
    setup_system_connections()
    setup_hero_pool()
    setup_deployment_zones()
    connect_to_wave_system()
    add_to_group("hero_systems")

func setup_hero_pool() -> void:
    if not Data.heroes:
        push_error("Hero data not available in Data.gd")
        return
    
    available_hero_pool = Data.heroes.keys()
    
    if available_hero_pool.size() < 5:
        push_warning("Less than 5 heroes available, selection system may not work properly")

func setup_deployment_zones() -> void:
    var tree = get_tree()
    if not tree or not tree.current_scene:
        return
    
    var path_nodes = tree.current_scene.get_tree().get_nodes_in_group("enemy_path")
    deployment_zones.clear()
    
    for path_node in path_nodes:
        var zone = {
            "center": path_node.global_position,
            "radius": deployment_range_from_path,
            "occupied": false,
            "hero": null
        }
        deployment_zones.append(zone)

func offer_hero_selection() -> void:
    if available_hero_pool.size() < 5:
        push_warning("Not enough heroes for selection")
        return
    
    var selection_options = get_random_heroes_for_selection(5)
    hero_selection_queue = selection_options
    pending_hero_selection = true
    
    hero_selection_available.emit(selection_options)

func get_random_heroes_for_selection(count: int) -> Array[String]:
    var available = available_hero_pool.duplicate()
    var selected: Array[String] = []
    
    # 移除已部署的英雄类型避免重复
    for hero in deployed_heroes:
        if is_instance_valid(hero) and hero.hero_type in available:
            available.erase(hero.hero_type)
    
    # 随机选择英雄
    for i in count:
        if available.is_empty():
            break
        
        var random_index = randi() % available.size()
        var hero_type = available[random_index]
        selected.append(hero_type)
        available.remove_at(random_index)
    
    return selected

func deploy_hero(hero_type: String, position: Vector2) -> HeroBase:
    # 验证部署
    if not can_deploy_hero_at_position(position):
        push_warning("Cannot deploy hero at position: " + str(position))
        return null
    
    if deployed_heroes.size() >= max_deployed_heroes:
        push_warning("Maximum heroes deployed")
        return null
    
    if not Data.heroes.has(hero_type):
        push_error("Hero type not found: " + hero_type)
        return null
    
    # 创建英雄实例
    var hero = create_hero_instance(hero_type)
    if not hero:
        return null
    
    # 设置位置并部署
    hero.global_position = position
    
    # 添加到场景
    var tree = get_tree()
    if tree and tree.current_scene:
        tree.current_scene.add_child(hero)
    
    # 注册英雄
    deployed_heroes.append(hero)
    connect_hero_signals(hero)
    mark_deployment_zone_occupied(position, hero)
    
    hero_deployed.emit(hero, position)
    return hero

func create_hero_instance(hero_type: String) -> HeroBase:
    var hero_data = Data.heroes[hero_type]
    var scene_path = hero_data.get("scene", "")
    
    if scene_path.is_empty():
        scene_path = "res://Scenes/heroes/HeroBase.tscn"
    
    var hero_scene = Data.load_resource_safe(scene_path, "PackedScene")
    if not hero_scene:
        push_error("Could not load hero scene: " + scene_path)
        return null
    
    var hero = hero_scene.instantiate() as HeroBase
    if not hero:
        push_error("Hero scene does not contain HeroBase")
        return null
    
    hero.hero_type = hero_type
    hero.name = hero_type + "_" + str(deployed_heroes.size() + 1)
    
    return hero

func can_deploy_hero_at_position(position: Vector2) -> bool:
    # 检查是否在路径附近
    var near_path = false
    for zone in deployment_zones:
        if position.distance_to(zone.center) <= zone.radius:
            near_path = true
            break
    
    if not near_path:
        return false
    
    # 检查是否与其他英雄冲突
    for hero in deployed_heroes:
        if is_instance_valid(hero) and hero.global_position.distance_to(position) < 60.0:
            return false
    
    return true

func check_wave_based_hero_selection() -> void:
    if pending_hero_selection:
        return
    
    if current_wave >= next_selection_wave and current_wave - last_selection_wave >= selection_cooldown_waves:
        offer_hero_selection()
```

### 4. 英雄选择UI系统

#### HeroSelectionUI 类结构
```gdscript
# Scenes/ui/heroSystem/HeroSelectionUI.gd (已存在，需完善)
class_name HeroSelectionUI extends Control

# UI引用
@onready var hero_selection_panel: Panel = $HeroSelectionPanel
@onready var hero_grid_container: GridContainer = $HeroSelectionPanel/VBoxContainer/HeroGridContainer
@onready var selection_title: Label = $HeroSelectionPanel/VBoxContainer/SelectionTitle
@onready var selection_description: Label = $HeroSelectionPanel/VBoxContainer/SelectionDescription
@onready var cancel_button: Button = $HeroSelectionPanel/VBoxContainer/ButtonContainer/CancelButton
@onready var confirm_button: Button = $HeroSelectionPanel/VBoxContainer/ButtonContainer/ConfirmButton

@onready var talent_selection_panel: Panel = $TalentSelectionPanel
@onready var talent_container: VBoxContainer = $TalentSelectionPanel/VBoxContainer/TalentContainer
@onready var talent_title: Label = $TalentSelectionPanel/VBoxContainer/TalentTitle
@onready var talent_hero_info: Label = $TalentSelectionPanel/VBoxContainer/HeroInfo

# 选择状态
var current_selection_type: String = ""
var available_heroes: Array[String] = []
var selected_hero_type: String = ""
var current_hero_for_talent: HeroBase
var available_talents: Array[Dictionary] = []
var selected_talent_id: String = ""

func show_hero_selection(hero_types: Array[String]) -> void:
    if hero_types.size() < 2:
        push_warning("Not enough heroes for selection")
        return
    
    available_heroes = hero_types.duplicate()
    selected_hero_type = ""
    current_selection_type = "hero"
    
    setup_hero_selection_ui()
    
    if hero_selection_panel:
        hero_selection_panel.visible = true
    
    create_hero_option_buttons()

func create_hero_option_buttons() -> void:
    if not hero_grid_container:
        return
    
    clear_container_children(hero_grid_container)
    
    for hero_type in available_heroes:
        var hero_button = create_hero_option_button(hero_type)
        if hero_button:
            hero_grid_container.add_child(hero_button)

func create_hero_option_button(hero_type: String) -> Control:
    if not Data.heroes.has(hero_type):
        push_error("Hero type not found: " + hero_type)
        return null
    
    var hero_data = Data.heroes[hero_type]
    
    # 创建按钮容器
    var button_container = VBoxContainer.new()
    button_container.custom_minimum_size = Vector2(200, 250)
    
    # 创建英雄按钮
    var hero_button = Button.new()
    hero_button.text = hero_data.get("name", hero_type)
    hero_button.custom_minimum_size = Vector2(180, 40)
    hero_button.pressed.connect(func(): _on_hero_option_selected(hero_type))
    
    # 创建英雄预览
    var hero_preview = TextureRect.new()
    hero_preview.custom_minimum_size = Vector2(150, 150)
    hero_preview.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
    hero_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    
    var sprite_path = hero_data.get("sprite", "")
    if not sprite_path.is_empty():
        var texture = Data.load_resource_safe(sprite_path, "Texture2D")
        if texture:
            hero_preview.texture = texture
    
    # 创建英雄描述
    var hero_description = Label.new()
    hero_description.text = hero_data.get("description", "")
    hero_description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    hero_description.custom_minimum_size = Vector2(180, 60)
    
    # 添加到容器
    button_container.add_child(hero_preview)
    button_container.add_child(hero_button)
    button_container.add_child(hero_description)
    
    return button_container

func show_talent_selection(hero: HeroBase, talents: Array[Dictionary]) -> void:
    if not hero or talents.size() < 2:
        push_warning("Invalid talent selection parameters")
        return
    
    current_hero_for_talent = hero
    available_talents = talents.duplicate(true)
    selected_talent_id = ""
    current_selection_type = "talent"
    
    setup_talent_selection_ui()
    
    if talent_selection_panel:
        talent_selection_panel.visible = true
    
    create_talent_option_buttons()
```

### 5. 英雄信息面板

#### HeroInfoPanel 类结构
```gdscript
# Scenes/ui/heroSystem/HeroInfoPanel.gd (已存在，需完善)
class_name HeroInfoPanel extends Control

# UI引用
@onready var main_panel: Panel = $MainPanel
@onready var hero_portrait: TextureRect = $MainPanel/VBoxContainer/HeaderContainer/HeroPortrait
@onready var hero_name_label: Label = $MainPanel/VBoxContainer/HeaderContainer/InfoContainer/HeroName
@onready var hero_level_label: Label = $MainPanel/VBoxContainer/HeaderContainer/InfoContainer/HeroLevel
@onready var hero_element_label: Label = $MainPanel/VBoxContainer/HeaderContainer/InfoContainer/HeroElement

@onready var stats_container: VBoxContainer = $MainPanel/VBoxContainer/StatsContainer
@onready var health_bar: ProgressBar = $MainPanel/VBoxContainer/StatsContainer/HealthContainer/HealthBar
@onready var charge_bar: ProgressBar = $MainPanel/VBoxContainer/StatsContainer/ChargeContainer/ChargeBar
@onready var experience_bar: ProgressBar = $MainPanel/VBoxContainer/StatsContainer/ExperienceContainer/ExperienceBar

@onready var skills_container: VBoxContainer = $MainPanel/VBoxContainer/SkillsContainer
@onready var talents_container: VBoxContainer = $MainPanel/VBoxContainer/TalentsContainer
@onready var effects_container: VBoxContainer = $MainPanel/VBoxContainer/EffectsContainer

# 显示状态
var current_hero: HeroBase
var auto_update: bool = true
var update_timer: float = 0.0
var update_interval: float = 0.1

func display_hero_info(hero: HeroBase) -> void:
    if not hero or not is_instance_valid(hero):
        hide_panel()
        return
    
    current_hero = hero
    
    update_hero_header()
    update_hero_stats()
    update_detailed_stats()
    update_skills_display()
    update_talents_display()
    update_effects_display()
    
    show_panel()

func update_hero_display() -> void:
    if not current_hero or not is_instance_valid(current_hero):
        hide_panel()
        return
    
    update_hero_stats()
    update_skills_display()
    update_effects_display()

func update_hero_stats() -> void:
    if not current_hero:
        return
    
    # 更新生命值
    if health_bar:
        var max_hp = current_hero.current_stats.get("max_hp", 100)
        var current_hp = max_hp
        
        if current_hero.health_bar:
            current_hp = current_hero.health_bar.value
        
        health_bar.max_value = max_hp
        health_bar.value = current_hp
        
        # 颜色编码
        var health_ratio = current_hp / max_hp
        if health_ratio > 0.6:
            health_bar.modulate = Color.GREEN
        elif health_ratio > 0.3:
            health_bar.modulate = Color.YELLOW
        else:
            health_bar.modulate = Color.RED
    
    # 更新充能
    if charge_bar:
        charge_bar.max_value = current_hero.max_charge
        charge_bar.value = current_hero.current_charge
    
    # 更新经验
    if experience_bar:
        var current_exp = current_hero.experience_points
        var next_level_exp = 0
        
        if current_hero.current_level < current_hero.experience_required.size():
            next_level_exp = current_hero.experience_required[current_hero.current_level]
        
        experience_bar.max_value = next_level_exp
        experience_bar.value = current_exp

func update_skills_display() -> void:
    if not skills_container or not current_hero:
        return
    
    clear_container_children(skills_container)
    
    # 添加技能标题
    var skills_header = Label.new()
    skills_header.text = "技能："
    skills_container.add_child(skills_header)
    
    # 添加每个技能
    for skill in current_hero.skills:
        create_skill_display(skill)

func create_skill_display(skill: HeroSkill) -> void:
    if not skill or not skills_container:
        return
    
    var skill_container = HBoxContainer.new()
    skill_container.custom_minimum_size = Vector2(0, 40)
    
    # 技能信息
    var skill_info = VBoxContainer.new()
    
    var skill_name_label = Label.new()
    skill_name_label.text = "%s (%s)" % [skill.skill_name, skill.skill_type]
    skill_info.add_child(skill_name_label)
    
    # 技能状态
    var skill_status = Label.new()
    if skill.is_on_cooldown:
        skill_status.text = "冷却中: %.1fs" % skill.cooldown_remaining
        skill_status.modulate = Color.RED
    else:
        var can_cast = skill.can_cast(current_hero) if current_hero else false
        skill_status.text = "就绪" if can_cast else "充能不足"
        skill_status.modulate = Color.GREEN if can_cast else Color.YELLOW
    
    skill_info.add_child(skill_status)
    skill_container.add_child(skill_info)
    
    # 技能按钮
    if skill.can_cast(current_hero) and current_hero:
        var skill_button = Button.new()
        skill_button.text = "释放"
        skill_button.custom_minimum_size = Vector2(60, 35)
        skill_button.pressed.connect(func(): _on_skill_button_pressed(skill.skill_id))
        skill_container.add_child(skill_button)
    
    skills_container.add_child(skill_container)
```

### 6. 英雄范围指示器

#### HeroRangeIndicator 类结构
```gdscript
# Scenes/ui/heroSystem/HeroRangeIndicator.gd (需要创建)
class_name HeroRangeIndicator extends Node2D

# 视觉组件
@onready var attack_range_circle: Line2D = $AttackRangeCircle
@onready var aura_range_circle: Line2D = $AuraRangeCircle
@onready var deployment_zones_container: Node2D = $DeploymentZones
@onready var valid_position_indicator: Sprite2D = $ValidPositionIndicator
@onready var invalid_position_indicator: Sprite2D = $InvalidPositionIndicator

# 状态
var current_hero_type: String = ""
var is_deployment_mode: bool = false
var show_attack_range: bool = false
var show_aura_range: bool = false

func _ready() -> void:
    hide_all_indicators()
    setup_range_circles()

func setup_range_circles() -> void:
    # 设置攻击范围圆圈
    if attack_range_circle:
        attack_range_circle.width = 2.0
        attack_range_circle.default_color = Color.YELLOW
        attack_range_circle.modulate.a = 0.5
    
    # 设置光环范围圆圈
    if aura_range_circle:
        aura_range_circle.width = 2.0
        aura_range_circle.default_color = Color.ORANGE
        aura_range_circle.modulate.a = 0.3

func show_deployment_zones(hero_type: String) -> void:
    current_hero_type = hero_type
    is_deployment_mode = true
    
    # 显示部署区域
    update_deployment_zones()
    
    # 显示有效/无效位置指示器
    valid_position_indicator.visible = true
    invalid_position_indicator.visible = true

func hide_deployment_zones() -> void:
    is_deployment_mode = false
    valid_position_indicator.visible = false
    invalid_position_indicator.visible = false
    
    # 清理部署区域显示
    for child in deployment_zones_container.get_children():
        child.queue_free()

func update_deployment_zones() -> void:
    if not is_deployment_mode:
        return
    
    # 获取英雄管理器
    var hero_manager = Globals.get_hero_manager()
    if not hero_manager:
        return
    
    var zones = hero_manager.get_deployment_zones_data()
    
    # 清理现有显示
    for child in deployment_zones_container.get_children():
        child.queue_free()
    
    # 创建部署区域指示器
    for zone in zones:
        var zone_indicator = create_deployment_zone_indicator(zone)
        deployment_zones_container.add_child(zone_indicator)

func create_deployment_zone_indicator(zone: Dictionary) -> Node2D:
    var indicator = Node2D.new()
    indicator.position = zone.center
    
    # 创建范围圆圈
    var range_circle = Line2D.new()
    range_circle.width = 2.0
    
    if zone.occupied:
        range_circle.default_color = Color.RED
        range_circle.modulate.a = 0.3
    else:
        range_circle.default_color = Color.GREEN
        range_circle.modulate.a = 0.2
    
    # 创建圆圈点
    var points = []
    var segments = 32
    for i in segments:
        var angle = (i / float(segments)) * 2 * PI
        var x = cos(angle) * zone.radius
        var y = sin(angle) * zone.radius
        points.append(Vector2(x, y))
    
    points.append(points[0])  # 闭合圆圈
    range_circle.points = points
    
    indicator.add_child(range_circle)
    return indicator

func update_position_validity(mouse_pos: Vector2) -> void:
    if not is_deployment_mode:
        return
    
    # 检查位置是否有效
    var is_valid = can_deploy_at_position(mouse_pos)
    
    # 更新指示器位置和状态
    valid_position_indicator.global_position = mouse_pos
    invalid_position_indicator.global_position = mouse_pos
    
    valid_position_indicator.visible = is_valid
    invalid_position_indicator.visible = not is_valid

func can_deploy_at_position(position: Vector2) -> bool:
    var hero_manager = Globals.get_hero_manager()
    if not hero_manager:
        return false
    
    return hero_manager.can_deploy_hero_at_position(position)

func show_hero_ranges(hero: HeroBase) -> void:
    if not hero or not is_instance_valid(hero):
        return
    
    show_attack_range = true
    show_aura_range = true
    
    # 更新范围圆圈
    update_attack_range(hero)
    update_aura_range(hero)
    
    # 显示圆圈
    attack_range_circle.visible = true
    aura_range_circle.visible = true

func hide_hero_ranges() -> void:
    show_attack_range = false
    show_aura_range = false
    
    attack_range_circle.visible = false
    aura_range_circle.visible = false

func update_attack_range(hero: HeroBase) -> void:
    if not attack_range_circle or not hero:
        return
    
    var attack_range = hero.current_stats.get("attack_range", 150.0)
    create_range_circle(attack_range_circle, attack_range)

func update_aura_range(hero: HeroBase) -> void:
    if not aura_range_circle or not hero:
        return
    
    # 检查英雄是否有光环技能
    var aura_range = 0.0
    
    for skill in hero.skills:
        if skill.skill_data.has("aura_radius"):
            aura_range = max(aura_range, skill.skill_data.aura_radius)
    
    if aura_range > 0:
        create_range_circle(aura_range_circle, aura_range)
        aura_range_circle.visible = true
    else:
        aura_range_circle.visible = false

func create_range_circle(line: Line2D, radius: float) -> void:
    var points = []
    var segments = 32
    
    for i in segments:
        var angle = (i / float(segments)) * 2 * PI
        var x = cos(angle) * radius
        var y = sin(angle) * radius
        points.append(Vector2(x, y))
    
    points.append(points[0])  # 闭合圆圈
    line.points = points

func hide_all_indicators() -> void:
    hide_deployment_zones()
    hide_hero_ranges()
    
    attack_range_circle.visible = false
    aura_range_circle.visible = false
    valid_position_indicator.visible = false
    invalid_position_indicator.visible = false
```

### 7. 数据结构设计

#### 英雄数据结构
```gdscript
# 在 Data.gd 中添加
var heroes: Dictionary = {
    "phantom_spirit": {
        "name": "幻影之灵",
        "element": "fire",
        "description": "火元素英雄，擅长范围攻击和光环效果",
        "sprite": "res://assets/heroes/phantom_spirit.png",
        "scene": "res://Scenes/heroes/HeroBase.tscn",
        "base_stats": {
            "max_hp": 540,
            "damage": 58,
            "defense": 10,
            "attack_speed": 0.9,
            "attack_range": 150.0
        },
        "max_charge": 100,
        "charge_generation": 2.0,
        "respawn_duration": 10.0,
        "skills": ["shadow_strike", "flame_armor", "flame_phantom"]
    }
}

var hero_skills: Dictionary = {
    "shadow_strike": {
        "name": "无影拳",
        "type": "A",
        "description": "快速范围攻击，期间无敌",
        "element": "fire",
        "charge_cost": 20,
        "cooldown": 5.0,
        "cast_time": 0.0,
        "range": 150.0,
        "damage_base": 70,
        "damage_scaling": 1.0,
        "effect_radius": 150.0,
        "attack_count": 5,
        "attack_interval": 0.3,
        "invulnerable_duration": 0.3
    },
    "flame_armor": {
        "name": "火焰甲",
        "type": "B",
        "description": "提升防御并生成伤害光环",
        "element": "fire",
        "charge_cost": 30,
        "cooldown": 12.0,
        "cast_time": 0.0,
        "range": 0.0,
        "duration": 15.0,
        "defense_bonus": 15,
        "shield_amount": 500,
        "aura_radius": 200.0,
        "aura_damage": 30.0
    },
    "flame_phantom": {
        "name": "末炎幻象",
        "type": "C",
        "description": "召唤强力幻象并生成增强光环",
        "element": "fire",
        "charge_cost": 60,
        "cooldown": 90.0,
        "cast_time": 0.0,
        "range": 0.0,
        "duration": 30.0,
        "phantom_damage": 200,
        "phantom_attack_speed": 1.7,
        "phantom_range": 350.0,
        "aura_radius": 250.0,
        "aura_damage": 65.0,
        "burn_stacks": 3
    }
}

var hero_talents: Dictionary = {
    "phantom_spirit": {
        "level_5": [
            {
                "id": "rapid_charge",
                "name": "快速充能",
                "description": "提升充能速度",
                "effects": {
                    "charge_generation_multiplier": 1.5
                }
            },
            {
                "id": "enhanced_strikes",
                "name": "强化打击",
                "description": "无影拳攻击次数+2",
                "effects": {
                    "shadow_strike_attack_count": 2
                }
            }
        ],
        "level_10": [
            {
                "id": "defensive_stance",
                "name": "防御姿态",
                "description": "提升生命值和防御力",
                "effects": {
                    "max_hp_multiplier": 1.5,
                    "defense_bonus": 10
                }
            },
            {
                "id": "flame_mastery",
                "name": "火焰精通",
                "description": "火焰甲效果增强",
                "effects": {
                    "flame_armor_aura_damage": 1.5,
                    "aura_radius_multiplier": 1.2
                }
            }
        ],
        "level_15": [
            {
                "id": "phantom_lord",
                "name": "幻影领主",
                "description": "末炎幻象效果大幅增强",
                "effects": {
                    "flame_phantom_duration": 2.0,
                    "flame_phantom_damage": 2.0,
                    "aura_burn_chance": 0.3
                }
            },
            {
                "id": "elemental_sync",
                "name": "元素同步",
                "description": "所有技能效果提升",
                "effects": {
                    "damage_multiplier": 1.3,
                    "aura_radius_multiplier": 1.5
                }
            }
        ]
    }
}
```

### 8. 关卡词缀系统

#### LevelModifierSystem 类结构
```gdscript
# Scenes/systems/LevelModifierSystem.gd (已存在，需完善)
class_name LevelModifierSystem extends Node

# 词缀数据库
var level_modifiers: Dictionary = {
    "enemy_health_boost": {
        "name": "敌人强化",
        "description": "敌人生命值+50%",
        "type": "enemy",
        "effect": "health_multiplier",
        "value": 1.5
    },
    "hero_damage_boost": {
        "name": "英雄强化",
        "description": "英雄伤害+25%",
        "type": "hero",
        "effect": "damage_multiplier",
        "value": 1.25
    },
    "faster_waves": {
        "name": "快速波次",
        "description": "敌人移动速度+30%",
        "type": "enemy",
        "effect": "speed_multiplier",
        "value": 1.3
    }
}

# 当前词缀
var current_modifiers: Array[Dictionary] = []

func _ready() -> void:
    add_to_group("hero_systems")

func generate_level_modifiers() -> Array[Dictionary]:
    var all_modifier_ids = level_modifiers.keys()
    var selected_modifiers: Array[Dictionary] = []
    
    # 随机选择1-2个词缀
    var modifier_count = randi() % 2 + 1
    
    for i in modifier_count:
        if all_modifier_ids.size() == 0:
            break
        
        var random_index = randi() % all_modifier_ids.size()
        var modifier_id = all_modifier_ids[random_index]
        
        var modifier_data = level_modifiers[modifier_id].duplicate(true)
        modifier_data.id = modifier_id
        
        selected_modifiers.append(modifier_data)
        all_modifier_ids.remove_at(random_index)
    
    current_modifiers = selected_modifiers
    level_modifiers_generated.emit(selected_modifiers)
    
    return selected_modifiers

func apply_modifiers_to_heroes(heroes: Array[HeroBase]) -> void:
    for hero in heroes:
        if not is_instance_valid(hero):
            continue
        
        apply_modifiers_to_hero(hero)

func apply_modifiers_to_hero(hero: HeroBase) -> void:
    for modifier in current_modifiers:
        if modifier.type != "hero":
            continue
        
        match modifier.effect:
            "damage_multiplier":
                hero.current_stats.damage *= modifier.value
            "health_multiplier":
                hero.current_stats.max_hp *= modifier.value
            "defense_multiplier":
                hero.current_stats.defense *= modifier.value
            "attack_speed_multiplier":
                hero.current_stats.attack_speed *= modifier.value

func apply_modifiers_to_enemies() -> void:
    # 实现敌人词缀应用
    pass

func get_current_modifiers() -> Array[Dictionary]:
    return current_modifiers.duplicate(true)

func get_modifier_description(modifier: Dictionary) -> String:
    return modifier.get("description", "未知词缀")
```

## 实现顺序

### 阶段1: 核心英雄系统
1. **完善 HeroBase 类**
   - 实现完整的属性系统
   - 添加碰撞和阻挡功能
   - 实现基础战斗系统
   - 添加复活机制

2. **创建 HeroSkill 类**
   - 实现技能资源类
   - 添加技能释放逻辑
   - 实现冷却和充能系统

3. **完善英雄数据**
   - 在 Data.gd 中添加英雄数据
   - 创建技能配置
   - 设计天赋树结构

### 阶段2: 管理和选择系统
1. **完善 HeroManager 类**
   - 实现英雄部署逻辑
   - 添加波次触发选择
   - 实现英雄池管理

2. **完善 HeroSelectionUI 类**
   - 实现英雄选择界面
   - 添加英雄预览功能
   - 实现选择确认逻辑

3. **完善 HeroTalentSystem 类**
   - 实现天赋选择逻辑
   - 添加天赋效果应用
   - 实现天赋树UI

### 阶段3: UI和可视化
1. **完善 HeroInfoPanel 类**
   - 实现实时信息显示
   - 添加技能控制按钮
   - 实现效果状态显示

2. **创建 HeroRangeIndicator 类**
   - 实现部署区域显示
   - 添加攻击范围指示
   - 实现光环范围可视化

3. **完善 LevelModifierSystem 类**
   - 实现词缀生成逻辑
   - 添加词缀效果应用
   - 创建词缀显示UI

### 阶段4: 集成和优化
1. **系统集成**
   - 连接到全局信号系统
   - 集成到波次管理
   - 添加保存/加载支持

2. **性能优化**
   - 实现分层更新
   - 添加对象池
   - 优化碰撞检测

3. **测试和调试**
   - 添加调试工具
   - 实现性能监控
   - 修复边缘情况

## 性能考虑

### 优化策略
1. **分层更新**: 英雄状态更新使用分层频率，避免每帧更新所有英雄
2. **对象池**: 技能效果和幻象使用对象池复用
3. **碰撞优化**: 使用空间分区或简化碰撞检测
4. **缓存系统**: 缓存常用查询结果，减少实时计算

### 内存管理
1. **资源管理**: 英雄和技能资源使用引用计数管理
2. **效果清理**: 及时清理过期效果和临时对象
3. **场景管理**: 合理管理英雄实例的生命周期

## 验证计划

### 单元测试
1. **HeroBase 功能测试**
   - 生命循环（生成、战斗、死亡、复活）
   - 技能释放逻辑
   - 经验和升级系统

2. **HeroManager 测试**
   - 英雄部署逻辑
   - 选择系统功能
   - 英雄池管理

3. **UI系统测试**
   - 选择界面交互
   - 信息面板显示
   - 范围指示器功能

### 集成测试
1. **系统间交互**
   - 英雄与敌人战斗
   - 英雄与宝石效果集成
   - 英雄与波次系统同步

2. **性能测试**
   - 多英雄同时运行的性能
   - 大量技能效果的性能
   - 长时间运行的稳定性

### 业务逻辑验证
1. **游戏平衡性**
   - 英雄强度评估
   - 技能平衡测试
   - 天赋选择影响

2. **用户体验**
   - 操作流程验证
   - UI响应性测试
   - 视觉效果评估

## 部署要求

### 文件结构
```
Scenes/
├── heroes/
│   ├── HeroBase.gd
│   ├── HeroBase.tscn
│   └── HeroSkill.gd
├── systems/
│   ├── HeroManager.gd
│   ├── HeroTalentSystem.gd
│   └── LevelModifierSystem.gd
└── ui/heroSystem/
    ├── HeroSelectionUI.gd
    ├── HeroSelectionUI.tscn
    ├── HeroInfoPanel.gd
    ├── HeroInfoPanel.tscn
    ├── HeroRangeIndicator.gd
    └── HeroRangeIndicator.tscn

Data.gd (需要添加英雄相关数据)
```

### 场景集成
1. **主场景集成**: 在主场景中添加英雄管理系统节点
2. **UI集成**: 将英雄UI添加到主UI容器
3. **信号连接**: 连接英雄系统到全局信号系统

### 数据准备
1. **英雄数据**: 至少准备5个英雄的完整数据
2. **技能配置**: 为每个英雄配置3个技能
3. **天赋树**: 为每个英雄设计完整的天赋树

此技术规格提供了完整的英雄系统实现指南，涵盖了所有核心功能和技术细节。按照此规格实现可以确保系统的完整性、性能和可维护性。