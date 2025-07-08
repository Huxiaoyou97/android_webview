import React, { useState } from 'react'
import { Upload, Download, Settings, Smartphone, Globe, Image } from 'lucide-react'
import BuildForm from './components/BuildForm'
import ProgressModal from './components/ProgressModal'
import DownloadModal from './components/DownloadModal'

function App() {
  const [isBuilding, setIsBuilding] = useState(false)
  const [buildProgress, setBuildProgress] = useState(0)
  const [buildLogs, setBuildLogs] = useState([])
  const [downloadUrl, setDownloadUrl] = useState(null)

  const handleBuild = async (buildData) => {
    setIsBuilding(true)
    setBuildProgress(0)
    setBuildLogs([])
    setDownloadUrl(null)

    try {
      const response = await fetch('/api/build', {
        method: 'POST',
        body: buildData, // FormData
      })

      if (!response.ok) {
        throw new Error('Build failed')
      }

      // 轮询构建状态
      const pollBuildStatus = async () => {
        const statusResponse = await fetch('/api/build/status')
        const status = await statusResponse.json()
        
        setBuildProgress(status.progress)
        setBuildLogs(status.logs)

        if (status.completed) {
          if (status.success) {
            setDownloadUrl(status.downloadUrl)
          } else {
            alert('构建失败，请查看日志')
          }
          setIsBuilding(false)
        } else {
          setTimeout(pollBuildStatus, 1000)
        }
      }

      setTimeout(pollBuildStatus, 1000)
    } catch (error) {
      console.error('Build error:', error)
      alert('构建失败: ' + error.message)
      setIsBuilding(false)
    }
  }

  const handleDownload = () => {
    if (downloadUrl) {
      window.open(downloadUrl, '_blank')
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="text-center mb-8">
          <div className="flex items-center justify-center mb-4">
            <Smartphone className="w-12 h-12 text-blue-600 mr-3" />
            <h1 className="text-4xl font-bold text-gray-800">Android WebApp Builder</h1>
          </div>
          <p className="text-xl text-gray-600">
            将你的网站轻松打包成Android应用
          </p>
        </div>

        {/* Features */}
        <div className="grid md:grid-cols-3 gap-6 mb-8">
          <div className="card p-6 text-center">
            <Globe className="w-12 h-12 text-blue-600 mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">网站转应用</h3>
            <p className="text-gray-600">输入网站URL，自动生成Android应用</p>
          </div>
          <div className="card p-6 text-center">
            <Image className="w-12 h-12 text-green-600 mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">自定义图标</h3>
            <p className="text-gray-600">上传512x512的PNG图标，自动适配各种尺寸</p>
          </div>
          <div className="card p-6 text-center">
            <Download className="w-12 h-12 text-purple-600 mx-auto mb-4" />
            <h3 className="text-lg font-semibold mb-2">一键下载</h3>
            <p className="text-gray-600">自动构建并提供APK下载</p>
          </div>
        </div>

        {/* Build Form */}
        <div className="max-w-2xl mx-auto">
          <div className="card p-8">
            <BuildForm onBuild={handleBuild} disabled={isBuilding} />
          </div>
        </div>

        {/* Footer */}
        <div className="text-center mt-12 text-gray-500">
          <p>基于Android WebView技术 • 支持文件上传和JavaScript交互</p>
        </div>
      </div>

      {/* Modals */}
      {isBuilding && (
        <ProgressModal
          progress={buildProgress}
          logs={buildLogs}
          onClose={() => setIsBuilding(false)}
        />
      )}

      {downloadUrl && (
        <DownloadModal
          downloadUrl={downloadUrl}
          onDownload={handleDownload}
          onClose={() => setDownloadUrl(null)}
        />
      )}
    </div>
  )
}

export default App