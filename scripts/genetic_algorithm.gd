extends Node

var num_bots = 8
var n_elite = 2
var bots_fitness := []
var gen = 0
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

var last_population = [{ 1: 1.41252899169922, 2: 0.99195492267609, 3: 4.31879997253418, 4: 42.3448867797852, 5: -127.159027099609, 6: 0, 7: 22.9579200744629, 8: 69.0926178693771, 9: 200, 10: 543.595092773438, 11: 500, 12: 175.253707885742 }, { 1: 0.57767850160599, 2: 0.94868111610413, 3: 1.7042647600174, 4: 59.1753025829792, 5: -102.919921445847, 6: 0, 7: 18.2738933563232, 8: 192.550231933594, 9: 200.016456317902, 10: 914.077331542969, 11: 545.488891601563, 12: 1000 }, { 1: 0.57247577905655, 2: 0.96246737241745, 3: 4.31879997253418, 4: 59.2210388183594, 5: 1.74151611328125, 6: 0, 7: 18.2738933563232, 8: 69.0926178693771, 9: 417.661163330078, 10: 914.077331542969, 11: 500.051652860641, 12: 1000 }, { 1: 0.57767850160599, 2: 0.94868111610413, 3: 1.78218884468079, 4: 59.2210388183594, 5: -102.970474243164, 6: 0, 7: 18.2738933563232, 8: 75.9342880249023, 9: 200.016456317902, 10: 543.593848371506, 11: 545.488891601563, 12: 1000 }, { 1: 0.57767850160599, 2: 1, 3: 1.7042647600174, 4: 88.3881683349609, 5: -102.919921445847, 6: 0, 7: 27.6915073394775, 8: 192.550231933594, 9: 417.661163330078, 10: 543.595092773438, 11: 889.875793457031, 12: 1000 }, { 1: 1.41252899169922, 2: 0.96246737241745, 3: 1.7042647600174, 4: 88.3881683349609, 5: -127.159027099609, 6: 0, 7: 18.2738933563232, 8: 69.0926178693771, 9: 206.126953125, 10: 543.595092773438, 11: 889.875793457031, 12: 759.133443248272 }, { 1: 0.57247577905655, 2: 0.95520466566086, 3: 1.78218884468079, 4: 59.1514423817396, 5: -102.970474243164, 6: 0, 7: 18.2738933563232, 8: 75.9342880249023, 9: 200.016456317902, 10: 543.593848371506, 11: 500, 12: 1000 }, { 1: 0.57767850160599, 2: 0.99195492267609, 3: 1.7042647600174, 4: 59.1753025829792, 5: -127.159027099609, 6: 0, 7: 18.2738933563232, 8: 192.550231933594, 9: 200.033326673508, 10: 914.077331542969, 11: 500, 12: 1000 }, { 1: 1.41252899169922, 2: 0.99195492267609, 3: 1.78218884468079, 4: 59.2210388183594, 5: -102.970474243164, 6: 0, 7: 22.9579200744629, 8: 75.9342880249023, 9: 200, 10: 543.595092773438, 11: 500, 12: 1000.01405683756 }, { 1: 0.57767850160599, 2: 0.94868111610413, 3: 0.66031914949417, 4: 59.2210388183594, 5: -127.159027099609, 6: 1, 7: 18.2738933563232, 8: 75.9342880249023, 9: 206.126953125, 10: 914.077331542969, 11: 545.488891601563, 12: 759.133443248272 }]
var continue_with_last_population := false # para iniciar o treinamento com a população de outro treino

var championship_mode := true # para realizar um campeonato MDx (MD5, por exemplo) entre os bots e definir o ganhador, sem aplicar o GA

func new_population():
	GlobalData.clear_bots()
	for i in range(num_bots):
		GlobalData.add_bot(create_bot())
		bots_fitness.append(0) 	
	add_specific_bot([1,1,5,60,0,1,2,100,200,250,500,1000])
	add_specific_bot([1.41252899169922, 0.97707498073578, 1.7042647600174, 88.3777362942695, -102.991931340098, 1, 18.2738933563232, 75.935868692398, 206.028515652381, 543.64482998848, 500.031824212521, 759.133443248272])
	add_specific_bot([0.95879989266396, 1, 9.38956937789917,  53.4195175170898, -49.2016143798828, 1, 18.2738933563232, 107.540453344584, 286.130897557735, 543.720483505726, 840.666850036383, 1000])	

func load_championship_bots():
	num_bots = 0
	GlobalData.clear_bots()
	add_specific_bot([1,1,5,60,0,1,2,100,200,250,500,1000])
	add_specific_bot([1.41252899169922, 0.97707498073578, 1.7042647600174, 88.3777362942695, -102.991931340098, 1, 18.2738933563232, 75.935868692398, 206.028515652381, 543.64482998848, 500.031824212521, 759.133443248272])
	add_specific_bot([0.95879989266396, 1, 9.38956937789917,  53.4195175170898, -49.2016143798828, 1, 18.2738933563232, 107.540453344584, 286.130897557735, 543.720483505726, 840.666850036383, 1000])

# Called when the node enters the scene tree for the first time.
func _ready() -> void:	
	if championship_mode:
		load_championship_bots()
	else:
		if continue_with_last_population:
			GlobalData.set_bots(last_population)
			num_bots = len(last_population)
			for i in range(num_bots):
				bots_fitness.append(0)
		else:
			new_population()
	GlobalData.set_matchups(create_matchups())
	if start_ga: 
		var scale = 100
		Engine.set_time_scale(scale)
		Engine.set_physics_ticks_per_second(300*scale)
		Engine.set_max_physics_steps_per_frame(8*scale)
		start_camp()
		
func add_specific_bot(parameters):
	var bot = {
		GlobalData.EnemyDififultyVariables.force_scale : parameters[0],
		GlobalData.EnemyDififultyVariables.precision : parameters[1],
		GlobalData.EnemyDififultyVariables.error_radius : parameters[2],
		GlobalData.EnemyDififultyVariables.max_shot_angle : parameters[3],
		GlobalData.EnemyDififultyVariables.min_score : parameters[4],
		GlobalData.EnemyDififultyVariables.risky : parameters[5],
		GlobalData.EnemyDififultyVariables.crit1 : parameters[6],
		GlobalData.EnemyDififultyVariables.crit2 : parameters[7],
		GlobalData.EnemyDififultyVariables.crit3 : parameters[8],
		GlobalData.EnemyDififultyVariables.crit4 : parameters[9],
		GlobalData.EnemyDififultyVariables.crit5 : parameters[10],
		GlobalData.EnemyDififultyVariables.crit6 : parameters[11],
	}
	num_bots += 1
	GlobalData.add_bot(bot)
	bots_fitness.append(0)
	
func start_camp():
	print("------------------------ Starting gen ", gen, " -------------------------------------")
	var population = GlobalData.get_bots()
	print(population)
	if not championship_mode:
		# zerar os fitness
		for i in range(num_bots):
			bots_fitness[i] = 0
	GlobalData.matchup_id = 0
	#get_tree().change_scene_to_file("res://scenes/camp_bots.tscn")
	get_tree().change_scene_to_file.bind("res://scenes/camp_bots.tscn").call_deferred()

func new_generation():
	print("New generation")
	print(bots_fitness)
	if not championship_mode:
		# Aplica elitismo
		var population = GlobalData.get_bots()
		var new_gen = apply_elitism(population, bots_fitness, n_elite)
		for _i in range(num_bots - len(new_gen)):
			var parents = select_parents(bots_fitness)
			var _new_bot = new_bot(population[parents[0]],population[parents[1]])
			new_gen.append(_new_bot)
		GlobalData.set_bots(new_gen)
	gen += 1
	start_camp()
	
func new_bot(parent1,parent2):
	var bot = cross_parents(parent1,parent2)
	bot = mutate(bot, 0.05, 0.1)
	return bot
	
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
		GlobalData.EnemyDififultyVariables.precision : rng.randf_range(0.9, 1.0),
		GlobalData.EnemyDififultyVariables.error_radius : rng.randf_range(0.5, 10.0),
		GlobalData.EnemyDififultyVariables.max_shot_angle : rng.randf_range(10.0, 90.0),
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

	
func cross_parents(parent1: Dictionary, parent2: Dictionary) -> Dictionary:
	var child = {}
	
	# Para cada chave, escolhe o gene de um dos pais aleatoriamente
	for key in parent1.keys():
		if randf() < 0.5:
			child[key] = parent1[key]  # Escolhe o gene do primeiro pai
		else:
			child[key] = parent2[key]  # Escolhe o gene do segundo pai
	
	return child
	
func mutate(child: Dictionary, mutation_rate: float, mutation_range: float) -> Dictionary:
	# Itera sobre os genes do child
	for key in child.keys():
		# Verifica se o gene será mutado baseado na taxa de mutação
		if randf() < mutation_rate:
			if key == 6:
				# Se for o gene 6, alterna entre 0 e 1
				child[key] = 1 if child[key] == 0 else 0
			else:
				# Para os outros genes, aplica uma variação dentro do range especificado
				var variation = (randf() * 2.0 - 1.0) * mutation_range
				child[key] += variation
				
				# Clampa o gene 2 para ficar no range de 0 a 1
				if key == 2:
					child[key] = clamp(child[key], 0, 1)
	
	return child
	
