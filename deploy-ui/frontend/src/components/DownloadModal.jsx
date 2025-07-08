import React from 'react'
import { Download, X, CheckCircle, Smartphone, Share2 } from 'lucide-react'

function DownloadModal({ downloadUrl, onDownload, onClose }) {
  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text)
    alert('链接已复制到剪贴板！')
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full mx-4">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b">
          <div className="flex items-center space-x-3">
            <CheckCircle className="w-6 h-6 text-green-500" />
            <h2 className="text-xl font-semibold text-gray-800">
              构建完成！
            </h2>
          </div>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 transition-colors"
          >
            <X className="w-6 h-6" />
          </button>
        </div>

        {/* Content */}
        <div className="p-6">
          <div className="text-center mb-6">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <Smartphone className="w-8 h-8 text-green-600" />
            </div>
            <h3 className="text-lg font-medium text-gray-800 mb-2">
              APK文件已准备就绪
            </h3>
            <p className="text-gray-600 text-sm">
              你的Android应用已成功构建完成
            </p>
          </div>

          {/* Download Button */}
          <button
            onClick={onDownload}
            className="w-full btn-primary flex items-center justify-center space-x-2 mb-4"
          >
            <Download className="w-5 h-5" />
            <span>下载APK文件</span>
          </button>

          {/* Share Link */}
          <div className="bg-gray-50 rounded-lg p-4">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              分享下载链接
            </label>
            <div className="flex items-center space-x-2">
              <input
                type="text"
                value={downloadUrl}
                readOnly
                className="flex-1 input-field text-sm"
              />
              <button
                onClick={() => copyToClipboard(downloadUrl)}
                className="btn-secondary p-2"
                title="复制链接"
              >
                <Share2 className="w-4 h-4" />
              </button>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="p-6 border-t bg-gray-50">
          <div className="text-xs text-gray-500 text-center space-y-1">
            <p>💡 安装提示：下载后在Android设备上安装</p>
            <p>🔒 可能需要在设置中允许"未知来源"应用安装</p>
          </div>
        </div>
      </div>
    </div>
  )
}

export default DownloadModal