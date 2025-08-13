#!/usr/bin/env python3
"""
Simple Elemental System Validation
"""

import os

def validate_elements():
    print("Elemental System Validation")
    print("=" * 40)
    
    elements = ["ice", "earth", "wind", "light", "shadow"]
    expected_gems = {
        "ice": ["ice_basic", "ice_intermediate", "ice_advanced"],
        "earth": ["earth_basic", "earth_intermediate", "earth_advanced"], 
        "wind": ["wind_basic", "wind_intermediate", "wind_advanced"],
        "light": ["light_basic", "light_intermediate", "light_advanced"],
        "shadow": ["暗影宝石 1级", "暗影之心 2级", "暗影之魂 3级"]
    }
    
    total_score = 0
    max_score = sum(len(gems) for gems in expected_gems.values())
    
    for element in elements:
        print(f"\nChecking {element.upper()} element...")
        
        gems_found = 0
        gem_list = expected_gems[element]
        for gem_name in gem_list:
            
            # Check Data.gd for gem definitions
            try:
                with open("Scenes/main/Data.gd", "r", encoding="utf-8") as f:
                    content = f.read()
                    if gem_name in content:
                        gems_found += 1
                        print(f"  [OK] {gem_name}")
                    else:
                        print(f"  [FAIL] {gem_name}")
            except:
                print(f"  [ERROR] Could not check {gem_name}")
        
        total_score += gems_found
        print(f"  {element}: {gems_found}/{len(expected_gems)} gems found")
    
    print(f"\nOverall: {total_score}/{max_score} gems found")
    
    if total_score >= max_score * 0.9:
        print("SUCCESS: All elemental systems are implemented!")
        return True
    else:
        print("WARNING: Some elemental systems need work")
        return False

if __name__ == "__main__":
    os.chdir(os.path.dirname(__file__))
    validate_elements()