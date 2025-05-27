# toast.gd
extends Node

const ToastScene = preload("res://components/ToastShow.tscn")

static func show(text: String, 
				color: Color = Color.WHITE,
				duration: float = 3.0,
				fade: float = 1.0) -> void:
	var toast = ToastScene.instantiate()
	# 延迟设置参数确保节点初始化完成
	toast.call_deferred("setup", text, color, duration, fade)
