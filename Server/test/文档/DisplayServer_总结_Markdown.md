# DisplayServer API 参考文档

## 类简介

**继承**：Object

DisplayServer 是用于低阶窗口管理的服务器接口。所有与窗口管理相关的内容都由 DisplayServer（显示服务器）处理。

> **无头模式**：如果使用 `--headless` 命令行参数启动引擎，就会禁用所有渲染和窗口管理功能，此时 DisplayServer 的大多数函数都会返回虚设值。

---

## 方法列表

### 🔔 系统交互

#### `void beep()`
发出系统提示音。

#### `void enable_for_stealing_focus(process_id: int)`
允许指定进程获取焦点。

#### `void force_process_and_drop_events()`
强制处理并丢弃所有事件。

---

### 📋 剪贴板操作

#### `String clipboard_get()`
获取剪贴板文本内容。

#### `Image clipboard_get_image()`
获取剪贴板图像内容。

#### `String clipboard_get_primary()`
获取主剪贴板文本内容（仅限 Linux）。

#### `bool clipboard_has()`
检查剪贴板是否有内容。

#### `bool clipboard_has_image()`
检查剪贴板是否有图像。

#### `void clipboard_set(clipboard: String)`
设置剪贴板文本内容。

#### `void clipboard_set_primary(clipboard_primary: String)`
设置主剪贴板文本内容（仅限 Linux）。

---

### 🖱️ 鼠标和光标

#### `CursorShape cursor_get_shape()`
获取当前光标形状。

#### `void cursor_set_custom_image(cursor: Resource, shape: CursorShape = 0, hotspot: Vector2 = Vector2(0, 0))`
设置自定义光标图像。

#### `void cursor_set_shape(shape: CursorShape)`
设置光标形状。

#### `BitField[MouseButtonMask] mouse_get_button_state()`
获取鼠标按键状态。

#### `MouseMode mouse_get_mode()`
获取鼠标模式。

#### `Vector2i mouse_get_position()`
获取鼠标位置。

#### `void mouse_set_mode(mouse_mode: MouseMode)`
设置鼠标模式。

#### `void warp_mouse(position: Vector2i)`
将鼠标光标移动到指定位置。

---

### 💬 对话框

#### `Error dialog_input_text(title: String, description: String, existing_text: String, callback: Callable)`
显示文本输入对话框。

#### `Error dialog_show(title: String, description: String, buttons: PackedStringArray, callback: Callable)`
显示系统对话框。

#### `Error file_dialog_show(title: String, current_directory: String, filename: String, show_hidden: bool, mode: FileDialogMode, filters: PackedStringArray, callback: Callable)`
显示文件选择对话框。

#### `Error file_dialog_with_options_show(title: String, current_directory: String, root: String, filename: String, show_hidden: bool, mode: FileDialogMode, filters: PackedStringArray, options: Array[Dictionary], callback: Callable)`
显示带扩展选项的文件选择对话框。

---

### 🎨 主题和颜色

#### `Color get_accent_color()`
获取系统强调色。

#### `Color get_base_color()`
获取系统基础色。

#### `bool is_dark_mode()`
检查系统是否为深色模式。

#### `bool is_dark_mode_supported()`
检查系统是否支持深色模式。

#### `void set_system_theme_change_callback(callable: Callable)`
设置系统主题变化时的回调。

---

### 📱 显示和屏幕

#### `Array[Rect2] get_display_cutouts()`
获取显示器刘海信息。

#### `Rect2i get_display_safe_area()`
获取显示器安全区域。

#### `int get_keyboard_focus_screen()`
获取键盘焦点所在屏幕。

#### `String get_name()`
获取显示服务器名称。

#### `int get_primary_screen()`
获取主屏幕索引。

#### `int get_screen_count()`
获取屏幕数量。

#### `int get_screen_from_rect(rect: Rect2)`
根据矩形位置获取屏幕索引。

#### `bool get_swap_cancel_ok()`
获取是否交换确定取消按钮。

#### `int get_window_at_screen_position(position: Vector2i)`
获取指定屏幕位置的窗口ID。

#### `PackedInt32Array get_window_list()`
获取所有窗口ID列表。

---

### 🖥️ 屏幕操作

#### `int screen_get_dpi(screen: int = -1)`
获取屏幕DPI。

#### `Image screen_get_image(screen: int = -1)`
获取屏幕截图。

#### `Image screen_get_image_rect(rect: Rect2i)`
获取屏幕指定区域截图。

#### `float screen_get_max_scale()`
获取所有屏幕的最大缩放系数。

#### `ScreenOrientation screen_get_orientation(screen: int = -1)`
获取屏幕朝向。

#### `Color screen_get_pixel(position: Vector2i)`
获取指定位置的像素颜色。

#### `Vector2i screen_get_position(screen: int = -1)`
获取屏幕位置。

#### `float screen_get_refresh_rate(screen: int = -1)`
获取屏幕刷新率。

#### `float screen_get_scale(screen: int = -1)`
获取屏幕缩放系数。

#### `Vector2i screen_get_size(screen: int = -1)`
获取屏幕大小。

#### `Rect2i screen_get_usable_rect(screen: int = -1)`
获取屏幕可用区域。

#### `bool screen_is_kept_on()`
检查屏幕是否保持开启。

#### `void screen_set_keep_on(enable: bool)`
设置屏幕保持开启。

#### `void screen_set_orientation(orientation: ScreenOrientation, screen: int = -1)`
设置屏幕朝向。

---

### 🖼️ 图标设置

#### `void set_icon(image: Image)`
设置窗口图标。

#### `void set_native_icon(filename: String)`
使用原生格式设置窗口图标。

---

### 💾 输出管理

#### `bool has_additional_outputs()`
检查是否有额外输出设备。

#### `void register_additional_output(object: Object)`
注册额外输出设备。

#### `void unregister_additional_output(object: Object)`
取消注册额外输出设备。

---

### ⚡ 功能检测

#### `bool has_feature(feature: Feature)`
检查是否支持指定功能。

#### `bool has_hardware_keyboard()`
检查是否有硬件键盘。

#### `bool is_touchscreen_available()`
检查是否支持触屏。

#### `bool is_window_transparency_available()`
检查是否支持窗口透明。

---

### ⌨️ 键盘

#### `int keyboard_get_current_layout()`
获取当前键盘布局。

#### `Key keyboard_get_keycode_from_physical(keycode: Key)`
从物理按键获取键码。

#### `Key keyboard_get_label_from_physical(keycode: Key)`
从物理按键获取标签。

#### `int keyboard_get_layout_count()`
获取键盘布局数量。

#### `String keyboard_get_layout_language(index: int)`
获取键盘布局语言。

#### `String keyboard_get_layout_name(index: int)`
获取键盘布局名称。

#### `void keyboard_set_current_layout(index: int)`
设置当前键盘布局。

---

### 📝 输入法

#### `Vector2i ime_get_selection()`
获取输入法选中范围。

#### `String ime_get_text()`
获取输入法文本。

---

### 🎯 状态指示器

#### `int create_status_indicator(icon: Texture2D, tooltip: String, callback: Callable)`
创建状态指示器。

#### `void delete_status_indicator(id: int)`
删除状态指示器。

#### `Rect2 status_indicator_get_rect(id: int)`
获取状态指示器位置。

#### `void status_indicator_set_callback(id: int, callback: Callable)`
设置状态指示器回调。

#### `void status_indicator_set_icon(id: int, icon: Texture2D)`
设置状态指示器图标。

#### `void status_indicator_set_menu(id: int, menu_rid: RID)`
设置状态指示器菜单。

#### `void status_indicator_set_tooltip(id: int, tooltip: String)`
设置状态指示器提示文本。

---

### 📱 数位板

#### `String tablet_get_current_driver()`
获取当前数位板驱动。

#### `int tablet_get_driver_count()`
获取数位板驱动数量。

#### `String tablet_get_driver_name(idx: int)`
获取数位板驱动名称。

#### `void tablet_set_current_driver(name: String)`
设置数位板驱动。

---

### 🗣️ 文本转语音

#### `Array[Dictionary] tts_get_voices()`
获取语音列表。

#### `PackedStringArray tts_get_voices_for_language(language: String)`
获取指定语言的语音列表。

#### `bool tts_is_paused()`
检查是否暂停。

#### `bool tts_is_speaking()`
检查是否正在朗读。

#### `void tts_pause()`
暂停朗读。

#### `void tts_resume()`
恢复朗读。

#### `void tts_set_utterance_callback(event: TTSUtteranceEvent, callable: Callable)`
设置朗读事件回调。

#### `void tts_speak(text: String, voice: String, volume: int = 50, pitch: float = 1.0, rate: float = 1.0, utterance_id: int = 0, interrupt: bool = false)`
开始朗读文本。

#### `void tts_stop()`
停止朗读。

---

### ⌨️ 虚拟键盘

#### `int virtual_keyboard_get_height()`
获取虚拟键盘高度。

#### `void virtual_keyboard_hide()`
隐藏虚拟键盘。

#### `void virtual_keyboard_show(existing_text: String, position: Rect2 = Rect2(0, 0, 0, 0), type: VirtualKeyboardType = 0, max_length: int = -1, cursor_start: int = -1, cursor_end: int = -1)`
显示虚拟键盘。

---

### 🪟 窗口管理

#### `bool window_can_draw(window_id: int = 0)`
检查窗口是否可绘制。

#### `int window_get_active_popup()`
获取活动弹出窗口ID。

#### `int window_get_attached_instance_id(window_id: int = 0)`
获取窗口附加的实例ID。

#### `int window_get_current_screen(window_id: int = 0)`
获取窗口所在屏幕。

#### `bool window_get_flag(flag: WindowFlags, window_id: int = 0)`
获取窗口标志。

#### `Vector2i window_get_max_size(window_id: int = 0)`
获取窗口最大尺寸。

#### `Vector2i window_get_min_size(window_id: int = 0)`
获取窗口最小尺寸。

#### `WindowMode window_get_mode(window_id: int = 0)`
获取窗口模式。

#### `int window_get_native_handle(handle_type: HandleType, window_id: int = 0)`
获取窗口原生句柄。

#### `Rect2i window_get_popup_safe_rect(window: int)`
获取弹出窗口安全区域。

#### `Vector2i window_get_position(window_id: int = 0)`
获取窗口位置。

#### `Vector2i window_get_position_with_decorations(window_id: int = 0)`
获取窗口位置（含边框）。

#### `Vector3i window_get_safe_title_margins(window_id: int = 0)`
获取标题栏安全边距。

#### `Vector2i window_get_size(window_id: int = 0)`
获取窗口大小。

#### `Vector2i window_get_size_with_decorations(window_id: int = 0)`
获取窗口大小（含边框）。

#### `Vector2i window_get_title_size(title: String, window_id: int = 0)`
获取标题栏大小。

#### `VSyncMode window_get_vsync_mode(window_id: int = 0)`
获取垂直同步模式。

#### `bool window_is_focused(window_id: int = 0)`
检查窗口是否有焦点。

#### `bool window_is_maximize_allowed(window_id: int = 0)`
检查窗口是否可最大化。

#### `bool window_maximize_on_title_dbl_click()`
检查双击标题栏是否最大化。

#### `bool window_minimize_on_title_dbl_click()`
检查双击标题栏是否最小化。

#### `void window_move_to_foreground(window_id: int = 0)`
将窗口移到前台。

#### `void window_request_attention(window_id: int = 0)`
请求窗口注意。

#### `void window_set_current_screen(screen: int, window_id: int = 0)`
设置窗口所在屏幕。

#### `void window_set_drop_files_callback(callback: Callable, window_id: int = 0)`
设置文件拖放回调。

#### `void window_set_exclusive(window_id: int, exclusive: bool)`
设置窗口独占模式。

#### `void window_set_flag(flag: WindowFlags, enabled: bool, window_id: int = 0)`
设置窗口标志。

#### `void window_set_ime_active(active: bool, window_id: int = 0)`
设置输入法是否激活。

#### `void window_set_ime_position(position: Vector2i, window_id: int = 0)`
设置输入法位置。

#### `void window_set_input_event_callback(callback: Callable, window_id: int = 0)`
设置输入事件回调。

#### `void window_set_input_text_callback(callback: Callable, window_id: int = 0)`
设置文本输入回调。

#### `void window_set_max_size(max_size: Vector2i, window_id: int = 0)`
设置窗口最大尺寸。

#### `void window_set_min_size(min_size: Vector2i, window_id: int = 0)`
设置窗口最小尺寸。

#### `void window_set_mode(mode: WindowMode, window_id: int = 0)`
设置窗口模式。

#### `void window_set_mouse_passthrough(region: PackedVector2Array, window_id: int = 0)`
设置鼠标穿透区域。

#### `void window_set_popup_safe_rect(window: int, rect: Rect2i)`
设置弹出窗口安全区域。

#### `void window_set_position(position: Vector2i, window_id: int = 0)`
设置窗口位置。

#### `void window_set_rect_changed_callback(callback: Callable, window_id: int = 0)`
设置窗口位置大小变化回调。

#### `void window_set_size(size: Vector2i, window_id: int = 0)`
设置窗口大小。

#### `void window_set_title(title: String, window_id: int = 0)`
设置窗口标题。

#### `void window_set_transient(window_id: int, parent_window_id: int)`
设置窗口为瞬态。

#### `void window_set_vsync_mode(vsync_mode: VSyncMode, window_id: int = 0)`
设置垂直同步模式。

#### `void window_set_window_buttons_offset(offset: Vector2i, window_id: int = 0)`
设置窗口按钮偏移。

#### `void window_set_window_event_callback(callback: Callable, window_id: int = 0)`
设置窗口事件回调。

#### `void window_start_drag(window_id: int = 0)`
开始拖拽窗口。

#### `void window_start_resize(edge: WindowResizeEdge, window_id: int = 0)`
开始调整窗口大小。

---

### 📞 帮助系统

#### `void help_set_search_callbacks(search_callback: Callable, action_callback: Callable)`
设置帮助系统搜索回调。

#### `void show_emoji_and_symbol_picker()`
显示表情符号选择器。

---

### ⚙️ 事件处理

#### `void process_events()`
处理事件。

---

## 常量

- `SCREEN_WITH_MOUSE_FOCUS = -4`：鼠标焦点所在屏幕
- `SCREEN_WITH_KEYBOARD_FOCUS = -3`：键盘焦点所在屏幕  
- `SCREEN_PRIMARY = -2`：主屏幕
- `SCREEN_OF_MAIN_WINDOW = -1`：主窗口所在屏幕
- `MAIN_WINDOW_ID = 0`：主窗口ID
- `INVALID_WINDOW_ID = -1`：无效窗口ID

---

## 枚举

### Feature
系统功能支持检测枚举，包含多种功能如子窗口、触屏、鼠标、剪贴板、虚拟键盘等支持检测。

### MouseMode  
鼠标模式枚举：可见、隐藏、捕获、限制等模式。

### ScreenOrientation
屏幕朝向枚举：横屏、竖屏及其反向，以及传感器自动模式。

### VirtualKeyboardType
虚拟键盘类型：默认、多行、数字、小数、电话、邮箱、密码、URL等。

### CursorShape
光标形状枚举：箭头、工字形、指向手形等多种光标样式。

### WindowFlags
窗口标志枚举：控制窗口的各种行为和外观属性。

### WindowMode
窗口模式枚举：窗口、最小化、最大化、全屏等模式。

### HandleType
句柄类型枚举：用于获取不同类型的原生窗口句柄。

### VSyncMode
垂直同步模式枚举：控制画面撕裂和帧率同步。

### TTSUtteranceEvent
语音朗读事件枚举：开始、结束、取消、边界等事件。

---

> **注意**：此文档已排除所有已弃用的方法。某些功能可能仅在特定平台上可用，请参考原始文档中的平台支持说明。