const fs = require('fs');
const path = require('path');

// 构建 JSON 文件的路径
const filePath = path.join(__dirname, 'Players', 'player.json');

// 读取 JSON 文件
fs.readFile(filePath, 'utf8', (err, data) => {
    if (err) {
        console.error('读取文件时出错:', err);
        return;
    }

    try {
        // 解析 JSON 数据
        const playerData = JSON.parse(data);
        console.log('玩家数据:', playerData);
    } catch (parseErr) {
        console.error('解析 JSON 数据时出错:', parseErr);
    }
});
