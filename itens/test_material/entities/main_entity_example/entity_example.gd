extends Node2D

# Called when the node enters the scene tree for the first time.
#@onready var damage_system: DamageSystem = get_node("../Systems/DamageSystem")
@onready var damage_system: DamageSystem =  get_node("%DamageSystem")
@onready var effect_system: EffectSystem = get_node("%EffectSystem")

func _input(event):
	"""Mudar no futuro a maneira de chamar a função do_damage, provavelmente usando sinais"""
	# The own DamageComponent will damage the HealthComponent, just for test purpose of the system
	if event.is_action_pressed("esquerda"):
		damage_system.do_damage(self, self)
	
	elif event.is_action_pressed("direita"):
		damage_system.do_damage(self, self, true)
	
	elif event.is_action_pressed("pular"):
		print(ClassDB.class_exists("HealthComponent"))
		print(damage_system.entities)
		

func _on_health_component_health_changed(new_health: int, behaviour: HealthComponent.CHANGE_BEHAVIOUR):
	if behaviour == HealthComponent.CHANGE_BEHAVIOUR.DECREASED:
		effect_system.queue_effect(self, self, "Endurance")
		print("levou dano")
	
	elif behaviour == HealthComponent.CHANGE_BEHAVIOUR.INCREASED:
		print("Curou")
	
	elif behaviour == HealthComponent.CHANGE_BEHAVIOUR.NOT_CHANGED:
		print("nada muda")
	
	print("vida atual: " + str(new_health))

func _on_health_component_health_depleted():
	self.hide()
	print("morreu")

func _on_health_component_health_recovered():
	self.show()
	print("reviveu")
