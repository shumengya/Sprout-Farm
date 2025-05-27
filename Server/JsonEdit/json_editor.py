#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from flask import Flask, request, jsonify, render_template, send_file
import json
import os
from datetime import datetime

app = Flask(__name__)

class JSONFormatter:
    """JSON格式化工具类"""
    
    @staticmethod
    def format_standard(data, indent=2):
        """标准格式化 - 带缩进的可读格式"""
        return json.dumps(data, ensure_ascii=False, indent=indent)
    
    @staticmethod
    def minify(data):
        """最小化 - 压缩去除空格"""
        return json.dumps(data, ensure_ascii=False, separators=(',', ':'))
    
    @staticmethod
    def one_line_per_object(data):
        """一行化 - 每个对象/元素占一行"""
        if isinstance(data, list):
            # 如果是数组，每个元素占一行
            lines = ['[']
            for i, item in enumerate(data):
                comma = ',' if i < len(data) - 1 else ''
                lines.append(f'  {json.dumps(item, ensure_ascii=False)}{comma}')
            lines.append(']')
            return '\n'.join(lines)
        
        elif isinstance(data, dict):
            # 如果是对象，每个键值对占一行
            lines = ['{']
            keys = list(data.keys())
            for i, key in enumerate(keys):
                comma = ',' if i < len(keys) - 1 else ''
                value_str = json.dumps(data[key], ensure_ascii=False)
                lines.append(f'  {json.dumps(key, ensure_ascii=False)}: {value_str}{comma}')
            lines.append('}')
            return '\n'.join(lines)
        
        else:
            # 基本类型直接返回
            return json.dumps(data, ensure_ascii=False)

@app.route('/')
def index():
    """主页"""
    return render_template('json_editor.html')

@app.route('/api/format', methods=['POST'])
def format_json():
    """JSON格式化API"""
    try:
        data = request.get_json()
        content = data.get('content', '')
        format_type = data.get('format_type', 'standard')  # standard, minify, oneline
        
        if not content.strip():
            return jsonify({'success': False, 'message': '请提供JSON内容'})
        
        # 解析JSON
        try:
            json_data = json.loads(content)
        except json.JSONDecodeError as e:
            return jsonify({'success': False, 'message': f'JSON格式错误: {str(e)}'})
        
        # 根据类型格式化
        formatter = JSONFormatter()
        
        if format_type == 'standard':
            formatted = formatter.format_standard(json_data)
            message = 'JSON标准格式化完成'
        elif format_type == 'minify':
            formatted = formatter.minify(json_data)
            message = 'JSON最小化完成'
        elif format_type == 'oneline':
            formatted = formatter.one_line_per_object(json_data)
            message = 'JSON一行化格式完成'
        else:
            return jsonify({'success': False, 'message': '不支持的格式化类型'})
        
        return jsonify({
            'success': True,
            'message': message,
            'formatted': formatted,
            'original_length': len(content),
            'formatted_length': len(formatted)
        })
        
    except Exception as e:
        return jsonify({'success': False, 'message': f'处理错误: {str(e)}'})

@app.route('/api/batch_add', methods=['POST'])
def batch_add_property():
    """批量添加属性API"""
    try:
        data = request.get_json()
        content = data.get('content', '')
        key_name = data.get('key_name', '')
        key_value = data.get('key_value', '')
        
        if not content.strip():
            return jsonify({'success': False, 'message': '请提供JSON内容'})
        
        if not key_name.strip():
            return jsonify({'success': False, 'message': '请提供键名'})
        
        # 解析JSON
        try:
            json_data = json.loads(content)
        except json.JSONDecodeError as e:
            return jsonify({'success': False, 'message': f'JSON格式错误: {str(e)}'})
        
        # 智能解析键值
        parsed_value = parse_value(key_value)
        
        # 批量添加属性
        count = add_property_to_all_objects(json_data, key_name, parsed_value)
        
        # 格式化输出
        formatted = JSONFormatter.format_standard(json_data)
        
        return jsonify({
            'success': True,
            'message': f'成功为 {count} 个对象添加了属性 "{key_name}": {json.dumps(parsed_value, ensure_ascii=False)}',
            'formatted': formatted,
            'count': count
        })
        
    except Exception as e:
        return jsonify({'success': False, 'message': f'处理错误: {str(e)}'})

def parse_value(value_str):
    """智能解析值的类型"""
    if value_str == '':
        return ''
    
    # null
    if value_str.lower() == 'null':
        return None
    
    # boolean
    if value_str.lower() == 'true':
        return True
    if value_str.lower() == 'false':
        return False
    
    # number
    try:
        if '.' in value_str:
            return float(value_str)
        else:
            return int(value_str)
    except ValueError:
        pass
    
    # JSON object or array
    if (value_str.startswith('{') and value_str.endswith('}')) or \
       (value_str.startswith('[') and value_str.endswith(']')):
        try:
            return json.loads(value_str)
        except json.JSONDecodeError:
            pass
    
    # string
    return value_str

def add_property_to_all_objects(obj, key, value):
    """递归为所有对象添加属性"""
    count = 0
    
    def traverse(current):
        nonlocal count
        if isinstance(current, dict):
            current[key] = value
            count += 1
            # 继续递归处理嵌套对象
            for val in current.values():
                if isinstance(val, (dict, list)) and val != current:
                    traverse(val)
        elif isinstance(current, list):
            for item in current:
                traverse(item)
    
    traverse(obj)
    return count

@app.route('/api/validate', methods=['POST'])
def validate_json():
    """JSON验证API"""
    try:
        data = request.get_json()
        content = data.get('content', '')
        
        if not content.strip():
            return jsonify({'success': False, 'message': '请提供JSON内容'})
        
        try:
            json_data = json.loads(content)
            return jsonify({
                'success': True,
                'message': 'JSON格式正确 ✓',
                'valid': True
            })
        except json.JSONDecodeError as e:
            return jsonify({
                'success': False,
                'message': f'JSON格式错误: {str(e)}',
                'valid': False,
                'error': str(e)
            })
            
    except Exception as e:
        return jsonify({'success': False, 'message': f'验证错误: {str(e)}'})

@app.route('/api/download', methods=['POST'])
def download_json():
    """下载JSON文件"""
    try:
        data = request.get_json()
        content = data.get('content', '')
        format_type = data.get('format_type', 'standard')
        
        if not content.strip():
            return jsonify({'success': False, 'message': '没有可下载的内容'})
        
        # 验证JSON格式
        try:
            json_data = json.loads(content)
        except json.JSONDecodeError as e:
            return jsonify({'success': False, 'message': f'JSON格式错误: {str(e)}'})
        
        # 格式化
        formatter = JSONFormatter()
        if format_type == 'minify':
            formatted_content = formatter.minify(json_data)
        elif format_type == 'oneline':
            formatted_content = formatter.one_line_per_object(json_data)
        else:
            formatted_content = formatter.format_standard(json_data)
        
        # 生成文件名
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"edited_json_{format_type}_{timestamp}.json"
        
        # 创建临时文件
        temp_file = f"temp_{filename}"
        with open(temp_file, 'w', encoding='utf-8') as f:
            f.write(formatted_content)
        
        return send_file(temp_file, as_attachment=True, download_name=filename)
        
    except Exception as e:
        return jsonify({'success': False, 'message': f'下载错误: {str(e)}'})

if __name__ == '__main__':
    # 确保templates目录存在
    os.makedirs('templates', exist_ok=True)
    
    # 运行应用
    app.run(debug=True, host='0.0.0.0', port=5000)
