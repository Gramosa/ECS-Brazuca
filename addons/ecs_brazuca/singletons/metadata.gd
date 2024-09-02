@tool
extends Node

var _components: Array[Dictionary]
var _systems: Array[Dictionary]

var _components_names: Array[String]

func _init():
	__load_brazuca_classes()
	
func __load_brazuca_classes() -> void:
	for item in ProjectSettings.get_global_class_list():
		var name: StringName = item["class"]
		if name.begins_with("BRZ"):
			if name.ends_with("Component"):
				_components.append(item)
				_components_names.append(name)
			elif name.ends_with("System"):
				_systems.append(item)
