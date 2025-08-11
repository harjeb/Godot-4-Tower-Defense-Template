extends Node
class_name InventoryManager

signal inventory_updated(inventory: Array)
signal item_added(item: Dictionary)
signal item_removed(item: Dictionary)

var inventory: Array[Dictionary] = []
var max_capacity: int = 20

func _ready():
	# 设置为AutoLoad单例
	name = "InventoryManager"

func add_item(item_id: String, quantity: int = 1) -> bool:
	# 检查是否已存在该物品，如果存在则增加数量
	for item in inventory:
		if item.id == item_id:
			item.quantity += quantity
			item_added.emit(item)
			inventory_updated.emit(inventory)
			return true
	
	# 检查容量限制
	if inventory.size() >= max_capacity:
		return false
	
	# 添加新物品
	var item = {
		"id": item_id,
		"quantity": quantity,
		"data": Data.gems[item_id] if item_id in Data.gems else {}
	}
	
	inventory.append(item)
	item_added.emit(item)
	inventory_updated.emit(inventory)
	return true

func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i in range(inventory.size()):
		if inventory[i].id == item_id:
			if inventory[i].quantity <= quantity:
				var removed_item = inventory[i]
				inventory.remove_at(i)
				item_removed.emit(removed_item)
			else:
				inventory[i].quantity -= quantity
			inventory_updated.emit(inventory)
			return true
	return false

func get_item_count(item_id: String) -> int:
	for item in inventory:
		if item.id == item_id:
			return item.quantity
	return 0

func has_item(item_id: String, required_quantity: int = 1) -> bool:
	return get_item_count(item_id) >= required_quantity

func craft_gem(gem_type: String, current_level: int) -> bool:
	if not ElementSystem.can_craft_gem(gem_type, current_level, inventory):
		return false
	
	var current_gem_id = gem_type + "_" + ElementSystem.get_level_name(current_level)
	var next_gem_id = gem_type + "_" + ElementSystem.get_level_name(current_level + 1)
	
	# 检查是否有足够材料
	if not has_item(current_gem_id, 2):
		return false
	
	# 消耗2个当前等级宝石
	remove_item(current_gem_id, 2)
	# 添加1个高等级宝石  
	add_item(next_gem_id, 1)
	return true

func get_gems_by_element(element: String) -> Array:
	var gems = []
	for item in inventory:
		if item.data.has("element") and item.data.element == element:
			gems.append(item)
	return gems

func get_craftable_gems() -> Array:
	var craftable = []
	var elements = ["fire", "ice", "wind", "earth", "light", "dark"]
	
	for element in elements:
		for level in [1, 2]:
			if ElementSystem.can_craft_gem(element, level, inventory):
				var gem_id = element + "_" + ElementSystem.get_level_name(level)
				var next_gem_id = element + "_" + ElementSystem.get_level_name(level + 1)
				craftable.append({
					"current_gem": gem_id,
					"result_gem": next_gem_id,
					"element": element,
					"level": level
				})
	
	return craftable

func clear_inventory():
	inventory.clear()
	inventory_updated.emit(inventory)

func get_inventory_data() -> Array:
	return inventory.duplicate()