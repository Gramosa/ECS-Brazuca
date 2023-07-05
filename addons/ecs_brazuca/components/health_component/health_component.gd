@icon("health_component_icon.svg")
extends BaseComponent

## HealthComponent are a component who deal with health every entity who can receive damage must own at least one
## This component is able to emit a health_points node (who have a short life, just to spam the actual health)
class_name HealthComponent

enum HealthChangeBehaviour {DAMAGED, HEALED, HEALTH_NOT_CHANGED}

## Emited when the health reach to 0 for the first time, this means when the entity become dead (in other words).
signal health_depleted
## Emitted when the health increase from 0 to any value, this means when the entity revive (in other words).
signal health_recovered
## Emited every call of update_health(), so does not change the property health directly, use the method update_health().
signal health_changed(new_health: int, behaviour: HealthChangeBehaviour)

const health_points_path: PackedScene = preload("health_points.tscn")

@export_group("Health")
## The max_health value, during runtime change this value using the method change_max_health()
@export var max_health: int:
	set(new_max_health):
		if new_max_health < 0:
			max_health = 0
		else:
			max_health = new_max_health

## The initial value for the entity, clamped to be at max the max_health
@export var initial_health: int:
	set(new_initial_health):
		initial_health = clamp(new_initial_health, 0, max_health)

@export_group("Health Point Colors")
## Display the actual health everytime update_health() are called, its just a visual number.
@export var visible_health_points: bool = true

## Its the color who appear when the health is not changed, for example, when it takes a damage equal to 0
## Only used when visible_health_points are true
@export var color_nothing_changed: Color = Color.WHITE

## Its the color who appear when the health is damaged
## Only used when visible_health_points are true
@export var color_damaged: Color = Color.RED

## Its the color who appear when the health is healed, if visible_health_points be true
## Only used when visible_health_points are true
@export var color_healed: Color = Color.GREEN

## Does NOT change health directly, utilize update_health.
var health: int

func _init():
	super()
	
	_target_entity_type = "Node2D"
	add_to_group("HealthComponentGroup", true)

func get_health() -> int:
	return health

func _ready() -> void:
	super()
	
	#Verify if the signals was connected
	if ignore_signal_warnings == false:
		verify_connections()

	health = initial_health

# Verify if the necessary connections was made, can be by editor or before the call for verify_connections in _ready()
func verify_connections() -> void:
	if len(health_depleted.get_connections()) == 0:
		push_warning(COMPONENT_WARNINGS["COMPONENT WARNING 1"].format([health_depleted.get_name(), self.get_name()]))
	
	if len(health_recovered.get_connections()) == 0:
		push_warning(COMPONENT_WARNINGS["COMPONENT WARNING 1"].format([health_recovered.get_name(), self.get_name()]))
	
	if len(health_changed.get_connections()) == 0:
		push_warning(COMPONENT_WARNINGS["COMPONENT WARNING 1"].format([health_changed.get_name(), self.get_name()]))

func update_health(damage : int) -> void:
	var new_health = clamp(health - damage, 0, max_health)
	var health_behaviour: HealthChangeBehaviour
	
	# If the new_health be 0 and the previous health was different than 0, this means the entity just died
	if new_health == 0 and health != 0:
		health_depleted.emit()
	
	elif new_health > 0 and health == 0:
		health_recovered.emit()
	
	# If the new_health are high than the health, its mean a healing
	if new_health > health:
		health_behaviour = HealthChangeBehaviour.HEALED

	# If the new_health be equal to the health, nothing will change
	elif new_health == health:
		health_behaviour = HealthChangeBehaviour.HEALTH_NOT_CHANGED
	
	# If the new_health is lower than the previuous one	
	else:
		health_behaviour = HealthChangeBehaviour.DAMAGED
	
	health_changed.emit(new_health, health_behaviour)
	health = new_health
	
	if visible_health_points == true:
		show_health_points(health_behaviour)

func show_health_points(health_behaviour: HealthChangeBehaviour) -> void:
	
	var health_points: Node2D = health_points_path.instantiate()
	var closest_node2d_parent = get_closest_parent_from_type(self, "Node2D")
	# If its equal than self, means there is not a parent who inherits from Node2D
	# So the transform is not visible, meaning there is not a position to display the health points
	if closest_node2d_parent != self:
		var health_points_color: Color
		# The color of health_points will be defined according the health_behaviour
		match health_behaviour:
			HealthChangeBehaviour.HEALED:
				health_points_color = color_healed
				
			HealthChangeBehaviour.HEALTH_NOT_CHANGED:
				health_points_color = color_nothing_changed
			
			HealthChangeBehaviour.DAMAGED:
				health_points_color = color_damaged
		
		health_points.setup(health, health_points_color)
		closest_node2d_parent.add_child(health_points)
	else:
		push_warning("The component {0} doesn't have an ancetor who inherits from Node2D, so the health points cannot be visible. Consider setting visible_health_points to false".format(self.get_name()))
