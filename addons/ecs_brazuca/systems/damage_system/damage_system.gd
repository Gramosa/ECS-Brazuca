@icon("damage_system_icon.svg")
extends BaseSystem

class_name DamageSystem

func _init() -> void:
	super()
	
	_components_requireds = ["HealthComponentGroup", "DamageComponentGroup"]

## if oposite_behaviour be true, the damage will be multiplied by -1. So damage become a healing and vice-versa
## specific_component_name only is necessary if the entity have two or more componenets from the same group
func do_damage(source_entity: Node, target_entity: Node, oposite_behaviour: bool = false, true_damage: bool = false, source_component_name: String = "", target_component_name: String = "") -> void:
	
	# The source_entity must have at least one component from DamageComponentGroup, and target_entity at least one HealthComponent
	var target_component = get_component_from_entity(target_entity, "HealthComponentGroup", target_component_name)
	if target_component == null:
		return
		
	var source_component = get_component_from_entity(source_entity, "DamageComponentGroup", source_component_name)
	if source_component == null:
		return
	
	var real_damage = _get_real_damage(source_component, target_component, true_damage)
	
	if oposite_behaviour == false:
		target_component.update_health(real_damage)
	else:
		target_component.update_health(-real_damage)
	
	
func do_continuous_damage(source_entity: Node, target_entity: Node) -> void:
	pass

func _get_real_damage(damage_component: DamageComponent, health_component: HealthComponent, true_damage: bool):
	var base_damage: int = damage_component.get_damage()
	var real_damage: int
	# The true damage ignore the resistance and damage_ratio
	if true_damage == true:
		real_damage = base_damage
	else:
		real_damage = int(base_damage * (damage_component.get_damage_ratio() / health_component.get_resistance_ratio()))
	
	return real_damage
