extends Node
class_name WeaponWheelManager

signal weapon_wheel_updated(items: Array)

var weapon_wheel_items: Array[Dictionary] = []
var max_slots: int = 10

func _ready():
	# 设置为AutoLoad单例
	name = "WeaponWheelManager"

func add_to_weapon_wheel(item_id: String) -> bool:
	if weapon_wheel_items.size() >= max_slots:
		return false
		
	if item_id in Data.weapon_wheel_buffs:
		var item = {
			"id": item_id,
			"data": Data.weapon_wheel_buffs[item_id]
		}
		weapon_wheel_items.append(item)
		weapon_wheel_updated.emit(weapon_wheel_items)
		return true
	return false

func remove_from_weapon_wheel(slot_index: int) -> bool:
	if slot_index >= 0 and slot_index < weapon_wheel_items.size():
		weapon_wheel_items.remove_at(slot_index)
		weapon_wheel_updated.emit(weapon_wheel_items)
		return true
	return false

func remove_item_by_id(item_id: String) -> bool:
	for i in range(weapon_wheel_items.size()):
		if weapon_wheel_items[i].id == item_id:
			weapon_wheel_items.remove_at(i)
			weapon_wheel_updated.emit(weapon_wheel_items)
			return true
	return false

func get_active_buffs() -> Array:
	return weapon_wheel_items.map(func(item): return item.data)

func get_turret_buffs(turret_category: String) -> Array:
	var applicable_buffs = []
	for buff in get_active_buffs():
		if buff.has("applies_to") and turret_category in buff.applies_to:
			applicable_buffs.append(buff)
	return applicable_buffs

func get_element_buffs(element: String) -> Array:
	var applicable_buffs = []
	for buff in get_active_buffs():
		if buff.has("element_type") and buff.element_type == element:
			applicable_buffs.append(buff)
	return applicable_buffs

func calculate_turret_multiplier(turret_category: String) -> float:
	var multiplier = 1.0
	var turret_buffs = get_turret_buffs(turret_category)
	for buff in turret_buffs:
		multiplier += buff.bonus
	return multiplier

func calculate_element_multiplier(element: String) -> float:
	var multiplier = 1.0
	var element_buffs = get_element_buffs(element)
	for buff in element_buffs:
		multiplier += buff.bonus
	return multiplier

func has_buff(buff_id: String) -> bool:
	for item in weapon_wheel_items:
		if item.id == buff_id:
			return true
	return false

func get_slot_count() -> int:
	return weapon_wheel_items.size()

func get_available_slots() -> int:
	return max_slots - weapon_wheel_items.size()

func clear_weapon_wheel():
	weapon_wheel_items.clear()
	weapon_wheel_updated.emit(weapon_wheel_items)

func get_weapon_wheel_data() -> Array:
	return weapon_wheel_items.duplicate()

func is_full() -> bool:
	return weapon_wheel_items.size() >= max_slots