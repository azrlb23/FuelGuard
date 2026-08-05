<script setup>
import { onMounted, onUnmounted } from 'vue'

defineProps({
  isOpen: {
    type: Boolean,
    required: true,
  },
})

const emit = defineEmits(['close'])
const close = () => emit('close')

const handleKeydown = (e) => {
  if (e.key === 'Escape') close()
}
onMounted(() => document.addEventListener('keydown', handleKeydown))
onUnmounted(() => document.removeEventListener('keydown', handleKeydown))

const contacts = [
  {
    id: 'whatsapp',
    icon: 'whatsapp',
    label: 'WhatsApp',
    value: null,
    description: 'Hubungi via pesan langsung',
    href: null,
    badge: 'Chat',
  },
  {
    id: 'office',
    icon: 'office',
    label: 'Jam Kantor',
    value: 'Senin – Jumat',
    description: '08.00 – 17.00 WITA',
    href: null,
    badge: 'Info',
  },
]
</script>

<template>
  <Teleport to="body">
    <Transition name="modal-fade">
      <div
        v-if="isOpen"
        class="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/60 backdrop-blur-md"
        @click.self="close"
        role="dialog"
        aria-modal="true"
        aria-labelledby="contact-modal-title"
      >
        <Transition name="modal-slide">
          <div
            v-if="isOpen"
            class="bg-white rounded-3xl w-full max-w-md overflow-hidden shadow-2xl flex flex-col relative"
          >
            <!-- Signature Gradient Header (Sesuai gaya Operator Modal) -->
            <div class="p-6 bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] text-white relative overflow-hidden">
              <div class="absolute top-0 right-0 w-48 h-48 bg-white/10 rounded-full blur-3xl -translate-y-12 translate-x-12 pointer-events-none"></div>

              <div class="flex items-center justify-between relative z-10">
                <div class="flex items-center gap-3">
                  <div class="w-10 h-10 rounded-2xl bg-white/15 backdrop-blur-md border border-white/20 flex items-center justify-center text-white shrink-0 shadow-inner">
                    <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-5 h-5">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M18.364 5.636l-3.536 3.536m0 5.656l3.536 3.536M9.172 9.172L5.636 5.636m3.536 9.192l-3.536 3.536M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-5 0a4 4 0 11-8 0 4 4 0 018 0z" />
                    </svg>
                  </div>
                  <div>
                    <h3 id="contact-modal-title" class="text-base font-black tracking-tight leading-tight">
                      Hubungi Admin
                    </h3>
                    <p class="text-xs text-emerald-100/80 font-medium mt-0.5">
                      Tim kami siap membantu kendala akses Anda
                    </p>
                  </div>
                </div>

                <button
                  @click="close"
                  class="text-white/80 hover:text-white bg-white/10 hover:bg-white/20 p-2 rounded-2xl transition-all cursor-pointer backdrop-blur-md border border-white/15 active:scale-95"
                  title="Tutup"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-4 h-4">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                  </svg>
                </button>
              </div>
            </div>

            <!-- Body Contact List Minimalis -->
            <div class="p-5 space-y-2.5">
              <component
                v-for="contact in contacts"
                :key="contact.id"
                :is="contact.href ? 'a' : 'div'"
                :href="contact.href || undefined"
                :target="contact.href ? '_blank' : undefined"
                :rel="contact.href ? 'noopener noreferrer' : undefined"
                class="flex items-center justify-between p-3.5 rounded-2xl border text-left transition-all active:scale-[0.99]"
                :class="contact.href ? 'border-gray-200/80 hover:border-emerald-500 hover:bg-emerald-50/40 cursor-pointer shadow-2xs' : 'border-gray-100 bg-gray-50/60'"
              >
                <div class="flex items-center gap-3.5 min-w-0">
                  <!-- Icon Bubble Minimalis -->
                  <div
                    class="w-10 h-10 rounded-xl flex items-center justify-center text-gray-700 shrink-0 transition-all border"
                    :class="contact.href ? 'bg-emerald-50 border-emerald-100 text-[#143d2e]' : 'bg-gray-100 border-gray-200 text-gray-600'"
                  >
                    <!-- WhatsApp -->
                    <svg v-if="contact.icon === 'whatsapp'" class="w-5 h-5 fill-current" viewBox="0 0 24 24">
                      <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                    </svg>
                    <!-- Email -->
                    <svg v-else-if="contact.icon === 'email'" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
                    </svg>
                    <!-- Office -->
                    <svg v-else-if="contact.icon === 'office'" class="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                    </svg>
                  </div>

                  <div class="min-w-0">
                    <p class="text-[10px] font-bold uppercase tracking-wider text-gray-400">
                      {{ contact.label }}
                    </p>
                    <p class="text-xs font-bold text-gray-900 truncate">
                      {{ contact.value }}
                    </p>
                    <p class="text-[11px] text-gray-500 font-medium">
                      {{ contact.description }}
                    </p>
                  </div>
                </div>

                <span
                  class="text-[10px] font-extrabold px-2.5 py-1 rounded-lg uppercase tracking-wider shrink-0"
                  :class="contact.href ? 'bg-[#143d2e] text-white shadow-2xs' : 'bg-gray-200 text-gray-600'"
                >
                  {{ contact.badge }}
                </span>
              </component>
            </div>

            <!-- Footer Minimalis -->
            <div class="px-5 py-3.5 bg-gray-50/80 border-t border-gray-100 flex items-center justify-between">
              <span class="text-[11px] font-medium text-gray-400 flex items-center gap-1.5">
                <svg class="w-3.5 h-3.5 text-emerald-600 shrink-0" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5h.253a.25.25 0 01.244.304l-.459 2.066A1.75 1.75 0 0010.747 15H11a.75.75 0 000-1.5h-.253a.25.25 0 01-.244-.304l.459-2.066A1.75 1.75 0 009.253 9H9z" clip-rule="evenodd" />
                </svg>
                Respon 1×24 jam kerja
              </span>
              <button
                @click="close"
                class="px-4 py-2 bg-gray-200 hover:bg-gray-300 text-gray-800 font-bold text-xs rounded-xl transition-all active:scale-95 cursor-pointer"
              >
                Tutup
              </button>
            </div>
          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.2s ease;
}
.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.modal-slide-enter-active {
  transition: opacity 0.25s ease, transform 0.25s cubic-bezier(0.16, 1, 0.3, 1);
}
.modal-slide-leave-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.modal-slide-enter-from {
  opacity: 0;
  transform: scale(0.96) translateY(10px);
}
.modal-slide-leave-to {
  opacity: 0;
  transform: scale(0.98) translateY(6px);
}
</style>

