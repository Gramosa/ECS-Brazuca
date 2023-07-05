"""NÃO IMPLEMENTADO AINDA, NÃO FUNCIONAL"""
extends BaseComponent

class_name EffectComponent

@export var effect_data: Array[EffectData]

## Used for the components as a workaround to get_class() problem (if necessary)
func get_class_name() -> String:
	return "EffectComponent"

func _init() -> void:
	super()
	
	add_to_group("EffectComponentGroup", true)

func _ready() -> void:
	super()

