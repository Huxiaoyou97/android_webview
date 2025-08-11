# Makefile for Android WebView Builder Docker Operations

# 默认配置（可通过命令行覆盖）
DOCKER_USERNAME ?= yourusername
IMAGE_NAME ?= android-webview-builder
VERSION ?= 1.0.0
PORT ?= 8080

# 镜像标签
LOCAL_IMAGE = $(IMAGE_NAME):$(VERSION)
REMOTE_IMAGE = $(DOCKER_USERNAME)/$(IMAGE_NAME):$(VERSION)
REMOTE_IMAGE_LATEST = $(DOCKER_USERNAME)/$(IMAGE_NAME):latest

.PHONY: help build run push push-latest clean deploy all

# 默认目标：显示帮助
help:
	@echo "Android WebView Builder - Docker管理命令"
	@echo ""
	@echo "使用方法: make [命令] [选项]"
	@echo ""
	@echo "命令:"
	@echo "  make build          - 构建Docker镜像"
	@echo "  make run            - 本地运行容器"
	@echo "  make push           - 推送到Docker Hub（需要先登录）"
	@echo "  make push-latest    - 推送版本号和latest标签"
	@echo "  make deploy         - 构建并运行"
	@echo "  make all            - 构建、推送并运行"
	@echo "  make clean          - 清理容器和镜像"
	@echo "  make logs           - 查看容器日志"
	@echo "  make stop           - 停止容器"
	@echo "  make restart        - 重启容器"
	@echo ""
	@echo "选项:"
	@echo "  DOCKER_USERNAME=xxx - Docker Hub用户名（默认: $(DOCKER_USERNAME)）"
	@echo "  IMAGE_NAME=xxx      - 镜像名称（默认: $(IMAGE_NAME)）"
	@echo "  VERSION=xxx         - 版本号（默认: $(VERSION)）"
	@echo "  PORT=xxx            - 端口号（默认: $(PORT)）"
	@echo ""
	@echo "示例:"
	@echo "  make build"
	@echo "  make push DOCKER_USERNAME=myname VERSION=2.0.0"
	@echo "  make run PORT=9090"

# 构建镜像
build:
	@echo "🔨 构建Docker镜像: $(LOCAL_IMAGE)"
	@echo "使用跨平台Dockerfile (支持Mac M1/M2和x86_64)..."
	docker build -t $(LOCAL_IMAGE) -f Dockerfile.cross-platform .
	@echo "✅ 构建完成"

# 运行容器
run:
	@echo "🚀 启动容器: $(IMAGE_NAME)"
	@docker stop $(IMAGE_NAME) 2>/dev/null || true
	@docker rm $(IMAGE_NAME) 2>/dev/null || true
	docker run -d \
		--name $(IMAGE_NAME) \
		-p $(PORT):80 \
		-v $(PWD)/data:/app/data \
		--restart unless-stopped \
		$(LOCAL_IMAGE)
	@echo "✅ 容器已启动"
	@echo "📍 访问地址: http://localhost:$(PORT)"

# 推送到Docker Hub（仅版本标签）
push: build
	@echo "📤 推送镜像到Docker Hub"
	@echo "目标: $(REMOTE_IMAGE)"
	docker tag $(LOCAL_IMAGE) $(REMOTE_IMAGE)
	docker push $(REMOTE_IMAGE)
	@echo "✅ 推送完成"
	@echo "🔗 https://hub.docker.com/r/$(DOCKER_USERNAME)/$(IMAGE_NAME)"

# 推送版本和latest标签
push-latest: build
	@echo "📤 推送镜像到Docker Hub（包含latest标签）"
	docker tag $(LOCAL_IMAGE) $(REMOTE_IMAGE)
	docker tag $(LOCAL_IMAGE) $(REMOTE_IMAGE_LATEST)
	docker push $(REMOTE_IMAGE)
	docker push $(REMOTE_IMAGE_LATEST)
	@echo "✅ 推送完成"
	@echo "🔗 https://hub.docker.com/r/$(DOCKER_USERNAME)/$(IMAGE_NAME)"

# 部署（构建并运行）
deploy: build run

# 完整流程（构建、推送、运行）
all: build push-latest run

# 清理
clean:
	@echo "🧹 清理容器和镜像"
	@docker stop $(IMAGE_NAME) 2>/dev/null || true
	@docker rm $(IMAGE_NAME) 2>/dev/null || true
	@docker rmi $(LOCAL_IMAGE) 2>/dev/null || true
	@echo "✅ 清理完成"

# 查看日志
logs:
	docker logs -f $(IMAGE_NAME)

# 停止容器
stop:
	@echo "⏹ 停止容器"
	docker stop $(IMAGE_NAME)
	@echo "✅ 已停止"

# 重启容器
restart:
	@echo "🔄 重启容器"
	docker restart $(IMAGE_NAME)
	@echo "✅ 已重启"

# 进入容器shell
shell:
	docker exec -it $(IMAGE_NAME) /bin/bash

# 查看容器状态
status:
	@docker ps | grep $(IMAGE_NAME) || echo "容器未运行"

# 拉取最新镜像（从Docker Hub）
pull:
	docker pull $(REMOTE_IMAGE_LATEST)

# 使用Docker Hub镜像运行
run-remote:
	@echo "🚀 使用Docker Hub镜像运行"
	@docker stop $(IMAGE_NAME) 2>/dev/null || true
	@docker rm $(IMAGE_NAME) 2>/dev/null || true
	docker run -d \
		--name $(IMAGE_NAME) \
		-p $(PORT):80 \
		-v $(PWD)/data:/app/data \
		--restart unless-stopped \
		$(REMOTE_IMAGE_LATEST)
	@echo "✅ 容器已启动"
	@echo "📍 访问地址: http://localhost:$(PORT)"