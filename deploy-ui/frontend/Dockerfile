# 使用官方 Node.js 镜像
FROM node:20-alpine

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 yarn.lock
COPY package*.json ./
COPY yarn.lock* ./

# 安装依赖
RUN yarn install

# 复制应用代码
COPY . .

# 构建生产版本
RUN yarn build

# 检查构建结果
RUN ls -la dist/

# 安装serve来服务静态文件
RUN yarn global add serve

# 暴露端口
EXPOSE 3000

# 启动应用 - 如果dist不存在则使用当前目录
CMD ["sh", "-c", "if [ -d dist ]; then serve -s dist -l 3000; else echo 'dist not found, using current dir' && serve -s . -l 3000; fi"]