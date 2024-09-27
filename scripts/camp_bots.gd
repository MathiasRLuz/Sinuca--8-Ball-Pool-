extends Node

@export var ball_scene : PackedScene
@export var current_enemy : Dictionary
@export var bots_id = [0,1]
@export var table_max_distance := 900.0
@onready var shapecast = $ShapeCast2D
@onready var shapecast2: ShapeCast2D = $ShapeCast2D2
@onready var raycast: RayCast2D = $RayCast2D
@onready var raycast2: RayCast2D = $RayCast2D2
var phantom_ball_detections: Dictionary = {}
var limites_paredes = [70, 850, 350, 70] # esquerda, direita, baixo, cima
var ball_images := []
var cue_ball
const START_POS := Vector2(810,259.5)
@export var MAX_POWER := 40
const MOVE_THRESHOLD := 5.0
var taking_shot : bool
var cue_ball_potted : bool
var potted := []
var all_potted := []
var ball_radius = 14.0
var mesa_aberta : bool = true

var jogador_atual : int = 0 # 0 jogador, 1 bot
var apply_max_force: bool = false
var force_first_player: int = -1 # -1 random, 0 bot, 1 jogador
var grupo_jogador : int = 0 # indefinido, 1 menores, 2 maiores

var grupo_maior := [9,10,11,12,13,14,15]
var grupo_menor := [1,2,3,4,5,6,7]
var foi_falta : bool = false
var primeira_bola_batida: int = 0
var moveram: bool = false
var derrubou_a_8_por_ultimo: bool = false
var buracos := []
var jogador_ja_tinha_grupo: bool = false

var faltas = [0,0]
var pontos = [0,0]
var tacadas = [0,0]
var vitorias = [0,0]
var pontos_da_tacada = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	Engine.set_time_scale(10)
	GlobalData.set_bots_ids(GlobalData.matchups[GlobalData.matchup_id])
	bots_id = GlobalData.get_bots_ids()
	print(bots_id[0]," vs ", bots_id[1])
	print(GlobalData.bots[bots_id[0]], " vs ", GlobalData.bots[bots_id[1]])
	hide_cue()
	all_potted = []
	randomize()  # Garante que a semente do gerador de números aleatórios seja diferente a cada execução
	if force_first_player!=-1: jogador_atual = force_first_player
	else: jogador_atual = randi() % 2  # Retorna 0 ou 1 aleatoriamente
	for hole in $Mesa/buracos.get_children():
		buracos.append(hole)
	#load_images()
	new_game()	
	$Mesa/buracos.body_entered.connect(potted_ball)

func proximo_jogador():
	jogador_atual = 1 - jogador_atual
	atualiza_texto()
	ajusta_texto_grupo()

func atualiza_texto():
	var adversario = abs(1-jogador_atual)	
	$jogador_atual.text = str(bots_id[jogador_atual]) + ", tacadas: " + str(tacadas[jogador_atual]) + ", pontos: " + str(pontos[jogador_atual]) + ", faltas: " + str(faltas[jogador_atual]) + " - Oponente> tacadas: " + str(tacadas[adversario]) + ", pontos: " + str(pontos[adversario]) + ", faltas: " + str(faltas[adversario])

func ajusta_texto_grupo():
	var grupo_texto = "indefinido"
	if jogador_atual == 0:
		if grupo_jogador == 1:
			grupo_texto = "menores"
		elif grupo_jogador == 2: 
			grupo_texto = "maiores"
	if jogador_atual == 1:
		if grupo_jogador == 2:
			grupo_texto = "menores"
		elif grupo_jogador == 1: 
			grupo_texto = "maiores"
	$grupo_atual.text = grupo_texto
	
func remove_bola(bola):	
	all_potted.append(bola)
	if bola>8:
		grupo_maior.erase(bola)
	else:
		grupo_menor.erase(bola)
	for b in get_tree().get_nodes_in_group("bolas"):
		if b.name == str(bola):
			var b_sprite = Sprite2D.new()
			add_child(b_sprite)
			b_sprite.texture = b.get_node("Sprite2D").texture
			b_sprite.hframes = b.get_node("Sprite2D").hframes
			b_sprite.vframes = b.get_node("Sprite2D").vframes
			b_sprite.frame = b.get_node("Sprite2D").frame
			b_sprite.scale = b.get_node("Sprite2D").scale
			b_sprite.position = get_potted_ball_position()
			b.queue_free()

func falta(grupo_favorecido):
	if grupo_favorecido == 1:
		if grupo_menor.size() < 1:
			# grupo menor vence
			if grupo_jogador == 1: fim_de_partida(0)
			else: fim_de_partida(1)
		else:
			remove_bola(grupo_menor[0])
	else:	
		if grupo_maior.size() < 1:
			# grupo maior vence
			if grupo_jogador == 2: fim_de_partida(0)
			else: fim_de_partida(1)
		else:
			remove_bola(grupo_maior[0])	

func fim_de_partida(jogador_vencedor): # 0 jogador, 1 bot

	$"Fim de jogo".text = "Jogador " + str(bots_id[jogador_vencedor]) + " venceu"
	set_process(false)
	vitorias[jogador_vencedor]+=1
	print("Vencedor: ", bots_id[jogador_vencedor])
	next_duel()

func load_images():
	for i in range(1,17,1):
		var filename = str("res://assets/ball_",i,".png")
		var ball_image = load(filename)
		ball_images.append(ball_image)

func new_game():
	generate_balls()
	reset_cue_ball()	
	
func generate_balls():
	var count : int = 0
	var rows : int = 5
	var diameter = 2 * ball_radius
	var ball_positions = []
	var ball8_pos : Vector2
	var ball15_pos : Vector2
	for col in range(5):
		for row in range(rows):			
			var pos = Vector2(180 + (col * diameter) - (col * 2), START_POS.y - 4 * ball_radius + (row * diameter) + (float(col * diameter) / 2.0))
			count += 1
			if count == 11:
				ball8_pos = pos
			else:
				ball_positions.append(pos)
		rows -= 1
	count = 0
	ball_positions.shuffle()	
	for i in range(15):
		var ball = ball_scene.instantiate()		
		#ball.get_node("Sprite2D").texture = ball_images[count]
		ball.get_node("Sprite2D").frame = i+1
		if count == 7:
			ball.position = ball8_pos
			ball15_pos = ball_positions[i]
		elif i<14:
			ball.position = ball_positions[i]
		else:
			ball.position = ball15_pos
		count += 1
		ball.name = str(count)
		ball.continuous_cd = true
		add_child(ball)	
		
func remove_cue_ball():
	var old_b = cue_ball
	shapecast.reparent($".")
	remove_child(old_b)
	old_b.queue_free()
	
func reset_cue_ball():
	cue_ball = ball_scene.instantiate()
	add_child(cue_ball)
	cue_ball.position = START_POS
	cue_ball.get_node("Sprite2D").frame = 0
	#cue_ball.get_node("Sprite2D").texture = ball_images.back() # última imagem do array
	taking_shot = false
	cue_ball.set_contact_monitor(true)
	cue_ball.max_contacts_reported = 256
	cue_ball.connect("body_entered", Callable(self, "_on_CueBall_area_entered"))
	cue_ball.continuous_cd = true  # Ativa o CCD
	shapecast.reparent(cue_ball)
	await get_tree().create_timer(1).timeout

func _on_CueBall_area_entered(body):
	if body.is_in_group("bolas") && primeira_bola_batida == 0 && body.name != "Bola":
		primeira_bola_batida = body.name.to_int()
		
func get_better_ball():
	var permitted_balls := []
	var best_ball = null
	var best_score = -INF
	var best_collision_point = null	
	var best_hole_position = Vector2.ZERO
	var direct_shot := false
	var possible_contact_points = []
	if not get_tree():
		return
	for b in get_tree().get_nodes_in_group("bolas"):
		if b.name != "Bola":
			if is_ball_permitted(b.name.to_int()):
				var ball = b
				permitted_balls.append(ball)
				
#region Acertar o ponto "ideal" de colisão	
	for b in permitted_balls: 
		for hole in buracos:
			var hole_position = hole.to_global(hole.get_child(0).position)
			var pocket_direction = (hole_position - b.position).normalized()
			var contact_point = b.position - pocket_direction * 2* ball_radius
			var white_to_ball = (contact_point - cue_ball.position).normalized()
			
			var angle_radians = pocket_direction.angle_to(white_to_ball)
			var angle_degrees = rad_to_deg(angle_radians)
			var collisions = await check_ball_path(contact_point,cue_ball.global_position)
			if collisions != {} and collisions.keys()[0] == b.name and check_collision_distance(collisions[collisions.keys()[0]],contact_point) and abs(angle_degrees) < current_enemy[GlobalData.EnemyDififultyVariables.max_shot_angle]:			
				var score = 0
				
				# Critério 1: Ângulo (quanto menor, melhor)
				score += (current_enemy[GlobalData.EnemyDififultyVariables.max_shot_angle] - abs(angle_degrees)) * current_enemy[GlobalData.EnemyDififultyVariables.crit1]
				
				# Critério 2: Distância da bola branca até a bola alvo (quanto menor, melhor)
				var distance_to_ball = cue_ball.position.distance_to(b.position)
				score += (1 / distance_to_ball) * current_enemy[GlobalData.EnemyDififultyVariables.crit2]  # Inverso da distância multiplicado para dar peso
				
				# Critério 3: Distância da bola alvo até a caçapa (quanto menor, melhor)
				var distance_to_hole = b.position.distance_to(hole_position)
				score += (1 / distance_to_hole) * current_enemy[GlobalData.EnemyDififultyVariables.crit3]
				
				# Critério 4: Interferências (penalizar se houver outras bolas no caminho)
				var clear_path = await check_clear_path(b, hole_position,contact_point) 
				# caminho direto ao buraco, numero de colisões sem contar as proibídas, 
				# numero de colisões proibídas sem contar a 8, e numero de colisões com a 8 (0 ou 1)
				if not clear_path[0]:
					var penalidade = current_enemy[GlobalData.EnemyDififultyVariables.crit4] * clear_path[1]
					penalidade += current_enemy[GlobalData.EnemyDififultyVariables.crit5] * clear_path[2]
					penalidade += current_enemy[GlobalData.EnemyDififultyVariables.crit6] * clear_path[3]
					score -= penalidade  # Penalidade se houver interferência
				# Avaliar se esta jogada é melhor que as anteriores
				if score > best_score:
					if score > current_enemy[GlobalData.EnemyDififultyVariables.min_score]:
						best_score = score
						best_ball = b
						best_collision_point = contact_point
						best_hole_position = hole_position
						# linha vermelha
						$Line2D2.clear_points()
						$Line2D2.add_point(contact_point)
						$Line2D2.add_point(hole_position)
						$Line2D2.visible = true
						direct_shot = true
					else:
						possible_contact_points.append([b,hole_position,contact_point,score])	
#endregion

	if best_ball == null:
		var best_contact_point = Vector2.ZERO
		var possible_points := []
		
		for possible_contact_point in possible_contact_points:
			if possible_contact_point[3] > best_score:				
				best_ball = possible_contact_point[0]
				best_hole_position = possible_contact_point[1]
				best_collision_point = possible_contact_point[2]
				best_score = possible_contact_point[3]			
				direct_shot = true
		
		# nenhum tiro direto
		# calcular 4 posições projetadas da bola branca nas tabelas (vetores em 0, 90, 180 e 270 graus, com comprimento x2)
		var cue_ball_projections = calculate_cue_ball_projections()
#region Verifica tabelas
		if current_enemy[GlobalData.EnemyDififultyVariables.risky] == 1:
			for b in permitted_balls:
				# para cada bola permitida, cria vetor do ponto de mira da bola em cada buraco até as 4 posições da bola branca projetada
				for projected_cue_ball in cue_ball_projections:
					for hole in buracos:	
						var hole_position = hole.to_global(hole.get_child(0).position)			
						var pocket_direction = (hole_position - b.position).normalized()
						var contact_point = b.position - pocket_direction * 2* ball_radius
						var direction = projected_cue_ball - contact_point	
						raycast.target_position = direction * 10000  # Lança o raycast numa grande distância
						raycast.global_position = contact_point # Posição do RayCast2D na bola
						raycast.force_raycast_update()
						if raycast.is_colliding():
							# Obtenha o ponto de tabela
							var collision_point = raycast.get_collision_point()
							# corrigir best_collision_point
							collision_point -= direction.normalized() * ball_radius
							# descobrir em qual parede está tabelando
							
							var collisions = await check_ball_path(collision_point,cue_ball.global_position)
							if collisions != {} and collisions.keys()[0] == "paredes" and check_collision_distance(collisions[collisions.keys()[0]],collision_point):
							# da posição da branca até a parede
								# se a bola branca tem caminho direto até o ponto de tabela
								collisions = await check_ball_path(contact_point,collision_point)
								if collisions != {} and collisions.keys()[0] == b.name and check_collision_distance(collisions[collisions.keys()[0]],contact_point):
									# da parede até a bola 
									# linha vermelha
									$Line2D2.clear_points()
									$Line2D2.add_point(contact_point)
									$Line2D2.add_point(hole_position)
									$Line2D2.visible = true
									# linha roxa
									$Line2D3.clear_points()
									$Line2D3.add_point(collision_point)
									$Line2D3.add_point(contact_point)
									$Line2D3.visible = true	
									
									var tabela_to_ball = (contact_point - collision_point).normalized()
									
									var angle_radians = pocket_direction.angle_to(tabela_to_ball)
									var angle_degrees = rad_to_deg(angle_radians)
									if abs(angle_degrees) < current_enemy[GlobalData.EnemyDififultyVariables.max_shot_angle]:
										var score = 0
										
										# Critério 1: Ângulo (quanto menor, melhor)
										score += (current_enemy[GlobalData.EnemyDififultyVariables.max_shot_angle] - abs(angle_degrees)) * current_enemy[GlobalData.EnemyDififultyVariables.crit1] # Multiplicador de 2 para dar mais peso
										
										# Critério 2: Distância da bola branca até a bola alvo (quanto menor, melhor)
										var distance_to_ball = cue_ball.position.distance_to(collision_point) + collision_point.distance_to(b.position)
										score += (1 / distance_to_ball) * current_enemy[GlobalData.EnemyDififultyVariables.crit2]  # Inverso da distância multiplicado para dar peso
										
										# Critério 3: Distância da bola alvo até a caçapa (quanto menor, melhor)
										var distance_to_hole = b.position.distance_to(hole_position)
										score += (1 / distance_to_hole) * current_enemy[GlobalData.EnemyDififultyVariables.crit3]
										
										# Critério 4: Interferências (penalizar se houver outras bolas no caminho)
										var clear_path = await check_clear_path(b, hole_position,contact_point) 
										# caminho direto ao buraco, numero de colisões sem contar as proibídas, 
										# numero de colisões proibídas sem contar a 8, e numero de colisões com a 8 (0 ou 1)
										if not clear_path[0]:
											var penalidade = current_enemy[GlobalData.EnemyDififultyVariables.crit4] * clear_path[1]
											penalidade += current_enemy[GlobalData.EnemyDififultyVariables.crit5] * clear_path[2]
											penalidade += current_enemy[GlobalData.EnemyDififultyVariables.crit6] * clear_path[3]
											score -= penalidade  # Penalidade se houver interferência
										# Avaliar se esta jogada é melhor que as anteriores
										if score > best_score:
											best_score = score
											best_ball = b
											best_collision_point = collision_point
											best_hole_position = hole_position
											best_contact_point = contact_point
											direct_shot = false
		if best_ball != null:
			if not direct_shot:
				# linha vermelha
				$Line2D2.clear_points()
				$Line2D2.add_point(best_contact_point)
				$Line2D2.add_point(best_hole_position)
				$Line2D2.visible = true
				# linha roxa
				$Line2D3.clear_points()
				$Line2D3.add_point(best_collision_point)
				$Line2D3.add_point(best_contact_point)
				$Line2D3.visible = true
#endregion
		else:
				# significa que best_ball = null, best_score = -INF e best_collision_point = null 
				# mirar apenas para acertar uma bola do grupo
				for b in permitted_balls:
					for degree in range(0, 360, 360.0/1.0): # 10 é o total de pontos verificados
						var radians = deg_to_rad(degree)  # Converte graus para radianos
						var x = b.position.x + ball_radius * cos(radians)  # Calcula a coordenada x
						var y = b.position.y + ball_radius * sin(radians)  # Calcula a coordenada y
						var point = Vector2(x, y)  # Cria o ponto como um Vector2
						var collisions = await check_ball_path(point,cue_ball.global_position)
						if collisions != {} and collisions.keys()[0] == b.name and check_collision_distance(collisions[collisions.keys()[0]],point):
							var distance_to_ball = cue_ball.position.distance_to(point)
							possible_points.append([point,distance_to_ball,b])
							
				if possible_points.size() > 0:
					for possible_point in possible_points:
						var point = possible_point[0]
						var distance_to_ball = possible_point[1]
						var score = (1 / distance_to_ball)
						var ball = possible_point[2]
						if score > best_score:
							best_score = score
							best_ball = ball
							best_collision_point = point
							direct_shot = true
				else:
					# Mirar na tabela apenas para acertar uma bola do grupo
					for b in permitted_balls:
						# para cada bola permitida, cria vetor do ponto de mira da bola em cada buraco até as 4 posições da bola branca projetada
						for projected_cue_ball in cue_ball_projections:
							for degree in range(0, 360, 360.0/1.0):
								var radians = deg_to_rad(degree)  # Converte graus para radianos
								var x = b.position.x + ball_radius * cos(radians)  # Calcula a coordenada x
								var y = b.position.y + ball_radius * sin(radians)  # Calcula a coordenada y
								var point = Vector2(x, y)  # Cria o ponto como um Vector2								
								var direction = projected_cue_ball - point
								raycast.target_position = direction * 10000  # Lança o raycast numa grande distância
								raycast.global_position = point # Posição do RayCast2D na bola
								raycast.force_raycast_update()
								if raycast.is_colliding():
									# Obtenha o ponto de tabela
									var collision_point = raycast.get_collision_point()
									
									var collisions = await check_ball_path(collision_point,cue_ball.global_position)
									if collisions != {} and collisions.keys()[0] == "paredes" and check_collision_distance(collisions[collisions.keys()[0]],collision_point):
									# da posição da branca até a parede
										# se a bola branca tem caminho direto até o ponto de tabela
										collisions = await check_ball_path(point,collision_point)
										if collisions != {} and collisions.keys()[0] == b.name and check_collision_distance(collisions[collisions.keys()[0]],collision_point):
										# da parede até a bola 
											var distance_to_ball = cue_ball.position.distance_to(collision_point) + collision_point.distance_to(b.position)
											possible_points.append([collision_point,distance_to_ball,b])
					if possible_points.size() > 0:
						for possible_point in possible_points:
							var point = possible_point[0]
							var distance_to_ball = possible_point[1]
							var score = (1 / distance_to_ball)
							var ball = possible_point[2]
							if score > best_score:
								best_score = score
								best_ball = ball
								best_collision_point = point
								direct_shot = false
					else:
						best_collision_point = permitted_balls.pick_random().position
		
			
	return [best_ball, best_hole_position,best_collision_point,best_score,direct_shot]

func calculate_cue_ball_projections():
	var ball_positions = []
	var directions = [
		Vector2(1, 0),   # 0° - Direita
		Vector2(0, -1),  # 90° - Cima
		Vector2(-1, 0),  # 180° - Esquerda
		Vector2(0, 1)    # 270° - Baixo
	]
	raycast2.enabled = true
	for direction in directions:
		raycast2.target_position = direction * 10000  # Lança o raycast numa grande distância
		raycast2.global_position = cue_ball.global_position  # Posição do RayCast2D na bola branca
		
		raycast2.force_raycast_update()
		if raycast2.is_colliding():
			var collision_point = raycast2.get_collision_point()
			var distance = cue_ball.global_position.distance_to(collision_point) - ball_radius/2
			var projected_position = cue_ball.position + direction * distance * 2
			ball_positions.append(projected_position)

	raycast2.enabled = false
	return ball_positions


func check_ball_path(destination,phantom_ball_position,parent = cue_ball):
	# Posição inicial do ShapeCast (global position da bola branca)
	var start_pos = phantom_ball_position
	
	# Definir o shape e a origem do cast
	shapecast.reparent(parent)
	shapecast.global_position = start_pos
	
	# Definir a direção do ShapeCast em relação à bola branca (diferenca entre destino e origem)
	var direction = (destination - start_pos).normalized()

	# Multiplicar a direção por um fator de distância grande para garantir que o shape percorra um caminho longo
	shapecast.target_position = shapecast.to_local(start_pos + direction * 1000)

	# Desenhar a linha de trajetória
	$Line2D3.clear_points()
	$Line2D3.add_point(shapecast.global_position)
	$Line2D3.add_point(shapecast.to_global(shapecast.target_position))
	$Line2D3.visible = true

	# Habilitar o ShapeCast para detectar colisões
	shapecast.enabled = true	
	shapecast.force_shapecast_update()
	# Armazenar todas as colisões
	phantom_ball_detections = {}
	# Verificar se o ShapeCast está colidindo
	if shapecast.is_colliding():
		var collider = shapecast.get_collider(0)
		
		

		# Loop para verificar todas as colisões
		while shapecast.is_colliding():
			var n_collisions = shapecast.get_collision_count()
			for collision in range(n_collisions):
				collider = shapecast.get_collider(collision)
				var collision_point = shapecast.get_collision_point(collision)
				var nome = collider.name

				if nome == "Area2D": 
					nome = collider.get_parent().name
				nome = str(nome)

				# Registrar a colisão se ainda não foi detectada
				if not phantom_ball_detections.has(nome) and nome != "Bola": 
					phantom_ball_detections[nome] = collision_point
				
				# Parar o loop se colidir com a parede
				if nome == "paredes":
					break
			
			# Mover o ShapeCast para o próximo ponto de colisão usando get_closest_collision_unsafe_fraction
			var collision_fraction = shapecast.get_closest_collision_unsafe_fraction()
			
			# Calcular a nova posição baseada na fração de colisão
			shapecast.global_position += (shapecast.to_global(shapecast.target_position) - shapecast.global_position) * collision_fraction		
			#$Ball18.global_position = shapecast.global_position
			# Atualizar a detecção de colisão novamente
			shapecast.force_shapecast_update()
	shapecast.reparent($".")
	return phantom_ball_detections
	
func check_collision_distance(p1,p2):
	var tolerancia = 0.05
	var distancia = p1.distance_to(p2) # distancia entre o ponto de colisão real e o contact_point calculado	
	return distancia<=ball_radius*(1+tolerancia)
	
func calculate_shot_power(hole_position, contact_point):
	var distance_white_to_ball = cue_ball.position.distance_to(contact_point)
	var distance_ball_to_hole = contact_point.distance_to(hole_position)
	
	# Configurações de física da mesa
	var friction_coefficient = 0.05  # Depende do material da mesa
	
	# Calcular a força necessária baseada na distância
	var power = distance_white_to_ball + distance_ball_to_hole
	
	# Ajustar a força com base no coeficiente de atrito
	power *= (1 + friction_coefficient)
	
	# Ajustar a força com base no ângulo
	var shot_direction = (contact_point - cue_ball.position).normalized()
	var pocket_direction = (hole_position - contact_point).normalized()
	var angle_radians = shot_direction.angle_to(pocket_direction)
	var angle_factor = 1.0 + 0.5 * abs(angle_radians / PI)
	power *= angle_factor
	var max_shot_power = table_max_distance * (1 + friction_coefficient) * 1.5 

	return power/max_shot_power

func check_clear_path(ball,pocket_position,start_point):
	var collisions = check_ball_path(pocket_position,start_point,ball)
	if collisions != {}:
		# Encontre o índice da chave "buracos"
		var clear_shot = collisions.keys()[0] == "buracos"
		if "buracos" in collisions:
			var keys = collisions.keys()
			var index_buracos = keys.find("buracos")

			# Remova as chaves a partir de "buracos"
			for i in range(keys.size() - 1, index_buracos - 1, -1):
				collisions.erase(keys[i])
		var n_collisions = len(collisions.keys())
		var forbidden_collisions = []
		for key in collisions.keys():		
			if str(key) != "paredes":
				if bateu_primeiro_em_bola_proibida(int(str(key))):
					forbidden_collisions.append(str(key))
		return [clear_shot,n_collisions-len(forbidden_collisions),len(forbidden_collisions)-forbidden_collisions.count("8"), forbidden_collisions.count("8")]
	else:
		return [false,0, 0, 0]

func check_clear_shot(ball_name, contact_point: Vector2, check_distance: bool = true):
	var tolerancia = 0.05 # porcentagem de distancia (entre o ponto de colisão real e o contact_point calculado) excedente ao raio da bola
	# Defina a posição de origem do shapecast2D	
	shapecast.position = Vector2.ZERO
	# Calcule o vetor de direção e distância para o shapecast2d
	shapecast.target_position = shapecast.to_local(contact_point)
	# Habilite o RayCast2D para começar a detectar colisões
	shapecast.enabled = true
	shapecast.force_shapecast_update()	
	# Verifique se há uma colisão
	if shapecast.is_colliding():
		# Obtenha o objeto colidido
		var collider = shapecast.get_collider(0)
		# qual será o ponto da primeira colisão
		var colision_point = shapecast.get_collision_point(0)
		var distancia = colision_point.distance_to(contact_point) # distancia entre o ponto de colisão real e o contact_point calculado
		shapecast.enabled = false	
		if (not check_distance and collider.name == ball_name) or (check_distance and distancia<=ball_radius*(1+tolerancia) and collider.name == ball_name):
			return true
		else: 
			return false
	else:
		shapecast.enabled = false
		return false
	
func get_nearest_hole(ball_position):
	var nearest_distance = INF
	var nearest_hole = null
	for hole in buracos:
		var distance = ball_position.distance_to(hole.position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_hole = hole
	return [nearest_hole,nearest_distance]

func is_ball_permitted(ball):
	if all_potted.has(ball):
		return false
	if grupo_jogador == 0: #todas permitidas, menos 8
		if ball != 8:
			return true
	else:
		if jogador_atual == 0:
			if grupo_jogador == 1: # jogador com as menores
				if grupo_menor.size() > 0:
					if ball < 8:
						return true
				else:
					if ball == 8:
						return true
			if grupo_jogador == 2: # jogador com as maiores
				if grupo_maior.size() > 0:
					if ball > 8:
						return true
				else:
					if ball == 8:
						return true
		else:
			if grupo_jogador == 2: # jogador com as maiores, bot com as menores
				if grupo_menor.size() > 0:
					if ball < 8:
						return true
				else:
					if ball == 8:
						return true
			if grupo_jogador == 1: # jogador com as menores, bot com as maiores
				if grupo_maior.size() > 0:
					if ball > 8:
						return true
				else:
					if ball == 8:
						return true
	
func vez_bot(bot_id):
	current_enemy = GlobalData.get_bots()[bots_id[bot_id]]
	var rng = RandomNumberGenerator.new()	
	var better_ball = await get_better_ball() # ([best_ball, best_hole_position,best_collision_point,best_score,direct_shot])
	
	if better_ball[2] != null:
		var target_point = better_ball[2]		
		if rng.randf() > current_enemy[GlobalData.EnemyDififultyVariables.precision]:
			var possible_points := []
			for degree in range(360):
				var radians = deg_to_rad(degree)  # Converte graus para radianos
				var x = target_point.x + current_enemy[GlobalData.EnemyDififultyVariables.error_radius] * cos(radians)  # Calcula a coordenada x
				var y = target_point.y + current_enemy[GlobalData.EnemyDififultyVariables.error_radius] * sin(radians)  # Calcula a coordenada y
				var point = Vector2(x, y)  # Cria o ponto como um Vector2
				possible_points.append(point)
			target_point = possible_points.pick_random()
		$Taco.position = cue_ball.position
		var dir = target_point - cue_ball.position
		$Taco.look_at(target_point)
		$Taco.show()
		
		$Line2D.clear_points()
		$Line2D.add_point(cue_ball.position)
		$Line2D.add_point(target_point)
		$Line2D.visible = true
		await get_tree().create_timer(0.01).timeout
		
		var power = MAX_POWER * dir.normalized() * $Taco.power_multiplier 
		# se tiro direto calcula a força, senão usa força maxima nas tabelas
		if better_ball[4]: power *= calculate_shot_power(better_ball[1],better_ball[2])
		power *= current_enemy[GlobalData.EnemyDififultyVariables.force_scale]
		cue_ball.apply_central_impulse(power)		
		$Line2D.visible = false
		$Line2D2.visible = false
		$Line2D3.visible = false
	else:		
		print("Não sei oq fazer")
	tacadas[jogador_atual] += 1
	#atualiza_texto()

func show_cue():
	$Taco.position = cue_ball.position
	$Taco.show()
	$PowerBar.show()
	$PowerBar.position.x = cue_ball.position.x - (0.5 * $PowerBar.size.x)
	$PowerBar.position.y = cue_ball.position.y + $PowerBar.size.y
	$Taco.set_process(true)	
	
func inicia_vez():
	pontos_da_tacada = 0
	vez_bot(jogador_atual)
			
func hide_cue():
	$Taco.set_process(false)
	$Taco.hide()
	$PowerBar.hide()

func nova_tacada():
	pontos[jogador_atual] += pontos_da_tacada
	atualiza_texto()
	if not jogador_ja_tinha_grupo and grupo_jogador != 0:
		jogador_ja_tinha_grupo = true
	if potted.size() == 0 || foi_falta:
		proximo_jogador()
	
	potted = []
	taking_shot = true
	inicia_vez()
	primeira_bola_batida = 0
	foi_falta = false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		next_duel()

func next_duel():
	GeneticAlgorithm.eval_bot(bots_id[0],[vitorias[0],tacadas[0],pontos[0],faltas[0]])
	GeneticAlgorithm.eval_bot(bots_id[1],[vitorias[1],tacadas[1],pontos[1],faltas[1]])
	if GlobalData.matchup_id < len(GlobalData.matchups) - 1: 
		GlobalData.matchup_id += 1		
		get_tree().change_scene_to_file(get_tree().current_scene.scene_file_path)
	else:
		GeneticAlgorithm.new_generation()
		
func reset_game():
	remove_cue_ball()
	new_game()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):	
	var moving := false
	for b in get_tree().get_nodes_in_group("bolas"):
		if (b.linear_velocity.length() > 0.0 and b.linear_velocity.length() < MOVE_THRESHOLD):
			b.sleeping = true
			
		elif b.linear_velocity.length() >= MOVE_THRESHOLD:
			moving = true
			moveram = true
			
	if not moving:
		
		# check if the cue ball has been potted and reset it
		if cue_ball_potted:
			if derrubou_a_8_por_ultimo: # a branca caiu depois de ter derrubado a 8
				fim_de_partida(1-jogador_atual)
				return
			if grupo_jogador != 0: foi_falta = true
			reset_cue_ball()
			cue_ball_potted = false
		else:
			if derrubou_a_8_por_ultimo:
				fim_de_partida(jogador_atual)
				return
		
		if moveram: # bolas pararam após a tacada
			if (primeira_bola_batida == 0 and grupo_jogador != 0) or (jogador_ja_tinha_grupo and primeira_bola_batida != 0 and bateu_primeiro_em_bola_proibida(primeira_bola_batida)):
				foi_falta = true
			
		if not taking_shot:			
			if foi_falta:
				faltas[jogador_atual] += 1
				verifica_favorecido_por_falta()
			nova_tacada()
		
		moveram = false	
	else:
		if taking_shot:
			taking_shot = false
			hide_cue()

func verifica_favorecido_por_falta():
	if jogador_atual == 0: 
		# jogador fez falta
		if (grupo_jogador == 1): #jogador no grupo das menores
			falta(2)		
		elif (grupo_jogador == 2): #jogador no grupo das maiores
			falta(1)
	else: 
		#bot fez falta
		if (grupo_jogador == 1): #jogador no grupo das menores
			falta(1)		
		elif (grupo_jogador == 2): #jogador no grupo das maiores
			falta(2)

func _on_taco_shoot(power):
	if apply_max_force: 
		power = power.normalized() * MAX_POWER * $Taco.power_multiplier
	# definir força manualmente
	#power = 80 *power.normalized() 
	cue_ball.apply_central_impulse(power)

func define_grupos(bola):
	if bola>8:
		if jogador_atual == 0:
			grupo_jogador = 2
		else:
			grupo_jogador = 1
	else:
		if jogador_atual == 0:
			grupo_jogador = 1
		else:
			grupo_jogador = 2
	ajusta_texto_grupo()

func bola_8_derrubada():	
	if jogador_atual == 0: # vez do player
		if grupo_jogador == 1: # o grupo do jogador são as menores
			if grupo_menor.size() > 0: # jogador perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(1) # bot vence
				return
			else:
				derrubou_a_8_por_ultimo = true
		elif grupo_jogador == 2: # o grupo do jogador são as maiores
			if grupo_maior.size() > 0: # jogador perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(1) # bot vence
				return
			else:
				derrubou_a_8_por_ultimo = true
		else: # sem grupos definidos, jogador perde
			fim_de_partida(1) # bot vence
			return
	else: # vez do bot
		if grupo_jogador == 1: # o grupo do jogador são as menores, grupo do bot são as maiores
			if grupo_maior.size() > 0: # bot perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(0) # jogador vence
				return
			else:
				derrubou_a_8_por_ultimo = true
		elif grupo_jogador == 2: # o grupo do jogador são as maiores, grupo do bot são as menores
			if grupo_menor.size() > 0: # bot perde, pois derrubou a 8 quando nem todas as bolas de seu grupo foram encaçapadas
				fim_de_partida(0) # jogador vence
				return
			else:
				derrubou_a_8_por_ultimo = true
		else: # sem grupos definidos, bot perde
			fim_de_partida(0) # jogador vence
			return

func potted_ball(body):
	if body == cue_ball:
		cue_ball_potted = true
		remove_cue_ball()
	else:
		var bola = body.name.to_int()
		if bola == 8:
			bola_8_derrubada()
		if grupo_jogador == 0: # grupos indefinidos
			define_grupos(bola)		
		if bola>8: # grupo maiores
			grupo_maior.erase(bola)		
		else: # grupo menores
			grupo_menor.erase(bola)
		if bola_adversaria(bola):
			pontos_da_tacada -= 1
			foi_falta = true		
		pontos_da_tacada += 1
		potted.append(body)
		all_potted.append(bola)
		var b_sprite = Sprite2D.new()
		add_child(b_sprite)
		b_sprite.texture = body.get_node("Sprite2D").texture
		b_sprite.hframes = body.get_node("Sprite2D").hframes
		b_sprite.vframes = body.get_node("Sprite2D").vframes
		b_sprite.frame = body.get_node("Sprite2D").frame
		b_sprite.scale = body.get_node("Sprite2D").scale
		b_sprite.position = get_potted_ball_position()
		body.queue_free()

func get_potted_ball_position():
	return Vector2(180 + 50 * (14-grupo_maior.size()-grupo_menor.size()),575)

func bateu_primeiro_em_bola_proibida(bola):
	if bola == 8:
		if jogador_atual == 0:
			# vez do jogador
			if grupo_jogador == 1:
				if grupo_menor.size() == 0:
					# só resta a 8 para o jogador
					return false
			if grupo_jogador == 2:
				if grupo_maior.size() == 0:
					# só resta a 8 para o jogador
					return false
		else:
			# vez do bot
			if grupo_jogador == 2:
				if grupo_menor.size() == 0:
					# só resta a 8 para o jogador
					return false
			if grupo_jogador == 1:
				if grupo_maior.size() == 0:
					# só resta a 8 para o jogador
					return false
	if bola == 0: #não bateu em nenhuma
		return true
		
	if bola_adversaria(bola):
		return true
	else:
		return false

func bola_adversaria(bola):
	if jogador_atual == 0: 
		# jogador fez tacada
		if (grupo_jogador == 1): #jogador no grupo das menores
			if bola < 8: return false
			else: return true
		elif (grupo_jogador == 2): #jogador no grupo das maiores
			if bola > 8: return false
			else: return true
	else: 
		#bot fez tacada
		if (grupo_jogador == 1): #jogador no grupo das menores, bot no grupo das maiores
			if bola > 8: return false
			else: return true	
		elif (grupo_jogador == 2): #jogador no grupo das maiores, bot no grupo das menores
			if bola < 8: return false
			else: return true
