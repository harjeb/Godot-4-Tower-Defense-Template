#!/usr/bin/env python3
"""
Complete Elemental System Validation Script
Validates all 5 elemental systems: Ice, Earth, Wind, Light, Shadow
"""

import os
import sys
import json
from pathlib import Path

def validate_element_system():
    """Validate the complete elemental system implementation"""
    
    print("Complete Elemental System Validation")
    print("=" * 50)
    
    # Define all elements and their core effects
    elements = {
        "ice": {
            "effects": ["frost", "freeze"],
            "gems": ["ice_basic", "ice_intermediate", "ice_advanced"],
            "color": "cyan"
        },
        "earth": {
            "effects": ["weight", "armor_break", "petrify"],
            "gems": ["earth_basic", "earth_intermediate", "earth_advanced"],
            "color": "brown"
        },
        "wind": {
            "effects": ["imbalance", "knockback", "silence"],
            "gems": ["wind_basic", "wind_intermediate", "wind_advanced"],
            "color": "green"
        },
        "light": {
            "effects": ["blind", "purify", "judgment"],
            "gems": ["light_basic", "light_intermediate", "light_advanced"],
            "color": "yellow"
        },
        "shadow": {
            "effects": ["corrosion", "fear", "life_drain"],
            "gems": ["shadow_basic", "shadow_intermediate", "shadow_advanced"],
            "color": "purple"
        }
    }
    
    # Expected status effects per element
    expected_effects = {
        "ice": ["frost_debuff", "freeze"],
        "earth": ["weight_debuff", "armor_break_debuff", "petrify"],
        "wind": ["imbalance_debuff", "knockback", "silence"],
        "light": ["blind", "purify", "judgment"],
        "shadow": ["corrosion", "fear", "life_drain"]
    }
    
    validation_results = {}
    
    for element_name, element_data in elements.items():
        print(f"\nValidating {element_name.upper()} Element...")
        print("-" * 30)
        
        element_results = {
            "gems": False,
            "effects": False,
            "integration": False,
            "tower_coverage": False
        }
        
        # Validate 1: Gem definitions in Data.gd
        print(f"  📋 Checking gem definitions...")
        gems_found = 0
        expected_gems = element_data["gems"]
        
        try:
            with open("Scenes/main/Data.gd", "r", encoding="utf-8") as f:
                data_content = f.read()
                
            for gem in expected_gems:
                if gem in data_content:
                    gems_found += 1
                    print(f"    [OK] Found gem: {gem}")
                else:
                    print(f"    [FAIL] Missing gem: {gem}")
            
            if gems_found == len(expected_gems):
                element_results["gems"] = True
                print(f"  [OK] All {element_name} gems found ({gems_found}/{len(expected_gems)})")
            else:
                print(f"  [FAIL] Missing {element_name} gems ({gems_found}/{len(expected_gems)})")
                
        except Exception as e:
            print(f"  [ERROR] Error checking gems: {e}")
        
        # Validate 2: Status effects in StatusEffect.gd
        print(f"  📋 Checking status effects...")
        effects_found = 0
        expected_element_effects = expected_effects[element_name]
        
        try:
            with open("Scenes/systems/StatusEffect.gd", "r", encoding="utf-8") as f:
                status_content = f.read()
                
            for effect in expected_element_effects:
                if effect in status_content:
                    effects_found += 1
                    print(f"    ✅ Found effect: {effect}")
                else:
                    print(f"    ❌ Missing effect: {effect}")
            
            if effects_found == len(expected_element_effects):
                element_results["effects"] = True
                print(f"  ✅ All {element_name} effects found ({effects_found}/{len(expected_element_effects)})")
            else:
                print(f"  ❌ Missing {element_name} effects ({effects_found}/{len(expected_element_effects)})")
                
        except Exception as e:
            print(f"  ❌ Error checking effects: {e}")
        
        # Validate 3: Integration in GemEffectSystem.gd
        print(f"  📋 Checking gem effect integration...")
        integration_methods = 0
        expected_methods = [f"apply_{effect}" for effect in element_data["effects"]]
        
        try:
            with open("Scenes/systems/GemEffectSystem.gd", "r", encoding="utf-8") as f:
                gem_content = f.read()
                
            for method in expected_methods:
                if method in gem_content:
                    integration_methods += 1
                    print(f"    ✅ Found method: {method}")
                else:
                    print(f"    ❌ Missing method: {method}")
            
            if integration_methods >= len(expected_methods) * 0.8:  # Allow some tolerance
                element_results["integration"] = True
                print(f"  ✅ {element_name} integration adequate ({integration_methods}/{len(expected_methods)})")
            else:
                print(f"  ❌ {element_name} integration insufficient ({integration_methods}/{len(expected_methods)})")
                
        except Exception as e:
            print(f"  ❌ Error checking integration: {e}")
        
        # Validate 4: Tower coverage
        print(f"  📋 Checking tower coverage...")
        tower_types = [
            "arrow_tower", "capture_tower", "mage_tower", "感应塔", 
            "末日塔", "pulse_tower", "弹射塔", "aura_tower", "weakness_tower"
        ]
        
        towers_with_element = 0
        try:
            with open("Scenes/main/Data.gd", "r", encoding="utf-8") as f:
                data_content = f.read()
                
            for tower in tower_types:
                if f'"{tower}"' in data_content and element_name in data_content:
                    # Check if this tower has the element
                    tower_section = data_content.find(f'"{tower}"')
                    if tower_section != -1:
                        nearby_text = data_content[tower_section:tower_section + 2000]
                        if any(gem in nearby_text for gem in expected_gems):
                            towers_with_element += 1
                            print(f"    ✅ Tower supports {element_name}: {tower}")
            
            if towers_with_element >= 7:  # Allow some tolerance
                element_results["tower_coverage"] = True
                print(f"  ✅ {element_name} tower coverage adequate ({towers_with_element}/{len(tower_types)})")
            else:
                print(f"  ❌ {element_name} tower coverage insufficient ({towers_with_element}/{len(tower_types)})")
                
        except Exception as e:
            print(f"  ❌ Error checking tower coverage: {e}")
        
        validation_results[element_name] = element_results
    
    # Overall validation summary
    print(f"\n🎯 Overall System Validation")
    print("=" * 50)
    
    total_elements = len(elements)
    complete_elements = 0
    
    for element_name, results in validation_results.items():
        element_score = sum(results.values())
        max_score = len(results)
        completion_rate = (element_score / max_score) * 100
        
        status = "✅ COMPLETE" if completion_rate >= 80 else "⚠️  PARTIAL" if completion_rate >= 60 else "❌ INCOMPLETE"
        print(f"{status} {element_name.upper()}: {completion_rate:.1f}% ({element_score}/{max_score})")
        
        if completion_rate >= 80:
            complete_elements += 1
    
    print(f"\n📊 System Summary")
    print(f"   Total Elements: {total_elements}")
    print(f"   Complete Elements: {complete_elements}")
    print(f"   System Completion: {(complete_elements/total_elements)*100:.1f}%")
    
    if complete_elements == total_elements:
        print(f"\n🎉 ALL ELEMENTAL SYSTEMS COMPLETE!")
        print(f"   The game now has a complete 5-element system:")
        print(f"   ❄️ Ice (control/slow)    🌍 Earth (defense/area)")
        print(f"   💨 Wind (disruption)      ☀️ Light (support/healing)")
        print(f"   🌑 Shadow (life drain)")
        return True
    else:
        print(f"\n⚠️  Some elements need additional work")
        return False

if __name__ == "__main__":
    os.chdir(Path(__file__).parent)
    success = validate_element_system()
    sys.exit(0 if success else 1)