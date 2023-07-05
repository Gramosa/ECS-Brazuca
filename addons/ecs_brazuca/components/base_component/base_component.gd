extends Node

## This is a base class that other components can inherit from in an Entity-Component-System (ECS) architecture.
## The signals of BaseComponent and inherited classes was developed to comunicate with the entity.
## But you are free to conect the signals anywhere, but I do not recommend conect between components, to avoid unexpected behaviours (for now)
## This provides functionality to comunicate automatically the systems when the component are _ready or was removed
## The derived components must extends this class and:
## Do NOT override the functions _init, _ready and _exit_tree (Utilize super() in the beggining of these functions)
class_name BaseComponent

"""
Talvez nunca sera usado, com a implementação atual dos sistemas, os componentes não precisam se conectar de forma alguma com outros componentes
Mas vou manter esse enum aqui, por enquanto
"""
## Passed as arguent when a signal is emitted and must be directed to a component
enum ComponentTargetType {
	CONTAINERT, 
	IDENTITY, 
	HEALTH,
	DAMAGE,
	}

## General warnings used for the components to notify when something are not configured, the node will work 
const COMPONENT_WARNINGS = {
	"COMPONENT WARNING 1": "The Signal {0} from component {1} is not connected, the component still works, but for this specific signal there isn't any purpose for the parent node",
	"COMPONENT WARNING 2": "There is not any System in the scene_tree(), the component will not work properly, since there is not a system to manage it",
}

## If true warnings will not be emitted if a signal are not connected
@export var ignore_signal_warnings: bool = false

@export_group("ID Data")
## If the data will be loaded from a IdentityComponent, it will ignore completly the exported values, and will load at runtime the values
@export var take_from_id_component: bool = false

## The IdentityComponent node, its preferable to be a simbling. The IdentityComponent load the data from the JSONS files at runtime execution
@export var identity_component: IdentityComponent

## Used by get_closest_parent_from_type to search for the parent
var _target_entity_type: String = "Node2D"

## Used for the components as a workaround to get_class() problem (if necessary)
func get_class_name():
	return "BaseComponent"

func _init() -> void:
	add_to_group("Components", true)

func _ready() -> void:
	# Once the component is _ready() it will call Systems inside the Systems group and pass self as argument
	if get_tree().has_group("Systems") == true:
		get_tree().call_group("Systems", "_on_component_added", self)
	else:
		push_warning(COMPONENT_WARNINGS["COMPONENT WARNING 2"])

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
			parent = parent.get_parent()
	
	push_warning("The node \"{0}\" does not have a parent who have \"{1}\" as ancestor, the own node \"{0}\" will be returned instead".format([node, parent_type]))
	return node

func _exit_tree() -> void:
	# If there is a system in the tree, it will comunicate each system about the remotion, so each system can deal with this remotion
	if get_tree().has_group("Systems") == true:
		get_tree().call_group_flags(SceneTree.GROUP_CALL_UNIQUE, "Systems", "_on_component_removed", self)
	else:
		push_warning(COMPONENT_WARNINGS["COMPONENT WARNING 2"])
	
