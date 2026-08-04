import { ref, onMounted, watch } from 'vue'
import { supabase } from '@/lib/supabaseClient'

export function useTeam() {
  const loading = ref(false)
  const isSubmitting = ref(false)
  const error = ref(null)

  const searchQuery = ref('')
  const selectedSpbuId = ref('')

  const kpis = ref({
    totalOperators: 0,
    activeOperators: 0,
    totalSpbu: 0
  })

  const spbuList = ref([])
  const teamMembers = ref([])
  const spbuAccounts = ref([])

  const fetchTeam = async () => {
    loading.value = true
    error.value = null
    try {
      const { data, error: err } = await supabase.rpc('get_master_team_overview', {
        p_spbu_id: selectedSpbuId.value ? String(selectedSpbuId.value) : '',
        p_search: searchQuery.value ? String(searchQuery.value) : ''
      })

      if (err) throw err

      if (data) {
        kpis.value = data.kpis || { totalOperators: 0, activeOperators: 0, totalSpbu: 0 }
        spbuList.value = data.spbuList || []
        teamMembers.value = data.operators || []
        spbuAccounts.value = data.accounts || []
      }
    } catch (err) {
      console.error('Gagal memuat data tim & operator:', err.message || err)
      error.value = err.message || 'Gagal terhubung ke RPC database'
    } finally {
      loading.value = false
    }
  }

  const createOperator = async ({ spbu_id, nama_operator, is_active = true }) => {
    isSubmitting.value = true
    try {
      const { data, error: err } = await supabase.rpc('manage_operator', {
        p_action: 'create',
        p_id: null,
        p_spbu_id: spbu_id || '',
        p_nama_operator: nama_operator || '',
        p_is_active: is_active ?? true
      })

      if (err) throw err

      await fetchTeam()
      return { success: true, data }
    } catch (err) {
      console.error('Gagal membuat operator:', err.message || err)
      return { success: false, message: err.message || 'Gagal menambah operator' }
    } finally {
      isSubmitting.value = false
    }
  }

  const updateOperator = async (id, { spbu_id, nama_operator, is_active }) => {
    isSubmitting.value = true
    try {
      const { data, error: err } = await supabase.rpc('manage_operator', {
        p_action: 'update',
        p_id: id,
        p_spbu_id: spbu_id || '',
        p_nama_operator: nama_operator || '',
        p_is_active: is_active ?? true
      })

      if (err) throw err

      await fetchTeam()
      return { success: true, data }
    } catch (err) {
      console.error('Gagal mengupdate operator:', err.message || err)
      return { success: false, message: err.message || 'Gagal memperbarui operator' }
    } finally {
      isSubmitting.value = false
    }
  }

  const toggleOperatorStatus = async (id) => {
    try {
      const { data, error: err } = await supabase.rpc('manage_operator', {
        p_action: 'toggle_status',
        p_id: id,
        p_spbu_id: '',
        p_nama_operator: '',
        p_is_active: true
      })

      if (err) throw err

      await fetchTeam()
      return { success: true, data }
    } catch (err) {
      console.error('Gagal mengubah status operator:', err.message || err)
      return { success: false, message: err.message || 'Gagal mengubah status' }
    }
  }

  let debounceTimer = null
  watch(searchQuery, () => {
    clearTimeout(debounceTimer)
    debounceTimer = setTimeout(() => {
      fetchTeam()
    }, 500)
  })

  watch(selectedSpbuId, () => {
    fetchTeam()
  })

  onMounted(() => {
    fetchTeam()
  })

  const resetOperatorAccountPassword = async (targetUserId, newPassword) => {
    isSubmitting.value = true
    try {
      const { data, error: err } = await supabase.rpc('master_reset_operator_password', {
        p_target_user_id: targetUserId,
        p_new_password: newPassword
      })

      if (err) throw err

      if (data && data.success === false) {
        return { success: false, message: data.message || 'Gagal mereset password' }
      }

      return { success: true, message: data?.message || 'Password akun operator berhasil diperbarui!' }
    } catch (err) {
      console.error('[useTeam] Gagal reset password operator:', err.message || err)
      return { success: false, message: err.message || 'Gagal mereset password akun' }
    } finally {
      isSubmitting.value = false
    }
  }

  return {
    teamMembers,
    spbuAccounts,
    spbuList,
    kpis,
    loading,
    isSubmitting,
    error,
    searchQuery,
    selectedSpbuId,
    fetchTeam,
    createOperator,
    updateOperator,
    toggleOperatorStatus,
    resetOperatorAccountPassword
  }
}
