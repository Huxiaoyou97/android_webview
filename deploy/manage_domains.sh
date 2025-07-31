#!/bin/bash

# 域名管理工具的便利脚本
# 使用方法：
#   ./manage_domains.sh list                    # 列出所有域名
#   ./manage_domains.sh add <app_url>          # 添加新域名配置
#   ./manage_domains.sh show <app_url>         # 显示域名配置
#   ./manage_domains.sh remove <domain>        # 移除域名配置

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOMAIN_MANAGER="$SCRIPT_DIR/domain_manager.py"

if [ ! -f "$DOMAIN_MANAGER" ]; then
    echo "❌ 错误：找不到域名管理器 $DOMAIN_MANAGER"
    exit 1
fi

case "${1:-}" in
    "list")
        echo "📋 域名列表："
        python3 "$DOMAIN_MANAGER" list
        ;;
    "add"|"show")
        if [ -z "${2:-}" ]; then
            echo "❌ 错误：请提供app_url"
            echo "用法: $0 $1 <app_url>"
            exit 1
        fi
        echo "🔍 获取域名配置："
        python3 "$DOMAIN_MANAGER" get "$2"
        ;;
    "remove")
        if [ -z "${2:-}" ]; then
            echo "❌ 错误：请提供域名"
            echo "用法: $0 remove <domain>"
            exit 1
        fi
        echo "🗑️  移除域名配置："
        python3 "$DOMAIN_MANAGER" remove "$2"
        ;;
    "help"|"--help"|"-h"|"")
        echo "域名管理工具"
        echo ""
        echo "用法:"
        echo "  $0 list                    # 列出所有已配置的域名"
        echo "  $0 add <app_url>          # 为新的app_url添加域名配置"
        echo "  $0 show <app_url>         # 显示app_url的域名配置"
        echo "  $0 remove <domain>        # 移除指定域名的配置"
        echo ""
        echo "示例:"
        echo "  $0 add https://example.com"
        echo "  $0 show https://a.com"
        echo "  $0 list"
        echo "  $0 remove example.com"
        ;;
    *)
        echo "❌ 未知命令: $1"
        echo "使用 '$0 help' 查看帮助"
        exit 1
        ;;
esac