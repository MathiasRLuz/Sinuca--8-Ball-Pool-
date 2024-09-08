extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var transition_node: CanvasLayer = $Transition

func _ready() -> void:
	if GlobalData.player_spawn_was_set:
		transition_node._set_animation(transition_node.Animations.HOR_CUT, 1.2,"transition_out") #PIXELS, SPOT_PLAYER, SPOT_CENTER, VER_CUT, HOR_CUT
		player.position = GlobalData.player_spawn_position
		match GlobalData.player_looking_dir:
			GlobalData.LookingDirection.RIGHT:
				player.sprite.animation = "walk_right"
			GlobalData.LookingDirection.LEFT:
				player.sprite.animation = "walk_left"
