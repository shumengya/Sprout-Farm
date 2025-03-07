const fs = require('fs');
const path = require('path');

// 构建 JSON 文件的路径
const filePath = path.join(__dirname, 'Players', '3205788256.json');

// 读取 JSON 文件
fs.readFile(filePath, 'utf8', (err, data) => {
    if (err) {
        console.error('读取文件时出错:', err);
        return;
    }

    try {
        // 解析 JSON 数据
        const playerData = JSON.parse(data);
        //console.log('玩家数据:', playerData);

        // 对解析后的数据进行分析
        analyzePlayerData(playerData);

    } catch (parseErr) {
        console.error('解析 JSON 数据时出错:', parseErr);
    }
});

// 分析玩家数据的函数
function analyzePlayerData(playerData) {
    // 打印玩家的基本信息
    console.log(`用户名: ${playerData.user_name}`);
    console.log(`用户密码: ${playerData.user_password}`);
    console.log(`农场名称: ${playerData.farm_name}`);
    console.log(`金钱: ${playerData.money}`);
    console.log(`经验值: ${playerData.experience}`);
    console.log(`等级: ${playerData.level}`);

    // 统计农场地块的状态
    const totalLots = playerData.farm_lots.length;
    const diggedLots = playerData.farm_lots.filter(lot => lot.is_diged).length;
    const plantedLots = playerData.farm_lots.filter(lot => lot.is_planted).length;
    const deadLots = playerData.farm_lots.filter(lot => lot.is_dead).length;

    console.log(`总地块数: ${totalLots}`);
    console.log(`已挖掘地块数: ${diggedLots}`);
    console.log(`已种植地块数: ${plantedLots}`);
    console.log(`已枯死地块数: ${deadLots}`);

    // 检查每个地块的生长状态
    playerData.farm_lots.forEach((lot, index) => {
        console.log(`地块 ${index + 1}: 已挖掘 - ${lot.is_diged}, 已种植 - ${lot.is_planted}, 已枯死 - ${lot.is_dead}, 作物类型 - ${lot.crop_type}, 生长时间 - ${lot.grow_time}/${lot.max_grow_time}`);
    });
}
