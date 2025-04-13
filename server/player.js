const fs = require('fs');
const path = require('path');
const express = require('express');
const app = express();
const port = 3000;

// 使用 express.json() 中间件来解析 JSON 请求体
app.use(express.json());

// 处理用户登录请求
app.post('/login', (req, res) => {
    const { user_name, user_password } = req.body;
    const filePath = path.join(__dirname, `Players/${user_name}.json`);

    fs.readFile(filePath, 'utf8', (err, data) => {
        if (err) {
            console.error('读取文件时出错:', err);
            console.error("用户：", user_name, '读取文件：', userData.user_name, ".json", "失败！", "原因：用户不存在");
            return res.status(404).json({ message: '用户不存在' });
        }

        try {
            const userData = JSON.parse(data);

            if (userData.user_password === user_password) {
                console.error("用户：", user_name, '读取文件：', userData.user_name, ".json", "成功！");
                return res.json({ message: '登录成功', data: userData });

            } else {
                console.error("用户：", user_name, '读取文件：', userData.user_name, ".json", "失败！","原因：密码错误");
                return res.status(401).json({ message: '密码错误' });
            }
        } catch (parseError) {
            console.error('解析 JSON 时出错:', parseError);
            return res.status(500).json({ message: '服务器错误', error: parseError });
        }
    });
});

// 处理保存数据请求
app.post('/save', (req, res) => {
    const receivedData = req.body;
    const filePath = path.join(__dirname, `Players/${receivedData.user_name}.json`);


    // 将数据写入文件
    fs.writeFile(filePath, JSON.stringify(receivedData, null, 2), (err) => {
        if (err) {
            console.error('保存数据时出错:', err);
            return res.status(500).json({ message: '数据保存失败', error: err });
        }
        console.log(`数据已保存到 ${receivedData.user_name}.json`);
        console.log("用户：", receivedData.user_name, '保存数据到：', receivedData.user_name, ".json", "成功！");
        return res.json({ message: '数据保存成功', data: receivedData });
    });
});


// 处理新用户注册请求
app.post('/register', (req, res) => {
    const newUserData = req.body;
    const filePath = path.join(__dirname, `Players/${newUserData.user_name}.json`);

    // 检查用户名是否已经存在
    if (fs.existsSync(filePath)) {
        console.error("新用户：", newUserData.user_name, '注册数据到：', newUserData.user_name, ".json", "失败！", "原因：用户名已存在");
        return res.status(400).json({ message: '用户名已存在' });
    }

    // 将新用户数据写入文件
    fs.writeFile(filePath, JSON.stringify(newUserData, null, 2), (err) => {
        if (err) {
            console.error("新用户：", newUserData.user_name, '注册数据到：', newUserData.user_name, ".json", "失败！", "原因：",err);
            return res.status(500).json({ message: '数据保存失败', error: err });
        }
        console.log("新用户：", newUserData.user_name, '注册数据到：', newUserData.user_name, ".json", "成功！");
        return res.json({ message: '注册成功', data: newUserData });
    });
});

app.listen(port, () => {
    console.log(`萌芽后端服务器正在运行在： http://localhost:${port}`);
});
