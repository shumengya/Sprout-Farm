extends Panel

# 预添加常用的面板
@onready var main_game = get_node("/root/main")
@onready var tcp_network_manager_panel: Panel = $'../TCPNetworkManagerPanel'

func _ready() -> void:
	self.hide()
	visibility_changed.connect(_on_visibility_changed)
	pass

func _on_quit_button_pressed() -> void:
	self.hide()
	pass 

#访问花卉农场QQ：520
func _on_flower_farm_button_pressed() -> void:
	_visit_special_farm("520", "花卉农场") 

#访问杂交农场QQ：666
func _on_hybrid_farm_button_pressed() -> void:
	_visit_special_farm("666", "杂交农场")

#访问幸运农场QQ：888
func _on_lucky_farm_button_pressed() -> void:
	_visit_special_farm("888", "幸运农场")

#访问稻谷农场QQ：111
func _on_rice_farm_button_pressed() -> void:
	_visit_special_farm("111", "稻谷农场") 

#访问小麦农场QQ：222
func _on_wheat_farm_button_pressed() -> void:
	_visit_special_farm("222", "小麦农场") 
	
#访问水果农场QQ：333
func _on_fruit_farm_button_pressed() -> void:
	_visit_special_farm("333", "水果农场")

# 访问特殊农场的通用函数
func _visit_special_farm(farm_qq: String, farm_name: String) -> void:
	# 访问农场后取消禁用相机功能，否则无法恢复
	GlobalVariables.isZoomDisabled = false
	
	# 检查网络连接
	if not tcp_network_manager_panel or not tcp_network_manager_panel.is_connected_to_server():
		Toast.show("未连接服务器，无法访问" + farm_name, Color.RED)
		return
	
	# 检查是否尝试访问自己
	if main_game and main_game.user_name == farm_qq:
		Toast.show("不能访问自己的农场", Color.ORANGE)
		return
	
	# 发送访问特殊农场请求
	if tcp_network_manager_panel and tcp_network_manager_panel.has_method("sendVisitPlayer"):
		var success = tcp_network_manager_panel.sendVisitPlayer(farm_qq)
		if success:
			Toast.show("正在访问" + farm_name + "...", Color.YELLOW)
			# 隐藏面板
			self.hide()
		else:
			Toast.show("发送访问请求失败", Color.RED)
	else:
		Toast.show("网络管理器不可用", Color.RED)

# 面板显示与隐藏切换处理
func _on_visibility_changed():
	if visible:
		GlobalVariables.isZoomDisabled = true
	else:
		GlobalVariables.isZoomDisabled = false
