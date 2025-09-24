extends TextureRect
class_name HTTPTextureRect

signal loading_started
signal loading_finished(success: bool)

# HTTP请求节点
var http_request: HTTPRequest

func _ready():
	# 创建HTTP请求节点
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	# 连接信号
	http_request.request_completed.connect(_on_request_completed)

# 从URL加载图像
func load_from_url(url: String, custom_headers: Array = []) -> void:
	if url.is_empty():
		push_error("HTTPTextureRect: URL不能为空")
		loading_finished.emit(false)
		return
		
	loading_started.emit()
	
	# 发起HTTP请求
	var error = http_request.request(url, custom_headers)
	if error != OK:
		push_error("HTTPTextureRect: 发起HTTP请求失败，错误码: " + str(error))
		loading_finished.emit(false)

# HTTP请求完成的回调函数
func _on_request_completed(result, response_code, headers, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		push_error("HTTPTextureRect: HTTP请求失败，错误码: " + str(result))
		loading_finished.emit(false)
		return
	
	if response_code != 200:
		push_error("HTTPTextureRect: HTTP请求返回非200状态码: " + str(response_code))
		loading_finished.emit(false)
		return
	
	# 检查内容类型
	var content_type = ""
	for header in headers:
		if header.to_lower().begins_with("content-type:"):
			content_type = header.substr(13).strip_edges().to_lower()
			#print("HTTPTextureRect: 内容类型: ", content_type)
			break
	
	# 创建图像
	var image = Image.new()
	var error = ERR_INVALID_DATA
	
	# 根据内容类型选择加载方法
	if content_type.begins_with("image/jpeg") or content_type.begins_with("image/jpg"):
		error = image.load_jpg_from_buffer(body)
	elif content_type.begins_with("image/png"):
		error = image.load_png_from_buffer(body)
	elif content_type.begins_with("image/webp"):
		error = image.load_webp_from_buffer(body)
	elif content_type.begins_with("image/bmp"):
		error = image.load_bmp_from_buffer(body)
	else:
		# 未知内容类型，尝试常见格式
		error = image.load_jpg_from_buffer(body)
		if error != OK:
			error = image.load_png_from_buffer(body)
			if error != OK:
				error = image.load_webp_from_buffer(body)
				if error != OK:
					error = image.load_bmp_from_buffer(body)
	
	# 检查加载结果
	if error != OK:
		push_error("HTTPTextureRect: 无法加载图像，错误码: " + str(error))
		loading_finished.emit(false)
		return
	
	# 创建纹理并应用
	var texture = ImageTexture.create_from_image(image)
	self.texture = texture
	#print("HTTPTextureRect: 图像加载成功，尺寸: ", image.get_width(), "x", image.get_height())
	loading_finished.emit(true)

# 加载QQ头像的便捷方法
func load_qq_avatar(qq_number: String) -> void:
	if not qq_number.is_valid_int():
		push_error("HTTPTextureRect: QQ号必须为纯数字")
		loading_finished.emit(false)
		return
	
	# 使用QQ头像API
	#var url = "https://q.qlogo.cn/headimg_dl?dst_uin=" + qq_number + "&spec=640&img_type=png"
	var url = "http://q1.qlogo.cn/g?b=qq&nk="+qq_number+"&s=100"
	
	# 添加浏览器模拟头
	var headers = [
		"User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
		"Accept: image/png,image/jpeg,image/webp,image/*,*/*;q=0.8"
	]
	
	# 加载图像
	load_from_url(url, headers) 
