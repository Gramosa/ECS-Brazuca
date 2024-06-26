"""NÃO IMPLEMENTADO AINDA, NÃO FUNCIONAL"""
"""
No futuro se for necessario mais componentes com função puramente de container, fazer a herança a partir de uma classe intermediaria,
então adicionar a API necessaria para containers. Talvez um ContainerComponent entre a BrazucaBaseComponent e AbilityComponent (hehe ficaria top)
"""

@tool
@icon("ability_component_icon.svg")
extends BrazucaBaseComponent

## This class are a container for AbilityData's objects, it is managed by an AbilitySystem
class_name BrazucaAbilityComponent

@export_enum("NONE:0") var target_component: int

#TODO: Automatizar as propriedades disponiuveis baseado na target_component
@export var target_property: String

## The initial signature used by the formula to calculate the designed property, of the designed component.
@export var formula: CalcFormula

#@export_group("Ability")
## Availibe abilities the entity can apply to the formula
@export var availibe_abilities: Array[BrazucaAbilityData]

func _validate_property(property: Dictionary):
	if property.name == "target_component":
		var txt: String = "NONE:0"
		var counter: int = 1
		for component_name in BrazucaMetadata._brazuca_components_names:
			txt += ",{0}:{1}".format([component_name, counter])
			counter += 1
		
		property.hint_string = txt
		
func _init() -> void:
	super()
	
	add_to_group("AbilityComponentGroup", true)

func get_availibe_abilities() -> Array[BrazucaAbilityData]:
	if availibe_abilities.is_empty():
		push_warning("The AbilityComponent {0} from entity {1} are empty, its impossible to apply any ability".format([self.get_name(), _entity.get_name()]))
	
	return availibe_abilities
	

func get_availibe_abilities_names() -> Array[String]:
	var abilities_names: Array[String] = []
	for ability in availibe_abilities:
		abilities_names.append(ability.ability_name)
	
	return abilities_names

func get_ability_by_name(required_name: String) -> BrazucaAbilityData:
	for ability in get_availibe_abilities():
		if ability.ability_name == required_name:
			return ability
	push_error("The ability with ability_name {0} does not exist on the component {1} from entity {2}, chose a different ability_name".format([required_name, self.get_name(), _entity.get_name()]))
	return null
