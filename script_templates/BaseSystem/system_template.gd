# meta-name: Brazuca System
# meta-description: Utilized as template to new nodes who extends from BaseSystem
# meta-default: true

extends BaseSystem

#class_name MySystem

## Do NOT override _init, utilize super() and begginin and set the target components groups with _component_requireds
## REMEMBER: The system will load every entity who have at least one component who belongs from at least one of the designed groups
func _init() -> void:
	super()
	
	#_components_requireds = ["MyComponentGroupA", "MyComponentGroupB"]


## Not obligated, in really, i may remove this in future
#func get_class_name():
#	return "MySystem"
