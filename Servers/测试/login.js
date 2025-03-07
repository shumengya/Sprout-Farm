const fs = require('fs');
const path = require('path');
const express = require('express');
const app = express();
const port = 3000;

app.get('/', (req, res) => {
    res.json({ message: 'GET 请求已收到！' });
    console.log('GET 请求已收到！');
});

app.post('/', (req, res) => {
    res.json({ message: 'POST 请求已收到！', data: req.body });
    console.log('POST 请求已收到！');
});

app.listen(port, () => {
    console.log(`萌芽后端服务器正在运行在： http://localhost:${port}`);
});