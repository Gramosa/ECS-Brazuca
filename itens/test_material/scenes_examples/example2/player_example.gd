extends Area2D

const VELOCITY: float = 200.0
const PROJECTILE_SCENE: PackedScene = preload("projectile.tscn")

var direction: Vector2

# Usado para determinar a direcao em que o projetil sera lancado
var fancing_direction: Vector2 = Vector2(1, 0) # padrao direita

func _process(delta: float) -> void:
	# Alterna a direcao no eixo x
	direction.x = Input.get_axis("esquerda", "direita")
	self.position += direction * VELOCITY * delta

	# Muda a direcao do projetil, caso o jogador nao esteja parado.
	if direction != Vector2.ZERO:
		fancing_direction = direction
	
	# Emite o projetil se "pular" for clicado, deveria mudar o nome mas eh... pular = atirar
	if Input.is_action_just_pressed("pular"):
		_emit_projectile()

func _emit_projectile() -> void:
	var projectile_instance: Area2D = PROJECTILE_SCENE.instantiate()
	# Configura o projetil
	projectile_instance.setup(fancing_direction, self)
	projectile_instance.global_position = self.global_position
	# Obviamente, não é a melhor alternativa, mas serve nesse exemplo.
	get_parent().add_child(projectile_instance)
