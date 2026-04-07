class_name TileModuleFactory
extends RefCounted

static func create_module(module_id: String) -> BaseTileModule:
	var module: BaseTileModule = null
	
	match module_id:
		"light_forest":
			module = LightForestModule.new()
		"abandoned_lab":
			module = AbandonedLabModule.new()
		"lava_crack":
			module = LavaCrackModule.new()
		_:
			module = BaseTileModule.new()
			var data := TileModuleData.new()
			data.module_id = module_id
			data.display_name = module_id
			data.initial_charge = 3
			module.module_data = data
	
	return module
