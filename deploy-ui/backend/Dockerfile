# 使用带有JDK的Node.js镜像
FROM node:18

# 优化apt安装速度
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    wget \
    unzip \
    curl \
    git \
    python3 \
    python3-pip \
    default-jdk-headless \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# 设置Java环境变量
ENV JAVA_HOME=/usr/lib/jvm/default-java
ENV PATH=$PATH:$JAVA_HOME/bin

# 设置Android SDK环境
ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# 创建Android SDK目录
RUN mkdir -p $ANDROID_HOME

# 检测架构并下载对应的Android SDK命令行工具
RUN ARCH=$(uname -m) && \
    if [ "$ARCH" = "aarch64" ]; then \
        echo "Detected ARM64 architecture" && \
        wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/tools.zip; \
    else \
        echo "Detected x86_64 architecture" && \
        wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip -O /tmp/tools.zip; \
    fi && \
    unzip -q /tmp/tools.zip -d $ANDROID_HOME && \
    rm /tmp/tools.zip && \
    mv $ANDROID_HOME/cmdline-tools $ANDROID_HOME/latest && \
    mkdir -p $ANDROID_HOME/cmdline-tools && \
    mv $ANDROID_HOME/latest $ANDROID_HOME/cmdline-tools/

ENV PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin

# 接受许可证并安装必要的Android组件
RUN yes | sdkmanager --licenses && \
    sdkmanager "platform-tools" "platforms;android-34" "build-tools;34.0.0"

# 设置工作目录
WORKDIR /app

# 先复制并安装后端依赖
COPY backend/package*.json ./
RUN npm install --production

# 构建前端
COPY frontend/package*.json ./frontend/
RUN cd frontend && npm install

COPY frontend ./frontend/
RUN cd frontend && npm run build

# 复制前端构建结果
RUN cp -r frontend/dist ./dist

# 复制后端代码
COPY backend .

# 创建必要的目录
RUN mkdir -p uploads builds public

# 暴露端口
EXPOSE 3001

# 启动应用
CMD ["node", "server.js"]