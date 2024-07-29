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

#TODO: Filter the components
func get_component_from_entity():
	pass
