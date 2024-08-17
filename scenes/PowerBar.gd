extends ProgressBar

var max_power = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	max_power = get_parent().MAX_POWER

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var power = $"../Taco".power
	if power > max_power:
		power = max_power
		
	value = power * 100/max_power
			
