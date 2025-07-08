import express from 'express'
import cors from 'cors'
import multer from 'multer'
import { v4 as uuidv4 } from 'uuid'
import path from 'path'
import fs from 'fs'
import { fileURLToPath } from 'url'
import { spawn } from 'child_process'
import sharp from 'sharp'

const __filename = fileURLToPath(import.meta.url)
const __dirname = path.dirname(__filename)

const app = express()
const PORT = process.env.PORT || 3001

// 构建状态存储
const buildStatus = {
  isBuilding: false,
  progress: 0,
  logs: [],
  success: false,
  completed: false,
  downloadUrl: null,
  buildId: null
}

// 文件清理记录
const fileCleanupQueue = new Map() // 存储文件路径和过期时间

// 中间件
app.use(cors())
app.use(express.json())
app.use(express.static(path.join(__dirname, 'public')))

// 服务前端静态文件
app.use(express.static(path.join(__dirname, 'dist')))

// 创建必要的目录
const uploadsDir = path.join(__dirname, 'uploads')
const buildsDir = path.join(__dirname, 'builds')
const publicDir = path.join(__dirname, 'public')

;[uploadsDir, buildsDir, publicDir].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true })
  }
})

// 配置multer用于文件上传
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadsDir)
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9)
    cb(null, file.fieldname + '-' + uniqueSuffix + path.extname(file.originalname))
  }
})

const upload = multer({ 
  storage: storage,
  limits: {
    fileSize: 5 * 1024 * 1024 // 5MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'image/png') {
      cb(null, true)
    } else {
      cb(new Error('只允许PNG格式的图标文件'))
    }
  }
})

// 日志记录函数
const addLog = (message, type = 'info') => {
  const timestamp = new Date().toLocaleTimeString()
  const logEntry = {
    timestamp,
    message,
    type
  }
  buildStatus.logs.push(logEntry)
  console.log(`[${timestamp}] ${message}`)
}

// 添加文件到清理队列
const addToCleanupQueue = (filePath, delayMinutes = 10) => {
  const expireTime = Date.now() + (delayMinutes * 60 * 1000)
  fileCleanupQueue.set(filePath, expireTime)
  console.log(`文件 ${filePath} 将在 ${delayMinutes} 分钟后被清理`)
}

// 清理过期文件
const cleanupExpiredFiles = () => {
  const now = Date.now()
  const filesToDelete = []

  for (const [filePath, expireTime] of fileCleanupQueue.entries()) {
    if (now >= expireTime) {
      filesToDelete.push(filePath)
    }
  }

  filesToDelete.forEach(filePath => {
    try {
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath)
        console.log(`✅ 已清理文件: ${filePath}`)
      }
      fileCleanupQueue.delete(filePath)
    } catch (error) {
      console.error(`❌ 清理文件失败 ${filePath}:`, error.message)
    }
  })

  if (filesToDelete.length > 0) {
    console.log(`🧹 本次清理了 ${filesToDelete.length} 个文件`)
  }
}

// 清理上传目录中的旧文件
const cleanupUploadsDirectory = () => {
  try {
    const files = fs.readdirSync(uploadsDir)
    const now = Date.now()
    const maxAge = 10 * 60 * 1000 // 10分钟

    files.forEach(file => {
      const filePath = path.join(uploadsDir, file)
      const stats = fs.statSync(filePath)
      
      if (now - stats.mtime.getTime() > maxAge) {
        try {
          fs.unlinkSync(filePath)
          console.log(`🧹 清理上传文件: ${file}`)
        } catch (error) {
          console.error(`清理上传文件失败 ${file}:`, error.message)
        }
      }
    })
  } catch (error) {
    console.error('清理上传目录失败:', error.message)
  }
}

// 启动定时清理任务
setInterval(() => {
  cleanupExpiredFiles()
  cleanupUploadsDirectory()
}, 60 * 1000) // 每分钟检查一次

console.log('🧹 文件清理服务已启动，每分钟检查一次过期文件')

// 处理图标尺寸
const processIcon = async (inputPath, outputPath) => {
  try {
    // 检查原始图片尺寸
    const metadata = await sharp(inputPath).metadata()
    addLog(`原始图标尺寸: ${metadata.width}x${metadata.height}`)
    
    // 调整到512x512
    await sharp(inputPath)
      .resize(512, 512)
      .png()
      .toFile(outputPath)
    
    addLog('图标已调整为512x512尺寸')
    return true
  } catch (error) {
    addLog(`图标处理失败: ${error.message}`, 'error')
    return false
  }
}

// 构建APK
const buildAPK = async (appName, appUrl, iconPath) => {
  return new Promise((resolve, reject) => {
    const buildId = uuidv4()
    const projectDir = '/app/workspace'  // 挂载的项目目录
    const deployDir = path.join(projectDir, 'deploy')
    const configFile = path.join(deployDir, 'config.json')
    const iconFile = path.join(deployDir, 'icon.png')
    
    try {
      // 复制图标文件
      fs.copyFileSync(iconPath, iconFile)
      addLog('图标文件已复制到deploy目录')
      
      // 创建配置文件
      const config = {
        app_name: appName,
        app_url: appUrl,
        icon_file: 'icon.png'
      }
      
      fs.writeFileSync(configFile, JSON.stringify(config, null, 2))
      addLog('配置文件已创建')
      
      // 执行构建脚本
      const buildScript = path.join(deployDir, 'auto_build.sh')
      const buildProcess = spawn('bash', [buildScript], {
        cwd: deployDir,
        stdio: 'pipe'
      })
      
      buildProcess.stdout.on('data', (data) => {
        const output = data.toString().trim()
        if (output) {
          addLog(output)
          
          // 更新进度
          if (output.includes('正在替换应用图标')) {
            buildStatus.progress = 10
          } else if (output.includes('正在修改')) {
            buildStatus.progress = 20
          } else if (output.includes('正在清理')) {
            buildStatus.progress = 30
          } else if (output.includes('开始构建APK')) {
            buildStatus.progress = 40
          } else if (output.includes('Welcome to Gradle')) {
            buildStatus.progress = 50
          } else if (output.includes('Task :')) {
            buildStatus.progress = Math.min(buildStatus.progress + 2, 85)
          } else if (output.includes('BUILD SUCCESSFUL')) {
            buildStatus.progress = 95
          } else if (output.includes('构建完成')) {
            buildStatus.progress = 100
          }
        }
      })
      
      buildProcess.stderr.on('data', (data) => {
        const error = data.toString().trim()
        if (error) {
          addLog(`Error: ${error}`, 'error')
        }
      })
      
      buildProcess.on('close', (code) => {
        if (code === 0) {
          addLog('APK构建成功完成！')
          
          // 查找生成的APK文件
          const apkFile = path.join(deployDir, 'app-release.apk')
          if (fs.existsSync(apkFile)) {
            // 复制APK到public目录供下载
            const publicApkPath = path.join(publicDir, `${buildId}.apk`)
            fs.copyFileSync(apkFile, publicApkPath)
            
            // 将生成的APK添加到清理队列
            addToCleanupQueue(publicApkPath)
            
            buildStatus.success = true
            buildStatus.downloadUrl = `/api/download/${buildId}.apk`
            addLog('APK文件已准备好下载')
          } else {
            addLog('未找到生成的APK文件', 'error')
            buildStatus.success = false
          }
        } else {
          addLog(`构建失败，退出代码: ${code}`, 'error')
          buildStatus.success = false
        }
        
        buildStatus.completed = true
        buildStatus.isBuilding = false
        buildStatus.progress = 100
        buildStatus.buildId = buildId
        
        resolve(buildStatus.success)
      })
      
    } catch (error) {
      addLog(`构建过程出错: ${error.message}`, 'error')
      buildStatus.success = false
      buildStatus.completed = true
      buildStatus.isBuilding = false
      reject(error)
    }
  })
}

// API路由
app.post('/api/build', upload.single('icon'), async (req, res) => {
  try {
    if (buildStatus.isBuilding) {
      return res.status(409).json({ error: '正在构建中，请稍后再试' })
    }
    
    const { appName, appUrl } = req.body
    const iconFile = req.file
    
    if (!appName || !appUrl || !iconFile) {
      return res.status(400).json({ error: '缺少必要的参数' })
    }
    
    // 重置构建状态
    buildStatus.isBuilding = true
    buildStatus.progress = 0
    buildStatus.logs = []
    buildStatus.success = false
    buildStatus.completed = false
    buildStatus.downloadUrl = null
    buildStatus.buildId = null
    
    addLog('开始构建Android应用...')
    addLog(`应用名称: ${appName}`)
    addLog(`应用URL: ${appUrl}`)
    addLog(`图标文件: ${iconFile.filename}`)
    
    // 处理图标
    const processedIconPath = path.join(uploadsDir, 'processed-' + iconFile.filename)
    const iconProcessed = await processIcon(iconFile.path, processedIconPath)
    
    if (!iconProcessed) {
      buildStatus.isBuilding = false
      return res.status(400).json({ error: '图标处理失败' })
    }
    
    // 将上传的文件和处理后的图标添加到清理队列
    addToCleanupQueue(iconFile.path)
    addToCleanupQueue(processedIconPath)
    
    // 异步构建APK
    buildAPK(appName, appUrl, processedIconPath)
      .catch(error => {
        console.error('Build error:', error)
      })
    
    res.json({ message: '构建已开始', buildId: buildStatus.buildId })
    
  } catch (error) {
    console.error('API Error:', error)
    buildStatus.isBuilding = false
    res.status(500).json({ error: '服务器错误: ' + error.message })
  }
})

// 获取构建状态
app.get('/api/build/status', (req, res) => {
  res.json(buildStatus)
})

// 下载APK文件
app.get('/api/download/:filename', (req, res) => {
  const filename = req.params.filename
  const filePath = path.join(publicDir, filename)
  
  if (fs.existsSync(filePath)) {
    res.download(filePath, filename, (err) => {
      if (err) {
        console.error('Download error:', err)
      }
    })
  } else {
    res.status(404).json({ error: '文件未找到' })
  }
})

// 健康检查
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() })
})

// 清理状态API
app.get('/api/cleanup/status', (req, res) => {
  const now = Date.now()
  const pendingFiles = Array.from(fileCleanupQueue.entries()).map(([path, expireTime]) => ({
    path: path.replace(__dirname, ''),
    expiresIn: Math.max(0, Math.floor((expireTime - now) / 1000 / 60)), // 分钟
    size: fs.existsSync(path) ? fs.statSync(path).size : 0
  }))

  res.json({
    pendingCleanup: pendingFiles.length,
    files: pendingFiles,
    nextCleanupIn: pendingFiles.length > 0 ? Math.min(...pendingFiles.map(f => f.expiresIn)) : 0
  })
})

// 手动清理API
app.post('/api/cleanup/manual', (req, res) => {
  const before = fileCleanupQueue.size
  cleanupExpiredFiles()
  cleanupUploadsDirectory()
  const after = fileCleanupQueue.size
  
  res.json({
    message: '手动清理完成',
    cleanedFiles: before - after,
    remainingFiles: after
  })
})

// 前端路由回退 - 处理SPA路由
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'dist', 'index.html'))
})

app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 服务器运行在端口 ${PORT}`)
  console.log(`📁 上传目录: ${uploadsDir}`)
  console.log(`📦 构建目录: ${buildsDir}`)
  console.log(`🌐 静态文件目录: ${publicDir}`)
})