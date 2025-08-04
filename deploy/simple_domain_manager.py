#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
简化版域名管理器 - 专为Docker环境优化
"""

import os
import hashlib
import json
import sys
import subprocess
from urllib.parse import urlparse

def url_to_domain(url):
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

def domain_to_package_name(domain):
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

def ensure_keystore_exists(domain, keystore_path, password, alias):
    """确保签名文件存在，如果不存在则创建"""
    # 获取绝对路径
    if keystore_path.startswith('../'):
        # 相对路径转换为绝对路径
        base_dir = os.path.dirname(os.path.abspath(__file__))
        parent_dir = os.path.dirname(base_dir)
        keystore_abs_path = os.path.join(parent_dir, keystore_path.replace('../', ''))
    else:
        keystore_abs_path = keystore_path
    
    # 确保目录存在
    keystore_dir = os.path.dirname(keystore_abs_path)
    os.makedirs(keystore_dir, exist_ok=True)
    
    # 如果文件不存在，创建新的
    if not os.path.exists(keystore_abs_path):
        print(f"创建新的签名文件: {keystore_abs_path}")
        
        # 生成自签名证书
        dname = f"CN={domain}, OU=Mobile, O=Company, L=City, ST=State, C=US"
        cmd = [
            'keytool', '-genkey',
            '-v', '-keystore', keystore_abs_path,
            '-alias', alias,
            '-keyalg', 'RSA',
            '-keysize', '2048',
            '-validity', '10000',
            '-storepass', password,
            '-keypass', password,
            '-dname', dname,
            '-noprompt'
        ]
        
        try:
            subprocess.run(cmd, check=True, capture_output=True, text=True)
            print(f"✅ 签名文件创建成功")
        except subprocess.CalledProcessError as e:
            print(f"❌ 创建签名文件失败: {e.stderr}")
            raise
    else:
        print(f"签名文件已存在: {keystore_abs_path}")

def generate_domain_config(app_url):
    """生成域名配置"""
    domain = url_to_domain(app_url)
    package_name = domain_to_package_name(domain)
    
    # 生成密码和别名
    password = hashlib.sha256(domain.encode()).hexdigest()[:16]
    alias = domain.replace('.', '').replace('-', '')[:20]
    
    # 检测环境并设置路径
    current_dir = os.getcwd()
    if '/app' in current_dir or os.path.exists('/app/workspace'):
        # Docker环境：使用相对于项目根目录的路径
        keystore_path = f"../deploy/keystores/{domain.replace('.', '_')}.jks"
    else:
        # 宿主机环境：使用绝对路径
        base_dir = os.path.dirname(os.path.abspath(__file__))
        keystore_path = os.path.join(base_dir, 'keystores', f"{domain.replace('.', '_')}.jks")
    
    # 确保签名文件存在
    ensure_keystore_exists(domain, keystore_path, password, alias)
    
    config = {
        'domain': domain,
        'package_name': package_name,
        'keystore_path': keystore_path,
        'keystore_password': password,
        'key_alias': alias,
        'key_password': password
    }
    
    return config

def main():
    if len(sys.argv) < 3 or sys.argv[1] != 'get':
        print("用法: python3 simple_domain_manager.py get <app_url>")
        sys.exit(1)
    
    app_url = sys.argv[2]
    try:
        config = generate_domain_config(app_url)
        print(json.dumps(config, indent=2, ensure_ascii=False))
    except Exception as e:
        print(f"错误: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()