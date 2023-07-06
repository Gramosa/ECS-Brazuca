"""NÃO IMPLEMENTADO AINDA, NÃO FUNCIONAL"""
extends BaseComponent

class_name EffectComponent

@export_group("Effects")
## Availibe Effects the entity can apply to itself or to others entities
@export var availibe_effects: Array[EffectData]

## Actives effects suffered by the entity
@export var active_effects: Array[EffectData]

## Used for the components as a workaround to get_class() problem (if necessary)
func get_class_name() -> String:
	return "EffectComponent"

func _init() -> void:
	super()
	
	add_to_group("EffectComponentGroup", true)

