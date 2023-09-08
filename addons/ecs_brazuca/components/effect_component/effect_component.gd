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
	if availibe_effects.is_empty():
		push_warning("The EffectComponent {0} from entity {1} are empty, its impossible to apply any effect".format([self.get_name(), _entity.get_name()]))
	
	return availibe_effects
	

func get_availibe_effects_names() -> Array[String]:
	var effects_names: Array[String] = []
	for effect in availibe_effects:
		effects_names.append(effect.effect_name)
	
	return effects_names
	

func get_effect_by_name(required_name: String) -> EffectData:
	for effect in get_availibe_effects():
		if effect.effect_name == required_name:
			if effect.effect_type != EffectData.EFFECT_TYPES.NOTHING:
				return effect
			else:
				push_warning("Trying to utilize the effect {0}, but it have effect_type equal to NOTHING, well nothing will happen".format([effect.effect_name]))
				return null
		
	push_error("The effect with effect_name {0} does not exist on the component {1} from entity {2}, chose a different effect_name".format([required_name, self.get_name(), _entity.get_name()]))
	return null
