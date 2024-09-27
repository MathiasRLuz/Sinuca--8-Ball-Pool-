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

func select_parents(fitness):
	# Passo 1: Classificar os indivíduos com base no fitness
	var sorted_indices = fitness.sorted(true).invert() # Ordena em ordem decrescente
	var ranking = range(1, len(fitness) + 1) # Gera o ranking

	# Passo 2: Calcular a soma do ranking manualmente
	var total_ranks = 0
	for rank in ranking:
		total_ranks += rank

	# Atribuir probabilidades com base no ranking
	var selection_prob = []
	for rank in ranking:
		selection_prob.append((len(fitness) - rank + 1) / total_ranks)

	# Reordenar as probabilidades para corresponder aos indivíduos na ordem original
	var final_selection_prob = []
	for i in range(len(fitness)):
		final_selection_prob.append(0)

	for i in range(len(sorted_indices)):
		final_selection_prob[sorted_indices[i]] = selection_prob[i]

	# Exibir as probabilidades
	print("Probabilidades de seleção com base no ranking: ", final_selection_prob)

	# Passo 3: Selecionar dois indivíduos para crossover com base nas probabilidades
	var selected = select_individuals(final_selection_prob, 2)
	print("Indivíduos selecionados: ", selected)

# Função para selecionar indivíduos com base nas probabilidades
func select_individuals(probabilities, n):
	var selected = []
	for _i in range(n):
		var r = randf()
		var cumulative_prob = 0.0
		for i in range(len(probabilities)):
			cumulative_prob += probabilities[i]
			if r < cumulative_prob:
				selected.append(i)
				break
	return selected
	
func cross_parents(a,b):
	pass
	
func mutation(a):
	pass
	
