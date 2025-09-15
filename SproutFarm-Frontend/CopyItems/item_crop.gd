extends Button

@onready var title :Label = $Title
@onready var crop_image: Sprite2D = $CropImage


func _ready() -> void:
	title.text = self.text
	pass
