class_name ObjectPool
extends RefCounted

var _pooled_objects: Array = []
var _scene: PackedScene
var _initial_size: int = 10

func _init(scene: PackedScene, initial_size: int = 10):
	_scene = scene
	_initial_size = initial_size
	_initialize_pool()

func _initialize_pool() -> void:
	for i in _initial_size:
		var obj := _scene.instantiate()
		obj.set_process(false)
		obj.set_physics_process(false)
		_pooled_objects.append(obj)

func acquire() -> Node:
	var obj: Node
	
	if _pooled_objects.is_empty():
		obj = _scene.instantiate()
	else:
		obj = _pooled_objects.pop_back()
	
	obj.set_process(true)
	obj.set_physics_process(true)
	return obj

func release(obj: Node) -> void:
	if obj == null or not is_instance_valid(obj):
		return
	
	obj.set_process(false)
	obj.set_physics_process(false)
	
	if obj.get_parent() != null:
		obj.get_parent().remove_child(obj)
	
	_pooled_objects.append(obj)

func clear() -> void:
	for obj in _pooled_objects:
		if is_instance_valid(obj):
			obj.queue_free()
	_pooled_objects.clear()

func get_pool_size() -> int:
	return _pooled_objects.size()
