"""NÃO IMPLEMENTADO AINDA, NÃO FUNCIONAL"""
"""
No futuro se for necessario mais componentes com função puramente de container, fazer a herança a partir de uma classe intermediaria,
então adicionar a API necessaria para containers. Talvez um ContainerComponent entre a BaseComponent e EffectComponent (hehe ficaria top)
"""
@icon("effect_component_icon.svg")
extends BaseComponent

## This class are a container for EffectData's objects, its managed by a EffectSystem
class_name EffectComponent

@export_group("Effects")
## Availibe Effects the entity can apply to itself or to others entities
@export var availibe_effects: Array[EffectData]

var effect_names: Array[String]

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
	

func get_effect_by_name(required_name: String) -> EffectData:
	for effect in availibe_effects:
		if effect.effect_name == required_name:
			return effect
		
	return null
