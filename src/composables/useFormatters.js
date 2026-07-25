export function useFormatters() {
  const formatRupiah = (val) => {
    return new Intl.NumberFormat('id-ID', { 
      style: 'currency', 
      currency: 'IDR', 
      maximumFractionDigits: 0 
    }).format(val)
  }

  const formatDate = (dateString, withTime = false) => {
    if (!dateString) return '-'
    const options = { 
      day: 'numeric', 
      month: 'short', 
      year: 'numeric',
      ...(withTime && { hour: '2-digit', minute: '2-digit' })
    }
    return new Date(dateString).toLocaleDateString('id-ID', options)
  }

  const formatTimeAgo = (dateString) => {
    
    if (!dateString) return ''
    const date = new Date(dateString)
    const now = new Date()
    const diffInHours = Math.floor((now - date) / (1000 * 60 * 60))
    
    if (diffInHours < 1) {
      const diffInMinutes = Math.floor((now - date) / (1000 * 60))
      return `${diffInMinutes} mins ago`
    }
    return `${diffInHours} hours ago`
  }

  return { formatRupiah, formatDate, formatTimeAgo }
}