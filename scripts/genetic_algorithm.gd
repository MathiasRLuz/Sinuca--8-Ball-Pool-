extends Node

var num_bots = 3
var bots_fitness := []
enum estilo_de_jogo {AGRESSIVO, CAUTELOSO, FACIL, DIFICIL}
var rng = RandomNumberGenerator.new()
@export var start_ga := false
@export var estilo_bot : estilo_de_jogo
var weights = {
	estilo_de_jogo.AGRESSIVO : [15,-1,8,-3], # vitorias,tacadas,pontos,faltas
	estilo_de_jogo.CAUTELOSO : [7,-3,3,-5],
	estilo_de_jogo.FACIL : [5,-1,4,1],
	estilo_de_jogo.DIFICIL : [10,-2,6,-5]
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	GlobalData.clear_bots()
	for i in range(num_bots):
		GlobalData.add_bot(create_bot())
		bots_fitness.append(0) 	
	GlobalData.set_matchups(create_matchups())
	if start_ga: start_camp()

func start_camp():
	GlobalData.matchup_id = 0
	get_tree().change_scene_to_file("res://scenes/camp_bots.tscn")

func new_generation():
	print("New generation")
	print(bots_fitness)
	# Aplica elitismo
	print(GlobalData.get_bots())
	var new_generation = apply_elitism(GlobalData.get_bots(), bots_fitness, 1)
	print(len(new_generation()))
	print(new_generation())
	print(select_parents(bots_fitness))

func apply_elitism(population: Array, fitness_array: Array, num_elites: int) -> Array:
	# Cria uma cópia da população ordenada pelo fitness (do maior para o menor)
	var elite_indices = []
	for i in range(fitness_array.size()):
		elite_indices.append([fitness_array[i], i])
	
	# Ordena pelos valores de fitness de forma crescente
	elite_indices.sort()

	# Inverte a lista para ordem decrescente (maior fitness primeiro)
	elite_indices.reverse()
	
	# Seleciona os 'num_elites' melhores indivíduos
	var elites := []
	for i in range(num_elites):
		var elite_index = elite_indices[i][1]  # Índice do melhor indivíduo
		elites.append(population[elite_index])  # Adiciona o melhor indivíduo na nova geração
	
	return elites

func eval_bot(bot, stats):	
	print(bot, ": ", stats)
	for i in len(stats):
		bots_fitness[bot] += stats[i] * weights[estilo_bot][i]
	print(bots_fitness[bot])
	
func eval_fitness():
	for bot in bots_fitness:
		pass

func create_matchups():
	var matchups = []
	for i in range(num_bots):
		for j in range(i + 1, num_bots):
			matchups.append([i, j])
	return matchups

func create_bot():
	var bot = {
		GlobalData.EnemyDififultyVariables.force_scale : rng.randf_range(0.5, 1.5),
		GlobalData.EnemyDififultyVariables.precision : rng.randf_range(0.5, 1.0),
		GlobalData.EnemyDififultyVariables.error_radius : rng.randf_range(0.5, 10.0),
		GlobalData.EnemyDififultyVariables.max_shot_angle : rng.randf_range(10.0, 180.0),
		GlobalData.EnemyDififultyVariables.min_score : rng.randf_range(-300.0, 100.0),
		GlobalData.EnemyDififultyVariables.risky : rng.randi_range(0, 1),
		GlobalData.EnemyDififultyVariables.crit1 : rng.randf_range(1.0, 50.0),
		GlobalData.EnemyDififultyVariables.crit2 : rng.randf_range(50.0, 200.0),
		GlobalData.EnemyDififultyVariables.crit3 : rng.randf_range(100.0, 500.0),
		GlobalData.EnemyDififultyVariables.crit4 : rng.randf_range(100.0, 1000.0),
		GlobalData.EnemyDififultyVariables.crit5 : rng.randf_range(100.0, 1000.0),
		GlobalData.EnemyDififultyVariables.crit6 : rng.randf_range(100.0, 1000.0)
	}
	return bot

func select_parents(fitness_array: Array) -> Array:
	# Soma total dos fitness
	var total_fitness = 0
	for fitness in fitness_array:
		total_fitness += fitness
	
	# Lista para armazenar os pais selecionados
	var selected_parents = []
	
	# Selecionar o primeiro pai
	var random_value = randf() * total_fitness
	var running_sum = 0
	for j in range(fitness_array.size()):
		running_sum += fitness_array[j]
		if running_sum >= random_value:
			selected_parents.append(j)
			break
	
	# Selecionar o segundo pai, diferente do primeiro
	while true:
		random_value = randf() * total_fitness
		running_sum = 0
		for j in range(fitness_array.size()):
			running_sum += fitness_array[j]
			if running_sum >= random_value and j != selected_parents[0]:
				selected_parents.append(j)
				break
		if selected_parents.size() == 2:
			break
	
	return selected_parents

	
func cross_parents(a,b):
	pass
	
func mutation(a):
	pass
	
