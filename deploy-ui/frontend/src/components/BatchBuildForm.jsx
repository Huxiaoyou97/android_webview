import { useState, useRef } from 'react'
import axios from 'axios'

const BatchBuildForm = ({ onBatchStart, onBatchProgress, onBatchComplete, isBuilding }) => {
  const [formData, setFormData] = useState({
    appName: '',
    urls: '',
    apkPrefix: '',
    appIcon: null
  })
  const [iconPreview, setIconPreview] = useState(null)
  const [errors, setErrors] = useState({})
  const fileInputRef = useRef(null)

  const handleInputChange = (e) => {
    const { name, value } = e.target
    setFormData(prev => ({
      ...prev,
      [name]: value
    }))
    // Clear error when user starts typing
    if (errors[name]) {
      setErrors(prev => ({
        ...prev,
        [name]: ''
      }))
    }
  }

  const handleIconChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      // Validate file type
      if (!file.type.startsWith('image/')) {
        setErrors(prev => ({
          ...prev,
          appIcon: '请选择有效的图片文件'
        }))
        return
      }

      // Validate file size (max 2MB)
      if (file.size > 2 * 1024 * 1024) {
        setErrors(prev => ({
          ...prev,
          appIcon: '图片大小不能超过2MB'
        }))
        return
      }

      setFormData(prev => ({
        ...prev,
        appIcon: file
      }))

      // Create preview
      const reader = new FileReader()
      reader.onload = (e) => {
        setIconPreview(e.target.result)
      }
      reader.readAsDataURL(file)

      // Clear error
      setErrors(prev => ({
        ...prev,
        appIcon: ''
      }))
    }
  }

  const parseUrls = (urlText) => {
    // Split by newlines and filter out empty lines
    const lines = urlText.split('\n').map(line => line.trim()).filter(line => line)
    const validUrls = []
    const invalidUrls = []

    lines.forEach(line => {
      try {
        const url = new URL(line)
        // Extract fb_pixel_id from URL
        const params = new URLSearchParams(url.search)
        const fbPixelId = params.get('fb_pixel_id')
        
        validUrls.push({
          url: line,
          fbPixelId: fbPixelId || null
        })
      } catch {
        if (line) {
          invalidUrls.push(line)
        }
      }
    })

    return { validUrls, invalidUrls }
  }

  const validateForm = () => {
    const newErrors = {}

    if (!formData.appName.trim()) {
      newErrors.appName = '请输入应用名称'
    }

    if (!formData.urls.trim()) {
      newErrors.urls = '请输入至少一个URL'
    } else {
      const { validUrls, invalidUrls } = parseUrls(formData.urls)
      if (validUrls.length === 0) {
        newErrors.urls = '没有有效的URL'
      } else if (invalidUrls.length > 0) {
        newErrors.urls = `以下URL无效: ${invalidUrls.join(', ')}`
      }
    }

    if (!formData.apkPrefix.trim()) {
      newErrors.apkPrefix = '请输入APK文件名前缀'
    }

    if (!formData.appIcon) {
      newErrors.appIcon = '请选择应用图标'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    
    if (!validateForm()) {
      return
    }

    const { validUrls } = parseUrls(formData.urls)
    
    const submitData = new FormData()
    submitData.append('appName', formData.appName)
    submitData.append('apkPrefix', formData.apkPrefix)
    submitData.append('icon', formData.appIcon)
    submitData.append('urls', JSON.stringify(validUrls))

    try {
      onBatchStart(validUrls.length)
      
      const response = await axios.post('/api/batch-build', submitData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        onUploadProgress: (progressEvent) => {
          const uploadProgress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
          onBatchProgress(0, validUrls.length, uploadProgress * 0.1, `上传文件中... ${uploadProgress}%`)
        }
      })

      // 检查响应状态
      if (response.status === 200 && response.data.batchId) {
        // 开始轮询批量构建状态
        pollBatchProgress(response.data.batchId)
      } else {
        onBatchComplete(false)
        setErrors({ submit: response.data.error || '批量构建失败' })
      }
    } catch (error) {
      onBatchComplete(false)
      setErrors({ 
        submit: error.response?.data?.error || '网络连接失败' 
      })
    }
  }

  const pollBatchProgress = async (batchId) => {
    try {
      const response = await axios.get(`/api/batch-build/status/${batchId}`)
      const { queue, completed, failed, currentBuild, totalBuilds, allCompleted, currentBuildProgress, progress } = response.data

      // 更新进度
      const completedCount = completed.length
      const overallProgress = progress || (totalBuilds > 0 ? (completedCount / totalBuilds) * 100 : 0)
      const currentMessage = currentBuild ? 
        `正在构建: ${currentBuild.apkName} (${completedCount + 1}/${totalBuilds})` : 
        `等待开始...`
      
      onBatchProgress(completedCount, totalBuilds, overallProgress, currentMessage, currentBuildProgress)

      if (allCompleted) {
        onBatchComplete(true, completed, failed)
      } else {
        // 继续轮询
        setTimeout(() => pollBatchProgress(batchId), 1000) // 更频繁的轮询以获取更流畅的进度
      }
    } catch (error) {
      onBatchComplete(false)
    }
  }

  const clearForm = () => {
    setFormData({
      appName: '',
      urls: '',
      apkPrefix: '',
      appIcon: null
    })
    setIconPreview(null)
    setErrors({})
    if (fileInputRef.current) {
      fileInputRef.current.value = ''
    }
  }

  return (
    <div className="card">
      <h2 className="text-2xl font-bold text-gray-800 mb-6">批量构建应用</h2>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="appName" className="block text-sm font-medium text-gray-700 mb-2">
            应用名称 *
          </label>
          <input
            type="text"
            id="appName"
            name="appName"
            value={formData.appName}
            onChange={handleInputChange}
            className={`input-field ${errors.appName ? 'border-red-500' : ''}`}
            placeholder="我的应用"
            disabled={isBuilding}
          />
          {errors.appName && <p className="text-red-500 text-sm mt-1">{errors.appName}</p>}
        </div>

        <div>
          <label htmlFor="apkPrefix" className="block text-sm font-medium text-gray-700 mb-2">
            APK文件名前缀 *
          </label>
          <input
            type="text"
            id="apkPrefix"
            name="apkPrefix"
            value={formData.apkPrefix}
            onChange={handleInputChange}
            className={`input-field ${errors.apkPrefix ? 'border-red-500' : ''}`}
            placeholder="Raja999-fb-"
            disabled={isBuilding}
          />
          {errors.apkPrefix && <p className="text-red-500 text-sm mt-1">{errors.apkPrefix}</p>}
          <p className="text-gray-500 text-xs mt-1">
            最终文件名格式: {formData.apkPrefix || '前缀'}{'<fb_pixel_id>'}.apk
          </p>
        </div>

        <div>
          <label htmlFor="urls" className="block text-sm font-medium text-gray-700 mb-2">
            网站URL列表 * (每行一个URL)
          </label>
          <textarea
            id="urls"
            name="urls"
            value={formData.urls}
            onChange={handleInputChange}
            className={`input-field ${errors.urls ? 'border-red-500' : ''}`}
            style={{
              whiteSpace: 'pre',
              overflowX: 'auto',
              overflowY: 'auto',
              wordBreak: 'keep-all',
              overflowWrap: 'normal'
            }}
            placeholder={`https://google.raja999v.com/?sdmode=3&fb_pixel_id=26
https://google.raja999v.com/?sdmode=3&fb_pixel_id=27
https://google.raja999v.com/?sdmode=3&fb_pixel_id=28`}
            rows={8}
            wrap="off"
            disabled={isBuilding}
          />
          {errors.urls && <p className="text-red-500 text-sm mt-1">{errors.urls}</p>}
          {formData.urls && (
            <p className="text-gray-500 text-xs mt-1">
              检测到 {parseUrls(formData.urls).validUrls.length} 个有效URL
            </p>
          )}
        </div>

        <div>
          <label htmlFor="appIcon" className="block text-sm font-medium text-gray-700 mb-2">
            应用图标 *
          </label>
          <div className="flex items-start space-x-4">
            <div className="flex-1">
              <input
                type="file"
                id="appIcon"
                ref={fileInputRef}
                onChange={handleIconChange}
                accept="image/*"
                className="hidden"
                disabled={isBuilding}
              />
              <button
                type="button"
                onClick={() => fileInputRef.current?.click()}
                className="w-full border-2 border-dashed border-gray-300 rounded-lg p-4 text-center hover:border-primary-400 transition-colors duration-200"
                disabled={isBuilding}
              >
                <div className="flex flex-col items-center space-y-2">
                  <svg className="w-8 h-8 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                  </svg>
                  <span className="text-sm text-gray-500">
                    点击上传图标
                  </span>
                </div>
              </button>
            </div>
            {iconPreview && (
              <div className="w-16 h-16 rounded-lg overflow-hidden border-2 border-gray-200">
                <img 
                  src={iconPreview} 
                  alt="Icon preview" 
                  className="w-full h-full object-cover"
                />
              </div>
            )}
          </div>
          {errors.appIcon && <p className="text-red-500 text-sm mt-1">{errors.appIcon}</p>}
          <p className="text-gray-500 text-xs mt-1">
            支持PNG、JPG格式，最大2MB，推荐尺寸512x512像素
          </p>
        </div>

        {errors.submit && (
          <div className="bg-red-50 border border-red-200 rounded-lg p-3">
            <p className="text-red-700 text-sm">{errors.submit}</p>
          </div>
        )}

        <div className="flex space-x-3 pt-4">
          <button
            type="submit"
            disabled={isBuilding}
            className="flex-1 btn-primary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {isBuilding ? (
              <span className="flex items-center justify-center space-x-2">
                <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24">
                  <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" fill="none" />
                  <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z" />
                </svg>
                <span>批量构建中...</span>
              </span>
            ) : (
              '开始批量构建'
            )}
          </button>
          <button
            type="button"
            onClick={clearForm}
            disabled={isBuilding}
            className="btn-secondary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            清空表单
          </button>
        </div>
      </form>
    </div>
  )
}

export default BatchBuildForm