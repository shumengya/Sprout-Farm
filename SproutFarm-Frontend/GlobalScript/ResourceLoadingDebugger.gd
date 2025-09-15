extends Node

## 资源加载调试器
## 用于诊断和监控资源加载问题

class_name ResourceLoadingDebugger

# 调试信息收集
var loading_stats: Dictionary = {}
var failed_resources: Array = []
var performance_metrics: Dictionary = {}

## 初始化调试器
func _ready():
	print("[ResourceLoadingDebugger] 资源加载调试器已启动")
	_init_performance_monitoring()

## 初始化性能监控
func _init_performance_monitoring():
	performance_metrics = {
		"total_load_time": 0.0,
		"average_load_time": 0.0,
		"peak_memory_usage": 0,
		"current_memory_usage": 0,
		"successful_loads": 0,
		"failed_loads": 0
	}

## 记录资源加载开始
func start_loading_resource(resource_path: String) -> int:
	var start_time = Time.get_ticks_msec()
	var load_id = randi()
	
	loading_stats[load_id] = {
		"path": resource_path,
		"start_time": start_time,
		"status": "loading"
	}
	
	return load_id

## 记录资源加载完成
func finish_loading_resource(load_id: int, success: bool, resource: Resource = null):
	if not loading_stats.has(load_id):
		return
	
	var end_time = Time.get_ticks_msec()
	var load_info = loading_stats[load_id]
	var load_time = end_time - load_info["start_time"]
	
	load_info["end_time"] = end_time
	load_info["load_time"] = load_time
	load_info["success"] = success
	load_info["status"] = "completed"
	
	# 更新性能指标
	performance_metrics["total_load_time"] += load_time
	if success:
		performance_metrics["successful_loads"] += 1
		if resource:
			load_info["resource_size"] = _get_resource_memory_size(resource)
	else:
		performance_metrics["failed_loads"] += 1
		failed_resources.append(load_info["path"])
	
	# 计算平均加载时间
	var total_loads = performance_metrics["successful_loads"] + performance_metrics["failed_loads"]
	if total_loads > 0:
		performance_metrics["average_load_time"] = performance_metrics["total_load_time"] / total_loads
	
	# 更新内存使用情况
	_update_memory_usage()

## 获取资源内存大小估算
func _get_resource_memory_size(resource: Resource) -> int:
	if resource is Texture2D:
		var texture = resource as Texture2D
		var size = texture.get_size()
		# 估算：RGBA * 宽 * 高 * 4字节
		return size.x * size.y * 4
	return 0

## 更新内存使用情况
func _update_memory_usage():
	var current_memory = OS.get_static_memory_usage()
	performance_metrics["current_memory_usage"] = current_memory
	
	if current_memory > performance_metrics["peak_memory_usage"]:
		performance_metrics["peak_memory_usage"] = current_memory

## 检测设备资源加载能力
func detect_device_capabilities() -> Dictionary:
	var capabilities = {}
	
	# 设备基本信息
	capabilities["platform"] = OS.get_name()
	capabilities["processor_count"] = OS.get_processor_count()
	capabilities["memory_total"] = OS.get_static_memory_usage()
	
	# 图形信息
	var rendering_device = RenderingServer.get_rendering_device()
	if rendering_device:
		capabilities["gpu_name"] = rendering_device.get_device_name()
		capabilities["gpu_vendor"] = rendering_device.get_device_vendor_name()
	
	# 存储信息
	capabilities["user_data_dir"] = OS.get_user_data_dir()
	
	# 性能测试
	capabilities["texture_loading_speed"] = _benchmark_texture_loading()
	
	return capabilities

## 基准测试纹理加载速度
func _benchmark_texture_loading() -> float:
	var test_path = "res://assets/作物/默认/0.webp"
	if not ResourceLoader.exists(test_path):
		return -1.0
	
	var start_time = Time.get_ticks_msec()
	var iterations = 10
	
	for i in range(iterations):
		var texture = ResourceLoader.load(test_path)
		if not texture:
			return -1.0
	
	var end_time = Time.get_ticks_msec()
	return float(end_time - start_time) / iterations

## 诊断资源加载问题
func diagnose_loading_issues() -> Dictionary:
	var diagnosis = {
		"issues_found": [],
		"recommendations": [],
		"severity": "normal"
	}
	
	# 检查失败率
	var total_loads = performance_metrics["successful_loads"] + performance_metrics["failed_loads"]
	if total_loads > 0:
		var failure_rate = float(performance_metrics["failed_loads"]) / total_loads
		if failure_rate > 0.1:  # 失败率超过10%
			diagnosis["issues_found"].append("资源加载失败率过高: %.1f%%" % (failure_rate * 100))
			diagnosis["recommendations"].append("检查资源文件完整性和路径正确性")
			diagnosis["severity"] = "warning"
		
		if failure_rate > 0.3:  # 失败率超过30%
			diagnosis["severity"] = "critical"
			diagnosis["recommendations"].append("考虑降低资源质量或减少同时加载的资源数量")
	
	# 检查加载速度
	if performance_metrics["average_load_time"] > 100:  # 平均加载时间超过100ms
		diagnosis["issues_found"].append("资源加载速度较慢: %.1fms" % performance_metrics["average_load_time"])
		diagnosis["recommendations"].append("考虑使用多线程加载或预加载常用资源")
		if diagnosis["severity"] == "normal":
			diagnosis["severity"] = "warning"
	
	# 检查内存使用
	var memory_mb = performance_metrics["peak_memory_usage"] / (1024 * 1024)
	if memory_mb > 500:  # 峰值内存使用超过500MB
		diagnosis["issues_found"].append("内存使用过高: %.1fMB" % memory_mb)
		diagnosis["recommendations"].append("实施LRU缓存清理或降低缓存大小")
		if diagnosis["severity"] == "normal":
			diagnosis["severity"] = "warning"
	
	# 检查平台特定问题
	var platform = OS.get_name()
	if platform in ["Android", "iOS"]:
		if performance_metrics["failed_loads"] > 5:
			diagnosis["issues_found"].append("移动设备上资源加载失败较多")
			diagnosis["recommendations"].append("移动设备内存有限，建议降低资源质量或实施更积极的缓存清理")
	
	return diagnosis

## 生成资源加载报告
func generate_loading_report() -> String:
	var report = "=== 资源加载调试报告 ===\n\n"
	
	# 基本统计
	report += "基本统计:\n"
	report += "  成功加载: %d\n" % performance_metrics["successful_loads"]
	report += "  失败加载: %d\n" % performance_metrics["failed_loads"]
	report += "  平均加载时间: %.1fms\n" % performance_metrics["average_load_time"]
	report += "  总加载时间: %.1fs\n" % (performance_metrics["total_load_time"] / 1000.0)
	report += "  峰值内存使用: %.1fMB\n\n" % (performance_metrics["peak_memory_usage"] / (1024 * 1024))
	
	# 设备信息
	var capabilities = detect_device_capabilities()
	report += "设备信息:\n"
	report += "  平台: %s\n" % capabilities.get("platform", "未知")
	report += "  CPU核心数: %d\n" % capabilities.get("processor_count", 0)
	report += "  纹理加载速度: %.1fms\n\n" % capabilities.get("texture_loading_speed", -1)
	
	# 失败的资源
	if failed_resources.size() > 0:
		report += "加载失败的资源:\n"
		for i in range(min(10, failed_resources.size())):  # 只显示前10个
			report += "  - %s\n" % failed_resources[i]
		if failed_resources.size() > 10:
			report += "  ... 还有 %d 个失败的资源\n" % (failed_resources.size() - 10)
		report += "\n"
	
	# 诊断结果
	var diagnosis = diagnose_loading_issues()
	report += "诊断结果 [%s]:\n" % diagnosis["severity"].to_upper()
	for issue in diagnosis["issues_found"]:
		report += "  问题: %s\n" % issue
	for recommendation in diagnosis["recommendations"]:
		report += "  建议: %s\n" % recommendation
	
	return report

## 清理调试数据
func clear_debug_data():
	loading_stats.clear()
	failed_resources.clear()
	_init_performance_monitoring()
	print("[ResourceLoadingDebugger] 调试数据已清理")

## 导出调试数据到文件
func export_debug_data_to_file():
	var report = generate_loading_report()
	var datetime = Time.get_datetime_dict_from_system()
	var filename = "resource_loading_debug_%04d%02d%02d_%02d%02d%02d.txt" % [
		datetime.year, datetime.month, datetime.day,
		datetime.hour, datetime.minute, datetime.second
	]
	
	var file_path = OS.get_user_data_dir() + "/" + filename
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(report)
		file.close()
		print("[ResourceLoadingDebugger] 调试报告已导出到: ", file_path)
		return file_path
	else:
		print("[ResourceLoadingDebugger] 导出调试报告失败")
		return "" 