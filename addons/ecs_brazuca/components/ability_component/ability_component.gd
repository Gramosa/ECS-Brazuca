"""NÃO IMPLEMENTADO AINDA, NÃO FUNCIONAL"""
"""
No futuro se for necessario mais componentes com função puramente de container, fazer a herança a partir de uma classe intermediaria,
então adicionar a API necessaria para containers. Talvez um ContainerComponent entre a BaseComponent e AbilityComponent (hehe ficaria top)
"""
@icon("ability_component_icon.svg")
extends BaseComponent

## This class are a container for AbilityData's objects, it is managed by an AbilitySystem
class_name AbilityComponent

@export_group("Formula")
## The formula used to calculate the designed property, of the designed component
#@export var formula: CalcFormula

@export_group("Ability")
## Availibe abilities the entity can apply to a given formula
@export var availibe_abilities: Array[AbilityData]

## Effects that were applied to this component

func _init() -> void:
	super()
	
	add_to_group("AbilityComponentGroup", true)

func get_availibe_abilities() -> Array[AbilityData]:
	if availibe_abilities.is_empty():
		push_warning("The AbilityComponent {0} from entity {1} are empty, its impossible to apply any effect".format([self.get_name(), _entity.get_name()]))
	
	return availibe_abilities
	

func get_availibe_abilities_names() -> Array[String]:
	var abilities_names: Array[String] = []
	for effect in availibe_abilities:
		abilities_names.append(effect.effect_name)
	
	return abilities_names
	

func get_effect_by_name(required_name: String) -> AbilityData:
	for effect in get_availibe_abilities():
		if effect.effect_name == required_name:
			return effect
	push_error("The effect with effect_name {0} does not exist on the component {1} from entity {2}, chose a different effect_name".format([required_name, self.get_name(), _entity.get_name()]))
	return null
