extends Node

# 全局通用功能脚本
# 使用方法：首先在项目设置的自动加载中添加此脚本，然后在任何地方使用 GlobalFunctions.函数名() 调用

func _ready():
	print("全局函数库已加载")

# 写入 TXT 文件	
func write_txt_file(file_path: String, text: String, append: bool = false) -> void:
	var file
	if append == true:
		file = FileAccess.open(file_path, FileAccess.READ_WRITE)  # 追加模式
		if file:
			file.seek_end()  # 移动光标到文件末尾
	else:
		file = FileAccess.open(file_path, FileAccess.WRITE)  # 覆盖模式
	if file:
		file.store_string(text)
		file.close()
		if has_node("/root/ToastScript"):
			get_node("/root/ToastScript").show("游戏已保存！", Color.GREEN, 5.0, 1.0)
	else:
		print("写入文件时打开失败: ", file_path)
		if has_node("/root/ToastScript"):
			get_node("/root/ToastScript").show("写入文件时打开失败！", Color.RED, 5.0, 1.0)
	
		
# 读取 TXT 文件
func read_txt_file(file_path: String) -> String:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var text = file.get_as_text()
		file.close()
		return text
	else:
		print("打开文件失败: ", file_path)
		return "false"

		
#生成随机数-用于作物随机死亡
func random_probability(probability: float) -> bool:
	# 确保传入的概率值在 0 到 1 之间
	if probability*0.001 < 0.0 or probability*0.001 > 1.0:
		print("概率值必须在 0 和 1 之间")
		return false
	
	# 生成一个 0 到 1 之间的随机数
	var random_value = randf()
	
	# 如果随机数小于等于概率值，则返回 true
	return random_value <= (probability*0.001)


# 格式化时间为可读字符串
func format_time(seconds: int) -> String:
	var minutes = seconds / 60
	seconds = seconds % 60
	var hours = minutes / 60
	minutes = minutes % 60
	
	if hours > 0:
		return "%02d:%02d:%02d" % [hours, minutes, seconds]
	else:
		return "%02d:%02d" % [minutes, seconds] 


#双击切换UI事件-比如按一下打开再按一下关闭
func double_click_close(node):
	if node.visible == false:
		node.show()
		pass
	else :
		node.hide()
		pass
	pass
