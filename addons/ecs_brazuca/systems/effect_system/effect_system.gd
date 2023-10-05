"""NÃO FUNCIONAL, NÃO IMPLEMENTADO"""
"""Falta possibilitar a remoção do efeito aplicado"""
"""Para fazer isso funcionar o registro do CalcChain atrelado a uma propriedade especifica deveria ser registrado antes da aplicação do efeito."""
"""Talvez criar algumas formulas genericas normalmente usadas, ainda permitindo que estruturas customizadas sejam criadas"""
extends BaseSystem

class_name EffectSystem

## A dictionary designed to map and track components and they properties, its may works together with _entities variable, but its not harded dependend, since its does not register the entity
## When a component are affected by an effect for the first time, its registered here, and the property in question have an CalcChain assigned to it.
## If the duraction are higher than 0 a cooldown are created, in the end, the effect are removed
## If the duraction are equal to -1, the system will take this like a permanent effect, its the structure of _map_effects
## 
## Lets consider an entity who have two components, a HealthComponent and a DamageComponent. And an effect was registered to affect the resistance_ratio and damage_ratio of them
## Here's the resulting `_map_effects` variable:
## {
##     HealthComponent(id) {
##         "resistance_ratio": CalcChainA (instance)
##     },
##     DamageComponent(id) {
##         "damage_ratio": CalcChainB (instance)
## }
##
var _map_effects: Dictionary = {}

## Do NOT override _init, utilize super() and begginin and set the target components groups with _component_requireds
## REMEMBER: The system will load every entity who have at least one component who belongs from at least one of the designed groups
func _init() -> void:
	super()
	
	_components_requireds = ["EffectComponentGroup", "HealthComponentGroup", "DamageComponentGroup"]

func test() -> void:
	var a: int = 2
	var b: int = 3
	var c: int = 4
	var d: int = 5
	var e: int = 6
	
	# (a + b) * c
	var sub_chain_1: CalculationManager.CalcChain = CM.CalcChain.new("multiplication")
	sub_chain_1.add_numeric_chain("sum", [a, b])
	sub_chain_1.add_numeric_link(c)

	# ((a + b) * c) / (d - e)
	var main_chain: CalculationManager.CalcChain = CM.CalcChain.new("division")
	main_chain.add_link(sub_chain_1)
	main_chain.add_numeric_chain("sum", [d, -e])
	
	# Print results
	#print("Calculated Chain Value:", main_chain.get_calculated_chain())

func test2() -> void:
	
	# ((d + ld + 2l + 2lc - 2) / 2)
	var d: int = 5
	var l: int = 20
	var c: int = 2
	var main_chain: CalculationManager.CalcChain = CM.CalcChainFactory.stat_mod_ratio()
	main_chain.add_numeric_link(l)
	main_chain.get_link_by_tag_bfs("buff").add_numeric_link(d)
	main_chain.get_link_by_tag_bfs("debuff").add_numeric_link(c)
	print(main_chain.get_calculated_chain())

func test3() -> void:
	var a = 2
	var b = 3
	var c = 5
	var d = 7
	var e = 11
	
	var main_chain: CalculationManager.CalcChain = CM.CalcChain.new("sum", "main")
	main_chain\
		.add_numeric_chain("multiplication", [a, b])\
		.add_numeric_chain("multiplication", [c, d], "chain2")
	print(main_chain.get_calculated_chain()) #41
	
	var chain2: CalculationManager.CalcChain = main_chain.get_link_by_tag_bfs("chain2")
	chain2.add_numeric_link(e)
	print(main_chain.get_calculated_chain()) #391
	
	main_chain.remove_link_by_tag("chain2")
	
	print(main_chain.get_calculated_chain()) #6
	
	chain2.add_link(main_chain)
	
	print(chain2.get_link_by_tag_dfs("main"))
	
func test4() -> void:
	var A: float = 5
	var B: float = 10
	var C: float = 15
	var D: float = 20
	var E: float = 2
	var F: float = 3
	var G: float = 4

	var main_chain: CalculationManager.CalcChain = CM.CalcChain.new("division", "main")
	var sub_chain1: CalculationManager.CalcChain = CM.CalcChain.new("multiplication", "sub1")
	var sub_chain2: CalculationManager.CalcChain = CM.CalcChain.new("multiplication", "sub2")
	
	#((A+B)*(C-D-E))
	sub_chain1\
		.add_numeric_chain("sum", [A, B], "A+B")\
		.add_numeric_chain("sum", [C, -D, -E])
	#(E*(F+G))
	sub_chain2\
		.add_numeric_link(E)\
		.add_numeric_chain("sum", [F, G])
	#((A+B)*(C-D-E))/(E*(F+G))
	main_chain\
		.add_link(sub_chain1)\
		.add_link(sub_chain2)
	
	print(main_chain.get_calculated_chain()) # out -7.5
	
	#Tests of remotion
	#((C-D-E))/(E*(F+G))
	print("Remotion:")
	main_chain.get_link_by_tag_dfs("sub1").remove_link_by_tag("A+B")
	print(main_chain.get_calculated_chain()) # out -0.5
	
	##((C-D-E)*(C+D))/(E*(F+G))
	sub_chain1.add_numeric_chain("sum", [C, D], "sub1_1") # out -17.5
	print(main_chain.get_calculated_chain()) 
	
	#Tests for parenting chains
	print("Circular Parenting:")
	var subchain1_1: CalculationManager.CalcChain = main_chain.get_link_by_tag_bfs("sub1_1")
	subchain1_1.add_link(main_chain) # Must throw an error due circular parenting main > sub1>  sub1_1 !> main
	
	#Tests duplicating
	print("Duplicating:")
	var new_chain: CalculationManager.CalcChain = main_chain.duplicate()
	if new_chain == main_chain:
		print("igual")
	print("Chains after duplication:")
	print(new_chain.get_calculated_chain()) #-17.5
	print(main_chain.get_calculated_chain()) #-17.5
	print("Chains after remotion:")
	##((C-D-E))/(E*(F+G))
	new_chain.remove_link_from_subchain("sub1", "sub1_1")
	print(new_chain.get_calculated_chain()) # -0.5
	print(main_chain.get_calculated_chain()) # -17.5
	
# This function is responsible for registering the properties and components on _map_effects.
func _register_property_on_map_effect(component: BaseComponent, property: String, calc_chain: CalculationManager.CalcChain) -> void:
	if property not in component:
		push_error("The property '{0}' does not exist on component '{1}', so this property cannot be registered".format([property, component.get_name()]))
		return
	
	var component_id: int = component.get_instance_id()
	if component_id not in _map_effects:
		_map_effects[component_id] = {}
	
	if property not in _map_effects[component_id]:
		"""Por enquanto o valor base da propriedade é adicionado como primeiro elemento da corrente"""
		var property_value: float = component.get(property)
		calc_chain.add_numeric_link(property_value, 0, "base_value")
		_map_effects[component_id][property] = calc_chain

func _unregister_property_on_map_effect(component: BaseComponent, property: String) -> void:
	if property not in component:
		push_error("The property '{0}' does not exist on component '{1}', so this property cannot be registered".format([property, component.get_name()]))
		return
	
	var component_id: int = component.get_instance_id()
	if component_id not in _map_effects:
		push_error("The component '{0}', are not registered on _map_effects. So you cannot unregister it".format([component.get_name()]))
		return
	
	if property not in _map_effects[component_id]:
		push_error("The component {0} are registered but the property {1} are not. So you cannot unregister it".format([property]))
		return
	
	_map_effects[component_id].erase(property)
	if _map_effects[component_id].is_empty():
		_map_effects.erase(component_id)
	
func _modify_property(component: BaseComponent, property: String):
	pass

## Usually to apply an effect, the event must be trigged from this function.
## source_entity must have an EffectComponent and target_entity must have at least one component required by the system.
## effect_name is the actual name of the effect, the value of EffectData.effect_name.
## source_component_name and target_component_name are used if the source_entity or target_entity have more than one component from the same type.
func apply_effect(source_entity: Node, target_entity: Node, effect_name: String, source_component_name: String = "", target_component_name: String = "") -> void:
	# The source_entity must have at least one EffectComponent
	var source_effect_component: EffectComponent = get_component_from_entity(source_entity, "EffectComponentGroup",source_component_name)
	if source_effect_component == null:
		return
	
	# Check if the EffectComponent does not have at least one EffectData, an empty EffectComponent cant apply any effect
	if source_effect_component.get_availibe_effects() == []:
		return
		
	var effect: EffectData = source_effect_component.get_effect_by_name(effect_name)
	if effect == null:
		return
		
	# Take the respective dictionary from the EFFECT_TARGETS dictionary
	var effect_target: Dictionary = effect.get_effect_target()
	if effect_target == {}:
		return
	
	# Take the component who will be affected, based on the effect who will be aplied
	var target_component: BaseComponent = get_component_from_entity(target_entity, effect_target["component_target_group"], target_component_name)
	if target_component == null:
		return
	
	var target_property: String = effect.get_effect_target()["property"]
	
	_register_property_on_map_effect(target_component, target_property, CM.CalcChainFactory.stat_mod_ratio())
	
"""Implementar efeito aleatorio e/ou aplicar todos os efeitos"""

func get_respective_calculaion_chain() -> CalculationManager.CalcChain:
	## entity, component name, property
	return CM.CalcChain.new("sum")

## This function actually is responsible to apply the effect, its means change directly the affected component.
## For internal purposes only, externally the effects is better applied with queue_effect()
## queued_effect are a Array with first item being the EffectData and the second the target component
func __apply_effect(queued_effect: Array) -> void:
	var effect: EffectData = queued_effect[0]
	var target_component: BaseComponent = queued_effect[1]
	
	"""Talvez mudar no futo para um array, e permitir mais de uma modificação por efeito, desde que o alvo seja o mesmo componente"""
	# Take the name of the property to be modified, and the value it must have
	var target_propertie: String = effect.get_effect_target()["property"]
	# Since for now only one property are modified by the effect, it will take the unique value from effect_value
	var propertie_value = effect.effect_value
	
	# Apply the effect, modifing the respective property
	target_component.set(target_propertie, propertie_value)
	
	# Create the timer for the effect, and add it to scene
	var effect_time: Timer = Timer.new()
	effect_time.set_wait_time(effect.effect_duraction)
	add_child(effect_time)
	
	# Conect the signal, when the effect_time reach to zero and start it
	effect_time.timeout.connect(_on_effect_time_timeout.bind(effect_time))
	effect_time.start()
	
	#_effects_to_apply.erase(queued_effect)

func _on_effect_time_timeout(timer: Timer) -> void:
	print("effect timeout" + str(timer.get_instance_id()))
	# Remove the timer, since its not needed anymore
	timer.queue_free()

func remove_effect(effect_name: String, target_entity: Node) -> void:
	var entity_id: int = target_entity.get_instance_id()
