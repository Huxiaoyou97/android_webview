import React, { useState } from 'react'
import { Upload, Globe, Type, Image, Loader2 } from 'lucide-react'

function BuildForm({ onBuild, disabled }) {
  const [formData, setFormData] = useState({
    appName: '',
    appUrl: '',
    icon: null
  })
  const [iconPreview, setIconPreview] = useState(null)
  const [errors, setErrors] = useState({})

  const validateForm = () => {
    const newErrors = {}

    if (!formData.appName.trim()) {
      newErrors.appName = '请输入应用名称'
    }

    if (!formData.appUrl.trim()) {
      newErrors.appUrl = '请输入网站URL'
    } else if (!/^https?:\/\/.+/.test(formData.appUrl)) {
      newErrors.appUrl = '请输入有效的URL（以http://或https://开头）'
    }

    if (!formData.icon) {
      newErrors.icon = '请选择应用图标'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    
    if (!validateForm()) return

    const buildData = new FormData()
    buildData.append('appName', formData.appName)
    buildData.append('appUrl', formData.appUrl)
    buildData.append('icon', formData.icon)

    onBuild(buildData)
  }

  const handleIconChange = (e) => {
    const file = e.target.files[0]
    if (file) {
      if (file.type !== 'image/png') {
        setErrors(prev => ({
          ...prev,
          icon: '请选择PNG格式的图标'
        }))
        return
      }

      if (file.size > 5 * 1024 * 1024) { // 5MB
        setErrors(prev => ({
          ...prev,
          icon: '图标文件不能超过5MB'
        }))
        return
      }

      setFormData(prev => ({ ...prev, icon: file }))
      setErrors(prev => ({ ...prev, icon: null }))

      // 创建预览
      const reader = new FileReader()
      reader.onload = (e) => {
        setIconPreview(e.target.result)
      }
      reader.readAsDataURL(file)
    }
  }

  const handleInputChange = (field, value) => {
    setFormData(prev => ({ ...prev, [field]: value }))
    if (errors[field]) {
      setErrors(prev => ({ ...prev, [field]: null }))
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      <div className="text-center mb-6">
        <h2 className="text-2xl font-bold text-gray-800 mb-2">创建你的Android应用</h2>
        <p className="text-gray-600">填写下方信息，我们将为你自动生成APK文件</p>
      </div>

      {/* App Name */}
      <div>
        <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
          <Type className="w-4 h-4 mr-2" />
          应用名称
        </label>
        <input
          type="text"
          value={formData.appName}
          onChange={(e) => handleInputChange('appName', e.target.value)}
          className={`input-field ${errors.appName ? 'border-red-500' : ''}`}
          placeholder="例如：我的应用"
          maxLength={20}
        />
        {errors.appName && (
          <p className="text-red-500 text-sm mt-1">{errors.appName}</p>
        )}
      </div>

      {/* App URL */}
      <div>
        <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
          <Globe className="w-4 h-4 mr-2" />
          网站URL
        </label>
        <input
          type="url"
          value={formData.appUrl}
          onChange={(e) => handleInputChange('appUrl', e.target.value)}
          className={`input-field ${errors.appUrl ? 'border-red-500' : ''}`}
          placeholder="https://www.example.com"
        />
        {errors.appUrl && (
          <p className="text-red-500 text-sm mt-1">{errors.appUrl}</p>
        )}
      </div>

      {/* Icon Upload */}
      <div>
        <label className="flex items-center text-sm font-medium text-gray-700 mb-2">
          <Image className="w-4 h-4 mr-2" />
          应用图标
        </label>
        <div className="flex items-start space-x-4">
          <div className="flex-1">
            <div className={`upload-area ${errors.icon ? 'border-red-500' : ''}`}>
              <input
                type="file"
                accept="image/png"
                onChange={handleIconChange}
                className="hidden"
                id="icon-upload"
              />
              <label htmlFor="icon-upload" className="cursor-pointer">
                <Upload className="w-8 h-8 text-gray-400 mx-auto mb-2" />
                <p className="text-sm text-gray-600">
                  点击选择PNG图标文件
                </p>
                <p className="text-xs text-gray-500 mt-1">
                  推荐尺寸：512x512像素
                </p>
              </label>
            </div>
            {errors.icon && (
              <p className="text-red-500 text-sm mt-1">{errors.icon}</p>
            )}
          </div>
          {iconPreview && (
            <div className="w-20 h-20 rounded-lg border-2 border-gray-200 overflow-hidden">
              <img
                src={iconPreview}
                alt="图标预览"
                className="w-full h-full object-cover"
              />
            </div>
          )}
        </div>
      </div>

      {/* Submit Button */}
      <div className="pt-4">
        <button
          type="submit"
          disabled={disabled}
          className="w-full btn-primary flex items-center justify-center space-x-2 py-3 text-lg"
        >
          {disabled ? (
            <>
              <Loader2 className="w-5 h-5 animate-spin" />
              <span>正在构建应用...</span>
            </>
          ) : (
            <>
              <Upload className="w-5 h-5" />
              <span>开始构建APK</span>
            </>
          )}
        </button>
      </div>
    </form>
  )
}

export default BuildForm