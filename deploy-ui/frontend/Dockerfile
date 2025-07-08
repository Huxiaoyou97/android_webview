# 使用官方 Node.js 镜像
FROM node:20-alpine

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 yarn.lock
COPY package*.json ./
COPY yarn.lock* ./

# 安装依赖
RUN yarn install --frozen-lockfile

# 复制应用代码
COPY . .

# 构建生产版本 - 详细输出
RUN echo "开始构建..." && \
    yarn build && \
    echo "构建完成，检查结果..." && \
    ls -la dist/ && \
    echo "检查index.html..." && \
    ls -la dist/index.html

# 验证构建结果
RUN test -f dist/index.html || (echo "ERROR: dist/index.html not found" && exit 1)

# 全局安装serve
RUN npm install -g serve

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["serve", "-s", "dist", "-l", "3000"]