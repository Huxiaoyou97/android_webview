#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
简化版域名管理器 - 专为Docker环境优化
"""

import os
import hashlib
import json
import sys
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
    
    # 确保第一部分以字母开头
    if reversed_parts and not reversed_parts[0][0].isalpha():
        reversed_parts[0] = 'domain' + reversed_parts[0]
    
    package_name = 'com.' + '.'.join(reversed_parts)
    
    # 如果包名太长，进行截断并添加哈希
    if len(package_name) > 50:
        hash_suffix = hashlib.md5(domain.encode()).hexdigest()[:8]
        package_name = package_name[:42] + hash_suffix
    
    return package_name

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
        # Docker环境：使用相对路径
        keystore_path = f"keystores/{domain.replace('.', '_')}.jks"
    else:
        # 宿主机环境：使用绝对路径
        base_dir = os.path.dirname(os.path.abspath(__file__))
        keystore_path = os.path.join(base_dir, 'keystores', f"{domain.replace('.', '_')}.jks")
    
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