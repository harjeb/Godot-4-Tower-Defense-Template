# Five Elemental Skills Implementation Requirements

## Original Request
检查下路径种的markdown文件，帮我实现 新增加的 5个元素的技能，我已实现火元素，其他优化也更新在其他md

## Clarified Requirements

### Target Elements (5 total)
1. **Ice** (冰霜) - Freeze and slow effects
2. **Earth** (大地) - Stone and defense-breaking effects  
3. **Wind** (疾风) - Knockback and silence effects
4. **Light** (光明) - Purification and blind effects
5. **Shadow** (暗影) - Corruption and life-drain effects

### Implementation Strategy
- **Approach**: Complete implementation of ONE element first (ice recommended as starter)
- **Reference**: Use existing fire element as template
- **Integration**: Full integration with ElementSystem.gd, GemEffectSystem.gd, StatusEffect.gd
- **Coverage**: All 9 tower types per element (箭塔, 捕获塔, 法师塔, 感应塔, 末日塔, 脉冲塔, 弹射塔, 光环塔, 虚弱塔)
- **Testing**: Manual testing acceptable, no automated tests required
- **Performance**: No specific performance constraints

### Technical Specifications
- **Code Structure**: Follow existing fire element conventions
- **File Naming**: Consistent with current naming patterns
- **Integration Points**: 
  - ElementSystem.gd for elemental damage calculations
  - GemEffectSystem.gd for skill effect applications
  - StatusEffect.gd for status effect management
  - Data.gd for skill definitions and balance data

### Quality Requirements
- **Functional Completeness**: All skills must work as specified in markdown tables
- **Integration Quality**: Seamless integration with existing systems
- **Code Consistency**: Follow established patterns and conventions
- **Balance**: Skills should be balanced relative to existing fire element

## Success Criteria
1. Ice element fully implemented with all 9 tower types
2. All skills functional and integrated with existing systems
3. Code follows established patterns and conventions
4. Skills balanced appropriately relative to fire element
5. No breaking changes to existing functionality

## Implementation Order
1. Ice element (complete implementation)
2. Earth element (if ice successful)
3. Wind element (if earth successful)  
4. Light element (if wind successful)
5. Shadow element (if light successful)

## Requirements Quality Score: 92/100
- Functional Clarity: 28/30 (clear scope and deliverables)
- Technical Specificity: 23/25 (clear integration points and structure)
- Implementation Completeness: 24/25 (comprehensive coverage defined)
- Business Context: 17/20 (clear value and progression strategy)