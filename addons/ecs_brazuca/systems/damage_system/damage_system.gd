@icon("damage_system_icon.svg")
extends BRZBaseSystem

class_name BRZDamageSystem

func _init() -> void:
	
	_allowed_components = ["HealthComponentGroup", "DamageComponentGroup"]

## if oposite_behaviour be true, the damage will be multiplied by -1. So damage become a healing and vice-versa
## The logic is a callable with this signature logic(HealthComponent, DamageComponent) -> float
## specific_component_name only is necessary if the entity have two or more componenets from the same group
func do_damage(source_entity: Node, target_entity: Node, logic: Callable, oposite_behaviour: bool = false, source_component_name: String = "", target_component_name: String = "") -> void:
	# The source_entity must have at least one component from DamageComponentGroup, and target_entity at least one HealthComponent
	var target_component: BRZHealthComponent = get_component_from_entity(target_entity, "BRZHealthComponent", target_component_name)
	if target_component == null:
		return
		
	var source_component: BRZDamageComponent = get_component_from_entity(source_entity, "BRZDamageComponent", source_component_name)
	if source_component == null:
		return
	
	var damage: float = logic.call(source_component, target_component)
	
	if oposite_behaviour == false:
		target_component.update_health(damage)
	else:
		target_component.update_health(-damage)

func do_normal_damage(source_entity: Node, target_entity: Node, source_component_name: String = "", target_component_name: String = "") -> void:
	var logic: Callable = func(source_component: BRZDamageComponent, target_component: BRZHealthComponent) -> float:
		return source_component.get_real_damage() / target_component.get_resistance_ratio()
	
	return do_damage(source_entity, target_entity, logic, false, source_component_name, target_component_name)

func do_true_damage(source_entity: Node, target_entity: Node, source_component_name: String = "", target_component_name: String = "") -> void:
	var logic: Callable = func(source_component: BRZDamageComponent, target_component: BRZHealthComponent) -> float:
		return source_component.get_damage()
	
	return do_damage(source_entity, target_entity, logic, false, source_component_name, target_component_name)

func do_continuous_damage(source_entity: Node, target_entity: Node) -> void:
	pass

func do_normal_healing():
	pass

func do_true_healing():
	pass

func do_continuous_healing():
	pass
