import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication
from email.header import Header
import random
import string
import json
import os

# 邮件发送配置
SENDER_EMAIL = '3205788256@qq.com'  # 发件人邮箱
SENDER_AUTH_CODE = 'szcaxvbftusqddhi'  # 授权码
SMTP_SERVER = 'smtp.qq.com'  # QQ邮箱SMTP服务器
SMTP_PORT = 465  # QQ邮箱SSL端口

# 验证码缓存文件
VERIFICATION_CACHE_FILE = os.path.join("config", "verification_codes.json")

class QQMailAPI:
    """QQ邮箱发送邮件API类"""
    
    def __init__(self, sender_email, authorization_code):
        """
        初始化邮箱配置
        :param sender_email: 发送方QQ邮箱地址
        :param authorization_code: QQ邮箱授权码
        """
        self.sender_email = sender_email
        self.authorization_code = authorization_code
        self.smtp_server = 'smtp.qq.com'
        self.smtp_port = 465  # SSL端口
    
    # 发送纯文本邮件
    def send_text_email(self, receiver_email, subject, content, cc_emails=None):
        """
        发送纯文本邮件
        :param receiver_email: 接收方邮箱地址（单个）
        :param subject: 邮件主题
        :param content: 邮件正文内容
        :param cc_emails: 抄送邮箱列表
        :return: 发送成功返回True，失败返回False
        """
        try:
            # 创建邮件对象
            message = MIMEText(content, 'plain', 'utf-8')
            message['From'] = Header(self.sender_email, 'utf-8')
            message['To'] = Header(receiver_email, 'utf-8')
            message['Subject'] = Header(subject, 'utf-8')
            
            # 添加抄送
            if cc_emails:
                message['Cc'] = Header(",".join(cc_emails), 'utf-8')
                all_receivers = [receiver_email] + cc_emails
            else:
                all_receivers = [receiver_email]
            
            # 连接SMTP服务器并发送邮件
            with smtplib.SMTP_SSL(self.smtp_server, self.smtp_port) as server:
                server.login(self.sender_email, self.authorization_code)
                server.sendmail(self.sender_email, all_receivers, message.as_string())
            
            print(f"邮件发送成功：主题='{subject}', 收件人='{receiver_email}'")
            return True
        except Exception as e:
            print(f"邮件发送失败：{str(e)}")
            return False
    
    # 发送HTML格式邮件，可带附件
    def send_html_email(self, receiver_email, subject, html_content, cc_emails=None, attachments=None):
        """
        发送HTML格式邮件，可带附件
        :param receiver_email: 接收方邮箱地址（单个）
        :param subject: 邮件主题
        :param html_content: HTML格式的邮件正文
        :param cc_emails: 抄送邮箱列表
        :param attachments: 附件文件路径列表
        :return: 发送成功返回True，失败返回False
        """
        try:
            # 创建带附件的邮件对象
            message = MIMEMultipart()
            message['From'] = Header(self.sender_email, 'utf-8')
            message['To'] = Header(receiver_email, 'utf-8')
            message['Subject'] = Header(subject, 'utf-8')
            
            # 添加抄送
            if cc_emails:
                message['Cc'] = Header(",".join(cc_emails), 'utf-8')
                all_receivers = [receiver_email] + cc_emails
            else:
                all_receivers = [receiver_email]
            
            # 添加HTML正文
            message.attach(MIMEText(html_content, 'html', 'utf-8'))
            
            # 添加附件
            if attachments:
                for file_path in attachments:
                    try:
                        with open(file_path, 'rb') as file:
                            attachment = MIMEApplication(file.read(), _subtype="octet-stream")
                            attachment.add_header('Content-Disposition', 'attachment', filename=file_path.split("/")[-1])
                            message.attach(attachment)
                    except Exception as e:
                        print(f"添加附件失败 {file_path}: {str(e)}")
            
            # 连接SMTP服务器并发送邮件
            with smtplib.SMTP_SSL(self.smtp_server, self.smtp_port) as server:
                server.login(self.sender_email, self.authorization_code)
                server.sendmail(self.sender_email, all_receivers, message.as_string())
            
            print(f"HTML邮件发送成功：主题='{subject}', 收件人='{receiver_email}'")
            return True
        except Exception as e:
            print(f"HTML邮件发送失败：{str(e)}")
            return False

class EmailVerification:

    #生成指定长度的随机验证码
    @staticmethod
    def generate_verification_code(length=6):
        """
        生成指定长度的随机验证码
        
        参数:
            length (int): 验证码长度，默认6位
            
        返回:
            str: 生成的验证码
        """
        # 生成包含大写字母和数字的验证码
        chars = string.ascii_uppercase + string.digits
        return ''.join(random.choice(chars) for _ in range(length))
    
    #发送验证码邮件到QQ邮箱
    @staticmethod
    def send_verification_email(qq_number, verification_code, email_type="register"):
        """
        发送验证码邮件到QQ邮箱
        
        参数:
            qq_number (str): 接收者QQ号
            verification_code (str): 验证码
            email_type (str): 邮件类型，"register" 或 "reset_password"
            
        返回:
            bool: 发送成功返回True，否则返回False
            str: 成功或错误信息
        """
        receiver_email = f"{qq_number}@qq.com"
        
        # 根据邮件类型设置不同的内容
        if email_type == "reset_password":
            email_title = "【萌芽农场】密码重置验证码"
            email_purpose = "重置萌芽农场游戏账号密码"
            email_color = "#FF6B35"  # 橙红色，表示警告性操作
        else:
            email_title = "【萌芽农场】注册验证码"
            email_purpose = "注册萌芽农场游戏账号"
            email_color = "#4CAF50"  # 绿色，表示正常操作
        
        # 创建邮件内容
        message = MIMEText(f'''
        <html>
        <body>
            <div style="font-family: Arial, sans-serif; color: #333;">
                <h2 style="color: {email_color};">萌芽农场 - 邮箱验证码</h2>
                <p>亲爱的玩家，您好！</p>
                <p>您正在{email_purpose}，您的验证码是：</p>
                <div style="background-color: #f2f2f2; padding: 10px; font-size: 24px; font-weight: bold; color: {email_color}; text-align: center; margin: 20px 0;">
                    {verification_code}
                </div>
                <p>该验证码有效期为5分钟，请勿泄露给他人。</p>
                <p>如果这不是您本人的操作，请忽略此邮件。</p>
                <p style="margin-top: 30px; font-size: 12px; color: #999;">
                    本邮件由系统自动发送，请勿直接回复。
                </p>
            </div>
        </body>
        </html>
        ''', 'html', 'utf-8')
        
        # 修正From头格式，符合QQ邮箱的要求
        message['From'] = SENDER_EMAIL
        message['To'] = receiver_email
        message['Subject'] = Header(email_title, 'utf-8')
        
        try:
            # 使用SSL/TLS连接而不是STARTTLS
            smtp_obj = smtplib.SMTP_SSL(SMTP_SERVER, 465)
            smtp_obj.login(SENDER_EMAIL, SENDER_AUTH_CODE)
            smtp_obj.sendmail(SENDER_EMAIL, [receiver_email], message.as_string())
            smtp_obj.quit()
            return True, "验证码发送成功"
        except Exception as e:
            return False, f"发送验证码失败: {str(e)}"
    
    #保存验证码到MongoDB（优先）或缓存文件（备用）
    @staticmethod
    def save_verification_code(qq_number, verification_code, expiry_time=300, code_type="register"):
        """
        保存验证码到MongoDB（优先）或缓存文件（备用）
        
        参数:
            qq_number (str): QQ号
            verification_code (str): 验证码
            expiry_time (int): 过期时间（秒），默认5分钟
            code_type (str): 验证码类型，"register" 或 "reset_password"
            
        返回:
            bool: 保存成功返回True，否则返回False
        """
        import time
        
        # 优先尝试使用MongoDB
        try:
            from SMYMongoDBAPI import SMYMongoDBAPI
            import os
            # 根据环境动态选择MongoDB配置
            if os.path.exists('/.dockerenv') or os.environ.get('PRODUCTION', '').lower() == 'true':
                environment = "production"
            else:
                environment = "test"
            mongo_api = SMYMongoDBAPI(environment)
            if mongo_api.is_connected():
                success = mongo_api.save_verification_code(qq_number, verification_code, expiry_time, code_type)
                if success:
                    print(f"[验证码系统-MongoDB] 为QQ {qq_number} 保存{code_type}验证码: {verification_code}")
                    return True
                else:
                    print(f"[验证码系统-MongoDB] 保存失败，尝试使用JSON文件")
        except Exception as e:
            print(f"[验证码系统-MongoDB] MongoDB保存失败: {str(e)}，尝试使用JSON文件")
        
        # MongoDB失败，使用JSON文件备用
        # 创建目录（如果不存在）
        os.makedirs(os.path.dirname(VERIFICATION_CACHE_FILE), exist_ok=True)
        
        # 读取现有的验证码数据
        verification_data = {}
        if os.path.exists(VERIFICATION_CACHE_FILE):
            try:
                with open(VERIFICATION_CACHE_FILE, 'r', encoding='utf-8') as file:
                    verification_data = json.load(file)
            except Exception as e:
                print(f"读取验证码文件失败: {str(e)}")
                verification_data = {}
        
        # 添加新的验证码
        expire_at = time.time() + expiry_time
        current_time = time.time()
        
        # 创建验证码记录，包含更多信息用于调试
        verification_data[qq_number] = {
            "code": verification_code,
            "expire_at": expire_at,
            "code_type": code_type,
            "created_at": current_time,
            "used": False  # 新增：标记验证码是否已使用
        }
        
        # 保存到文件
        try:
            with open(VERIFICATION_CACHE_FILE, 'w', encoding='utf-8') as file:
                json.dump(verification_data, file, indent=2, ensure_ascii=False)
            
            print(f"[验证码系统-JSON] 为QQ {qq_number} 保存{code_type}验证码: {verification_code}, 过期时间: {expire_at}")
            return True
        except Exception as e:
            print(f"保存验证码失败: {str(e)}")
            return False
    
    #验证用户输入的验证码（优先使用MongoDB）
    @staticmethod
    def verify_code(qq_number, input_code, code_type="register"):
        """
        验证用户输入的验证码（优先使用MongoDB）
        
        参数:
            qq_number (str): QQ号
            input_code (str): 用户输入的验证码
            code_type (str): 验证码类型，"register" 或 "reset_password"
            
        返回:
            bool: 验证成功返回True，否则返回False
            str: 成功或错误信息
        """
        import time
        
        # 优先尝试使用MongoDB
        try:
            from SMYMongoDBAPI import SMYMongoDBAPI
            import os
            # 根据环境动态选择MongoDB配置
            if os.path.exists('/.dockerenv') or os.environ.get('PRODUCTION', '').lower() == 'true':
                environment = "production"
            else:
                environment = "test"
            mongo_api = SMYMongoDBAPI(environment)
            if mongo_api.is_connected():
                success, message = mongo_api.verify_verification_code(qq_number, input_code, code_type)
                print(f"[验证码系统-MongoDB] QQ {qq_number} 验证结果: {success}, 消息: {message}")
                return success, message
        except Exception as e:
            print(f"[验证码系统-MongoDB] MongoDB验证失败: {str(e)}，尝试使用JSON文件")
        
        # MongoDB失败，使用JSON文件备用
        # 检查缓存文件是否存在
        if not os.path.exists(VERIFICATION_CACHE_FILE):
            print(f"[验证码系统-JSON] QQ {qq_number} 验证失败: 缓存文件不存在")
            return False, "验证码不存在或已过期"
        
        # 读取验证码数据
        try:
            with open(VERIFICATION_CACHE_FILE, 'r', encoding='utf-8') as file:
                verification_data = json.load(file)
        except Exception as e:
            print(f"[验证码系统-JSON] 读取验证码文件失败: {str(e)}")
            return False, "验证码数据损坏"
        
        # 检查该QQ号是否有验证码
        if qq_number not in verification_data:
            print(f"[验证码系统-JSON] QQ {qq_number} 验证失败: 没有找到验证码记录")
            return False, "验证码不存在，请重新获取"
        
        # 获取存储的验证码信息
        code_info = verification_data[qq_number]
        stored_code = code_info.get("code", "")
        expire_at = code_info.get("expire_at", 0)
        stored_code_type = code_info.get("code_type", "register")
        is_used = code_info.get("used", False)
        created_at = code_info.get("created_at", 0)
        
        print(f"[验证码系统-JSON] QQ {qq_number} 验证码详情: 存储码={stored_code}, 输入码={input_code}, 类型={stored_code_type}, 已使用={is_used}, 创建时间={created_at}")
        
        # 检查验证码类型是否匹配
        if stored_code_type != code_type:
            print(f"[验证码系统-JSON] QQ {qq_number} 验证失败: 验证码类型不匹配，存储类型={stored_code_type}, 请求类型={code_type}")
            return False, f"验证码类型不匹配，请重新获取{code_type}验证码"
        
        # 检查验证码是否已被使用
        if is_used:
            print(f"[验证码系统-JSON] QQ {qq_number} 验证失败: 验证码已被使用")
            return False, "验证码已被使用，请重新获取"
        
        # 检查验证码是否过期
        current_time = time.time()
        if current_time > expire_at:
            # 移除过期的验证码
            del verification_data[qq_number]
            with open(VERIFICATION_CACHE_FILE, 'w', encoding='utf-8') as file:
                json.dump(verification_data, file, indent=2, ensure_ascii=False)
            print(f"[验证码系统-JSON] QQ {qq_number} 验证失败: 验证码已过期")
            return False, "验证码已过期，请重新获取"
        
        # 验证码比较（不区分大小写）
        if input_code.upper() == stored_code.upper():
            # 验证成功，标记为已使用而不是删除
            verification_data[qq_number]["used"] = True
            verification_data[qq_number]["used_at"] = current_time
            
            try:
                with open(VERIFICATION_CACHE_FILE, 'w', encoding='utf-8') as file:
                    json.dump(verification_data, file, indent=2, ensure_ascii=False)
                print(f"[验证码系统-JSON] QQ {qq_number} 验证成功: 验证码已标记为已使用")
                return True, "验证码正确"
            except Exception as e:
                print(f"[验证码系统-JSON] 标记验证码已使用时失败: {str(e)}")
                return True, "验证码正确"  # 即使标记失败，验证还是成功的
        else:
            print(f"[验证码系统-JSON] QQ {qq_number} 验证失败: 验证码不匹配")
            return False, "验证码错误"
    
    #清理过期的验证码和已使用的验证码（优先使用MongoDB）
    @staticmethod
    def clean_expired_codes():
        """
        清理过期的验证码和已使用的验证码（优先使用MongoDB）
        """
        import time
        
        # 优先尝试使用MongoDB
        try:
            from SMYMongoDBAPI import SMYMongoDBAPI
            import os
            # 根据环境动态选择MongoDB配置
            if os.path.exists('/.dockerenv') or os.environ.get('PRODUCTION', '').lower() == 'true':
                environment = "production"
            else:
                environment = "test"
            mongo_api = SMYMongoDBAPI(environment)
            if mongo_api.is_connected():
                expired_count = mongo_api.clean_expired_verification_codes()
                print(f"[验证码系统-MongoDB] 清理完成，删除了 {expired_count} 个过期验证码")
                return expired_count
        except Exception as e:
            print(f"[验证码系统-MongoDB] MongoDB清理失败: {str(e)}，尝试使用JSON文件")
        
        # MongoDB失败，使用JSON文件备用
        if not os.path.exists(VERIFICATION_CACHE_FILE):
            return
        
        try:
            with open(VERIFICATION_CACHE_FILE, 'r', encoding='utf-8') as file:
                verification_data = json.load(file)
            
            current_time = time.time()
            removed_keys = []
            
            # 找出过期的验证码和已使用的验证码（超过1小时）
            for qq_number, code_info in verification_data.items():
                expire_at = code_info.get("expire_at", 0)
                is_used = code_info.get("used", False)
                used_at = code_info.get("used_at", 0)
                
                should_remove = False
                
                # 过期的验证码
                if current_time > expire_at:
                    should_remove = True
                    print(f"[验证码清理-JSON] 移除过期验证码: QQ {qq_number}")
                
                # 已使用超过1小时的验证码
                elif is_used and used_at > 0 and (current_time - used_at) > 3600:
                    should_remove = True
                    print(f"[验证码清理-JSON] 移除已使用的验证码: QQ {qq_number}")
                
                if should_remove:
                    removed_keys.append(qq_number)
            
            # 移除标记的验证码
            for key in removed_keys:
                del verification_data[key]
            
            # 保存更新后的数据
            if removed_keys:
                with open(VERIFICATION_CACHE_FILE, 'w', encoding='utf-8') as file:
                    json.dump(verification_data, file, indent=2, ensure_ascii=False)
                print(f"[验证码清理-JSON] 共清理了 {len(removed_keys)} 个验证码")
                
        except Exception as e:
            print(f"清理验证码失败: {str(e)}")
    
    #获取验证码状态（优先使用MongoDB）
    @staticmethod
    def get_verification_status(qq_number):
        """
        获取验证码状态（优先使用MongoDB）
        
        参数:
            qq_number (str): QQ号
            
        返回:
            dict: 验证码状态信息
        """
        import time
        
        # 优先尝试使用MongoDB
        try:
            from SMYMongoDBAPI import SMYMongoDBAPI
            import os
            # 根据环境动态选择MongoDB配置
            if os.path.exists('/.dockerenv') or os.environ.get('PRODUCTION', '').lower() == 'true':
                environment = "production"
            else:
                environment = "test"
            mongo_api = SMYMongoDBAPI(environment)
            if mongo_api.is_connected():
                verification_codes = mongo_api.get_verification_codes()
                if verification_codes and qq_number in verification_codes:
                    code_info = verification_codes[qq_number]
                    current_time = time.time()
                    
                    return {
                        "status": "found",
                        "code": code_info.get("code", ""),
                        "code_type": code_info.get("code_type", "unknown"),
                        "used": code_info.get("used", False),
                        "expired": current_time > code_info.get("expire_at", 0),
                        "created_at": code_info.get("created_at", 0),
                        "expire_at": code_info.get("expire_at", 0),
                        "used_at": code_info.get("used_at", 0),
                        "source": "mongodb"
                    }
                else:
                    return {"status": "no_code", "source": "mongodb"}
        except Exception as e:
            print(f"[验证码系统-MongoDB] MongoDB状态查询失败: {str(e)}，尝试使用JSON文件")
        
        # MongoDB失败，使用JSON文件备用
        if not os.path.exists(VERIFICATION_CACHE_FILE):
            return {"status": "no_cache_file"}
        
        try:
            with open(VERIFICATION_CACHE_FILE, 'r', encoding='utf-8') as file:
                verification_data = json.load(file)
            
            if qq_number not in verification_data:
                return {"status": "no_code"}
            
            code_info = verification_data[qq_number]
            current_time = time.time()
            
            return {
                "status": "found",
                "code": code_info.get("code", ""),
                "code_type": code_info.get("code_type", "unknown"),
                "used": code_info.get("used", False),
                "expired": current_time > code_info.get("expire_at", 0),
                "created_at": code_info.get("created_at", 0),
                "expire_at": code_info.get("expire_at", 0),
                "used_at": code_info.get("used_at", 0),
                "source": "json"
            }
            
        except Exception as e:
            return {"status": "error", "message": str(e)}


# 测试邮件发送
if __name__ == "__main__":
    # 清理过期验证码
    EmailVerification.clean_expired_codes()
    
    # 生成验证码
    test_qq = input("请输入测试QQ号: ")
    verification_code = EmailVerification.generate_verification_code()
    print(f"生成的验证码: {verification_code}")
    
    # 发送测试邮件
    success, message = EmailVerification.send_verification_email(test_qq, verification_code)
    print(f"发送结果: {success}, 消息: {message}")
    
    if success:
        # 保存验证码
        EmailVerification.save_verification_code(test_qq, verification_code)
        
        # 测试验证
        test_input = input("请输入收到的验证码: ")
        verify_success, verify_message = EmailVerification.verify_code(test_qq, test_input)
        print(f"验证结果: {verify_success}, 消息: {verify_message}")