#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
域名管理系统 - 管理每个域名的包名和签名
"""

import os
import hashlib
import json
import subprocess
from urllib.parse import urlparse
from datetime import datetime

class DomainManager:
    def __init__(self, base_dir=None):
        if base_dir is None:
            base_dir = os.path.dirname(os.path.abspath(__file__))
        
        self.base_dir = base_dir
        self.keystores_dir = os.path.join(base_dir, 'keystores')
        self.config_file = os.path.join(base_dir, 'domain_configs.json')
        
        # 确保目录存在
        os.makedirs(self.keystores_dir, exist_ok=True)
        
        # 加载或创建配置
        self.configs = self._load_configs()
    
    def _load_configs(self):
        """加载域名配置"""
        try:
            if os.path.exists(self.config_file) and os.path.getsize(self.config_file) > 0:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    content = f.read().strip()
                    if content:
                        return json.loads(content)
            # 如果文件不存在或为空，创建空配置
            return {}
        except (json.JSONDecodeError, FileNotFoundError, IOError) as e:
            print(f"警告: 配置文件读取失败: {e}")
            # 重新创建配置文件
            return {}
    
    def _save_configs(self):
        """保存域名配置"""
        try:
            # 确保目录存在
            os.makedirs(os.path.dirname(self.config_file), exist_ok=True)
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(self.configs, f, indent=2, ensure_ascii=False)
        except IOError as e:
            print(f"警告: 配置文件保存失败: {e}")
    
    def _url_to_domain(self, url):
        """从URL提取域名"""
        parsed = urlparse(url)
        domain = parsed.netloc
        if not domain:
            # 如果没有协议，尝试添加http://再解析
            parsed = urlparse(f"http://{url}")
            domain = parsed.netloc
        
        # 移除www前缀
        if domain.startswith('www.'):
            domain = domain[4:]
        
        return domain.lower()
    
    def _domain_to_package_name(self, domain):
        """将域名转换为包名"""
        # 移除特殊字符，只保留字母、数字和点
        clean_domain = ''.join(c for c in domain if c.isalnum() or c == '.')
        
        # 反转域名部分作为包名
        parts = clean_domain.split('.')
        reversed_parts = parts[::-1]
        
        # 处理每个部分，确保符合Java包名规范
        processed_parts = []
        for part in reversed_parts:
            if not part:
                continue
            
            # 如果部分以数字开头，添加前缀
            if part[0].isdigit():
                part = 'domain' + part
            
            # 确保只包含字母和数字
            part = ''.join(c for c in part if c.isalnum())
            
            # 如果处理后为空，跳过
            if part:
                processed_parts.append(part.lower())
        
        # 构建包名
        if not processed_parts:
            # 如果没有有效部分，使用域名的hash
            domain_hash = hashlib.md5(domain.encode()).hexdigest()[:8]
            package_name = f'com.generated.domain{domain_hash}'
        else:
            package_name = 'com.' + '.'.join(processed_parts)
        
        # 如果包名太长，进行截断并添加哈希
        if len(package_name) > 50:
            hash_suffix = hashlib.md5(domain.encode()).hexdigest()[:8]
            package_name = package_name[:42] + hash_suffix
        
        return package_name
    
    def _normalize_keystore_path(self, keystore_path):
        """标准化签名文件路径，支持Docker环境"""
        # 检测是否在Docker环境中（通过工作目录判断）
        current_dir = os.getcwd()
        if '/app' in current_dir or os.path.exists('/app/workspace'):
            # Docker环境：返回相对路径
            keystore_name = os.path.basename(keystore_path)
            return f"keystores/{keystore_name}"
        else:
            # 宿主机环境：返回绝对路径
            return keystore_path
    
    def _generate_keystore(self, domain):
        """为域名生成签名文件"""
        keystore_name = f"{domain.replace('.', '_')}.jks"
        keystore_path = os.path.join(self.keystores_dir, keystore_name)
        
        if os.path.exists(keystore_path):
            print(f"签名文件已存在: {keystore_path}")
            return keystore_path
        
        # 生成密钥参数
        alias = domain.replace('.', '').replace('-', '')[:20]  # 限制别名长度
        password = hashlib.sha256(domain.encode()).hexdigest()[:16]  # 生成16位密码
        
        # 检查keytool是否可用
        try:
            subprocess.run(['keytool', '-version'], capture_output=True, check=True)
        except (subprocess.CalledProcessError, FileNotFoundError):
            print(f"警告: keytool不可用，将在需要时生成签名文件")
            # 创建一个占位文件，实际签名由构建过程处理
            with open(keystore_path, 'w') as f:
                f.write("# Placeholder keystore file\n")
            return keystore_path
        
        # 生成keystore
        cmd = [
            'keytool', '-genkey', '-v',
            '-keystore', keystore_path,
            '-alias', alias,
            '-keyalg', 'RSA',
            '-keysize', '2048',
            '-validity', '10000',
            '-storepass', password,
            '-keypass', password,
            '-dname', f'CN={domain}, OU=WebApp, O=AutoBuild, L=City, S=State, C=CN'
        ]
        
        try:
            subprocess.run(cmd, capture_output=True, text=True, check=True)
            print(f"✅ 为域名 {domain} 生成签名文件: {keystore_path}")
            return keystore_path
        except subprocess.CalledProcessError as e:
            print(f"❌ 生成签名文件失败: {e}")
            print(f"错误输出: {e.stderr}")
            return None
    
    def get_domain_config(self, app_url):
        """获取域名的完整配置"""
        domain = self._url_to_domain(app_url)
        
        if domain in self.configs:
            print(f"使用已存在的域名配置: {domain}")
            config = self.configs[domain]
        else:
            print(f"为新域名创建配置: {domain}")
            
            # 生成包名
            package_name = self._domain_to_package_name(domain)
            
            # 生成签名文件
            keystore_path = self._generate_keystore(domain)
            if not keystore_path:
                raise Exception(f"无法为域名 {domain} 生成签名文件")
            
            # 生成密码
            password = hashlib.sha256(domain.encode()).hexdigest()[:16]
            alias = domain.replace('.', '').replace('-', '')[:20]
            
            config = {
                'domain': domain,
                'package_name': package_name,
                'keystore_path': self._normalize_keystore_path(keystore_path),
                'keystore_password': password,
                'key_alias': alias,
                'key_password': password,
                'created_at': datetime.now().isoformat()
            }
            
            self.configs[domain] = config
            self._save_configs()
        
        return config
    
    def list_domains(self):
        """列出所有域名配置"""
        return list(self.configs.keys())
    
    def remove_domain(self, domain):
        """移除域名配置（但保留签名文件）"""
        if domain in self.configs:
            del self.configs[domain]
            self._save_configs()
            print(f"已移除域名配置: {domain}")
            return True
        return False

def main():
    """命令行工具"""
    import sys
    
    if len(sys.argv) < 2:
        print("用法:")
        print("  python3 domain_manager.py get <app_url>     # 获取域名配置")
        print("  python3 domain_manager.py list              # 列出所有域名")
        print("  python3 domain_manager.py remove <domain>   # 移除域名配置")
        sys.exit(1)
    
    manager = DomainManager()
    command = sys.argv[1]
    
    if command == 'get':
        if len(sys.argv) < 3:
            print("错误: 需要提供app_url")
            sys.exit(1)
        
        app_url = sys.argv[2]
        try:
            config = manager.get_domain_config(app_url)
            print(json.dumps(config, indent=2, ensure_ascii=False))
        except Exception as e:
            print(f"错误: {e}")
            sys.exit(1)
    
    elif command == 'list':
        domains = manager.list_domains()
        if domains:
            print("已配置的域名:")
            for domain in domains:
                config = manager.configs[domain]
                print(f"  {domain} -> {config['package_name']}")
        else:
            print("暂无配置的域名")
    
    elif command == 'remove':
        if len(sys.argv) < 3:
            print("错误: 需要提供域名")
            sys.exit(1)
        
        domain = sys.argv[2]
        if manager.remove_domain(domain):
            print(f"已移除域名: {domain}")
        else:
            print(f"域名不存在: {domain}")
    
    else:
        print(f"未知命令: {command}")
        sys.exit(1)

if __name__ == '__main__':
    main()