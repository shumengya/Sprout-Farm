const express = require('express');
const fs = require('fs');
const path = require('path');
const bodyParser = require('body-parser');
const cors = require('cors');

// 创建 Express 应用
const app = express();
const PORT = 3000;

// 配置中间件
app.use(cors());  // 允许跨域资源共享
app.use(bodyParser.json());  // 解析 JSON 请求体

// 服务器存储目录，模拟远程存储位置
const SERVER_STORAGE_PATH = path.join(__dirname, 'game_saves');

// 确保存储目录存在
if (!fs.existsSync(SERVER_STORAGE_PATH)) {
    fs.mkdirSync(SERVER_STORAGE_PATH);
}

/**
 * 保存游戏数据到服务器
 * @route POST /save_game
 * @param {Object} req.body - 游戏保存数据
 * @returns {Object} 保存结果
 */
app.post('/save_game', (req, res) => {
    try {
        // 从请求体中获取用户名和完整的游戏数据
        const { user_name, ...gameData } = req.body;

        // 检查用户名是否存在
        if (!user_name) {
            return res.status(400).json({ 
                success: false, 
                message: '用户名不能为空' 
            });
        }

        // 构建保存文件路径
        const filePath = path.join(SERVER_STORAGE_PATH, `${user_name}.json`);

        // 将游戏数据转换为 JSON 字符串
        const saveData = JSON.stringify(req.body, null, 2);

        // 写入文件
        fs.writeFileSync(filePath, saveData, 'utf8');

        res.json({ 
            success: true, 
            message: '游戏数据保存成功' 
        });
    } catch (error) {
        console.error('保存游戏数据时发生错误:', error);
        res.status(500).json({ 
            success: false, 
            message: '服务器保存数据失败',
            error: error.message 
        });
    }
});

/**
 * 从服务器加载游戏数据
 * @route POST /load_game
 * @param {string} req.body.user_name - 用户名
 * @param {string} req.body.user_password - 用户密码
 * @returns {Object} 游戏数据或错误信息
 */
app.post('/load_game', (req, res) => {
    try {
        const { user_name, user_password } = req.body;

        // 检查用户名和密码是否存在
        if (!user_name || !user_password) {
            return res.status(400).json({ 
                success: false, 
                message: '用户名和密码不能为空' 
            });
        }

        // 构建文件路径
        const filePath = path.join(SERVER_STORAGE_PATH, `${user_name}.json`);

        // 检查文件是否存在
        if (!fs.existsSync(filePath)) {
            return res.status(404).json({ 
                success: false, 
                message: '未找到用户数据' 
            });
        }

        // 读取文件内容
        const fileContent = fs.readFileSync(filePath, 'utf8');
        const userData = JSON.parse(fileContent);

        // 验证密码
        if (userData.user_password !== user_password) {
            return res.status(401).json({ 
                success: false, 
                message: '密码错误' 
            });
        }

        res.json({
            success: true,
            message: '游戏数据加载成功',
            data: userData
        });
    } catch (error) {
        console.error('加载游戏数据时发生错误:', error);
        res.status(500).json({ 
            success: false, 
            message: '服务器加载数据失败',
            error: error.message 
        });
    }
});

/**
 * 服务器健康检查路由
 * @route GET /health
 * @returns {Object} 服务器状态
 */
app.get('/health', (req, res) => {
    res.json({ 
        status: 'healthy', 
        message: 'Godot农场游戏服务器正在运行' 
    });
});

// 启动服务器
app.listen(PORT, () => {
    console.log(`农场游戏后端服务已启动，监听端口：${PORT}`);
});