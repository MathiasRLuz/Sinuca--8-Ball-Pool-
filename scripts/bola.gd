extends RigidBody2D

func _on_area_2d_body_entered(body):
	$AudioStreamPlayer.play()
