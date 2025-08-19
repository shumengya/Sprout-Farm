import os

def check_folders():
    # 获取当前脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    
    # 需要检查的文件名
    required_files = {
        "未成熟.webp",
        "成熟.webp",
        "幼苗.webp",
        "收获物.webp"
    }
    
    # 遍历当前目录下的所有项
    for item in os.listdir(script_dir):
        item_path = os.path.join(script_dir, item)
        
        # 只处理文件夹
        if os.path.isdir(item_path):
            # 获取文件夹中的所有文件
            folder_files = set(os.listdir(item_path))
            
            # 检查是否缺少必要文件
            missing_files = required_files - folder_files
            
            # 如果有缺少的文件，输出文件夹名称
            if missing_files:
                print(f"文件夹 '{item}' 缺少以下文件: {', '.join(missing_files)}")

if __name__ == "__main__":
    check_folders()
    print("检查完成")
    