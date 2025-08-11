extends Control
class_name GemCraftingUI

signal crafting_closed
signal gem_crafted(gem_id: String)

@onready var crafting_container: VBoxContainer
@onready var close_button: Button
@onready var title_label: Label
@onready var scroll_container: ScrollContainer

var inventory_manager: InventoryManager
var crafting_recipes: Array[CraftingRecipe] = []

func _ready():
	# 获取管理器引用
	inventory_manager = get_inventory_manager()
	if inventory_manager:
		inventory_manager.inventory_updated.connect(_on_inventory_updated)
	
	# 创建UI元素
	setup_ui()
	
	# 设置输入处理
	set_process_input(true)

func setup_ui():
	# 创建主面板
	var panel = Panel.new()
	panel.size = Vector2(450, 600)
	panel.position = Vector2(200, 50)
	add_child(panel)
	
	# 创建标题
	title_label = Label.new()
	title_label.text = "宝石合成"
	title_label.position = Vector2(10, 10)
	title_label.size = Vector2(200, 30)
	panel.add_child(title_label)
	
	# 创建关闭按钮
	close_button = Button.new()
	close_button.text = "X"
	close_button.position = Vector2(410, 10)
	close_button.size = Vector2(30, 30)
	close_button.pressed.connect(_on_close_button_pressed)
	panel.add_child(close_button)
	
	# 创建滚动容器
	scroll_container = ScrollContainer.new()
	scroll_container.position = Vector2(10, 50)
	scroll_container.size = Vector2(430, 540)
	panel.add_child(scroll_container)
	
	# 创建合成容器
	crafting_container = VBoxContainer.new()
	crafting_container.size = Vector2(410, 520)
	scroll_container.add_child(crafting_container)
	
	# 创建说明标签
	var info_label = Label.new()
	info_label.text = "使用2个相同等级的宝石可以合成1个更高等级的宝石"
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_label.custom_minimum_size = Vector2(410, 40)
	crafting_container.add_child(info_label)

func _input(event):
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("craft_gems"):
		close_crafting()

func _on_inventory_updated(inventory: Array):
	update_crafting_recipes()

func update_crafting_recipes():
	# 清空现有配方
	for recipe in crafting_recipes:
		recipe.queue_free()
	crafting_recipes.clear()
	
	if not inventory_manager:
		return
	
	# 获取可合成的宝石
	var craftable = inventory_manager.get_craftable_gems()
	
	for craft_info in craftable:
		var recipe = CraftingRecipe.new()
		recipe.setup_recipe(craft_info, inventory_manager)
		recipe.gem_crafted.connect(_on_gem_crafted)
		crafting_container.add_child(recipe)
		crafting_recipes.append(recipe)
	
	# 如果没有可合成的配方，显示提示
	if craftable.is_empty():
		var no_recipe_label = Label.new()
		no_recipe_label.text = "当前没有可合成的宝石\n收集2个相同的初级或中级宝石来合成更高等级的宝石"
		no_recipe_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_recipe_label.custom_minimum_size = Vector2(410, 100)
		crafting_container.add_child(no_recipe_label)
		crafting_recipes.append(no_recipe_label)

func _on_gem_crafted(gem_id: String):
	gem_crafted.emit(gem_id)
	# 更新配方显示
	update_crafting_recipes()

func _on_close_button_pressed():
	close_crafting()

func close_crafting():
	crafting_closed.emit()
	hide()

func open_crafting():
	show()
	update_crafting_recipes()

func get_inventory_manager() -> InventoryManager:
	var tree = get_tree()
	if tree and tree.root:
		return tree.root.get_node_or_null("InventoryManager") as InventoryManager
	return null

# 内部合成配方类
class CraftingRecipe:
	extends HBoxContainer
	
	signal gem_crafted(gem_id: String)
	
	var craft_info: Dictionary
	var inventory_manager: InventoryManager
	var craft_button: Button
	var result_icon: TextureRect
	var materials_container: HBoxContainer
	var description_label: Label
	
	func _init():
		custom_minimum_size = Vector2(410, 80)
		
		# 创建材料容器
		materials_container = HBoxContainer.new()
		materials_container.custom_minimum_size = Vector2(150, 80)
		add_child(materials_container)
		
		# 创建箭头标签
		var arrow_label = Label.new()
		arrow_label.text = " → "
		arrow_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		arrow_label.custom_minimum_size = Vector2(30, 80)
		add_child(arrow_label)
		
		# 创建结果图标
		result_icon = TextureRect.new()
		result_icon.custom_minimum_size = Vector2(64, 64)
		result_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		add_child(result_icon)
		
		# 创建描述和按钮容器
		var info_container = VBoxContainer.new()
		info_container.custom_minimum_size = Vector2(150, 80)
		add_child(info_container)
		
		# 创建描述标签
		description_label = Label.new()
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.custom_minimum_size = Vector2(150, 40)
		info_container.add_child(description_label)
		
		# 创建合成按钮
		craft_button = Button.new()
		craft_button.text = "合成"
		craft_button.custom_minimum_size = Vector2(150, 30)
		craft_button.pressed.connect(_on_craft_pressed)
		info_container.add_child(craft_button)
	
	func setup_recipe(craft_data: Dictionary, manager: InventoryManager):
		craft_info = craft_data
		inventory_manager = manager
		
		var current_gem_id = craft_info.current_gem
		var result_gem_id = craft_info.result_gem
		var element = craft_info.element
		
		# 设置材料图标
		create_material_icons(current_gem_id, 2)
		
		# 设置结果图标
		setup_result_icon(result_gem_id)
		
		# 设置描述
		var current_gem_data = Data.gems.get(current_gem_id, {})
		var result_gem_data = Data.gems.get(result_gem_id, {})
		description_label.text = "%s → %s" % [
			current_gem_data.get("name", "未知"),
			result_gem_data.get("name", "未知")
		]
	
	func create_material_icons(gem_id: String, count: int):
		for i in range(count):
			var icon = TextureRect.new()
			icon.custom_minimum_size = Vector2(64, 64)
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			
			# 设置占位符纹理
			var texture = PlaceholderTexture2D.new()
			texture.size = Vector2(60, 60)
			icon.texture = texture
			
			# 根据宝石设置颜色
			if gem_id in Data.gems:
				var gem_data = Data.gems[gem_id]
				if gem_data.has("element"):
					icon.modulate = ElementSystem.get_element_color(gem_data.element)
			
			materials_container.add_child(icon)
	
	func setup_result_icon(gem_id: String):
		# 设置占位符纹理
		var texture = PlaceholderTexture2D.new()
		texture.size = Vector2(60, 60)
		result_icon.texture = texture
		
		# 根据宝石设置颜色
		if gem_id in Data.gems:
			var gem_data = Data.gems[gem_id]
			if gem_data.has("element"):
				result_icon.modulate = ElementSystem.get_element_color(gem_data.element)
			
			# 高级宝石使用更亮的颜色
			if gem_data.get("level", 1) == 3:
				result_icon.modulate = result_icon.modulate.lightened(0.3)
	
	func _on_craft_pressed():
		if not inventory_manager:
			return
		
		var element = craft_info.element
		var level = craft_info.level
		
		if inventory_manager.craft_gem(element, level):
			gem_crafted.emit(craft_info.result_gem)
			print("成功合成: ", craft_info.result_gem)