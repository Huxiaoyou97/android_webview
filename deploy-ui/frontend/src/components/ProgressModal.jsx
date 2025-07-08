import React from 'react'
import { X, Loader2, CheckCircle, AlertCircle } from 'lucide-react'

function ProgressModal({ progress, logs, onClose }) {
  const getStatusIcon = () => {
    if (progress === 100) {
      return <CheckCircle className="w-6 h-6 text-green-500" />
    }
    if (progress > 0) {
      return <Loader2 className="w-6 h-6 text-blue-500 animate-spin" />
    }
    return <AlertCircle className="w-6 h-6 text-gray-400" />
  }

  const getStatusText = () => {
    if (progress === 100) return '构建完成'
    if (progress > 0) return '正在构建...'
    return '准备开始'
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full mx-4 max-h-[80vh] overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b">
          <div className="flex items-center space-x-3">
            {getStatusIcon()}
            <h2 className="text-xl font-semibold text-gray-800">
              {getStatusText()}
            </h2>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Progress Bar */}
        <div className="p-6 border-b">
          <div className="flex items-center justify-between mb-2">
            <span className="text-sm font-medium text-gray-700">构建进度</span>
            <span className="text-sm text-gray-500">{progress}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all duration-300 ease-out"
              style={{ width: `${progress}%` }}
            />
          </div>
        </div>

        {/* Logs */}
        <div className="p-6">
          <h3 className="text-lg font-medium text-gray-800 mb-4">构建日志</h3>
          <div className="bg-gray-900 text-green-400 p-4 rounded-lg max-h-64 overflow-y-auto font-mono text-sm">
            {logs.length === 0 ? (
              <div className="text-gray-500">等待构建开始...</div>
            ) : (
              logs.map((log, index) => (
                <div key={index} className="mb-1">
                  <span className="text-gray-500">[{log.timestamp}]</span> {log.message}
                </div>
              ))
            )}
          </div>
        </div>

        {/* Footer */}
        <div className="p-6 border-t bg-gray-50">
          <div className="flex items-center justify-between">
            <div className="text-sm text-gray-600">
              {progress === 100 ? '✅ 构建完成，APK已准备好下载' : '⏳ 请耐心等待构建完成...'}
            </div>
            {progress !== 100 && (
              <button
                onClick={onClose}
                className="btn-secondary"
              >
                后台运行
              </button>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}

export default ProgressModal