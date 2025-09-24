extends Panel


var _2048_GAME = preload('res://Scene/SmallGame/2048Game.tscn').instantiate()
var PUSH_BOX = preload('res://Scene/SmallGame/PushBox.tscn').instantiate()
var SNAKE_GAME = preload('res://Scene/SmallGame/SnakeGame.tscn').instantiate()
var TETRIS = preload('res://Scene/SmallGame/Tetris.tscn').instantiate()


func _on_game_button_pressed() -> void:
	self.add_child(_2048_GAME)
	pass 


func _on_push_box_button_pressed() -> void:
	self.add_child(PUSH_BOX)
	pass 


func _on_snake_game_button_pressed() -> void:
	self.add_child(SNAKE_GAME)
	pass 


func _on_tetris_button_pressed() -> void:
	self.add_child(TETRIS)
	pass 


func _on_quit_button_pressed() -> void:
	self.hide()
	pass 
