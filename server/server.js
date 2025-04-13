const express = require('express');
const fs = require('fs');
const path = require('path');
const bodyParser = require('body-parser');
const cors = require('cors');
const chalk = require('chalk'); // 用于控制台颜色

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

// 日志记录函数
function logServer(message) {
    const timestamp = new Date().toLocaleTimeString();
    console.log(chalk.gray(`[${timestamp}] `) + chalk.cyan('[服务器] ') + message);
}

function logPlayer(player, message) {
    const timestamp = new Date().toLocaleTimeString();
    console.log(chalk.gray(`[${timestamp}] `) + chalk.yellow(`[${player}] `) + message);
}

function logWarning(message) {
    const timestamp = new Date().toLocaleTimeString();
    console.log(chalk.gray(`[${timestamp}] `) + chalk.yellow('[警告] ') + message);
}

function logError(message) {
    const timestamp = new Date().toLocaleTimeString();
    console.log(chalk.gray(`[${timestamp}] `) + chalk.red('[错误] ') + message);
}

/**
 * 登录路由
 * @route POST /login
 * @param {string} req.body.user_name - 用户名
 * @param {string} req.body.user_password - 用户密码
 * @returns {Object} 登录结果
 */
app.post('/login', (req, res) => {
    try {
        const { user_name, user_password } = req.body;

        if (!user_name || !user_password) {
            logWarning(`登录尝试失败: 用户名或密码为空`);
            return res.json({ 
                message: '用户名和密码不能为空'
            });
        }

        const filePath = path.join(SERVER_STORAGE_PATH, `${user_name}.json`);

        if (!fs.existsSync(filePath)) {
            logWarning(`登录失败: 用户 ${user_name} 不存在`);
            return res.json({ 
                message: '用户不存在'
            });
        }

        const fileContent = fs.readFileSync(filePath, 'utf8');
        const userData = JSON.parse(fileContent);

        if (userData.user_password !== user_password) {
            logWarning(`用户 ${user_name} 登录失败: 密码错误`);
            return res.json({ 
                message: '密码错误'
            });
        }

        logPlayer(user_name, '成功登录游戏');
        res.json({
            message: '登录成功',
            data: userData
        });
    } catch (error) {
        logError(`登录过程发生错误: ${error.message}`);
        res.json({ 
            message: '服务器错误',
            error: error.message 
        });
    }
});

/**
 * 注册路由
 * @route POST /register
 * @param {string} req.body.user_name - 用户名
 * @param {string} req.body.user_password - 用户密码
 * @param {string} req.body.farm_name - 农场名称
 * @returns {Object} 注册结果
 */
app.post('/register', (req, res) => {
    try {
        const { user_name, user_password, farm_name } = req.body;

        if (!user_name || !user_password || !farm_name) {
            logWarning(`注册失败: 注册信息不完整`);
            return res.json({ 
                message: '注册信息不完整'
            });
        }

        const filePath = path.join(SERVER_STORAGE_PATH, `${user_name}.json`);

        if (fs.existsSync(filePath)) {
            logWarning(`注册失败: 用户名 ${user_name} 已存在`);
            return res.json({ 
                message: '用户名已存在'
            });
        }

        fs.writeFileSync(filePath, JSON.stringify(req.body, null, 2), 'utf8');
        logPlayer(user_name, `注册成功，农场名称: ${farm_name}`);

        res.json({ 
            message: '注册成功'
        });
    } catch (error) {
        logError(`注册过程发生错误: ${error.message}`);
        res.json({ 
            message: '服务器错误',
            error: error.message 
        });
    }
});

/**
 * 保存游戏数据
 * @route POST /save
 * @param {string} req.body.user_name - 用户名
 * @param {Object} req.body - 游戏保存数据
 * @returns {Object} 保存结果
 */
app.post('/save', (req, res) => {
    try {
        const { user_name, money, level, experience } = req.body;

        if (!user_name) {
            logWarning(`保存失败: 用户名为空`);
            return res.json({ 
                message: '用户名不能为空'
            });
        }

        const filePath = path.join(SERVER_STORAGE_PATH, `${user_name}.json`);
        fs.writeFileSync(filePath, JSON.stringify(req.body, null, 2), 'utf8');
        
        logPlayer(user_name, `保存游戏数据 [金钱: ${money}, 等级: ${level}, 经验: ${experience}]`);
        res.json({ 
            message: '保存成功'
        });
    } catch (error) {
        logError(`保存游戏数据时发生错误: ${error.message}`);
        res.json({ 
            message: '服务器错误',
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
    logServer('收到健康检查请求');
    res.json({ 
        status: 'healthy', 
        message: 'Godot农场游戏服务器正在运行' 
    });
});

// 启动服务器
app.listen(PORT, () => {
    logServer(chalk.green('农场游戏服务器启动成功'));
    logServer(`监听端口: ${PORT}`);
    logServer(`存储路径: ${SERVER_STORAGE_PATH}`);
    logServer('等待玩家连接...');
});

// 优雅关闭服务器
process.on('SIGINT', () => {
    logServer(chalk.yellow('正在关闭服务器...'));
    // 这里可以添加一些清理工作
    process.exit();
});