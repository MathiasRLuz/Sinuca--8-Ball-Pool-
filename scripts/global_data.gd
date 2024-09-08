extends Node

enum Npcs {NPC, DOMOVOY, BRUXA}
enum Falas {PRE_BATALHA, VITORIOSO, DERROTADO, GENERICA, }
var Texts = {
	Npcs.NPC : {
		Falas.PRE_BATALHA: [
			["Oi, sou um NPC", "Hi, I'm an NPC"],
			["AAAA, teste", "AAAA, test"],
		]
	}, 
	Npcs.BRUXA : {
		Falas.PRE_BATALHA: [
			["Oi, sou a Bruxa", "Hi, I'm the Witch"],
			["HAHAHAHA", "HAHAHAHA"],
		]
	}
}

var current_enemy : Enemy
var enemy_original_position : Vector2
var enemy_can_move: bool
var player_spawn_position: Vector2
var player_spawn_was_set := false

func set_new_enemy(_enemy,_enemy_original_position,_enemy_can_move):
	current_enemy = _enemy
	enemy_original_position = _enemy_original_position
	enemy_can_move = _enemy_can_move
	
func clear_enemy_data():
	current_enemy = null
	enemy_original_position = Vector2.ZERO
	enemy_can_move = false
	
func get_current_enemy():
	return [current_enemy,enemy_original_position,enemy_can_move]
	
func set_player_spawn_position(pos):
	player_spawn_position = pos
	player_spawn_was_set = true
