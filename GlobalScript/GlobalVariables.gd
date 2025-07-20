extends Node

const  client_version :String = "2.0.1" #记录客户端版本

var  isZoomDisabled :bool = false

const  server_configs = [
	#{"host": "127.0.0.1", "port": 6060, "name": "本地"},
	#{"host": "192.168.31.233", "port": 6060, "name": "家里面局域网"},
	{"host": "192.168.31.205", "port": 6060, "name": "家里面电脑"},
	#{"host": "192.168.1.110", "port": 4040, "name": "萌芽局域网"},
	#{"host": "47.108.90.0", "port": 4040, "name": "成都内网穿透"}#成都内网穿透
	#{"host": "47.108.90.0", "port": 6060, "name": "成都公网"}#成都服务器
]

const DisableWeatherDisplay :bool = false #是否禁止显示天气
const BackgroundMusicVolume = 1.0 #背景音乐音量
