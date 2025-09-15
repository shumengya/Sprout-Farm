extends Control

@onready var http_texture_rect = $VBoxContainer/ImageContainer/HTTPTextureRect
@onready var url_input = $VBoxContainer/HBoxContainer/URLInput
@onready var load_url_button = $VBoxContainer/HBoxContainer/LoadURLButton
@onready var qq_input = $VBoxContainer/HBoxContainer2/QQInput
@onready var load_qq_button = $VBoxContainer/HBoxContainer2/LoadQQButton
@onready var status_label = $VBoxContainer/StatusLabel

func _ready():
	# 设置默认URL和QQ号
	url_input.text = "https://picsum.photos/200"
	qq_input.text = "3205788256"
	
	# 连接按钮信号
	load_url_button.pressed.connect(_on_load_url_button_pressed)
	load_qq_button.pressed.connect(_on_load_qq_button_pressed)
	
	# 连接HTTP纹理矩形的信号
	http_texture_rect.loading_started.connect(_on_loading_started)
	http_texture_rect.loading_finished.connect(_on_loading_finished)

func _on_load_url_button_pressed():
	var url = url_input.text.strip_edges()
	if url.is_empty():
		status_label.text = "状态: URL不能为空"
		return
	
	http_texture_rect.load_from_url(url)

func _on_load_qq_button_pressed():
	var qq_number = qq_input.text.strip_edges()
	if qq_number.is_empty() or not qq_number.is_valid_int():
		status_label.text = "状态: 无效的QQ号"
		return
	
	http_texture_rect.load_qq_avatar(qq_number)

func _on_loading_started():
	status_label.text = "状态: 正在加载..."

func _on_loading_finished(success: bool):
	if success:
		status_label.text = "状态: 加载成功"
	else:
		status_label.text = "状态: 加载失败" 
