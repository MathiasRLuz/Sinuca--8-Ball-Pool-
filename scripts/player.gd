extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var movement_speed:= 18000.0
var character_direction : Vector2

enum States {IDLE, MOVE}
var currentState = States.IDLE

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
