extends Control
#各种面板
@onready var game_about_panel: Panel = $GameAboutPanel
@onready var game_update_panel: Panel = $GameUpdatePanel
#@onready var game_setting_panel: Panel = $GameSettingPanel

@onready var game_version_label: Label = $GUI/GameVersionLabel

@export var smy :TextureRect

func _ready():
	game_version_label.text = "版本号："+GlobalVariables.client_version
	pass 

func SetGameVersionLabel(version :String):
	game_version_label.text = version
	pass 

#开始游戏
func _on_start_game_button_pressed() -> void:
	await get_tree().process_frame
	get_tree().change_scene_to_file('res://MainGame.tscn')
	pass 

#游戏设置
func _on_game_setting_button_pressed() -> void:
	#game_setting_panel.show()
	pass 

#游戏更新
func _on_game_update_button_pressed() -> void:
	game_update_panel.ShowPanel(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        )
	pass 

#游戏关于
func _on_game_about_button_pressed() -> void:
	game_about_panel.show()
	pass 

#游戏结束
func _on_exit_button_pressed() -> void:
	get_tree().quit()
	pass 
