extends Sprite2D



@export var descendo := true
@export var direction := GlobalData.LookingDirection.RIGHT
@export var player_spawn_position: Vector2
@export var next_scene_path : String

@onready var transition_node = $"../Transition"
@onready var player: CharacterBody2D = $"../Player"


func _on_area_2d_body_entered(body: Node2D) -> void:	
	if body == player:		
		player.set_physics_process(false)
		player.z_index = 4096
		if descendo:
			if direction == GlobalData.LookingDirection.RIGHT: # descendo pra direita
				player.animation_player.play("down_stairs_right")
			else: # descendo pra esquerda
				player.animation_player.play("down_stairs_left")
		else:
			if direction == GlobalData.LookingDirection.RIGHT: # subindo pra direita
				player.animation_player.play("up_stairs_right")
			else: # subindo pra esquerda
				player.animation_player.play("up_stairs_left")
		transition_node._set_animation(transition_node.Animations.HOR_CUT, 1.2,"transition_in") #PIXELS, SPOT_PLAYER, SPOT_CENTER, VER_CUT, HOR_CUT
		await get_tree().create_timer(2).timeout
		GlobalData.set_player_spawn(player_spawn_position,direction)
		GlobalData.clear_enemy_data()
		player.set_physics_process(true)
		get_tree().change_scene_to_file(next_scene_path)
		
