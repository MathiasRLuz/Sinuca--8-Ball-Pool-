class_name Kid extends Sprite2D
@export var npc_name: String
@export var npc_type : GlobalData.Npcs
@export var image_pre : Texture2D
@export var image_victory : Texture2D
@export var image_defeat : Texture2D
@export var icon : Texture2D

@export var state_fala : GlobalData.Falas
@onready var name_text: RichTextLabel = $Dialogue/NinePatchRect/Name
@onready var text_text: RichTextLabel = $Dialogue/NinePatchRect/Text
@onready var dialogue: Control = $Dialogue
@onready var interact_icon: Control = $InteractIcon
var falas = []
var current_dialogue_id = -1
var derrotado := false
var enfrentado := false

func _ready() -> void:
	interact_icon.visible = false
	dialogue.visible = false
	falas = GlobalData.Texts[npc_type][state_fala]
	name_text.text = npc_name
	derrotado = GlobalData.defeated_enemies.count(npc_name) > 0		
	enfrentado = GlobalData.faced_enemies.count(npc_name) > 0
	
func talk():
	if derrotado:
		print(npc_name, " já foi derrotado")		
	elif enfrentado:
		print(npc_name, "já foi enfrentado, mas ganhou")
		
	current_dialogue_id+=1
	if current_dialogue_id >= len(falas):
		current_dialogue_id = -1
		dialogue.visible = false
		return
	text_text.text = falas[current_dialogue_id][GameSettings.lang[GameSettings.currentLanguage]]
	dialogue.visible = true	
