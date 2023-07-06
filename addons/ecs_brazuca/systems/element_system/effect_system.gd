extends BaseSystem

class_name EffectSystem

## Do NOT override _init, utilize super() and begginin and set the target components groups with _component_requireds
## REMEMBER: The system will load every entity who have at least one component who belongs from at least one of the designed groups
func _init() -> void:
	super()
	
	_components_requireds = ["EffectComponentGroup"]


func get_class_name():
	return "EffectSystem"

