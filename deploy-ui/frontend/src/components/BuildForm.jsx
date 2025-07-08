import { useState, useRef } from 'react'
import axios from 'axios'

const BuildForm = ({ onBuildStart, onBuildProgress, onBuildComplete, isBuilding }) => {
  const [formData, setFormData] = useState({
    appName: '',
    appUrl: '',
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
          appIcon: 'Please select a valid image file'
        }))
        return
      }

      // Validate file size (max 2MB)
      if (file.size > 2 * 1024 * 1024) {
        setErrors(prev => ({
          ...prev,
          appIcon: 'Image size must be less than 2MB'
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

  const validateForm = () => {
    const newErrors = {}

    if (!formData.appName.trim()) {
      newErrors.appName = 'App name is required'
    }


    if (!formData.appUrl.trim()) {
      newErrors.appUrl = 'App URL is required'
    } else {
      try {
        new URL(formData.appUrl)
      } catch {
        newErrors.appUrl = 'Please enter a valid URL'
      }
    }

    if (!formData.appIcon) {
      newErrors.appIcon = 'App icon is required'
    }

    setErrors(newErrors)
    return Object.keys(newErrors).length === 0
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    
    if (!validateForm()) {
      return
    }

    const submitData = new FormData()
    submitData.append('appName', formData.appName)
    submitData.append('appUrl', formData.appUrl)
    submitData.append('icon', formData.appIcon)

    try {
      onBuildStart(formData.appName)
      
      const response = await axios.post('/api/build', submitData, {
        headers: {
          'Content-Type': 'multipart/form-data'
        },
        onUploadProgress: (progressEvent) => {
          const uploadProgress = Math.round((progressEvent.loaded * 100) / progressEvent.total)
          onBuildProgress(uploadProgress * 0.1, `Uploading files... ${uploadProgress}%`)
        }
      })

      if (response.data.success) {
        // Start polling for build progress
        pollBuildProgress(response.data.buildId)
      } else {
        onBuildComplete(false)
        setErrors({ submit: response.data.message || 'Build failed' })
      }
    } catch (error) {
      onBuildComplete(false)
      setErrors({ 
        submit: error.response?.data?.message || 'Network error occurred' 
      })
    }
  }

  const pollBuildProgress = async (buildId) => {
    try {
      const response = await axios.get(`/api/build/${buildId}/progress`)
      const { progress, log, status, downloadUrl } = response.data

      onBuildProgress(progress, log)

      if (status === 'completed') {
        onBuildComplete(true, downloadUrl)
      } else if (status === 'failed') {
        onBuildComplete(false)
      } else {
        // Continue polling
        setTimeout(() => pollBuildProgress(buildId), 1000)
      }
    } catch (error) {
      onBuildComplete(false)
    }
  }

  const clearForm = () => {
    setFormData({
      appName: '',
      appUrl: '',
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
      <h2 className="text-2xl font-bold text-gray-800 mb-6">Build Your App</h2>
      
      <form onSubmit={handleSubmit} className="space-y-4">
        <div>
          <label htmlFor="appName" className="block text-sm font-medium text-gray-700 mb-2">
            App Name *
          </label>
          <input
            type="text"
            id="appName"
            name="appName"
            value={formData.appName}
            onChange={handleInputChange}
            className={`input-field ${errors.appName ? 'border-red-500' : ''}`}
            placeholder="My Awesome App"
            disabled={isBuilding}
          />
          {errors.appName && <p className="text-red-500 text-sm mt-1">{errors.appName}</p>}
        </div>


        <div>
          <label htmlFor="appUrl" className="block text-sm font-medium text-gray-700 mb-2">
            Website URL *
          </label>
          <input
            type="url"
            id="appUrl"
            name="appUrl"
            value={formData.appUrl}
            onChange={handleInputChange}
            className={`input-field ${errors.appUrl ? 'border-red-500' : ''}`}
            placeholder="https://example.com"
            disabled={isBuilding}
          />
          {errors.appUrl && <p className="text-red-500 text-sm mt-1">{errors.appUrl}</p>}
        </div>

        <div>
          <label htmlFor="appIcon" className="block text-sm font-medium text-gray-700 mb-2">
            App Icon *
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
                    Click to upload icon
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
            PNG, JPG, or SVG. Max 2MB. Recommended: 512x512px
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
                <span>Building...</span>
              </span>
            ) : (
              'Build APK'
            )}
          </button>
          <button
            type="button"
            onClick={clearForm}
            disabled={isBuilding}
            className="btn-secondary disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Clear
          </button>
        </div>
      </form>
    </div>
  )
}

export default BuildForm