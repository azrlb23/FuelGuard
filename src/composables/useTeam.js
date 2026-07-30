import { ref, onMounted } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useAuthStore } from '@/stores/auth'

export function useTeam() {
  const teamMembers = ref([])
  const loading = ref(false)
  const error = ref(null)
  const authStore = useAuthStore()

  const fetchTeam = async () => {
    if (!authStore.spbuId) return

    loading.value = true
    try {
      const { data, error: err } = await supabase
        .from('operator_profiles')
        .select('*')
        .eq('spbu_id', authStore.spbuId)
        .order('nama_operator', { ascending: true })

      if (err) throw err

      teamMembers.value = data
    } catch (err) {
      console.error('Gagal memuat tim:', err.message)
      error.value = err.message
    } finally {
      loading.value = false
    }
  }

  onMounted(() => {
    fetchTeam()
  })

  return { teamMembers, loading, fetchTeam }
}