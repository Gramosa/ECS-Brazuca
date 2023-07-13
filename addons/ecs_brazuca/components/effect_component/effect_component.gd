"""NÃO IMPLEMENTADO AINDA, NÃO FUNCIONAL"""
"""
No futuro se for necessario mais componentes com função puramente de container, fazer a herança a partir de uma classe intermediaria,
então adicionar a API necessaria para containers. Talvez um ContainerComponent entre a BaseComponent e EffectComponent (hehe ficaria top)
"""
extends BaseComponent

## This class are a container for EffectData's objects, its managed by a EffectSystem
class_name EffectComponent

@export_group("Effects")
## Availibe Effects the entity can apply to itself or to others entities
@export var availibe_effects: Array[EffectData]

## Actives effects suffered by the entity
@export var active_effects: Array[EffectData]

var effect_names: Array[String]

## Used for the components as a workaround to get_class() problem (if necessary)
func get_class_name() -> String:
	return "EffectComponent"

func _init() -> void:
	super()
	
	add_to_group("EffectComponentGroup", true)

func get_availibe_effects() -> Array[EffectData]:
	return availibe_effects

func get_availibe_effects_names() -> Array[String]:
	var effects_names: Array[String] = []
	for effect in availibe_effects:
		effects_names.append(effect.effect_name)
	
	return effects_names
	
func get_active_effects() -> Array[EffectData]:
	return active_effects

func get_effect_by_name(required_name: String) -> EffectData:
	for effect in availibe_effects:
		if effect.effect_name == required_name:
			return effect
		
	return null
