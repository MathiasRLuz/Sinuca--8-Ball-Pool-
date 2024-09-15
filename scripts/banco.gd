extends Node2D
var player_on_area : = false
var occupied := false

func _ready() -> void:
	$InteractIcon.visible = false
	
func _process(_delta: float) -> void:
	z_index = int(position.y)
	$SeatedChar.visible =  occupied		
	if occupied: 
		$InteractIcon.visible = false
	elif player_on_area:
		$InteractIcon.visible = true

func _input(event: InputEvent) -> void:
	if player_on_area and not occupied:
		if event.is_action_pressed("interact"):
			occupied = true				
			$"../Player".sentou(self)
			$"../Player".position = $SeatedChar.global_position

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_on_area = true
		


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		player_on_area = false
		$InteractIcon.visible = false
