extends Node2D
@onready var player: CharacterBody2D = $"../../Player"
var objs_na_area := []
@export var look_at_player := true
@export var kids_sprites : Array[Kid]
var closest_kid : Kid = null
var current_dialogue : Control = null
func _on_area_2d_body_entered(body: Node2D) -> void:
	objs_na_area.append(body)



func _on_area_2d_body_exited(body: Node2D) -> void:
	objs_na_area.erase(body)

func _input(event):
	if objs_na_area.count(player) > 0:
		if event.is_action_pressed("interact"):
			if closest_kid != null:
				closest_kid.talk()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:		
	
	if objs_na_area.count(player) > 0:
		#interact_icon.visible = true
		if look_at_player:
			look_to()
	else:
		for kid in kids_sprites:
			kid.dialogue.visible = false
			kid.interact_icon.visible = false
		

func look_to():
	var smallest_distance = INF
	for kid in kids_sprites:
		kid.interact_icon.visible = false
		var look_dir = (player.global_position-kid.global_position).normalized()
		var distance = player.global_position.distance_to(kid.global_position)
		if distance < smallest_distance:
			smallest_distance = distance
			if closest_kid != kid:
				closest_kid = kid
				current_dialogue = closest_kid.dialogue
		if abs(look_dir.x) > abs(look_dir.y): # olhando para os lados
			if look_dir.x > 0: # olhando para a direita
				kid.frame_coords = Vector2(0,3) # down, up, left, right
			elif look_dir.x < 0: # olhando para a esquerda
				kid.frame_coords = Vector2(0,2) # down, up, left, right
		elif abs(look_dir.x) < abs(look_dir.y): # olhando para cima/baixo
			if look_dir.y > 0: # olhando para baixo
				kid.frame_coords = Vector2(0,0) # down, up, left, right
			elif look_dir.y < 0: # olhando para cima
				kid.frame_coords = Vector2(0,1) # down, up, left, right
	closest_kid.interact_icon.visible = true
