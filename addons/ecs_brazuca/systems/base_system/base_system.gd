extends Node

## This is a base class that other systems can inherit from in an Entity-Component-System (ECS) architecture.
## It provides functionality for organizing entities and their components based on component groups.
## The derived systems should extend this class and:
## - Define their own required component groups in the `_components_requireds` variable on _init.
## - Do NOT override the _init() function (Utilize super() after define the required components)
class_name BRZBaseSystem

## An array of component groups names that entities must belong to in order to be added to the `entities` dictionary.
## Each component must be in at least one of these groups to be considered by the system.
var _allowed_components: Array[String] = []

## Important to know: an entity can not have two components with same name AND type, but it can have the same type with different names, or same name with different types.
## An entity can have any number of components.
##
## The `entities` variable is a dictionary of lists with a specific nested structure:
##   - The first level is a dictionary where each key represents the entity id, by the built-in godot function get_instance_id().
##   - The second level is a list with a fixed length of 2: [entity_node, {}].
##   - The third level is a dictionary where each key represents a component group name.
##   - The fourth level is a list of component nodes belonging to the corresponding group.
##
## In other words, the structure can be represented as:
##   { entity_id1: [ entity_node, { component_class1: [ component1, component2, ... ], component_class2: [...], ... } ],
##     entity_id2: [ entity_node, { component_class1: [ component1, component2, ... ], component_class2: [...], ... } ],
##     ... }
##
## Let's consider an example node tree with entities and their components organized into component groups specified in `_components_requireds`:
##
## Example:
## Game
##   Player: CharacterBody2D
##     Health: HealthComponent
##     Damage: DamageComponent
##     ElementalDamage: DamageComponent
##   Enemy: Area2D
##     EnemyHealth: HealthComponent
##     EnemyMovement: MovementComponent
##
## Here's the resulting `entities` variable:
## {
##   Player(id): [
##     CharacterBody2D(node),
##     {
##       "HealthComponentGroup": [
##         Health(node)
##       ],
##       "DamageComponentGroup": [
##         Damage(node),
##         ElementalDamage(node)
##       ]
##     }
##   ],
##   Enemy(id): [
##     Area2D(node),
##     {
##       "HealthComponentGroup": [
##         EnemyHealth(node)
##       ],
##       "MovementComponentGroup": [
##         EnemyMovement(node)
##       ]
##     }
##   ]
## }
static var entities: Dictionary = {}

# Called by each components inside "Components" group to each system in "Systems" group when the component is _ready(), anywhere in scene tree
# Used to add components at runtime
static func register_component(component: BRZBaseComponent) -> bool:
	var entity: Node = component._entity
	if entity == null:
		push_error("Component does not have a parent, so it cannot be registered")
		return false
		
	var entity_id: int = entity.get_instance_id()
	var component_class: String = component.get_class_name()
	
	# Check if the entity is already present in the entities dictionary
	# If the entity is not present, create a new entry with an empty component dictionary
	# In other words, create the 1° and 2° level, and the 3° empty one
	if entity_id not in entities:
		entities[entity_id] = {}
		
	# Check if the component group is already present in the entity's component dictionary
	# In other words, add the component_class to fill the third level if the component_class is not there
	if component_class not in entities[entity_id]:
		entities[entity_id][component_class] = []
	
	# Verify if the entity already exist, the system will not load the same entity twice
	if entities[entity_id][component_class].has(component):
		return false
	
	# Add the component to the component list of the corresponding component group (4th level)
	entities[entity_id][component_class].append(component)
	return true
	
static func unregister_component(component: BRZBaseComponent) -> bool:
	var entity: Node = component._entity
	if entity == null:
		return false
	
	var entity_id: int = entity.get_instance_id()
	if entity_id not in entities:
		return false
	
	var component_class: String = component.get_class_name()
	
	# It is not compatible, if the component be part of a component_class and this component group be inside _components_requireds
	# but the component is not inside entities variable
	if component_class not in entities[entity_id]:
		push_error(
			"Behaviour not expected: The component {0} is from component group {1}, but during remotion from scene its not inside the entities variable. Probably due wrong changes on entities variable".format([component.get_name(), component_class])
		)
		return false
	
	# Remove the component from the entities
	entities[entity_id][component_class].erase(component)
	
	# Check if the component group have no more entities, if so, remove the group from the entity inside entities
	if entities[entity_id][component_class].is_empty():
		entities[entity_id].erase(component_class)
		
		# Check if the entity have no more any component group, if so remove the entity from the system
		if entities[entity_id].is_empty():
			entities.erase(entity_id)
	return true

## Checks if the specified entity can be operated by the system.
## This function verifies if the entity meets the requirements to be processed by the system, considering the components associated with the system's component classes.
##
## The function checks two main conditions:
##   1. The system must have the entity stored in its entities dictionary, indicating that the entity is relevant to the system's operations.
##   2. The entity must have at least one component from the specified component group associated with the system.
##
## Parameters:
##   - entity: The entity node to check operability for.
##   - component_class: The name of the component group that the entity's component should belong to.
##   - specific_component_name (optional): The specific name of the component (within the component group) to check for.
## Example Usage: 
##   if can_system_operate_entity(source_entity, "DamageComponentGroup"):
##       # Perform operation on the entities
static func can_system_operate_entity(entity: Node, component_class: String, specific_component_name: String="") -> bool:
	var entity_id: int = entity.get_instance_id()
	
	if entity_id not in entities:
		#push_warning("The entity {0} is not part of the system {1}, because this entity does not have any component from {2} groups. So the operation will be ignored".format([entity.get_name(), self.get_name(), _components_requireds]))
		return false
	
	if component_class not in entities[entity_id]:
		#push_warning("The entity {0} is part of the system {1}, but there is not a component from the specific group {3} required to fullfit an specific operation. So the operation will be ignored".format([entity.get_name(), self.get_name(), component_class]))
		return false
	
	if specific_component_name != "":
		# take all names of the components from component_class that belongs to entity
		var components_names = []
		for component in entities[entity_id][component_class]:
			components_names.append(component.get_name())
		
		# check if the given specific_component_name is part of the group
		if specific_component_name not in components_names:
			BRZErr.warning(
				BRZErrContext.new(BRZErrContext.CODE.COMPONENT_NOT_FOUND)
				.set_message("The component with name '{0}' was not found".format([specific_component_name]))
				.set_details("The entity {0}, does not have any component with the specified name from class {1}".format([entity.get_name(), component_class]))
				.set_proposed_solution("Check if the name of the component was correctly written, or if the designed class is correct")
			)
			return false
	
	var number_of_components_from_same_class: int = len(entities[entity_id][component_class])
	if number_of_components_from_same_class == 0:
		push_error("Behaviour not expected: The component class {0} is registered for the entity {0}, but does not have any component".format([component_class, entity.get_name()]))
		return false
	
	if number_of_components_from_same_class >= 2 and specific_component_name == "":
		push_warning("The entity '{0}' has multiple components from the class '{1}'. It cannot determine which component to use for the operation. Please specify a specific component name. The operation will be ignored.".format([entity.get_name(), component_class]))
		return false
	
	return true

## Work with can_system_operate_entity function, this function will return the component instead of true or false
## Usualy used by the system to take the reference of the component
static func get_component_from_entity(entity: Node, component_class: String, specific_component_name: String = "") -> BRZBaseComponent:
	var entity_id: int = entity.get_instance_id()
	if can_system_operate_entity(entity, component_class, specific_component_name):
		## If passes the tests with specific_component_name equal to "", means there is only one component from the component_class
		if specific_component_name == "":
			return entities[entity_id][component_class][0]
		
		for component in entities[entity_id][component_class]:
			var component_name = component.get_name()
			if component_name == specific_component_name:
				return component
	
	return null
	
