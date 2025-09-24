extends Node

## 简单背景音乐播放器 - 支持多平台导出
## 自动加载音乐文件，支持顺序和随机循环播放

# 播放模式
enum PlayMode {
	SEQUENTIAL,  # 顺序循环
	RANDOM      # 随机循环
}

# 配置
@export var play_mode: PlayMode = PlayMode.SEQUENTIAL    # 播放模式
@export var auto_start: bool = true                      # 自动开始播放

# 预设音乐文件列表（用于导出版本）
@export var music_files_list: Array[String] = [
]

# 内部变量
var audio_player: AudioStreamPlayer
var music_files: Array[String] = []
var current_index: int = 0
var played_indices: Array[int] = []  # 随机模式已播放的索引

# 音量控制相关
var current_volume: float = 1.0  # 当前音量 (0.0-1.0)
var is_muted: bool = false       # 是否静音
var volume_before_mute: float = 1.0  # 静音前的音量

func _ready():
	# 创建音频播放器
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	audio_player.finished.connect(_on_music_finished)
	
	# 从全局变量读取初始音量设置
	current_volume = GlobalVariables.BackgroundMusicVolume
	audio_player.volume_db = linear_to_db(current_volume)
	
	# 加载音乐文件
	_load_music_files()
	
	# 自动开始播放
	if auto_start and music_files.size() > 0:
		play_next()

func _load_music_files():
	"""加载音乐文件"""
	music_files.clear()
	
	# 在编辑器中尝试动态加载文件夹
	if OS.has_feature("editor"):
		_load_from_folder()
	
	# 如果没有找到文件或者是导出版本，使用预设列表
	if music_files.size() == 0:
		_load_from_preset_list()

func _load_from_folder():
	"""从文件夹动态加载（仅编辑器模式）"""
	var music_folder = "res://audio/music/"
	var dir = DirAccess.open(music_folder)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				var extension = file_name.get_extension().to_lower()
				# 支持常见音频格式
				if extension in ["mp3", "ogg", "wav"]:
					music_files.append(music_folder + file_name)
					print("动态加载音乐: ", file_name)
			file_name = dir.get_next()
		
		print("动态加载了 ", music_files.size(), " 首音乐")

func _load_from_preset_list():
	"""从预设列表加载音乐"""
	for file_path in music_files_list:
		if ResourceLoader.exists(file_path):
			music_files.append(file_path)
			#print("预设加载音乐: ", file_path.get_file())
		else:
			print("音乐文件不存在: ", file_path)
	
	print("预设加载了 ", music_files.size(), " 首音乐")

func play_next():
	"""播放下一首音乐"""
	if music_files.size() == 0:
		print("没有音乐文件可播放")
		return
	
	# 根据播放模式获取下一首音乐的索引
	match play_mode:
		PlayMode.SEQUENTIAL:
			current_index = (current_index + 1) % music_files.size()
		PlayMode.RANDOM:
			current_index = _get_random_index()
	
	# 播放音乐
	_play_music(current_index)

func _get_random_index() -> int:
	"""获取随机音乐索引（避免重复直到所有歌曲都播放过）"""
	# 如果所有歌曲都播放过了，重置列表
	if played_indices.size() >= music_files.size():
		played_indices.clear()
	
	# 获取未播放的歌曲索引
	var available_indices: Array[int] = []
	for i in range(music_files.size()):
		if i not in played_indices:
			available_indices.append(i)
	
	# 随机选择一个
	if available_indices.size() > 0:
		var random_choice = available_indices[randi() % available_indices.size()]
		played_indices.append(random_choice)
		return random_choice
	
	return 0

func _play_music(index: int):
	"""播放指定索引的音乐"""
	if index < 0 or index >= music_files.size():
		return
	
	var music_path = music_files[index]
	var audio_stream = load(music_path)
	
	if audio_stream:
		audio_player.stream = audio_stream
		audio_player.play()
		print("正在播放: ", music_path.get_file())
	else:
		print("加载音乐失败: ", music_path)

func _on_music_finished():
	"""音乐播放完成时自动播放下一首"""
	play_next()

# 公共接口方法
func set_play_mode(mode: PlayMode):
	"""设置播放模式"""
	play_mode = mode
	played_indices.clear()  # 重置随机播放历史
	print("播放模式设置为: ", "顺序循环" if mode == PlayMode.SEQUENTIAL else "随机循环")

func toggle_play_mode():
	"""切换播放模式"""
	if play_mode == PlayMode.SEQUENTIAL:
		set_play_mode(PlayMode.RANDOM)
	else:
		set_play_mode(PlayMode.SEQUENTIAL)

func get_current_music_name() -> String:
	"""获取当前播放的音乐名称"""
	if current_index >= 0 and current_index < music_files.size():
		return music_files[current_index].get_file()
	return ""

# 运行时添加音乐文件（用于用户自定义音乐）
func add_music_file(file_path: String) -> bool:
	"""添加音乐文件到播放列表"""
	if ResourceLoader.exists(file_path):
		music_files.append(file_path)
		print("添加音乐: ", file_path.get_file())
		return true
	else:
		print("音乐文件不存在: ", file_path)
		return false

# ============================= 音量控制功能 =====================================

func set_volume(volume: float):
	"""设置音量 (0.0-1.0)"""
	current_volume = clamp(volume, 0.0, 1.0)
	if not is_muted:
		audio_player.volume_db = linear_to_db(current_volume)
	#print("背景音乐音量设置为: ", current_volume)

func get_volume() -> float:
	"""获取当前音量"""
	return current_volume

func set_mute(muted: bool):
	"""设置静音状态"""
	if muted and not is_muted:
		# 静音
		volume_before_mute = current_volume
		audio_player.volume_db = -80.0  # 设置为最小音量
		is_muted = true
		print("背景音乐已静音")
	elif not muted and is_muted:
		# 取消静音
		audio_player.volume_db = linear_to_db(current_volume)
		is_muted = false
		print("背景音乐取消静音")

func toggle_mute():
	"""切换静音状态"""
	set_mute(not is_muted)

func is_music_muted() -> bool:
	"""获取静音状态"""
	return is_muted

func pause():
	"""暂停音乐"""
	if audio_player.playing:
		audio_player.stream_paused = true
		print("背景音乐已暂停")

func resume():
	"""恢复音乐"""
	if audio_player.stream_paused:
		audio_player.stream_paused = false
		print("背景音乐已恢复")

func stop():
	"""停止音乐"""
	if audio_player.playing:
		audio_player.stop()
		print("背景音乐已停止")

func is_playing() -> bool:
	"""检查是否正在播放"""
	return audio_player.playing and not audio_player.stream_paused

func get_current_position() -> float:
	"""获取当前播放位置（秒）"""
	return audio_player.get_playback_position()

func get_current_length() -> float:
	"""获取当前音乐总长度（秒）"""
	if audio_player.stream:
		return audio_player.stream.get_length()
	return 0.0 
