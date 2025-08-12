# Tower Defense Enhancement System - Technical Specification

## Problem Statement
- **Business Issue**: Current tower defense template has limited tower variety (4 types), no advanced combat mechanics, and basic enemy AI without skill systems
- **Current State**: Simple projectile/ray/melee tower system with basic enemy pathing and no passive synergies or defense mechanics
- **Expected Outcome**: Rich tactical gameplay with 9 new tower types, DA/TA system, monster skills, defense mechanics, and passive synergy system supporting 20 towers + 50 monsters simultaneously

## Solution Overview
- **Approach**: Extend existing Godot 4 turret_base.gd and enemy_mover.gd systems with new tower types, combat mechanics, and skill systems while maintaining performance
- **Core Changes**: Add 9 new tower definitions to Data.gd, implement DA/TA attack system, create monster skill framework, add defense calculation system, implement passive synergy manager
- **Success Criteria**: All 9 towers functional with demo values, DA/TA system working on projectile towers, 4 monster skills operational, Chapter 1 with 5 levels playable

## Technical Implementation

### Database Changes
- **Tables to Modify**: 
  - `Data.gd.turrets` - Add 9 new tower definitions
  - `Data.gd.enemies` - Add defense values and skill definitions
  - `Data.gd.maps` - Add Chapter 1 level configurations
- **New Tables**: None required (using existing dictionary structure)
- **Migration Scripts**: Data modifications in existing `Data.gd` file

### Code Changes

#### Files to Modify:
- **D:\pycode\Godot-4-Tower-Defense-Template\Scenes\main\Data.gd** - Add new tower/enemy definitions
- **D:\pycode\Godot-4-Tower-Defense-Template\Scenes\turrets\turretBase\turret_base.gd** - Add DA/TA system and passive effects
- **D:\pycode\Godot-4-Tower-Defense-Template\Scenes\turrets\projectileTurret\projectileTurret.gd** - Implement DA/TA attack mechanics
- **D:\pycode\Godot-4-Tower-Defense-Template\Scenes\enemies\enemy_mover.gd** - Add defense system and monster skills
- **D:\pycode\Godot-4-Tower-Defense-Template\Scenes\maps\EnemySpawner.gd** - Update wave configurations for Chapter 1

#### New Files:
- **D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\PassiveSynergyManager.gd** - Manages tower passive bonuses
- **D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\DefenseSystem.gd** - Handles damage reduction calculations
- **D:\pycode\Godot-4-Tower-Defense-Template\Scenes\systems\MonsterSkillSystem.gd** - Manages monster skill effects
- **D:\pycode\Godot-4-Tower-Defense-Template\Scenes\turrets\specialTurrets\** - Directory for specialized tower scenes
- **D:\pycode\Godot-4-Tower-Defense-Template\Scenes\effects\** - Visual effects for skills and DA/TA

#### Function Signatures:
```gdscript
# PassiveSynergyManager.gd
class_name PassiveSynergyManager
func calculate_tower_bonuses(tower: Turret) -> Dictionary
func get_towers_in_range(center_position: Vector2, range: float) -> Array[Turret]
func get_adjacent_towers(tower: Turret) -> Array[Turret]

# DefenseSystem.gd
class_name DefenseSystem
static func calculate_damage_after_defense(original_damage: float, defense_value: float) -> float
static func get_defense_multiplier(defense_value: float) -> float

# MonsterSkillSystem.gd
class_name MonsterSkillSystem
func trigger_frost_aura(enemy: Node2D) -> void
func trigger_acceleration(enemy: Node2D) -> void
func trigger_self_destruct(enemy: Node2D) -> void
func trigger_petrification(enemy: Node2D) -> void

# Enhanced turret_base.gd methods
func calculate_da_ta_attacks() -> int  # Returns 1, 2, or 3 based on DA/TA probability
func apply_passive_bonuses() -> void
func get_effective_stats() -> Dictionary
```

### API Changes
- **Endpoints**: No REST API changes (local game)
- **Request/Response**: Enhanced signal system for tower interactions
- **Validation Rules**: Input validation for tower placement and upgrade constraints

### Configuration Changes
- **Settings**: Performance target constants (MAX_TOWERS = 20, MAX_MONSTERS = 50)
- **Environment Variables**: None required
- **Feature Flags**: None required

## Implementation Sequence

### Phase 1: Core Data and Base Systems
1. **Update Data.gd** - Add 9 new tower definitions with demo stats
   - Arrow Tower: damage=15, range=80, speed=1.2s, cost=50
   - Capture Tower: damage=8, range=100, speed=2.0s, cost=75, AOE slow
   - Mage Tower: damage=45, range=90, speed=3.0s, cost=120, AOE
   - Detection Tower: damage=0, range=120, cost=60, stealth detection
   - Doomsday Tower: damage=25/s, range=70, CD=20s, cost=200, DOT+disable
   - Pulse Tower: damage=20, range=85, speed=1.8s, cost=90, periodic AOE
   - Ricochet Tower: damage=12, range=75, speed=1.5s, cost=80, 5x bounce
   - Aura Tower: damage=0, range=95, cost=70, persistent slow
   - Weakness Tower: damage=10, range=65, speed=0.8s, cost=65, armor reduction

2. **Create DefenseSystem.gd** - Damage calculation: `damage = original / (1 + defense/100)`
   - Normal enemies: 10-30 defense
   - Elite enemies: 40-80 defense  
   - Boss enemies: 100-200 defense

3. **Update enemy_mover.gd** - Add defense property and damage calculation integration

### Phase 2: DA/TA Attack System
1. **Enhance turret_base.gd** - Add DA/TA properties and calculation
   - DA base probability: 5%
   - TA base probability: 1%
   - Additive stacking from passive bonuses

2. **Update projectileTurret.gd** - Implement multi-shot mechanics
   - DA: Fire 2 projectiles with visual effect
   - TA: Fire 3 projectiles with enhanced visual effect
   - Only affects projectile-type towers

3. **Create visual effects** - Projectile trail enhancements for DA/TA

### Phase 3: Passive Synergy System
1. **Create PassiveSynergyManager.gd** - Central passive bonus calculator
   - Range-based bonuses using tower attack range
   - Adjacent bonuses for 4-directional neighbors
   - Additive stacking rules implementation

2. **Implement passive effects** in turret_base.gd:
   - Arrow Tower: +10% DA, +5% TA per Capture Tower in range
   - Capture Tower: +10% attack speed to all towers in range
   - Mage Tower: +10% damage per other Mage Tower
   - Doomsday Tower: -0.5s CD per TA triggered anywhere
   - Pulse Tower: +5% speed, +5% damage to adjacent 2 towers
   - Ricochet Tower: +50% damage when only one exists
   - Aura Tower: +15% DA, +10% TA to adjacent 2 towers
   - Weakness Tower: +15% damage vs slowed enemies

### Phase 4: Monster Skill System
1. **Create MonsterSkillSystem.gd** - Skill effect manager
2. **Add monster skill definitions** to Data.gd:
   - Frost Aura: range=100, -20% attack speed, -20% CD recovery, 3s duration, 8s CD
   - Acceleration: range=150, random ally +50% speed, 2s duration, 5s CD
   - Self-Destruct: HP<10% trigger, 1s cast time, range=80, 1.5s stun
   - Petrification: self +500% defense, 3s duration, 7s CD

3. **Update enemy_mover.gd** - Integrate skill triggering and effects

### Phase 5: Chapter System and UI Integration
1. **Update EnemySpawner.gd and Data.gd** - Chapter 1 configuration:
   - Level 1: 20 waves (basic monsters)
   - Level 2: 20 waves (skill monsters) 
   - Level 3: 30 waves (mixed types)
   - Level 4: 30 waves (elite monsters)
   - Level 5: 50 waves (boss level)

2. **Enhance UI systems** - Tower placement interface updates for new towers
3. **Add performance monitoring** - FPS tracking for 20 towers + 50 monsters target

## Validation Plan

### Unit Tests
- **DefenseSystem**: Test damage calculation formula with various defense values
- **PassiveSynergyManager**: Test range detection and bonus calculation
- **DA/TA System**: Verify probability calculations and multi-shot mechanics
- **MonsterSkillSystem**: Test skill triggering conditions and cooldowns

### Integration Tests  
- **Full Chapter 1 Playthrough**: All 5 levels completable with performance targets
- **Tower Synergy Combinations**: Test all passive bonus interactions
- **Monster Skill vs Tower Interactions**: Verify skill effects on tower mechanics
- **Performance Stress Test**: 20 towers + 50 monsters simultaneous operation

### Business Logic Verification
- **Gameplay Balance**: Demo values provide meaningful tactical choices
- **Performance Goals**: Maintain 60 FPS with target entity counts
- **Save System**: Level progress persists within levels, resets between levels
- **User Experience**: Intuitive tower placement and upgrade interface

## Technical Architecture Details

### Data Structures

#### New Tower Properties
```gdscript
# Extended turret data structure in Data.gd
{
    "arrow_tower": {
        "stats": {
            "damage": 15,
            "attack_speed": 1.2,  # attacks per second
            "attack_range": 80.0,
            "bulletSpeed": 200.0,
            "bulletPierce": 1,
        },
        "da_bonus": 0.05,  # 5% base DA chance
        "ta_bonus": 0.01,  # 1% base TA chance  
        "passive_effect": "capture_tower_synergy",
        "turret_category": "projectile",
        "aoe_type": "none",  # none, circle, pierce, bounce
        "special_mechanics": []
    }
}
```

#### Defense System Integration
```gdscript
# Enhanced enemy data structure
{
    "normalEnemy": {
        "stats": {
            "hp": 20.0,
            "defense": 15,  # New defense property
            "speed": 1.0,
            "baseDamage": 5.0,
            "goldYield": 10.0
        },
        "monster_skills": ["frost_aura"],  # Array of available skills
        "skill_cooldowns": {"frost_aura": 8.0}
    }
}
```

### Component Relationships

#### PassiveSynergyManager Dependencies
- **Requires**: Access to all deployed towers via Globals.turretsNode
- **Provides**: Bonus calculations to turret_base.gd
- **Update Frequency**: On tower placement, removal, or upgrade

#### MonsterSkillSystem Dependencies  
- **Requires**: Access to enemy instances and tower instances
- **Provides**: Skill effect application and area-of-effect calculations
- **Update Frequency**: Per enemy per frame based on cooldown timers

#### DefenseSystem Integration
- **Called By**: Projectile impact, ray damage, melee damage calculations
- **Modifies**: Final damage values before applying to enemy HP
- **Performance**: Static method calls for minimal overhead

### Performance Optimization Strategies

#### Entity Management
- **Object Pooling**: Reuse projectile instances rather than instantiate/free
- **Spatial Partitioning**: Divide map into cells for efficient range queries
- **Update Batching**: Group passive bonus updates to single frame per second

#### Visual Effects Optimization
- **Particle Pooling**: Limited particle effects for DA/TA visual feedback
- **LOD System**: Reduce effect quality when many entities active
- **Frame Skipping**: Stagger monster skill effect updates across frames

#### Memory Management
- **Skill Instance Limits**: Maximum 10 concurrent skill effects per type
- **Projectile Limits**: Cap total projectiles at 100 simultaneous
- **Effect Cleanup**: Auto-remove expired skill effects and visual indicators

### Integration Approaches

#### Existing Codebase Integration
1. **Extend Rather Than Replace**: All new functionality extends existing base classes
2. **Signal System**: Use existing Godot signal patterns for inter-component communication  
3. **Data.gd Pattern**: Follow existing dictionary-based configuration approach
4. **Scene Structure**: Maintain current scene hierarchy and node organization

#### Backwards Compatibility
- **Existing Saves**: No breaking changes to save data structure
- **Current Maps**: Existing map1 and map2 remain functional
- **UI Components**: Existing turret UI components work with new towers

## Code Generation Guidelines

### Naming Conventions
- **Classes**: PascalCase (e.g., PassiveSynergyManager)
- **Methods**: snake_case (e.g., calculate_tower_bonuses)
- **Variables**: snake_case (e.g., da_bonus_chance)
- **Constants**: UPPER_SNAKE_CASE (e.g., MAX_TOWERS)
- **Signals**: camelCase (e.g., towerBonusUpdated)

### Code Organization Patterns
- **System Scripts**: Place in /Scenes/systems/ directory
- **Tower Variants**: Extend existing turret types rather than create new base classes
- **Skill Effects**: Centralized in MonsterSkillSystem with individual effect methods
- **Data Extensions**: Add to existing Data.gd rather than separate files

### Integration Approaches
- **Dependency Injection**: Use get_node() patterns for system access
- **Event-Driven**: Leverage signals for loose coupling between systems
- **Configuration-Driven**: Store all balance values in Data.gd for easy modification
- **Performance-First**: Optimize for target 60 FPS with 20 towers + 50 monsters

### File Structure Requirements
```
Scenes/
├── systems/
│   ├── PassiveSynergyManager.gd
│   ├── DefenseSystem.gd
│   └── MonsterSkillSystem.gd
├── turrets/
│   └── specialTurrets/
│       ├── aoe_turret.gd          # For AOE-specific logic
│       ├── detection_turret.gd    # For stealth detection
│       └── dot_turret.gd          # For damage-over-time effects
└── effects/
    ├── da_ta_effect.gd            # Visual effects for multiple attacks
    ├── skill_effect.gd            # Monster skill visual effects
    └── passive_indicator.gd       # Visual indicators for passive bonuses
```

This technical specification provides comprehensive implementation guidance for direct code generation while maintaining integration with the existing Godot 4 tower defense template architecture.