import { ref } from 'vue'
import { supabase } from '@/lib/supabaseClient'
import { useAuthStore } from '@/stores/auth'


const onlineUserIds = ref(new Set())

export function usePresence() {
  const authStore = useAuthStore()
  let channel = null

  
  const initPresence = () => {
    if (!authStore.user) return

    
    channel = supabase.channel('system-presence')

    channel
      .on('presence', { event: 'sync' }, () => {
        
        const newState = channel.presenceState()
        const userIds = new Set()
        
        
        for (const id in newState) {
          
          const sessions = newState[id]
          sessions.forEach(session => {
            if (session.user_id) userIds.add(session.user_id)
          })
        }
        
        onlineUserIds.value = userIds
      })
      .subscribe(async (status) => {
        if (status === 'SUBSCRIBED') {
          
          await channel.track({ 
            user_id: authStore.user.id,
            online_at: new Date().toISOString()
          })
        }
      })
  }

  
  const leavePresence = async () => {
    if (channel) {
      await channel.unsubscribe()
      channel = null
    }
  }

  return {
    onlineUserIds,
    initPresence,
    leavePresence
  }
}