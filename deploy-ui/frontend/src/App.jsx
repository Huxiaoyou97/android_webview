import { useState } from 'react'
import BuildForm from './components/BuildForm'
import BatchBuildForm from './components/BatchBuildForm'
import ProgressModal from './components/ProgressModal'
import BatchProgressModal from './components/BatchProgressModal'
import DownloadModal from './components/DownloadModal'

function App() {
  const [buildMode, setBuildMode] = useState('single') // 'single' or 'batch'
  const [isBuilding, setIsBuilding] = useState(false)
  const [buildProgress, setBuildProgress] = useState(0)
  const [buildLog, setBuildLog] = useState('')
  const [downloadUrl, setDownloadUrl] = useState('')
  const [showDownloadModal, setShowDownloadModal] = useState(false)
  const [appName, setAppName] = useState('')
  
  // Batch build states
  const [batchProgress, setBatchProgress] = useState({
    completed: 0,
    total: 0,
    progress: 0,
    message: '',
    isComplete: false,
    successBuilds: [],
    failedBuilds: []
  })
  const [showBatchModal, setShowBatchModal] = useState(false)

  const handleBuildStart = (name) => {
    setAppName(name)
    setIsBuilding(true)
    setBuildProgress(0)
    setBuildLog('')
  }

  const handleBuildProgress = (progress, log) => {
    setBuildProgress(progress)
    setBuildLog(log)
  }

  const handleBuildComplete = (success, downloadUrl = '') => {
    setIsBuilding(false)
    if (success && downloadUrl) {
      setDownloadUrl(downloadUrl)
      setShowDownloadModal(true)
    }
  }

  const handleDownloadClose = () => {
    setShowDownloadModal(false)
    setDownloadUrl('')
    setBuildProgress(0)
    setBuildLog('')
  }

  // Batch build handlers
  const handleBatchStart = (totalBuilds) => {
    setIsBuilding(true)
    setShowBatchModal(true)
    setBatchProgress({
      completed: 0,
      total: totalBuilds,
      progress: 0,
      message: '准备开始批量构建...',
      isComplete: false,
      successBuilds: [],
      failedBuilds: []
    })
  }

  const handleBatchProgress = (completed, total, progress, message) => {
    setBatchProgress(prev => ({
      ...prev,
      completed,
      total,
      progress,
      message
    }))
  }

  const handleBatchComplete = (success, successBuilds = [], failedBuilds = []) => {
    setIsBuilding(false)
    setBatchProgress(prev => ({
      ...prev,
      isComplete: true,
      successBuilds,
      failedBuilds,
      progress: 100,
      message: `批量构建完成: ${successBuilds.length} 成功, ${failedBuilds.length} 失败`
    }))
  }

  const handleBatchModalClose = () => {
    setShowBatchModal(false)
    setBatchProgress({
      completed: 0,
      total: 0,
      progress: 0,
      message: '',
      isComplete: false,
      successBuilds: [],
      failedBuilds: []
    })
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 py-8 px-4">
      <div className="max-w-4xl mx-auto">
        <div className="text-center mb-8">
          <h1 className="text-4xl font-bold text-gray-800 mb-2">
            Android WebApp Builder
          </h1>
          <p className="text-gray-600 text-lg">
            Convert your website into an Android APK in minutes
          </p>
        </div>

        {/* Mode Selector */}
        <div className="flex justify-center mb-6">
          <div className="bg-white rounded-lg shadow-sm p-1 inline-flex">
            <button
              onClick={() => setBuildMode('single')}
              className={`px-6 py-2 rounded-md font-medium transition-all ${
                buildMode === 'single' 
                  ? 'bg-primary-500 text-white' 
                  : 'text-gray-600 hover:text-gray-800'
              }`}
            >
              单个构建
            </button>
            <button
              onClick={() => setBuildMode('batch')}
              className={`px-6 py-2 rounded-md font-medium transition-all ${
                buildMode === 'batch' 
                  ? 'bg-primary-500 text-white' 
                  : 'text-gray-600 hover:text-gray-800'
              }`}
            >
              批量构建
            </button>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          <div className="space-y-6">
            {buildMode === 'single' ? (
              <BuildForm 
                onBuildStart={handleBuildStart}
                onBuildProgress={handleBuildProgress}
                onBuildComplete={handleBuildComplete}
                isBuilding={isBuilding}
              />
            ) : (
              <BatchBuildForm
                onBatchStart={handleBatchStart}
                onBatchProgress={handleBatchProgress}
                onBatchComplete={handleBatchComplete}
                isBuilding={isBuilding}
              />
            )}
          </div>

          <div className="space-y-6">
            <div className="card">
              <h3 className="text-xl font-semibold text-gray-800 mb-4">
                How it works
              </h3>
              <div className="space-y-3 text-left">
                <div className="flex items-start space-x-3">
                  <div className="w-6 h-6 bg-primary-100 text-primary-600 rounded-full flex items-center justify-center text-sm font-medium">
                    1
                  </div>
                  <p className="text-gray-600">
                    Upload your app icon and enter your app details
                  </p>
                </div>
                <div className="flex items-start space-x-3">
                  <div className="w-6 h-6 bg-primary-100 text-primary-600 rounded-full flex items-center justify-center text-sm font-medium">
                    2
                  </div>
                  <p className="text-gray-600">
                    Our system builds your Android APK automatically
                  </p>
                </div>
                <div className="flex items-start space-x-3">
                  <div className="w-6 h-6 bg-primary-100 text-primary-600 rounded-full flex items-center justify-center text-sm font-medium">
                    3
                  </div>
                  <p className="text-gray-600">
                    Download your ready-to-install APK file
                  </p>
                </div>
              </div>
            </div>

            <div className="card">
              <h3 className="text-xl font-semibold text-gray-800 mb-4">
                Features
              </h3>
              <div className="space-y-2 text-left">
                <div className="flex items-center space-x-2">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  <span className="text-gray-600">Custom app icon support</span>
                </div>
                <div className="flex items-center space-x-2">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  <span className="text-gray-600">Real-time build progress</span>
                </div>
                <div className="flex items-center space-x-2">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  <span className="text-gray-600">Automatic APK signing</span>
                </div>
                <div className="flex items-center space-x-2">
                  <svg className="w-5 h-5 text-green-500" fill="currentColor" viewBox="0 0 20 20">
                    <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
                  </svg>
                  <span className="text-gray-600">Ready for installation</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <ProgressModal 
        isOpen={isBuilding}
        progress={buildProgress}
        log={buildLog}
        appName={appName}
      />

      <DownloadModal 
        isOpen={showDownloadModal}
        onClose={handleDownloadClose}
        downloadUrl={downloadUrl}
        appName={appName}
      />

      <BatchProgressModal
        isOpen={showBatchModal}
        onClose={handleBatchModalClose}
        completedBuilds={batchProgress.completed}
        totalBuilds={batchProgress.total}
        currentProgress={batchProgress.progress}
        currentMessage={batchProgress.message}
        isComplete={batchProgress.isComplete}
        successBuilds={batchProgress.successBuilds}
        failedBuilds={batchProgress.failedBuilds}
      />
    </div>
  )
}

export default App