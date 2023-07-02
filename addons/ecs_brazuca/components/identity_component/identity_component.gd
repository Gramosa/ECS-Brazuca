"""PARCIALMENTE IMPLEMENTADO"""
extends BaseComponent

class_name IdentityComponent

@export_group("JsonLoader Configuration")
## MUST have the json_loader.gd as an autoload of the game named JsonLoader
@export var utilize_json_loader: bool = false
## The specific ID for the JSON Object, every JSON Object must have an key named "id" with a unique value
@export var id: String

var entity_properties: Dictionary = {}

func _init():
	assert(Engine.has_singleton("JsonLoader"), "The Identity Component will not work, must have the JsonLoader as singleton")
	#entity_properties = JsonLoader.get_data_by_key("id")[id]
	
