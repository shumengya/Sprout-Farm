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
    
    @staticmethod
    def send_verification_email(qq_number, verification_code):
        """
        发送验证码邮件到QQ邮箱
        
        参数:
            qq_number (str): 接收者QQ号
            verification_code (str): 验证码
            
        返回:
            bool: 发送成功返回True，否则返回False
            str: 成功或错误信息
        """
        receiver_email = f"{qq_number}@qq.com"
        
        # 创建邮件内容
        message = MIMEText(f'''
        <html>
        <body>
            <div style="font-family: Arial, sans-serif; color: #333;">
                <h2 style="color: #4CAF50;">萌芽农场 - 邮箱验证码</h2>
                <p>亲爱的玩家，您好！</p>
                <p>您正在注册萌芽农场游戏账号，您的验证码是：</p>
                <div style="background-color: #f2f2f2; padding: 10px; font-size: 24px; font-weight: bold; color: #4CAF50; text-align: center; margin: 20px 0;">
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
        message['Subject'] = Header('【萌芽农场】注册验证码', 'utf-8')
        
        try:
            # 使用SSL/TLS连接而不是STARTTLS
            smtp_obj = smtplib.SMTP_SSL(SMTP_SERVER, 465)
            smtp_obj.login(SENDER_EMAIL, SENDER_AUTH_CODE)
            smtp_obj.sendmail(SENDER_EMAIL, [receiver_email], message.as_string())
            smtp_obj.quit()
            return True, "验证码发送成功"
        except Exception as e:
            return False, f"发送验证码失败: {str(e)}"
    
    @staticmethod
    def save_verification_code(qq_number, verification_code, expiry_time=300):
        """
        保存验证码到缓存文件
        
        参数:
            qq_number (str): QQ号
            verification_code (str): 验证码
            expiry_time (int): 过期时间（秒），默认5分钟
            
        返回:
            bool: 保存成功返回True，否则返回False
        """
        import time
        
        # 创建目录（如果不存在）
        os.makedirs(os.path.dirname(VERIFICATION_CACHE_FILE), exist_ok=True)
        
        # 读取现有的验证码数据
        verification_data = {}
        if os.path.exists(VERIFICATION_CACHE_FILE):
            try:
                with open(VERIFICATION_CACHE_FILE, 'r', encoding='utf-8') as file:
                    verification_data = json.load(file)
            except:
                verification_data = {}
        
        # 添加新的验证码
        expire_at = time.time() + expiry_time
        verification_data[qq_number] = {
            "code": verification_code,
            "expire_at": expire_at
        }
        
        # 保存到文件
        try:
            with open(VERIFICATION_CACHE_FILE, 'w', encoding='utf-8') as file:
                json.dump(verification_data, file, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            print(f"保存验证码失败: {str(e)}")
            return False
    
    @staticmethod
    def verify_code(qq_number, input_code):
        """
        验证用户输入的验证码
        
        参数:
            qq_number (str): QQ号
            input_code (str): 用户输入的验证码
            
        返回:
            bool: 验证成功返回True，否则返回False
            str: 成功或错误信息
        """
        import time
        
        # 检查缓存文件是否存在
        if not os.path.exists(VERIFICATION_CACHE_FILE):
            return False, "验证码不存在或已过期"
        
        # 读取验证码数据
        try:
            with open(VERIFICATION_CACHE_FILE, 'r', encoding='utf-8') as file:
                verification_data = json.load(file)
        except:
            return False, "验证码数据损坏"
        
        # 检查该QQ号是否有验证码
        if qq_number not in verification_data:
            return False, "验证码不存在，请重新获取"
        
        # 获取存储的验证码信息
        code_info = verification_data[qq_number]
        stored_code = code_info.get("code", "")
        expire_at = code_info.get("expire_at", 0)
        
        # 检查验证码是否过期
        current_time = time.time()
        if current_time > expire_at:
            # 移除过期的验证码
            del verification_data[qq_number]
            with open(VERIFICATION_CACHE_FILE, 'w', encoding='utf-8') as file:
                json.dump(verification_data, file, indent=2, ensure_ascii=False)
            return False, "验证码已过期，请重新获取"
        
        # 验证码比较（不区分大小写）
        if input_code.upper() == stored_code.upper():
            # 验证成功后移除该验证码
            del verification_data[qq_number]
            with open(VERIFICATION_CACHE_FILE, 'w', encoding='utf-8') as file:
                json.dump(verification_data, file, indent=2, ensure_ascii=False)
            return True, "验证码正确"
        else:
            return False, "验证码错误"
    
    @staticmethod
    def clean_expired_codes():
        """
        清理过期的验证码
        """
        import time
        
        if not os.path.exists(VERIFICATION_CACHE_FILE):
            return
        
        try:
            with open(VERIFICATION_CACHE_FILE, 'r', encoding='utf-8') as file:
                verification_data = json.load(file)
            
            current_time = time.time()
            removed_keys = []
            
            # 找出过期的验证码
            for qq_number, code_info in verification_data.items():
                expire_at = code_info.get("expire_at", 0)
                if current_time > expire_at:
                    removed_keys.append(qq_number)
            
            # 移除过期的验证码
            for key in removed_keys:
                del verification_data[key]
            
            # 保存更新后的数据
            with open(VERIFICATION_CACHE_FILE, 'w', encoding='utf-8') as file:
                json.dump(verification_data, file, indent=2, ensure_ascii=False)
                
        except Exception as e:
            print(f"清理过期验证码失败: {str(e)}")


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