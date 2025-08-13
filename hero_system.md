# Hero System Technical Specification

## Problem Statement

- **Business Issue**: Replace melee towers with a more engaging Hero system that provides unique gameplay mechanics
- **Current State**: Basic tower defense with melee towers that lack distinctive mechanics and player engagement
- **Expected Outcome**: Fully functional Hero system with path-blocking units, skill systems, talent progression, level modifiers, and integrated UI components

## Solution Overview

- **Approach**: Implement a complete Hero system as a modular addition to the existing tower defense framework, leveraging current systems while adding hero-specific mechanics
- **Core Changes**: Add Hero base classes, skill system, talent progression, revival mechanics, level modifier system, and specialized UI components
- **Success Criteria**: Heroes can be deployed on paths, use skills, level up through kills, respawn after death, and integrate seamlessly with existing game systems

## Technical Implementation

### Database Changes

**New Configuration Files**:
- `hero_data.gd` - Hero definitions and base stats
- `hero_skills.gd` - Skill definitions and effects
- `hero_talents.gd` - Talent tree configurations
- `level_modifiers.gd` - Random level modifier configurations

**Data Structure Extensions**:
```gdscript
# Add to Data.gd
var heroes := {
    "phantom_spirit": {
        "name": "幻影之灵",
        "element": "fire",
        "base_stats": {
            "max_hp": 540,
            "damage": 58,
            "defense": 10,
            "attack_speed": 0.9,
            "attack_range": 150.0,
            "movement_speed": 0.0  # Heroes are stationary when deployed
        },
        "skills": ["shadow_strike", "flame_armor", "flame_phantom"],
        "sprite": "res://Assets/heroes/phantom_spirit.png",
        "scene": "res://Scenes/heroes/phantom_spirit.tscn",
        "charge_generation": 2.0,  # Charge per second
        "max_charge": 100
    }
}

var hero_skills := {
    "shadow_strike": {
        "name": "无影拳",
        "type": "A",
        "charge_cost": 20,
        "cooldown": 5.0,
        "cast_range": 200.0,
        "effect_radius": 150.0,
        "damage_base": 70,
        "damage_scaling": 1.0,  # Multiplied by hero attack
        "invulnerable_duration": 0.3,
        "attack_count": 5,
        "attack_interval": 0.3
    },
    "flame_armor": {
        "name": "火焰甲", 
        "type": "B",
        "charge_cost": 35,
        "cooldown": 12.0,
        "duration": 15.0,
        "defense_bonus": 15,
        "shield_amount": 500,
        "aura_radius": 200.0,
        "aura_damage": 30.0
    },
    "flame_phantom": {
        "name": "末炎幻象",
        "type": "C",
        "charge_cost": 60,
        "cooldown": 90.0,
        "duration": 30.0,
        "phantom_damage": 200,
        "phantom_attack_speed": 1.7,
        "phantom_range": 350.0,
        "aura_radius": 250.0,
        "aura_damage": 65.0,
        "burn_stacks": 3
    }
}
```

### Code Changes

**Core Hero System Files**:

1. **HeroBase.gd** (`D:\pycode\Godot-4-Tower-Defense-Template\Scenes\heroes\HeroBase.gd`)
```gdscript
class_name HeroBase
extends Node2D

# Hero state management
var hero_type: String
var current_level: int = 1
var experience_points: int = 0
var is_alive: bool = true
var respawn_timer: float = 0.0
var respawn_duration: float = 10.0

# Stats system
var base_stats: Dictionary
var current_stats: Dictionary 
var max_charge: int = 100
var current_charge: float = 0.0
var charge_generation_rate: float = 2.0

# Skill system
var skills: Array[HeroSkill] = []
var skill_queue: Array[String] = []
var current_casting_skill: HeroSkill = null

# Talent system
var talent_selections: Dictionary = {}  # level -> talent_id
var available_talents: Array = []

# Integration with existing systems
var gem_effect_system: GemEffectSystem
var da_bonus: float = 0.0
var ta_bonus: float = 0.0
```

2. **HeroSkill.gd** (`D:\pycode\Godot-4-Tower-Defense-Template\Scenes\heroes\HeroSkill.gd`)
```gdscript
class_name HeroSkill
extends Resource

@export var skill_id: String
@export var skill_type: String  # "A", "B", "C"
@export var charge_cost: int
@export var cooldown: float
@export var is_on_cooldown: bool = false
@export var cooldown_remaining: float = 0.0

func can_cast(hero: HeroBase) -> bool
func execute_skill(hero: HeroBase, target_position: Vector2) -> void
func get_skill_priority() -> int  # C=3, B=2, A=1
```

3. **HeroManager.gd** (`D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\HeroManager.gd`)
```gdscript
class_name HeroManager
extends Node

signal hero_deployed(hero: HeroBase)
signal hero_died(hero: HeroBase)
signal hero_respawned(hero: HeroBase)
signal hero_leveled_up(hero: HeroBase, new_level: int)

var deployed_heroes: Array[HeroBase] = []
var hero_selection_queue: Array[String] = []  # For 5-choose-1 system
var level_modifiers: Array[Dictionary] = []
```

4. **HeroTalentSystem.gd** (`D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\HeroTalentSystem.gd`)
```gdscript
class_name HeroTalentSystem
extends Node

func get_talent_options(hero: HeroBase, level: int) -> Array[Dictionary]
func apply_talent(hero: HeroBase, talent_id: String) -> void
func get_talent_effects(hero: HeroBase) -> Dictionary
```

5. **LevelModifierSystem.gd** (`D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\LevelModifierSystem.gd`)
```gdscript
class_name LevelModifierSystem  
extends Node

signal modifiers_applied(modifiers: Array[Dictionary])

func generate_random_modifiers(count: int = 2) -> Array[Dictionary]
func apply_level_modifiers(modifiers: Array[Dictionary]) -> void
func remove_level_modifiers() -> void
```

**UI System Files**:

6. **HeroSelectionUI.gd** (`D:\pycode\Godot-4-Tower-Defense-Template\Scenes\ui\heroSelection\HeroSelectionUI.gd`)
```gdscript
class_name HeroSelectionUI
extends Control

signal hero_selected(hero_type: String)
signal talent_selected(hero: HeroBase, talent_id: String)

func show_hero_selection(available_heroes: Array[String]) -> void
func show_talent_selection(hero: HeroBase, talents: Array[Dictionary]) -> void
```

7. **HeroInfoPanel.gd** (`D:\pycode\Godot-4-Tower-Defense-Template\Scenes\ui\heroInfo\HeroInfoPanel.gd`)
```gdscript
class_name HeroInfoPanel
extends Control

func display_hero_info(hero: HeroBase) -> void
func update_hero_stats(hero: HeroBase) -> void
func show_skill_details(skill: HeroSkill) -> void
```

8. **HeroRangeIndicator.gd** (`D:\pycode\Godot-4-Tower-Defense-Template\Scenes\ui\heroIndicators\HeroRangeIndicator.gd`)
```gdscript
class_name HeroRangeIndicator
extends Node2D

func show_deployment_zones(hero_type: String) -> void
func show_skill_ranges(hero: HeroBase) -> void
func highlight_affected_areas(skill: HeroSkill, position: Vector2) -> void
```

### API Changes

**New Signals in Globals.gd**:
```gdscript
signal hero_deployed(hero: HeroBase, position: Vector2)
signal hero_died(hero: HeroBase)
signal hero_respawned(hero: HeroBase) 
signal hero_skill_cast(hero: HeroBase, skill: HeroSkill)
signal level_modifiers_generated(modifiers: Array)
signal talent_selection_available(hero: HeroBase, level: int)
```

**Integration Methods**:
```gdscript
# In GemEffectSystem.gd - Add hero support
func apply_effect_to_hero(hero: HeroBase, effect_type: String, duration: float, stacks: int = 1) -> void

# In WaveManager.gd - Add modifier integration  
func apply_wave_modifiers(modifiers: Array) -> void

# In main.gd - Add hero deployment
func deploy_hero(hero_type: String, position: Vector2) -> HeroBase
```

### Configuration Changes

**Scene Structure**:
```
Scenes/heroes/
├── HeroBase.tscn                 # Base hero scene template
├── phantom_spirit/
│   ├── phantom_spirit.tscn       # Phantom Spirit hero scene
│   └── phantom_spirit.gd         # Hero-specific logic
└── skills/
    ├── shadow_strike.gd          # Shadow Strike skill implementation
    ├── flame_armor.gd            # Flame Armor skill implementation
    └── flame_phantom.gd          # Flame Phantom skill implementation

Scenes/ui/heroSystem/
├── HeroSelectionUI.tscn          # Hero selection interface
├── HeroInfoPanel.tscn            # Detailed hero information panel
├── HeroTalentSelection.tscn      # Talent selection dialog
├── LevelModifierDisplay.tscn     # Level modifier announcement
└── HeroRangeIndicator.tscn       # Range and area indicators
```

**System Integration Points**:
```gdscript
# In main.gd scene tree
MainScene/
├── Systems/
│   ├── HeroManager
│   ├── HeroTalentSystem  
│   ├── LevelModifierSystem
│   └── (existing systems...)
├── UI/
│   ├── HeroSelectionUI
│   ├── HeroInfoPanel
│   └── HeroRangeIndicator
└── Heroes/  # Container for deployed heroes
```

## Implementation Sequence

### Phase 1: Core Hero System Foundation
1. **Create HeroBase.gd** - Basic hero entity with stats, health, charge system
2. **Create HeroSkill.gd** - Skill resource class and casting framework
3. **Create HeroManager.gd** - Hero deployment, lifecycle, and management
4. **Integrate with GemEffectSystem** - Add hero support to existing effect system
5. **Add hero data definitions** - Configure Phantom Spirit hero data in Data.gd

### Phase 2: Skill System Implementation  
1. **Implement Shadow Strike (A skill)** - Area attack with invulnerability frames
2. **Implement Flame Armor (B skill)** - Self-buff with damage shield and aura
3. **Implement Flame Phantom (C skill)** - Summon phantom unit with persistent effects
4. **Add skill priority system** - Automatic skill casting based on charge and cooldowns
5. **Integrate skills with GemEffectSystem** - Apply burn, buffs, and area effects

### Phase 3: Progression Systems
1. **Create HeroTalentSystem** - Talent trees with 2-choice selections at levels 5/10/15
2. **Add experience and leveling** - Kill-based progression system
3. **Add respawn mechanics** - 10-second death timer and revival system
4. **Implement level modifiers** - Random level-wide effects (1-2 per level)
5. **Add talent selection UI** - Interface for choosing talents on level up

### Phase 4: UI and Visual Systems
1. **Create HeroSelectionUI** - 5-choose-1 hero selection interface
2. **Create HeroInfoPanel** - Detailed stats display for selected heroes/enemies
3. **Create HeroRangeIndicator** - Visual range indicators for deployment and skills
4. **Add level modifier display** - Announcement and persistent display of active modifiers
5. **Integrate with existing HUD** - Add hero charge bars, skill cooldowns, and level display

### Phase 5: Integration and Polish
1. **Add hero deployment zones** - Restrict hero placement to valid path positions
2. **Implement DA/TA integration** - Apply existing damage amplification systems to heroes
3. **Add save/load support** - Persist hero progress and talent selections
4. **Performance optimization** - Efficient skill effect processing and range checking
5. **Testing and balancing** - Validate all systems work together correctly

## Validation Plan

**Unit Tests**:
- Hero stat calculation and modification
- Skill casting validation and cooldown management  
- Talent application and effect stacking
- Experience gain and level progression
- Respawn timer and revival mechanics

**Integration Tests**:
- Hero deployment on valid path positions
- Skill effects integration with GemEffectSystem
- Level modifier application to enemies and heroes
- Hero skill target acquisition and damage calculation
- UI state synchronization with hero system events

**Business Logic Verification**:
- Heroes can only be deployed on paths (not open areas)
- Hero dies when HP reaches 0 and respawns after 10 seconds
- Heroes gain experience from kills and level up appropriately
- Talent selection appears at correct levels (5, 10, 15) with 2 choices
- Skills cast in priority order (C > B > A) when charge is available
- Level modifiers affect gameplay as specified
- Hero information panel shows all relevant stats and effects
- Range indicators accurately display deployment zones and skill areas

## Key Implementation Details

### Hero Deployment System
```gdscript
# Validate deployment position is on enemy path
func can_deploy_hero(position: Vector2) -> bool:
    var path_nodes = get_tree().get_nodes_in_group("enemy_path")
    for path_node in path_nodes:
        if path_node.global_position.distance_to(position) < 50.0:
            return true
    return false
```

### Skill Priority System
```gdscript
# Automatic skill casting based on priority and availability
func update_skill_casting(delta: float):
    if current_casting_skill or not is_alive:
        return
        
    var available_skills = skills.filter(func(s): return s.can_cast(self))
    if available_skills.is_empty():
        return
        
    available_skills.sort_custom(func(a, b): return a.get_skill_priority() > b.get_skill_priority())
    cast_skill(available_skills[0])
```

### Integration with GemEffectSystem
```gdscript
# Extend existing effect system to support heroes
func _apply_hero_specific_effects(hero: HeroBase, effect_type: String):
    match effect_type:
        "burn":
            if hero.hero_type == "phantom_spirit":
                # Fire heroes take reduced burn damage
                effect.damage_multiplier = 0.5
        "freeze":
            # Heroes have freeze resistance
            effect.duration *= 0.7
```

### Performance Considerations

**Optimization Strategies**:
- Use object pooling for skill effects and phantom summons
- Cache path validation results for hero deployment
- Limit skill range checking to once per second for inactive skills  
- Use area-based queries for skill targeting instead of iterating all enemies
- Batch hero status updates in HeroManager to reduce per-frame processing

**Memory Management**:
- Clean up skill effects when heroes die or respawn
- Release phantom summons when their duration expires
- Use weak references in talent effect callbacks to prevent memory leaks
- Limit maximum number of simultaneous heroes to prevent performance degradation

This technical specification provides a complete blueprint for implementing the Hero System that integrates seamlessly with the existing tower defense framework while adding engaging new gameplay mechanics focused on active skill usage, character progression, and strategic positioning.