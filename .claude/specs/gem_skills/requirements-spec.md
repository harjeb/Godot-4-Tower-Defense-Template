# Gem Skills Implementation Technical Specification

## Problem Statement

### Business Issue
The current gem system only provides basic damage bonuses through `damage_bonus` attributes. The system needs to be enhanced to support complex gem skills that activate automatically when towers equip gems, including special effects like multi-target attacks, debuffs, area effects, and unique mechanics based on the gem type and level.

### Current State
- Gems only provide simple damage bonuses (`damage_bonus: 0.10-0.35`)
- No skill system exists for gems
- Effects are limited to basic damage calculations
- No debuff or buff management system
- UI only shows basic gem information

### Expected Outcome
- Automatic activation of gem skills when equipped to towers
- Integration of 9 different gem types with unique skills and 5 debuff types
- Skills scale with gem level (basic → intermediate → advanced)
- UI displays gem skills during drag-and-drop operations
- Complete effect management system for debuffs and buffs

## Solution Overview

### Approach
1. **Extend Gem Data Structure**: Add comprehensive skill definitions to existing gem data
2. **Create Effect System**: Implement a robust debuff/buff management system
3. **Enhance Bullet/Turret Logic**: Modify projectile and tower systems to apply gem skills
4. **Update UI Systems**: Add skill display functionality for gem dragging and turret details
5. **Create Skill Manager**: Centralized system for skill activation and management

### Core Changes
- Extend `Data.gems` with skill definitions and effects
- Create new `GemSkillSystem` for skill management
- Implement `EffectManager` for debuff/buff handling
- Modify `bulletBase.gd` and `turret_base.gd` to support skills
- Update `InventoryUI` to display gem skills
- Add visual effects for skill activations

### Success Criteria
- All 9 gem types automatically activate skills when equipped
- 5 debuff types (灼烧, 冰冻, 中毒, 致盲, 腐蚀) are properly applied and managed
- Skills scale correctly with gem levels
- UI displays gem skills during all interactions
- Effects have proper duration, stacking, and cleanup mechanics
- System integrates seamlessly with existing combat mechanics

## Technical Implementation

### Database Changes

#### Modified Gem Data Structure
```gdscript
# Extended gem data structure in Data.gd
const gems := {
    "fire_basic": {
        "name": "初级火宝石",
        "element": "fire",
        "level": 1,
        "damage_bonus": 0.10,
        "skills": {
            "burn_debuff": {
                "type": "debuff",
                "effect": "burn",
                "duration": 3.0,
                "damage_per_second": 5.0,
                "chance": 1.0,
                "description": "灼烧DEBUFF，每秒5点伤害，持续3秒"
            },
            "multi_target": {
                "type": "attack_modifier",
                "max_targets": 3,
                "damage_multiplier": 1.0,
                "description": "3目标攻击"
            }
        },
        "sprite": "res://Assets/gems/fire_basic.png"
    },
    "fire_intermediate": {
        "name": "中级火宝石",
        "element": "fire",
        "level": 2,
        "damage_bonus": 0.20,
        "skills": {
            "burn_debuff": {
                "type": "debuff",
                "effect": "burn",
                "duration": 3.0,
                "damage_per_second": 8.0,
                "chance": 1.0,
                "description": "灼烧DEBUFF，每秒8点伤害，持续3秒"
            },
            "multi_target": {
                "type": "attack_modifier",
                "max_targets": 3,
                "damage_multiplier": 1.1,
                "description": "3目标攻击，伤害+10%"
            }
        },
        "sprite": "res://Assets/gems/fire_intermediate.png"
    },
    # ... similar structure for other gem types and levels
}
```

#### New Debuff Definitions
```gdscript
# Add to Data.gd
const debuff_types := {
    "burn": {
        "name": "灼烧",
        "color": Color.ORANGE_RED,
        "icon": "res://Assets/effects/burn.png",
        "effect_type": "damage_over_time",
        "stackable": true,
        "max_stacks": 3
    },
    "freeze": {
        "name": "冰冻",
        "color": Color.CYAN,
        "icon": "res://Assets/effects/freeze.png",
        "effect_type": "disable",
        "disables_movement": true,
        "disables_attack": true,
        "stackable": false
    },
    "poison": {
        "name": "中毒",
        "color": Color.DARK_GREEN,
        "icon": "res://Assets/effects/poison.png",
        "effect_type": "vulnerability",
        "damage_taken_multiplier": 1.25,
        "stackable": true,
        "max_stacks": 5
    },
    "blind": {
        "name": "致盲",
        "color": Color.DARK_GRAY,
        "icon": "res://Assets/effects/blind.png",
        "effect_type": "disable",
        "disables_movement": true,
        "stackable": false
    },
    "corrosion": {
        "name": "腐蚀",
        "color": Color.PURPLE,
        "icon": "res://Assets/effects/corrosion.png",
        "effect_type": "damage_amplification",
        "poison_damage_multiplier": 1.5,
        "stackable": true,
        "max_stacks": 3
    }
}
```

### Code Changes

#### New Files to Create

**1. `Scenes/systems/GemSkillSystem.gd`**
```gdscript
extends Node
class_name GemSkillSystem

signal skill_activated(skill_data: Dictionary, target: Node, source: Node)
signal effect_applied(effect_type: String, target: Node, duration: float)

var effect_manager: EffectManager

func _ready():
    effect_manager = get_effect_manager()

func activate_gem_skills(tower: Turret, target: Node):
    if not tower.equipped_gem:
        return
    
    var gem_data = tower.equipped_gem
    if not gem_data.has("skills"):
        return
    
    for skill_id in gem_data.skills:
        var skill = gem_data.skills[skill_id]
        execute_skill(skill, tower, target)

func execute_skill(skill: Dictionary, tower: Turret, target: Node):
    match skill.type:
        "debuff":
            apply_debuff_skill(skill, tower, target)
        "attack_modifier":
            apply_attack_modifier_skill(skill, tower, target)
        "area_effect":
            apply_area_effect_skill(skill, tower, target)
        "aura":
            apply_aura_skill(skill, tower)

func apply_debuff_skill(skill: Dictionary, tower: Turret, target: Node):
    if not target.has_method("apply_effect"):
        return
    
    if randf() <= skill.get("chance", 1.0):
        var effect_data = {
            "type": skill.effect,
            "duration": skill.duration,
            "source": tower,
            "values": skill
        }
        
        if effect_manager:
            effect_manager.apply_effect(target, effect_data)
        
        skill_activated.emit(skill, target, tower)

func apply_attack_modifier_skill(skill: Dictionary, tower: Turret, primary_target: Node):
    # Handle multi-target attacks, ricochet, etc.
    if skill.has("max_targets"):
        var additional_targets = find_additional_targets(tower, primary_target, skill.max_targets)
        for target in additional_targets:
            create_secondary_attack(tower, target, skill.get("damage_multiplier", 1.0))

func apply_area_effect_skill(skill: Dictionary, tower: Turret, center_target: Node):
    # Handle area damage, knockback, etc.
    var area_radius = skill.get("radius", 50.0)
    var targets_in_area = get_targets_in_area(center_target.global_position, area_radius)
    
    for target in targets_in_area:
        if target != center_target:
            apply_area_effect_to_target(skill, tower, target)

func apply_aura_skill(skill: Dictionary, tower: Turret):
    # Handle persistent aura effects
    pass

func find_additional_targets(tower: Turret, primary_target: Node, max_targets: int) -> Array:
    var targets = []
    var detection_area = tower.get_node("DetectionArea")
    
    for area in detection_area.get_overlapping_areas():
        var potential_target = area.get_parent()
        if potential_target.is_in_group("enemy") and potential_target != primary_target:
            targets.append(potential_target)
            if targets.size() >= max_targets:
                break
    
    return targets

func get_effect_manager() -> EffectManager:
    var tree = get_tree()
    if tree and tree.current_scene:
        return tree.current_scene.get_node_or_null("EffectManager") as EffectManager
    return null
```

**2. `Scenes/systems/EffectManager.gd`**
```gdscript
extends Node
class_name EffectManager

signal effect_applied(effect: Dictionary, target: Node)
signal effect_removed(effect: Dictionary, target: Node)
signal effect_expired(effect: Dictionary, target: Node)

var active_effects = {}  # target_id -> [effects]
var effect_timers = {}   # target_id -> Timer

func _ready():
    # Setup effect processing
    set_process(true)

func _process(delta):
    update_active_effects(delta)

func apply_effect(target: Node, effect_data: Dictionary):
    if not target.has_method("get_instance_id"):
        return
    
    var target_id = target.get_instance_id()
    
    # Initialize target effects array if needed
    if not active_effects.has(target_id):
        active_effects[target_id] = []
    
    var effect = create_effect_instance(effect_data, target)
    active_effects[target_id].append(effect)
    
    # Apply immediate effects
    apply_effect_immediate(target, effect)
    
    # Setup duration timer
    if effect.duration > 0:
        setup_effect_timer(target_id, effect)
    
    effect_applied.emit(effect, target)

func create_effect_instance(effect_data: Dictionary, target: Node) -> Dictionary:
    var effect = {
        "type": effect_data.type,
        "duration": effect_data.duration,
        "source": effect_data.source,
        "start_time": Time.get_ticks_msec(),
        "values": effect_data.values,
        "stacks": 1,
        "target": target
    }
    
    return effect

func apply_effect_immediate(target: Node, effect: Dictionary):
    var debuff_config = Data.debuff_types.get(effect.type, {})
    
    match effect.type:
        "burn":
            if target.has_method("apply_burn"):
                target.apply_burn(effect.values.damage_per_second)
        "freeze":
            if target.has_method("apply_freeze"):
                target.apply_freeze(effect.duration)
        "poison":
            if target.has_method("apply_poison"):
                target.apply_poison(effect.values.damage_taken_multiplier)
        "blind":
            if target.has_method("apply_blind"):
                target.apply_blind(effect.duration)
        "corrosion":
            if target.has_method("apply_corrosion"):
                target.apply_corrosion(effect.values.poison_damage_multiplier)

func update_active_effects(delta):
    for target_id in active_effects:
        var effects = active_effects[target_id]
        var effects_to_remove = []
        
        for effect in effects:
            # Update duration-based effects
            if effect.duration > 0:
                var elapsed = (Time.get_ticks_msec() - effect.start_time) / 1000.0
                if elapsed >= effect.duration:
                    effects_to_remove.append(effect)
                else:
                    update_effect_over_time(effect, delta, elapsed)
        
        # Remove expired effects
        for effect in effects_to_remove:
            remove_effect(target_id, effect)

func update_effect_over_time(effect: Dictionary, delta: float, elapsed: float):
    match effect.type:
        "burn":
            # Apply periodic damage
            if fmod(elapsed, 1.0) < delta:
                var target = effect.target
                if target and target.has_method("get_damage"):
                    target.get_damage(effect.values.damage_per_second)

func remove_effect(target_id: int, effect: Dictionary):
    var effects = active_effects.get(target_id, [])
    effects.erase(effect)
    
    # Remove effect from target
    var target = effect.target
    if target and target.has_method("remove_effect"):
        target.remove_effect(effect.type)
    
    effect_removed.emit(effect, target)
    effect_expired.emit(effect, target)

func get_target_effects(target: Node) -> Array:
    if not target or not target.has_method("get_instance_id"):
        return []
    
    var target_id = target.get_instance_id()
    return active_effects.get(target_id, [])

func has_effect(target: Node, effect_type: String) -> bool:
    var effects = get_target_effects(target)
    for effect in effects:
        if effect.type == effect_type:
            return true
    return false

func clear_all_effects(target: Node):
    if not target or not target.has_method("get_instance_id"):
        return
    
    var target_id = target.get_instance_id()
    if active_effects.has(target_id):
        var effects = active_effects[target_id].duplicate()
        for effect in effects:
            remove_effect(target_id, effect)
        active_effects.erase(target_id)
```

#### Modified Files

**1. `Scenes/turrets/projectileTurret/bullet/bulletBase.gd`**
```gdscript
# Add to existing bulletBase.gd
var gem_skill_system: GemSkillSystem

func _ready():
    super._ready()
    find_gem_skill_system()

func find_gem_skill_system():
    var tree = get_tree()
    if tree and tree.current_scene:
        gem_skill_system = tree.current_scene.get_node_or_null("GemSkillSystem") as GemSkillSystem

func _on_area_2d_area_entered(area):
    var obj = area.get_parent()
    if obj.is_in_group("enemy"):
        pierce -= 1
        
        # Calculate enhanced damage
        var target_element = "neutral"
        if obj.has_method("get_element"):
            target_element = obj.get_element()
        
        var final_damage = calculate_enhanced_damage(target_element)
        obj.get_damage(final_damage)
        
        # Activate gem skills
        if gem_skill_system and source_tower and source_tower.equipped_gem:
            gem_skill_system.activate_gem_skills(source_tower, obj)
        
        # Charge system notification
        if source_tower and not has_meta("is_charge_ability"):
            var charge_system = get_charge_system()
            if charge_system:
                charge_system.add_charge_on_hit(source_tower)
    
    if pierce == 0:
        queue_free()
```

**2. `Scenes/turrets/turretBase/turret_base.gd`**
```gdscript
# Add to existing turret_base.gd
var gem_skill_system: GemSkillSystem

func _ready():
    super._ready()
    find_gem_skill_system()

func find_gem_skill_system():
    var tree = get_tree()
    if tree and tree.current_scene:
        gem_skill_system = tree.current_scene.get_node_or_null("GemSkillSystem") as GemSkillSystem

# Modify attack method for non-projectile towers
func attack():
    if is_instance_valid(current_target):
        # Handle non-projectile skill activation
        if gem_skill_system and equipped_gem and turret_category != "projectile":
            gem_skill_system.activate_gem_skills(self, current_target)
        
        # Charge system notification
        if turret_category != "projectile":
            var charge_system = get_charge_system()
            if charge_system and has_charge_ability():
                charge_system.add_charge_on_hit(self)
    else:
        try_get_closest_target()
```

**3. `Scenes/ui/inventory/InventoryUI.gd`**
```gdscript
# Add to existing InventoryUI.gd
func create_gem_slot(gem_id: String, container: Container):
    var gem_data = Data.gems.get(gem_id, {})
    var slot = Button.new()
    slot.custom_minimum_size = Vector2(64, 64)
    
    # Set gem icon
    if gem_data.has("sprite"):
        var texture = load(gem_data.sprite)
        if texture:
            slot.icon = texture
    
    # Set tooltip with skill information
    slot.tooltip_text = create_gem_tooltip(gem_data)
    
    # Connect drag functionality
    slot.set_drag_preview(create_drag_preview(gem_data))
    
    container.add_child(slot)
    return slot

func create_gem_tooltip(gem_data: Dictionary) -> String:
    var tooltip = gem_data.get("name", "未知宝石") + "\n"
    tooltip += "等级: " + str(gem_data.get("level", 1)) + "\n"
    tooltip += "元素: " + gem_data.get("element", "neutral") + "\n"
    
    if gem_data.has("damage_bonus"):
        tooltip += "伤害加成: +" + str(int(gem_data.damage_bonus * 100)) + "%\n"
    
    if gem_data.has("skills"):
        tooltip += "\n技能:\n"
        for skill_id in gem_data.skills:
            var skill = gem_data.skills[skill_id]
            tooltip += "• " + skill.get("description", "未知技能") + "\n"
    
    return tooltip

func create_drag_preview(gem_data: Dictionary) -> Control:
    var preview = Control.new()
    preview.custom_minimum_size = Vector2(200, 150)
    
    # Create background panel
    var panel = Panel.new()
    panel.size = Vector2(200, 150)
    preview.add_child(panel)
    
    # Create gem icon
    var icon = TextureRect.new()
    icon.position = Vector2(10, 10)
    icon.size = Vector2(64, 64)
    if gem_data.has("sprite"):
        icon.texture = load(gem_data.sprite)
    panel.add_child(icon)
    
    # Create skill description
    var skill_label = Label.new()
    skill_label.position = Vector2(80, 10)
    skill_label.size = Vector2(110, 130)
    skill_label.text = create_skill_description(gem_data)
    skill_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    panel.add_child(skill_label)
    
    return preview

func create_skill_description(gem_data: Dictionary) -> String:
    var description = gem_data.get("name", "未知宝石") + "\n\n"
    
    if gem_data.has("skills"):
        for skill_id in gem_data.skills:
            var skill = gem_data.skills[skill_id]
            description += skill.get("description", "未知技能") + "\n\n"
    
    return description
```

### API Changes

#### New Scene Structure
```
Scenes/systems/
├── GemSkillSystem.gd          # Main skill activation system
├── EffectManager.gd          # Debuff/buff management
└── EffectVisualizer.gd       # Visual effects for skills

Scenes/effects/
├── BurnEffect.tscn           # Burning visual effect
├── FreezeEffect.tscn         # Freezing visual effect
├── PoisonEffect.tscn         # Poison visual effect
├── BlindEffect.tscn          # Blind visual effect
└── CorrosionEffect.tscn      # Corrosion visual effect
```

#### Enemy Interface Extensions
```gdscript
# Add to enemy base class
func apply_effect(effect_data: Dictionary):
    # Handle effect application
    pass

func remove_effect(effect_type: String):
    # Handle effect removal
    pass

func apply_burn(damage_per_second: float):
    # Apply burn effect
    pass

func apply_freeze(duration: float):
    # Apply freeze effect
    pass

func apply_poison(damage_multiplier: float):
    # Apply poison effect
    pass

func apply_blind(duration: float):
    # Apply blind effect
    pass

func apply_corrosion(poison_multiplier: float):
    # Apply corrosion effect
    pass
```

### Configuration Changes

#### New Settings in Data.gd
```gdscript
# Add to Data.gd
const gem_skill_settings := {
    "effect_tick_rate": 1.0,          # How often effects tick (seconds)
    "max_concurrent_effects": 10,     # Max effects per target
    "effect_visual_duration": 0.5,    # Duration of effect visuals
    "skill_cooldown_reduction": 0.0,  # Global skill cooldown reduction
    "area_effect_delay": 0.1,         # Delay for area effect propagation
    "multi_target_search_range": 150.0 # Range for finding additional targets
}
```

## Implementation Sequence

### Phase 1: Core System Foundation
1. **Create EffectManager** - Build the debuff/buff management system
2. **Create GemSkillSystem** - Implement the main skill activation system
3. **Extend Data Structures** - Add skill definitions to gem data
4. **Create Effect Visuals** - Build visual effects for each debuff type

### Phase 2: Integration with Existing Systems
1. **Modify bulletBase.gd** - Add skill activation to projectile hits
2. **Modify turret_base.gd** - Add skill activation to non-projectile attacks
3. **Update Enemy Classes** - Add effect application methods
4. **Test Basic Skills** - Verify fire gem burn effect works

### Phase 3: Advanced Skill Implementation
1. **Implement Multi-Target Skills** - Add area targeting and secondary attacks
2. **Implement Aura Skills** - Add persistent area effects
3. **Implement Complex Debuffs** - Add stacking, duration, and interaction logic
4. **Add Skill Scaling** - Ensure skills scale with gem levels

### Phase 4: UI and Polish
1. **Update InventoryUI** - Add skill tooltips and drag previews
2. **Update Turret Details** - Show equipped gem skills
3. **Add Visual Effects** - Implement particle effects and animations
4. **Add Sound Effects** - Add audio feedback for skill activations

### Phase 5: Testing and Balance
1. **Unit Testing** - Test each skill type individually
2. **Integration Testing** - Test skill interactions and combinations
3. **Performance Testing** - Ensure effect system doesn't impact performance
4. **Balance Adjustments** - Fine-tune skill values and interactions

## Validation Plan

### Unit Tests
1. **EffectManager Tests**
   - Verify effect application and removal
   - Test effect stacking mechanics
   - Validate duration and timing
   - Test effect cleanup

2. **GemSkillSystem Tests**
   - Verify skill activation on hit
   - Test multi-target targeting
   - Validate skill scaling with levels
   - Test different skill types

3. **Integration Tests**
   - Test bullet-skill interaction
   - Test turret-skill interaction
   - Verify effect-enemy interaction
   - Test UI skill display

### Integration Tests
1. **Fire Gem Skills**
   - Burn debuff application and damage
   - Multi-target attack functionality
   - Level scaling verification

2. **Ice Gem Skills**
   - Freeze effect application
   - Slow effect mechanics
   - Area effect functionality

3. **Complete System Test**
   - All gem types functional
   - All debuff types working
   - UI displaying skills correctly
   - Performance under load

### Business Logic Verification
1. **Automatic Activation**
   - Skills activate when gems are equipped
   - No manual activation required
   - Skills persist through gem changes

2. **Gem Level Progression**
   - Basic gems have basic effects
   - Intermediate gems have enhanced effects
   - Advanced gems have maximum effects

3. **UI Integration**
   - Skills visible during gem dragging
   - Skill descriptions in tooltips
   - Visual feedback for skill activation

## Success Metrics

### Technical Metrics
- All 9 gem types implement at least 1 unique skill
- All 5 debuff types are functional with proper mechanics
- Skill activation success rate > 99%
- Effect system performance impact < 5% CPU time
- No memory leaks from effect accumulation

### User Experience Metrics
- Skills are clearly visible in UI
- Skill effects have clear visual feedback
- Game performance remains smooth during intense combat
- Players can understand which skills are active
- Skill effects feel impactful and satisfying

### Balance Metrics
- Skills are appropriately powerful for their gem level
- No single gem type dominates all situations
- Skill combinations create interesting gameplay
- Effects are balanced against base game difficulty