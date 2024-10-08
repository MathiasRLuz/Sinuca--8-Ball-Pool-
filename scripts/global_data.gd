extends Node

enum LookingDirection {RIGHT, LEFT, UP, DOWN}
enum Npcs {NPC, DOMOVOY, SLIME, ESQUELETO, GOBLIN, CICLOPE, BRUXA, GOLEM, MEDUSA, PRINCIPE, PRINCESA, FANTASMA, MINOTAURO}
enum Falas {PRE_BATALHA, VITORIOSO, DERROTADO, GENERICA, }

enum EnemyDififultyVariables {power_probability, force_scale, precision, error_radius, max_shot_angle, min_score, risky, crit1, crit2, crit3, crit4, crit5, crit6}

var bots := []
var current_bots_ids = [0,1]
var matchups := []
var matchup_id = 0

var EnemyDificulty = {
	Npcs.NPC : {		
		EnemyDififultyVariables.power_probability : 0,
		EnemyDififultyVariables.force_scale : 0.95879989266396, 
		EnemyDififultyVariables.precision : 1, 
		EnemyDififultyVariables.error_radius : 9.38956937789917, 
		EnemyDififultyVariables.max_shot_angle : 53.4195175170898,  
		EnemyDififultyVariables.min_score : -49.2016143798828, 
		EnemyDififultyVariables.risky: 1, 
		EnemyDififultyVariables.crit1 : 18.2738933563232, 
		EnemyDififultyVariables.crit2 : 107.540453344584,  
		EnemyDififultyVariables.crit3 : 286.130897557735, 
		EnemyDififultyVariables.crit4 : 543.720483505726, 
		EnemyDififultyVariables.crit5 : 840.666850036383, 
		EnemyDififultyVariables.crit6 : 1000,
	},
	
	Npcs.PRINCIPE : {
		EnemyDififultyVariables.power_probability : 1,
		EnemyDififultyVariables.force_scale : 1,
		EnemyDififultyVariables.precision : 1,
		EnemyDififultyVariables.error_radius : 5,
		EnemyDififultyVariables.max_shot_angle : 60,
		EnemyDififultyVariables.min_score : 0,
		EnemyDififultyVariables.risky: 1,
		EnemyDififultyVariables.crit1 : 2,
		EnemyDififultyVariables.crit2 : 100,
		EnemyDififultyVariables.crit3 : 200,
		EnemyDififultyVariables.crit4 : 250,
		EnemyDififultyVariables.crit5 : 500,
		EnemyDififultyVariables.crit6 : 1000
	}, 
	Npcs.PRINCESA : {
		EnemyDififultyVariables.power_probability : 0,
		EnemyDififultyVariables.force_scale : 1,
		EnemyDififultyVariables.precision : 1,
		EnemyDififultyVariables.error_radius : 5,
		EnemyDififultyVariables.max_shot_angle : 60,
		EnemyDififultyVariables.min_score : 0,
		EnemyDififultyVariables.risky: 1,
		EnemyDififultyVariables.crit1 : 2,
		EnemyDififultyVariables.crit2 : 100,
		EnemyDififultyVariables.crit3 : 200,
		EnemyDififultyVariables.crit4 : 250,
		EnemyDififultyVariables.crit5 : 500,
		EnemyDififultyVariables.crit6 : 1000
	}, 
	Npcs.SLIME : {
		EnemyDififultyVariables.power_probability : 0,
		EnemyDififultyVariables.force_scale : 0.8,
		EnemyDififultyVariables.precision : 0.95,
		EnemyDififultyVariables.error_radius : 5,
		EnemyDififultyVariables.max_shot_angle : 60,
		EnemyDififultyVariables.min_score : 0,
		EnemyDififultyVariables.risky: 0,
		EnemyDififultyVariables.crit1 : 5,
		EnemyDififultyVariables.crit2 : 100,
		EnemyDififultyVariables.crit3 : 200,
		EnemyDififultyVariables.crit4 : 500,
		EnemyDififultyVariables.crit5 : 750,
		EnemyDififultyVariables.crit6 : 1000
	},
	Npcs.MINOTAURO : {
		EnemyDififultyVariables.power_probability : 0,
		EnemyDififultyVariables.force_scale : 1.41252899169922, 
		EnemyDififultyVariables.precision : 0.97707498073578, 
		EnemyDififultyVariables.error_radius : 1.7042647600174, 
		EnemyDififultyVariables.max_shot_angle : 88.3777362942695, 
		EnemyDififultyVariables.min_score : -102.991931340098, 
		EnemyDififultyVariables.risky: 1, 
		EnemyDififultyVariables.crit1 : 18.2738933563232, 
		EnemyDififultyVariables.crit2 : 75.935868692398, 
		EnemyDififultyVariables.crit3 : 206.028515652381, 
		EnemyDififultyVariables.crit4 : 543.64482998848, 
		EnemyDififultyVariables.crit5 : 500.031824212521, 
		EnemyDififultyVariables.crit6 : 759.133443248272
	},
}

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

var current_enemy : Enemy = null
var current_enemy_name : String
var enemy_original_position : Vector2
var enemy_can_move: bool
var player_spawn_position: Vector2
var player_spawn_was_set := false
var player_looking_dir := LookingDirection.RIGHT
var last_scene_before_battle : String
var enemy_pos : Vector2
var defeated_enemies := []
var faced_enemies := []

func enemy_defeated(enemy_name):
	defeated_enemies.append(enemy_name)

func enemy_faced(enemy_name):
	faced_enemies.append(enemy_name)

func set_new_enemy(_enemy,_enemy_original_position,_enemy_can_move,_current_enemy_name):
	current_enemy = _enemy
	enemy_original_position = _enemy_original_position
	enemy_can_move = _enemy_can_move
	current_enemy_name = _current_enemy_name
func clear_enemy_data():
	current_enemy = null	
	enemy_original_position = Vector2.ZERO
	enemy_can_move = false
	current_enemy_name = ""
	
func get_current_enemy():
	return [current_enemy,enemy_original_position,enemy_can_move,current_enemy_name]
	
func set_player_spawn(pos,dir):
	player_spawn_position = pos
	player_spawn_was_set = true
	player_looking_dir = dir


func clear_bots():
	bots = []
	
func get_bots():
	return bots

func set_bots(new_bots):
	bots = new_bots
	
func add_bot(bot):
	bots.append(bot)
	
func get_bots_ids():
	return current_bots_ids
	
func set_bots_ids(bots_ids):
	current_bots_ids = bots_ids

func set_matchups(_matchups):
	matchups = _matchups
