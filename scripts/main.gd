extends Node

@export var ball_scene : PackedScene
@export var force_victory := false
@export var current_enemy : GlobalData.Npcs
@export var table_max_distance := 900.0
@onready var shapecast = $ShapeCast2D
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
@export var force_first_player: int = 0 # -1 random, 0 bot, 1 jogador
var grupo_jogador : int = 0 # indefinido, 1 menores, 2 maiores
var estouro := true

var grupo_maior := [9,10,11,12,13,14,15]
var grupo_menor := [1,2,3,4,5,6,7]
var foi_falta : bool = false
var primeira_bola_batida: int = 0
var moveram: bool = false
var derrubou_a_8_por_ultimo: bool = false
var buracos := []
var jogador_ja_tinha_grupo: bool = false
var bot_power_ready := false

# poderes bots
var domovoy_ball_to_remove = null
var domovoy_has_removed_ball := false
var domovoy_removed_ball_last_position : Vector2

var waiting_timer := false

@export var debug_slow_time := false
# Called when the node enters the scene tree for the first time.
func _ready():	
	hide_cue()
	all_potted = []
	randomize()  # Garante que a semente do gerador de números aleatórios seja diferente a cada execução
	if force_first_player!=-1: jogador_atual = force_first_player
	else: jogador_atual = randi() % 2  # Retorna 0 ou 1 aleatoriamente
	for hole in $Mesa/buracos.get_children():
		buracos.append(hole)
	new_game()	
	$Mesa/buracos.body_entered.connect(potted_ball)

func proximo_jogador():
	jogador_atual = 1 - jogador_atual
	print("Jogador atual: ", jogador_atual)
	$jogador_atual.text = str(jogador_atual)
	ajusta_texto_grupo()
	
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
	print("Remover bola " + str(bola))
	all_potted.append(bola)
	if bola>8:
		grupo_maior.erase(bola)
		print(grupo_maior)
	else:
		grupo_menor.erase(bola)
		print(grupo_menor)
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
	if jogador_vencedor == 0:
		print("Parabens, você venceu")
		GlobalData.enemy_defeated(GlobalData.current_enemy_name)
		$"Fim de jogo".text = "Jogador 0 venceu"
	else:
		print("Você perdeu")
		$"Fim de jogo".text = "Jogador 1 venceu"
	get_tree().change_scene_to_file(GlobalData.last_scene_before_battle)
	set_process(false)

func new_game():
	generate_balls()
	create_cue_ball()
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

func create_cue_ball():
	cue_ball = ball_scene.instantiate()
	add_child(cue_ball)
	cue_ball.set_contact_monitor(true)
	cue_ball.max_contacts_reported = 256
	cue_ball.connect("body_entered", Callable(self, "_on_CueBall_area_entered"))
	cue_ball.continuous_cd = true  # Ativa o CCD
	cue_ball.get_node("Sprite2D").frame = 0

func reset_cue_ball():
	cue_ball.position = START_POS
	taking_shot = false

func _on_CueBall_area_entered(body):
	if body.is_in_group("bolas") && primeira_bola_batida == 0 && body.name != "Bola":
		estouro = false
		Engine.set_time_scale(1)
		primeira_bola_batida = body.name.to_int()
		
func get_better_ball():
	var permitted_balls := []
	var best_ball = null
	var best_score = -INF
	var best_collision_point = null	
	var best_hole_position = Vector2.ZERO
	var direct_shot := false
	var possible_contact_points = []
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
			var domovoy_removing_ball_name = ""
			if bot_power_ready and current_enemy == GlobalData.Npcs.DOMOVOY and collisions != {} and collisions.keys()[0] != b.name and collisions.keys()[0] != "paredes":
				domovoy_removing_ball_name = collisions.keys()[0]
				collisions.erase(domovoy_removing_ball_name)
				#print("Removendo a bola ", domovoy_removing_ball_name, " para acertar a bola ", b.name)
			if collisions != {} and collisions.keys()[0] == b.name and check_collision_distance(collisions[collisions.keys()[0]],contact_point) and abs(angle_degrees) < GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.max_shot_angle]:			
				var score = 0
				
				# Critério 1: Ângulo (quanto menor, melhor)
				score += (GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.max_shot_angle] - abs(angle_degrees)) * GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit1]
				
				# Critério 2: Distância da bola branca até a bola alvo (quanto menor, melhor)
				var distance_to_ball = cue_ball.position.distance_to(b.position)
				score += (1 / distance_to_ball) * GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit2]  # Inverso da distância multiplicado para dar peso
				
				# Critério 3: Distância da bola alvo até a caçapa (quanto menor, melhor)
				var distance_to_hole = b.position.distance_to(hole_position)
				score += (1 / distance_to_hole) * GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit3]
				
				# Critério 4: Interferências (penalizar se houver outras bolas no caminho)
				var clear_path = await check_clear_path(b, hole_position,contact_point) 
				# caminho direto ao buraco, numero de colisões sem contar as proibídas, 
				# numero de colisões proibídas sem contar a 8, e numero de colisões com a 8 (0 ou 1)
				if not clear_path[0]:
					var penalidade = GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit4] * clear_path[1]
					penalidade += GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit5] * clear_path[2]
					penalidade += GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit6] * clear_path[3]
					#print("Penalidade colisões: ", penalidade)
					score -= penalidade  # Penalidade se houver interferência
				print(b.name," - ",hole.name," - ",score)
				# Avaliar se esta jogada é melhor que as anteriores
				if score > best_score:
					if score > GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.min_score]:
						best_score = score
						best_ball = b
						best_collision_point = contact_point
						best_hole_position = hole_position
						
						# poder domovoy
						if domovoy_removing_ball_name != "":
							for _b in get_tree().get_nodes_in_group("bolas"):
								if _b.name == domovoy_removing_ball_name:
									domovoy_ball_to_remove = _b
									break
						else:
							domovoy_ball_to_remove = null
							
						# linha vermelha
						if debug_slow_time:
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
		var debug = false
#region Verifica tabelas
		if GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.risky] == 1:
			for b in permitted_balls:
				if debug: print("Bola: ", b.name)
				# para cada bola permitida, cria vetor do ponto de mira da bola em cada buraco até as 4 posições da bola branca projetada
				for projected_cue_ball in cue_ball_projections:
					for hole in buracos:	
						if debug: print("Buraco: ", hole.name)
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
							var parede = ""
							if collision_point.x>limites_paredes[1]: # direita
								#collision_point -= Vector2(ball_radius,0)
								if debug: print("Tabelando na direita ", collision_point, " Branca em: ", cue_ball.position)
								parede = "Direita"
							elif collision_point.x<limites_paredes[0]: # esquerda
								#collision_point += Vector2(ball_radius,0)							
								if debug: print("Tabelando na esquerda ", collision_point, " Branca em: ", cue_ball.position)
								parede = "Esquerda"
							elif collision_point.y>limites_paredes[2]: # baixo
								#collision_point -= Vector2(0,ball_radius)
								if debug: print("Tabelando em baixo ", collision_point, " Branca em: ", cue_ball.position)
								parede = "Baixo"
							elif collision_point.y<limites_paredes[3]: # cima
								#collision_point += Vector2(0,ball_radius)
								if debug: print("Tabelando em cima ", collision_point, " Branca em: ", cue_ball.position)
								parede = "Cima"						
							var collisions = await check_ball_path(collision_point,cue_ball.global_position)
							if collisions != {} and collisions.keys()[0] == "paredes" and check_collision_distance(collisions[collisions.keys()[0]],collision_point):
							# da posição da branca até a parede
								#print("Caminho livre até o ponto de tabela em ", parede, " em ", collision_point, " na bola ", b.name, " na caçapa ", hole.name)
								# se a bola branca tem caminho direto até o ponto de tabela
								collisions = await check_ball_path(contact_point,collision_point)
								if collisions != {} and collisions.keys()[0] == b.name and check_collision_distance(collisions[collisions.keys()[0]],contact_point):
									# da parede até a bola 
									print("Buraco: ", hole.name, " Bola: ", b.name)
									if debug_slow_time:
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
									if debug: await get_tree().create_timer(1).timeout
									
									var tabela_to_ball = (contact_point - collision_point).normalized()
									
									var angle_radians = pocket_direction.angle_to(tabela_to_ball)
									var angle_degrees = rad_to_deg(angle_radians)
									print("Angle: ", angle_degrees)
									if abs(angle_degrees) < GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.max_shot_angle]:
										var score = 0
										
										# Critério 1: Ângulo (quanto menor, melhor)
										score += (GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.max_shot_angle] - abs(angle_degrees)) * GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit1] # Multiplicador de 2 para dar mais peso
										
										# Critério 2: Distância da bola branca até a bola alvo (quanto menor, melhor)
										var distance_to_ball = cue_ball.position.distance_to(collision_point) + collision_point.distance_to(b.position)
										score += (1 / distance_to_ball) * GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit2]  # Inverso da distância multiplicado para dar peso
										
										# Critério 3: Distância da bola alvo até a caçapa (quanto menor, melhor)
										var distance_to_hole = b.position.distance_to(hole_position)
										score += (1 / distance_to_hole) * GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit3]
										
										# Critério 4: Interferências (penalizar se houver outras bolas no caminho)
										var clear_path = await check_clear_path(b, hole_position,contact_point) 
										# caminho direto ao buraco, numero de colisões sem contar as proibídas, 
										# numero de colisões proibídas sem contar a 8, e numero de colisões com a 8 (0 ou 1)
										if not clear_path[0]:
											var penalidade = GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit4] * clear_path[1]
											penalidade += GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit5] * clear_path[2]
											penalidade += GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.crit6] * clear_path[3]
											if debug: print("Penalidade colisões: ", penalidade)
											score -= penalidade  # Penalidade se houver interferência
										print(b.name," - ",hole.name," - ",score)
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
				print("--------------------- Tabelando no ponto de contato")
				if debug_slow_time:
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
					print("Mirando para acertar a bola permitida mais próxima")
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
						print("Bola: ", b.name)
						var debug_full = false
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
									
									# corrigir best_collision_point
									# descobrir em qual parede está tabelando
									if collision_point.x>limites_paredes[1]: # direita
										#collision_point -= Vector2(ball_radius,0)
										if debug_full: print("Tabelando na direita ", collision_point)							
									elif collision_point.x<limites_paredes[0]: # esquerda
										#collision_point += Vector2(ball_radius,0)							
										if debug_full: print("Tabelando na esquerda ", collision_point)							
									elif collision_point.y>limites_paredes[2]: # baixo
										#collision_point -= Vector2(0,ball_radius)
										if debug_full: print("Tabelando em baixo ", collision_point)							
									elif collision_point.y<limites_paredes[3]: # cima
										#collision_point += Vector2(0,ball_radius)
										if debug_full: print("Tabelando em cima ", collision_point)							
									
									var collisions = await check_ball_path(collision_point,cue_ball.global_position)
									if collisions != {} and collisions.keys()[0] == "paredes" and check_collision_distance(collisions[collisions.keys()[0]],collision_point):
									# da posição da branca até a parede
										if debug: print("Caminho livre até o ponto de tabela")
										# se a bola branca tem caminho direto até o ponto de tabela
										collisions = await check_ball_path(point,collision_point)
										if collisions != {} and collisions.keys()[0] == b.name and check_collision_distance(collisions[collisions.keys()[0]],collision_point):
										# da parede até a bola 
											var distance_to_ball = cue_ball.position.distance_to(collision_point) + collision_point.distance_to(b.position)
											possible_points.append([collision_point,distance_to_ball,b])
					print("Bot não sabe onde mirar")
					if possible_points.size() > 0:
						print("Mirando na tabela apenas para acertar uma bola do grupo")
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
						print("mirou em ", best_collision_point)
					else:
						print("mirou em qualquer bola")
						best_collision_point = permitted_balls.pick_random().position
		
	
	# poder domovoy
	if bot_power_ready and current_enemy == GlobalData.Npcs.DOMOVOY and domovoy_ball_to_remove:
		domovoy_power_remove()
	
	return [best_ball, best_hole_position,best_collision_point,best_score,direct_shot]

func domovoy_power_remove():
	print("Removendo a bola ", domovoy_ball_to_remove.name)
	bot_power_ready = false
	domovoy_removed_ball_last_position = domovoy_ball_to_remove.position
	domovoy_ball_to_remove.position = Vector2(-10000,10000)
	domovoy_has_removed_ball = true

func domovoy_power_return():
	print("Devolvendo a bola ", domovoy_ball_to_remove.name)
	domovoy_ball_to_remove.position = domovoy_removed_ball_last_position
	domovoy_ball_to_remove = null
	domovoy_has_removed_ball = false

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
	if debug_slow_time:
		for i in range(len(ball_positions)):
			match i:
				0:
					$Projection0.position = ball_positions[i]
				1:
					$Projection1.position = ball_positions[i]
				2:
					$Projection2.position = ball_positions[i]
				3:
					$Projection3.position = ball_positions[i]
	raycast2.enabled = false
	print("Projections: ", ball_positions)
	return ball_positions

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
	var collisions = await check_ball_path(pocket_position,start_point,ball)
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
		print(collisions, [clear_shot,n_collisions-len(forbidden_collisions),len(forbidden_collisions)-forbidden_collisions.count("8"), forbidden_collisions.count("8")])
		return [clear_shot,n_collisions-len(forbidden_collisions),len(forbidden_collisions)-forbidden_collisions.count("8"), forbidden_collisions.count("8")]
	else:
		return [false,0, 0, 0]

func check_collision_distance(p1,p2):
	var tolerancia = 0.05
	var distancia = p1.distance_to(p2) # distancia entre o ponto de colisão real e o contact_point calculado	
	return distancia<=ball_radius*(1+tolerancia)
	
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
	
func vez_bot():
	print("INICIO VEZ BOT")
	await get_tree().create_timer(1).timeout
	if estouro:
		var dir = Vector2(-1, 0) # Direção padrão para o estouro
		# Adicionar variação na direção do estouro
		var angle_variation = randf_range(-0.01, 0.01) # Ajuste o valor para mais ou menos variação (em radianos)
		dir = dir.rotated(angle_variation) # Rotaciona a direção base
		$Taco.position = cue_ball.position
		$Taco.show()
		$Taco.look_at(cue_ball.to_global(dir))
		await get_tree().create_timer(0.5).timeout
		var power = MAX_POWER * dir.normalized() * $Taco.power_multiplier
		power *= GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.force_scale]
		power+=randf_range(0.1, 0.3)*power
		power = randf_range(1.1, 1.3)*700*GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.force_scale]* dir.normalized()
		print("POWER > ", power.length())
		cue_ball.apply_central_impulse(power)
	else:	
		var rng = RandomNumberGenerator.new()
		if rng.randf() < GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.power_probability]:
			print("Usar poder")
			bot_power_ready = true
		var better_ball = await get_better_ball() # ([best_ball, best_hole_position,best_collision_point,best_score,direct_shot])
		if better_ball[4]:
			if debug_slow_time:
				# linha vermelha
				$Line2D2.clear_points()
				$Line2D2.add_point(better_ball[2])
				$Line2D2.add_point(better_ball[1])
				$Line2D2.visible = true
				$Line2D3.visible = false
		print("Betterball: ",better_ball)	
		if better_ball[2] != null:
			var target_point = better_ball[2]		
			if rng.randf() > GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.precision]:
				print("Falha na precisão")
				var possible_points := []
				for degree in range(0, 360, 360.0/1.0):
					var radians = deg_to_rad(degree)  # Converte graus para radianos
					var x = target_point.x + GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.error_radius] * cos(radians)  # Calcula a coordenada x
					var y = target_point.y + GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.error_radius] * sin(radians)  # Calcula a coordenada y
					var point = Vector2(x, y)  # Cria o ponto como um Vector2
					possible_points.append(point)				
				target_point = possible_points.pick_random()
			print(target_point)
			$Taco.position = cue_ball.position
			$Taco.show()
			var dir = target_point - cue_ball.position
			$Taco.look_at(target_point)
			if debug_slow_time:
				$Line2D.clear_points()
				$Line2D.add_point(cue_ball.position)
				$Line2D.add_point(target_point)
				$Line2D.visible = true
			await get_tree().create_timer(1).timeout
			
			if debug_slow_time:
				# Camera lenta na tabela
				if better_ball[4]: Engine.set_time_scale(0.2)
				else: Engine.set_time_scale(0.05)
			
			var power = MAX_POWER * dir.normalized() * $Taco.power_multiplier 
			# se tiro direto calcula a força, senão usa força maxima nas tabelas
			if better_ball[4]: power *= calculate_shot_power(better_ball[1],better_ball[2])
			power *= GlobalData.EnemyDificulty[current_enemy][GlobalData.EnemyDififultyVariables.force_scale]
			print("POWER > ", power.length())
			cue_ball.apply_central_impulse(power)		
			#$Line2D.visible = false
			#$Line2D2.visible = false
			#$Line2D3.visible = false
		else:		
			print("Não sei oq fazer")		
	print("FIM VEZ BOT")

func show_cue():
	$Taco.position = cue_ball.position
	$Taco.show()
	$PowerBar.show()
	$PowerBar.position.x = cue_ball.position.x - (0.5 * $PowerBar.size.x)
	$PowerBar.position.y = cue_ball.position.y + $PowerBar.size.y
	$Taco.set_process(true)	
	
func inicia_vez():
	if jogador_atual == 1:
		vez_bot() # show_cue()
	else:
		Engine.set_time_scale(1)
		if bot_power_ready and current_enemy == GlobalData.Npcs.SLIME:
			bot_power_ready = false
			# poder slime
			var margin = 30
			#  limites_paredes => [70, 850, 350, 70] # esquerda, direita, baixo, cima
			var x = randi_range(limites_paredes[0]+margin,limites_paredes[1]-margin)
			var y = randi_range(limites_paredes[3]+margin,limites_paredes[2]-margin)
			$SlimePower.global_position = Vector2(x,y)
			
		show_cue()
			
func hide_cue():
	$Taco.set_process(false)
	$Taco.hide()
	$PowerBar.hide()

func nova_tacada():
	waiting_timer = true
	await get_tree().create_timer(1).timeout
	waiting_timer = false
	
	if not jogador_ja_tinha_grupo and grupo_jogador != 0:
		jogador_ja_tinha_grupo = true
	if potted.size() == 0 || foi_falta:
		proximo_jogador()
	
	potted = []
	taking_shot = true
	inicia_vez()
	primeira_bola_batida = 0
	foi_falta = false

func _input(event):
	if event.is_action_pressed("interact"):	
		if force_victory: GlobalData.enemy_defeated(GlobalData.current_enemy_name) # força vitória do jogador
		get_tree().change_scene_to_file(GlobalData.last_scene_before_battle)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if waiting_timer:
		return
		
	if cue_ball != null and debug_slow_time: $WhiteBall.position = cue_ball.global_position
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
			print("Primeira bola ", primeira_bola_batida)
			
			remove_power_effects()
			if (primeira_bola_batida == 0 and grupo_jogador != 0) or (jogador_ja_tinha_grupo and primeira_bola_batida != 0 and bateu_primeiro_em_bola_proibida(primeira_bola_batida)):
				foi_falta = true
			
		if not taking_shot:			
			if foi_falta:
				print("Foi falta")
				verifica_favorecido_por_falta()
			nova_tacada()
		
		moveram = false	
	else:
		if taking_shot:
			taking_shot = false
			hide_cue()

func remove_power_effects():
	# Domovoy
	if domovoy_has_removed_ball:
		domovoy_power_return()
	# Slime
	$SlimePower.global_position = Vector2(-625,194)
	# Esqueleto
	# Bruxa
	# Medusa
	# Golem

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

func _on_taco_shoot(power, _mouse_pos):
	if apply_max_force: 
		power = power.normalized() * MAX_POWER * $Taco.power_multiplier
		print("Power: ",power.length())
	# definir força manualmente
	#power = 80 *power.normalized()	
	cue_ball.apply_central_impulse(power)
	
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
	if debug_slow_time:
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
	print("Grupo do jogador: " + str(grupo_jogador))
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

func teleport_cue_ball():
	# Congelar o movimento da bola branca (cue ball)
	cue_ball.linear_velocity = Vector2.ZERO
	cue_ball.angular_velocity = 0.0
	
	# Teleportar a bola para a nova posição
	cue_ball.position = Vector2(10000,10000)
	
	# Atualizar o estado da física para evitar problemas na simulação
	cue_ball.sleeping = true # Faz a bola "dormir" até receber um novo impulso

func potted_ball(body):
	if body == cue_ball:
		cue_ball_potted = true
		teleport_cue_ball()
	else:
		print(body.name)
		var bola = body.name.to_int()
		if bola == 8:
			bola_8_derrubada()
		if grupo_jogador == 0: # grupos indefinidos
			define_grupos(bola)		
		if bola>8: # grupo maiores
			grupo_maior.erase(bola)			
			print(grupo_maior)
		else: # grupo menores
			grupo_menor.erase(bola)
			print(grupo_menor)
		if bola_adversaria(bola):
			foi_falta = true
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
	return Vector2(180 + 50 * (14-grupo_maior.size()-grupo_menor.size()),550)

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
