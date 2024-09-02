@tool
extends Node

## This is a base class that other components can inherit from in an Entity-Component-System (ECS) architecture.
## The signals of BaseComponent and inherited classes was developed to comunicate with the entity.
## But the signals can be connected anywhere
## This provides functionality to comunicate automatically the systems when the component are _ready or was removed
## The derived components must extends this class and:
## Do NOT override the functions _enter_tree and _exit_tree (Utilize super() in the beggining of these functions)
class_name BRZBaseComponent

## A general signal designed to be emitted when a proerty are depleted
#signal property_depleted(property: String)

## A general signal designed to be emitted when a proerty are recovered
#signal property_recovered(property: String)

## A general signal designed to be emitted when a proerty is changed
signal property_changed(property: String, old_value: float, new_value: float)

## If true warnings will not be emitted if a signal are not connected
#@export var ignore_signal_warnings: bool = false

## Used by get_closest_parent_from_type to search for the parent, check get_closest_parent_from_type()
@export var target_entity_type: String = "Node2D":
	set(value):
		target_entity_type = value

## Actually the entity who belongs this component, does not modify direct, it are always updated automatically in the _enter_tree()
## check get_closest_parent_from_type()
var _entity: Node = null
var __class_name = get_script().get_global_name()

func get_class_name() -> String:
	return __class_name

func _ready() -> void:
	assert(ClassDB.class_exists(target_entity_type), "The class {0} does not exist".format([target_entity_type]))

func _to_string() -> String:
	var txt: String = get_name()
	txt += "| {0}".format([get_class_name()])
	if _entity != null:
		txt += "| {0}".format([_entity.get_name()])
	else:
		txt += "| NO ENTITY"
	
	return txt

## Check recursivaly if the parent of node inherits from a specified type, if not, check the grandparent, great_grandfather...
## If no one inherits from the specified parent_type the own node will be returned (argument "node")
## Important, does not need to inherity direct, but an ancestor must be from this parent_type. 
## For example, if parent_type arg are "Node2D", even a parent that are a CharacterBody2D will be considered a valid parent
## The parent_type arg must be a built-in class, described by ClassDB (for now)
func get_closest_parent_from_type(parent_type: String) -> Node:
	var parent = self.get_parent()
	
	while parent != null:
		#if parent.get_class() == parent_type:
		if ClassDB.is_parent_class(parent.get_class(), parent_type):
			return parent
		
		parent = parent.get_parent()
	
	push_warning("The node \"{0}\" does not have a parent who have \"{1}\" as ancestor".format([self, parent_type]))
	return null

func _enter_tree() -> void:
	_entity = get_closest_parent_from_type(target_entity_type)
	
	if not Engine.is_editor_hint():
		BRZBaseSystem.register_component(self)

func _exit_tree() -> void:
	# If there is a system in the tree, it will comunicate each system about the remotion, so each system can deal with this remotion
	if not Engine.is_editor_hint():
		BRZBaseSystem.unregister_component(self)

## An generic alternastive to modify an property, impoortant to note, it may ignore specicifc methods
## i.e update_health from health component
func update_property(property: String, new_value: float) -> Error:
	var old_value: float = self.get(property)
	
	if old_value == null:
		BRZErr.hard_error(
			BRZErrContext.new(BRZErrContext.CODE.COMPONENT_PROPERTY_NOT_FOUND)
			.set_message("The property '{0}' does not exist on the component '{1}'".format([property, self]))
			.set_proposed_solution("Check if you typed the property name correctly")
		)
		return FAILED
	
	property_changed.emit(property, old_value, new_value)
	self.set(property, new_value)
	
	return OK
