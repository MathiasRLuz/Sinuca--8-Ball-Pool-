extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var movement_speed:= 18000.0
var character_direction : Vector2

enum States {IDLE, MOVE, SENTADO}
var currentState = States.IDLE
var banco : Node2D

func _physics_process(delta: float) -> void:
	handle_state_transitions()
	perform_state_actions(delta)
	move_and_slide()
	z_index = int(position.y)	
	
func handle_state_transitions():
	if Input.is_action_pressed("up") or Input.is_action_pressed("down") or Input.is_action_pressed("left") or Input.is_action_pressed("right"):
		currentState = States.MOVE
	else:		
		currentState = States.IDLE
		

func sentou(_banco):
	visible = false
	set_physics_process(false)
	banco = _banco
	await get_tree().create_timer(0.1).timeout
	currentState = States.SENTADO

func _input(event):
	if currentState == States.SENTADO and (event.is_action_pressed("up") or event.is_action_pressed("down") or event.is_action_pressed("left") or event.is_action_pressed("right") or event.is_action_pressed("interact")):
		banco.occupied = false
		visible = true
		set_physics_process(true)
		

func perform_state_actions(delta):
	match currentState:
		States.MOVE:
			character_direction.x = Input.get_axis("left","right")
			character_direction.y = Input.get_axis("up","down")
			character_direction = character_direction.normalized()
			
			if character_direction.x < 0 && character_direction.y == 0:
				sprite.animation = "walk_left"
			elif character_direction.x > 0 && character_direction.y == 0: 
				sprite.animation = "walk_right"
			elif character_direction.y < 0: 
				sprite.animation = "walk_up"
			elif character_direction.y > 0: 
				sprite.animation = "walk_down"
			velocity = character_direction * movement_speed * delta
			sprite.play()
			
		States.IDLE:
			velocity = velocity.move_toward(Vector2.ZERO, movement_speed * delta)
			sprite.stop()
