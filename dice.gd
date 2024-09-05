extends RigidBody3D

@export var maxRandomForce := 0.1
@onready var faces: Node3D = $Faces
var isMoving := false
var hasNumber := true
var hasRolled := false
var pos : Vector3

func _ready() -> void:
	pos = position	

func _physics_process(delta: float) -> void:
	isMoving = linear_velocity.length() > 0.01	
	position.x = 0
	position.z = 0
	if Input.is_key_pressed(KEY_SPACE):
		_roll()#roll_dice()
	elif not isMoving and hasRolled:
		get_number()		
	
	
func get_number():
	var highest_y = -INF
	var number
	
	for node in faces.get_children():
		var y_value = node.global_position.y
		
		if not highest_y || y_value > highest_y:
			highest_y = y_value
			number = node.name
	print(number)
	hasNumber = true
	hasRolled = false
	return int(str(number))

func roll_dice():
	if isMoving: return
	position = pos
	hasNumber = false
	
	apply_torque_impulse(Vector3(randf(), randf(), randf()) * 20)
	
func _roll():
	position = pos
	
	for i in range(10):
		transform.basis = Basis(Vector3.RIGHT,randf_range(0, 2*PI)) * transform.basis
		transform.basis = Basis(Vector3.UP,randf_range(0, 2*PI)) * transform.basis
		transform.basis = Basis(Vector3.FORWARD,randf_range(0, 2*PI)) * transform.basis
	#apply_central_impulse(Vector3.UP * maxRandomForce)
	hasRolled = true
