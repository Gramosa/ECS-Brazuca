extends Node

## This is a base class that other systems can inherit from in an Entity-Component-System (ECS) architecture.
## It provides functionality for organizing entities and their components based on component groups.
## The derived systems should extend this class and:
## - Define their own required component groups in the `_components_requireds` variable on _init.
## - Do NOT override the _init() function (Utilize super() after define the required components)
## - MUST override the function get_class_name to return the apropriate name of the class (Not much important, only for raise warnings purposes)
class_name BaseSystem

## An array of component groups names that entities must belong to in order to be added to the `entities` dictionary.
## Each component must be in at least one of these groups to be considered by the system.
var _components_requireds: Array[String] = []

## Important to know, each entity in the scene_tree must have a unique name (maybe change the dictionary structure in future to fix that)
## And an entity cannnot have two components with same name AND type, but it can have the same type with different names, or same name with different types.
##
## The `entities` variable is a dictionary of lists with a specific nested structure:
##   - The first level is a dictionary where each key represents an entity name.
##   - The second level is a list with a fixed length of 2: [entity_node, {}].
##   - The third level is a dictionary where each key represents a component group name.
##   - The fourth level is a list of component nodes belonging to the corresponding group.
##
## In other words, the structure can be represented as:
##   { entity_name1: [ entity_node, { component_group1: [ component1, component2, ... ], component_group2: [...], ... } ],
##     entity_name2: [ entity_node, { component_group1: [ component1, component2, ... ], component_group2: [...], ... } ],
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
##   Player(name): [
##     CharacterBody2D(node),
##     {
##       HealthComponentGroup: [
##         Health(node)
##       ],
##       DamageComponentGroup: [
##         Damage(node),
##         ElementalDamage(node)
##       ]
##     }
##   ],
##   Enemy(name): [
##     Area2D(node),
##     {
##       HealthComponentGroup: [
##         EnemyHealth(node)
##       ],
##       MovementComponentGroup: [
##         EnemyMovement(node)
##       ]
##     }
##   ]
## }
var entities: Dictionary = {}

func get_class_name():
	return "BaseSystem"

func _init() -> void:
	add_to_group("Systems", true)

## Load the variable entities with the structure described up to entities variable
## Its recomended to add new entities to "entities" variable using this function, to maintain the dictionary structure
func _update_entity_with_component(entity: Node, component: Node, component_group: String) -> void:

	var entity_name: String = entity.get_name()
	
	# Verify if the entity already exist, the system will not load the same entity twice
	if entity_name in entities and component_group in entities[entity_name][1]:
		if entities[entity_name][1][component_group].has(component):
			# Component already exists, skip adding it again
			return
	
	# Check if the entity is already present in the entities dictionary
	# If the entity is not present, create a new entry with an empty component dictionary
	# In other words, create the 1° and 2° level, and the 3° empty one
	if entity_name not in entities:
		entities[entity_name] = [entity, {}]
		
	# Check if the component group is already present in the entity's component dictionary
	# In other words, add the component_group to fill the third level if the component_group is not there
	if component_group not in entities[entity_name][1]:
		entities[entity_name][1][component_group] = []
		
	# Add the component to the component list of the corresponding component group (4th level)
	entities[entity_name][1][component_group].append(component)
	
## Utilize if a system be added at runtime, to populate the entities variable
func load_entities_from_group(component_group: String):
	# Get all the nodes belonging to the specified component group
	var members_from_group: Array = get_tree().get_nodes_in_group(component_group)
	for component in members_from_group:
		# Find the closest parent node of the component that is of type Node2D
		var entity = get_closest_parent_from_type(component, "Node2D")
		
		_update_entity_with_component(entity, component, component_group)

## Check recursivaly if the parent of node inherits from a specifief type, if not check the grandparent, great_grandfather...
## If no one inherits from the specified parent_type the own node will be returned (argument "node")
## Important, does not need to inherity direct, but an ancestor must be from this parent_type. 
## For example, if parent_type arg are "Node2D", even a parent that are a CharacterBody2D will be considered a valid parent
## The parent_type arg must be a built-in class, described by ClassDB (for now)
func get_closest_parent_from_type(node: Node, parent_type: String) -> Node:
	assert(ClassDB.class_exists(parent_type), "The class name \"{0}\" passed as argument \"parent_type\" does not exist. For now only built-in classes works".format([parent_type]))
	var parent = node.get_parent()
	
	while parent != null:
		#if parent.get_class() == parent_type:
		if ClassDB.is_parent_class(parent.get_class(), parent_type):
			return parent
		else:
			# In other worlds, grandparent, great-grandfather
			# Will return the parent if have, but if there is not will return null.
			parent = parent.get_parent()
	
	push_warning("The node \"{0}\" does not have a parent who have \"{1}\" type as ancestor, the own node \"{0}\" will be returned instead".format([node, parent_type]))
	return node

# Called by each components inside "Components" group to each system in "Systems" group when the component is _ready(), anywhere in scene tree
# Used to add components at runtime
func _on_component_added(component: Node) -> void:
	for component_group in _components_requireds:
		if component.is_in_group(component_group):
			# Find the closest parent node of the component that is of type Node2D
			var entity = get_closest_parent_from_type(component, "Node2D")
			
			_update_entity_with_component(entity, component, component_group)

func _on_component_removed(component: Node) -> void:
	var entity: Node = get_closest_parent_from_type(component, "Node2D")
	var entity_name = entity.get_name()
	
	# if the entity are not in entities, the system will ignore the component remotion
	if entity_name not in entities:
		return
	
	# Check for each group required by the system if the component is part of these group
	for component_group in _components_requireds:
		if component.is_in_group(component_group):
			# It is not compatible the component be part of a component_group and this component group be inside _components_requireds
			# but the component is not inside entities variable
			if component_group not in entities[entity_name][1]:
				push_error(
					"Behaviour not expected: The component {0} is from component group {1} who are required by the system {2}, but during remotion from scene its not inside the entities variable. Probably due wrong changes on entities variable".format([component.get_name(), component_group, self.get_name()])
				)
				return
			# Remove the component from the entities
			entities[entity_name][1][component_group].erase(component)
			
			# Check if the component group have no more entities, if so remove the group from the entity inside entities
			if entities[entity_name][1][component_group].is_empty():
				entities[entity_name][1].erase(component_group)
				
				# Check if the entity have no more any component group, if so remove the entity from the system
				if entities[entity_name][1].is_empty():
					entities.erase(entity_name)


## Checks if the specified entity can be operated on by the system.
## This function verifies if the entity meets the requirements to be processed by the system, considering the components associated with the system's component groups.
##
## The function checks two main conditions:
##   1. The system must have the entity stored in its entities dictionary, indicating that the entity is relevant to the system's operations.
##   2. The entity must have at least one component from the specified component group associated with the system.
##
## Parameters:
##   - entity: The entity node to check operability for.
##   - component_group: The name of the component group that the entity's component should belong to.
##   - specific_component_name (optional): The specific name of the component (within the component group) to check for.
## Example Usage: 
##   if can_system_operate_entity(source_entity, "DamageComponentGroup"):
##       # Perform operation on the entities
func can_system_operate_entity(entity: Node, component_group: String, specific_component_name: String="") -> bool:
	var entity_name: String = entity.get_name()
	
	if entity_name not in entities:
		#push_warning("The entity {0} is not part of the system {1}, because this entity does not have any component from {2} groups. So the operation will be ignored".format([entity_name, self.get_name(), _components_requireds]))
		return false
	
	if component_group not in entities[entity_name][1]:
		#push_warning("The entity {0} is part of the system {1}, but there is not a component from the specific group {3} required to fullfit an specific operation. So the operation will be ignored".format([entity_name, self.get_name(), component_group]))
		return false
	
	if specific_component_name != "":
		if specific_component_name not in entities[entity_name][1][component_group]:
			push_warning("The component {0}, that belongs to the entity {1} is not part of the group {2}".format([specific_component_name, entity_name, component_group]))
			return false
	
	var number_of_components_from_same_group: int = len(entities[entity_name][1][component_group])
	if number_of_components_from_same_group == 0:
		push_warning("The system {0} somehow have the entity {1} with component group {2}, but the group is empty".format([self.get_name(), entity_name, component_group]))
		return false
	
	if number_of_components_from_same_group >= 2 and specific_component_name == "":
		push_warning("The entity '{0}' has multiple components from the group '{1}'. The system '{2}' cannot determine which component to use for the operation. Please specify a specific component name. The operation will be ignored.".format([entity_name, component_group, self.get_class_name()]))
		return false
	
	return true

## Work with can_system_operate_entity, this function will return the component instead of true or false
## Usualy used by the system to take the reference of the component
func get_commponent_from_entity(entity: Node, component_group: String, specific_component_name: String = ""):
	var entity_name: String = entity.get_name()
	if can_system_operate_entity(entity, component_group, specific_component_name) == true:
		## If passe the tests with specific_component_name equal to "", means there is only one component from the component_group
		if specific_component_name == "":
			return entities[entity_name][1][component_group][0]
		
		for component in entities[entity_name][1][component_group]:
			var component_name = component.get_name()
			if component_name == specific_component_name:
				return component
				
	return null
