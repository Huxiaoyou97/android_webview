import { useEffect, useState } from 'react'

const BatchProgressModal = ({ isOpen, onClose, completedBuilds, totalBuilds, currentProgress, currentMessage, isComplete, successBuilds, failedBuilds }) => {
  const [showDetails, setShowDetails] = useState(false)

  useEffect(() => {
    if (isComplete) {
      setShowDetails(true)
    }
  }, [isComplete])

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center p-4 z-50">
      <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full max-h-[80vh] overflow-hidden">
        <div className="p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="text-xl font-bold text-gray-800">
              {isComplete ? '批量构建完成' : '批量构建进度'}
            </h3>
            {isComplete && (
              <button
                onClick={onClose}
                className="text-gray-400 hover:text-gray-600 transition-colors"
              >
                <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            )}
          </div>

          {/* Progress Bar */}
          <div className="mb-6">
            <div className="flex justify-between text-sm text-gray-600 mb-2">
              <span>已完成: {completedBuilds}/{totalBuilds}</span>
              <span>{Math.round(currentProgress)}%</span>
            </div>
            <div className="w-full bg-gray-200 rounded-full h-3 overflow-hidden">
              <div 
                className={`h-full transition-all duration-500 ${isComplete ? 'bg-green-500' : 'bg-primary-500'}`}
                style={{ width: `${currentProgress}%` }}
              >
                <div className="h-full bg-white/20 animate-pulse"></div>
              </div>
            </div>
          </div>

          {/* Current Status */}
          {!isComplete && (
            <div className="bg-blue-50 border border-blue-200 rounded-lg p-4 mb-4">
              <div className="flex items-center space-x-2">
                <svg className="animate-spin h-5 w-5 text-blue-600" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                <span className="text-blue-800">{currentMessage}</span>
              </div>
            </div>
          )}

          {/* Completion Summary */}
          {isComplete && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <div className="bg-green-50 border border-green-200 rounded-lg p-4">
                  <div className="flex items-center space-x-2 mb-2">
                    <svg className="w-5 h-5 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                    </svg>
                    <span className="font-semibold text-green-800">成功</span>
                  </div>
                  <p className="text-2xl font-bold text-green-600">{successBuilds?.length || 0}</p>
                </div>
                
                <div className="bg-red-50 border border-red-200 rounded-lg p-4">
                  <div className="flex items-center space-x-2 mb-2">
                    <svg className="w-5 h-5 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                    </svg>
                    <span className="font-semibold text-red-800">失败</span>
                  </div>
                  <p className="text-2xl font-bold text-red-600">{failedBuilds?.length || 0}</p>
                </div>
              </div>

              {/* Details Toggle */}
              <button
                onClick={() => setShowDetails(!showDetails)}
                className="w-full text-center text-primary-600 hover:text-primary-700 font-medium py-2"
              >
                {showDetails ? '隐藏详情' : '显示详情'}
              </button>

              {/* Build Details */}
              {showDetails && (
                <div className="max-h-60 overflow-y-auto space-y-2">
                  {successBuilds && successBuilds.length > 0 && (
                    <div>
                      <h4 className="font-semibold text-green-700 mb-2">成功的构建:</h4>
                      {successBuilds.map((build, index) => (
                        <div key={index} className="bg-gray-50 rounded-lg p-3 mb-2">
                          <div className="flex items-center justify-between">
                            <span className="text-sm font-medium">{build.apkName}</span>
                            <a
                              href={build.downloadUrl}
                              download
                              className="text-primary-600 hover:text-primary-700 text-sm font-medium"
                            >
                              下载
                            </a>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}

                  {failedBuilds && failedBuilds.length > 0 && (
                    <div>
                      <h4 className="font-semibold text-red-700 mb-2">失败的构建:</h4>
                      {failedBuilds.map((build, index) => (
                        <div key={index} className="bg-gray-50 rounded-lg p-3 mb-2">
                          <div className="flex items-center justify-between">
                            <span className="text-sm font-medium">{build.apkName}</span>
                            <span className="text-red-600 text-xs">{build.error}</span>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              )}

              {/* Download All Button */}
              {successBuilds && successBuilds.length > 0 && (
                <button
                  onClick={() => {
                    successBuilds.forEach(build => {
                      const link = document.createElement('a')
                      link.href = build.downloadUrl
                      link.download = build.apkName
                      document.body.appendChild(link)
                      link.click()
                      document.body.removeChild(link)
                    })
                  }}
                  className="w-full btn-primary"
                >
                  下载所有成功的APK ({successBuilds.length}个)
                </button>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  )
}

export default BatchProgressModal