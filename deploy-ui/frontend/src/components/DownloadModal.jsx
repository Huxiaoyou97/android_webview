const DownloadModal = ({ isOpen, onClose, downloadUrl, appName }) => {

  if (!isOpen) return null

  const handleDownload = () => {
    // 直接打开下载链接，后端会处理文件名
    window.open(downloadUrl, '_blank')
  }

  const copyToClipboard = async () => {
    try {
      await navigator.clipboard.writeText(downloadUrl)
      // You could add a toast notification here
    } catch (error) {
      console.error('Failed to copy URL:', error)
    }
  }

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-md w-full">
        <div className="px-6 py-4 border-b border-gray-200">
          <div className="flex items-center justify-between">
            <h3 className="text-xl font-semibold text-gray-800">
              APK 构建完成！
            </h3>
            <button
              onClick={onClose}
              className="text-gray-400 hover:text-gray-600 transition-colors"
            >
              <svg className="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          </div>
        </div>

        <div className="p-6 space-y-4">
          <div className="text-center">
            <div className="w-16 h-16 bg-green-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <svg className="w-8 h-8 text-green-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <h4 className="text-lg font-medium text-gray-800 mb-2">
              {appName} 已构建完成！
            </h4>
            <p className="text-gray-600 text-sm">
              你的Android APK已成功构建，现在可以下载了。
            </p>
          </div>

          <div className="space-y-3">
            <button
              onClick={handleDownload}
              className="w-full btn-primary"
            >
              <span className="flex items-center justify-center space-x-2">
                <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 10v6m0 0l-3-3m3 3l3-3m2 8H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
                <span>下载APK</span>
              </span>
            </button>

          </div>

          <div className="bg-blue-50 border border-blue-200 rounded-lg p-4">
            <h5 className="font-medium text-blue-800 mb-2">安装说明：</h5>
            <ol className="text-sm text-blue-700 space-y-1">
              <li>1. 将APK文件传输到你的Android设备</li>
              <li>2. 在设备设置中允许“未知来源”</li>
              <li>3. 打开APK文件安装应用</li>
              <li>4. 按照提示完成安装</li>
            </ol>
          </div>

          <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
            <div className="flex items-start space-x-2">
              <svg className="w-5 h-5 text-yellow-600 mt-0.5 flex-shrink-0" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L3.732 16c-.77.833.192 2.5 1.732 2.5z" />
              </svg>
              <div>
                <h5 className="font-medium text-yellow-800">重要提示：</h5>
                <p className="text-sm text-yellow-700">
                  此APK仅供测试使用。如需发布到Google Play商店，需要使用自己的密钥库签名。
                </p>
              </div>
            </div>
          </div>
        </div>

        <div className="px-6 py-4 bg-gray-50 border-t border-gray-200 rounded-b-lg">
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-500">
              构建成功完成
            </span>
            <button
              onClick={onClose}
              className="text-sm text-primary-600 hover:text-primary-700 font-medium"
            >
              构建另一个应用
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}

export default DownloadModal