extends Node
#一个基本的TCP客户端API
class_name TCPClient

signal connected_to_server#连接到服务器信号
signal connection_failed#连接失败信号
signal connection_closed#连接关闭信号
signal data_received(data)#收到数据信号

var tcp: StreamPeerTCP = StreamPeerTCP.new()
var host: String = "127.0.0.1"
var port: int = 4040
var is_connected: bool = false
var auto_reconnect: bool = true
var reconnect_delay: float = 2.0

# 缓冲区管理
var buffer = ""

func _ready():
	pass

func _process(_delta):
	# 更新连接状态
	tcp.poll()
	_update_connection_status()
	_check_for_data()


func connect_to_server(custom_host = null, custom_port = null):
	if custom_host != null:
		host = custom_host
	if custom_port != null:
		port = custom_port
		
	if tcp.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		tcp.disconnect_from_host()
		print("连接到服务器: %s:%s" % [host, port])
		var error = tcp.connect_to_host(host, port)
		if error != OK:
			print("连接错误: %s" % error)
			emit_signal("connection_failed")


func disconnect_from_server():
	tcp.disconnect_from_host()
	is_connected = false
	emit_signal("connection_closed")


func _update_connection_status():
	var status = tcp.get_status()
	
	match status:
		StreamPeerTCP.STATUS_NONE:
			if is_connected:
				is_connected = false
				print("连接已断开")
				emit_signal("connection_closed")
				
				if auto_reconnect:
					var timer = get_tree().create_timer(reconnect_delay)
					await timer.timeout
					connect_to_server()
		
		StreamPeerTCP.STATUS_CONNECTING:
			pass
			
		StreamPeerTCP.STATUS_CONNECTED:
			if not is_connected:
				is_connected = true
				tcp.set_no_delay(true) # 禁用Nagle算法提高响应速度
				print("已连接到服务器")
				emit_signal("connected_to_server")
				
		StreamPeerTCP.STATUS_ERROR:
			is_connected = false
			print("连接错误")
			emit_signal("connection_failed")
			
			if auto_reconnect:
				var timer = get_tree().create_timer(reconnect_delay)
				await timer.timeout
				connect_to_server()


func _check_for_data():
	if tcp.get_status() == StreamPeerTCP.STATUS_CONNECTED and tcp.get_available_bytes() > 0:
		var bytes = tcp.get_available_bytes()
		var data = tcp.get_utf8_string(bytes)
		
		# 将数据添加到缓冲区进行处理
		buffer += data
		_process_buffer()


func _process_buffer():
	# 处理缓冲区中的JSON消息
	# 假设每条消息以换行符结尾
	while "\n" in buffer:
		var message_end = buffer.find("\n")
		var message_text = buffer.substr(0, message_end)
		buffer = buffer.substr(message_end + 1)
		
		# 处理JSON数据
		if message_text.strip_edges() != "":
			var json = JSON.new()
			var error = json.parse(message_text)
			
			if error == OK:
				var data = json.get_data()
				#print("收到JSON数据: ", data)
				emit_signal("data_received", data)
			else:
				# 非JSON格式数据，直接传递
				#print("收到原始数据: ", message_text)
				emit_signal("data_received", message_text)

func send_data(data):
	if not is_connected:
		print("未连接，无法发送数据")
		return false
	
	var message: String
	
	# 如果是字典/数组，转换为JSON
	if typeof(data) == TYPE_DICTIONARY or typeof(data) == TYPE_ARRAY:
		message = JSON.stringify(data) + "\n"
	else:
		# 否则简单转换为字符串
		message = str(data) + "\n"
	
	var result = tcp.put_data(message.to_utf8_buffer())
	return result == OK

func is_client_connected() -> bool:
	return is_connected

# 示例: 如何使用此客户端
# 
# func _ready():
#     var client = TCPClient.new()
#     add_child(client)
#     
#     client.connected_to_server.connect(_on_connected)
#     client.connection_failed.connect(_on_connection_failed)
#     client.connection_closed.connect(_on_connection_closed)
#     client.data_received.connect(_on_data_received)
#     
#     client.connect_to_server("127.0.0.1", 9000)
# 
# func _on_connected():
#     print("已连接")
#     client.send_data({"type": "greeting", "content": "Hello Server!"})
# 
# func _on_data_received(data):
#     print("收到数据: ", data)
