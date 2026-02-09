extends SubViewport

# This allows you to type "jump_p1" or "jump_p2" directly in the Inspector
@export var player_action_name : String = "jump_p1"

# _init runs as soon as the object is created, before it even enters the tree.
# This is the safest place to override the physics world.
func _init():
	world_2d = World2D.new()

func _ready():
	pass
