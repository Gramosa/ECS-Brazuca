extends BaseSystem

class_name DamageSystem

func get_class_name():
	return "DamageSystem"

func _init() -> void:
	super()
	
	_components_requireds = ["HealthComponentGroup", "DamageComponentGroup"]

"""
Se for necessário (e parece ser) transformar parte da logica de do_damage em uma função de BaseSystem, assim como foi feito com can_system_operate_entity
OU Criar uma função "get" que colete o componente de entities tendo a entidade e o grupo do componente
"""
# For now only works for entities who DONT multiple HealthComponent (target_entity) or DamageComponent (source_entity)
## if oposite_behaviour be true, the damage will be multiplied by -1. So damage become a healing and vice-versa
func do_damage(source_entity: Node, target_entity: Node, oposite_behaviour: bool = false) -> void:
	# The source_entity must have at least one component from DamageComponentGroup, and target_entity at least one HealthComponent
	if can_system_operate_entity(source_entity, "DamageComponentGroup") == true and can_system_operate_entity(target_entity, "HealthComponentGroup") == true:
		
		var source_entity_name: String = source_entity.get_name()
		var target_entity_name: String = target_entity.get_name()
		# Take the first component from DamageComponentGroup
		var source_component: DamageComponent = entities[source_entity_name][1]["DamageComponentGroup"][0]
		# Take the first component from HealthComponentGroup
		var target_component: HealthComponent = entities[target_entity_name][1]["HealthComponentGroup"][0]
		
		var source_damage = source_component.get_damage()
		if oposite_behaviour == false:
			target_component.update_health(source_damage)
		else:
			target_component.update_health(-source_damage)

func do_continuous_damage(source_entity: Node, target_entity: Node) -> void:
	pass
