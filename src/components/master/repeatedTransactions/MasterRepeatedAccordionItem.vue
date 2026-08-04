<script setup>
defineProps({
  item: {
    type: Object,
    required: true
  },
  index: {
    type: Number,
    required: true
  },
  isExpanded: {
    type: Boolean,
    default: false
  }
})

defineEmits(['toggle'])

const normalizePlate = (plat) => {
  if (!plat) return ''
  return plat.trim().toUpperCase().replace(/\s+/g, ' ')
}

const formatTimeOnly = (dateString) => {
  if (!dateString) return '-'
  const d = new Date(dateString)
  return d.toLocaleTimeString('id-ID', {
    timeZone: 'Asia/Makassar',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false
  }).replace('.', ':') + ' WITA'
}

const formatDateOnly = (dateString) => {
  if (!dateString) return '-'
  const d = new Date(dateString)
  return d.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric'
  })
}

const getInitials = (name) => {
  if (!name) return 'A'
  return name.charAt(0).toUpperCase()
}
</script>

<template>
  <div class="bg-[#184635]/90 border border-emerald-800/60 rounded-2xl overflow-hidden shadow-md transition-all duration-200">
    <!-- Accordion Header Bar -->
    <div
      @click="$emit('toggle')"
      class="p-4 flex items-center justify-between gap-4 cursor-pointer hover:bg-white/5 transition-colors select-none"
    >
      <!-- Left: License Plate -->
      <div class="flex items-center gap-3">
        <h3 class="text-lg md:text-xl font-black font-mono tracking-wider text-white">
          {{ normalizePlate(item.plat_nomor) }}
        </h3>
      </div>

      <!-- Right: Warning Pill + Chevron Toggle -->
      <div class="flex items-center gap-3">
        <div class="px-3 py-1 rounded-full bg-red-950/70 border border-red-700/60 text-red-300 text-xs font-extrabold flex items-center gap-1.5 shadow-2xs">
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor" class="w-3.5 h-3.5 text-red-400">
            <path stroke-linecap="round" stroke-linejoin="round" d="M12 9v3.75m-9.303 3.376c-.866 1.5.217 3.374 1.948 3.374h14.71c1.73 0 2.813-1.874 1.948-3.374L13.949 3.378c-.866-1.5-3.032-1.5-3.898 0L2.697 16.126zM12 15.75h.007v.008H12v-.008z" />
          </svg>
          <span>{{ item.attempt_count }}x</span>
        </div>

        <button
          type="button"
          class="w-8 h-8 rounded-full bg-white/10 hover:bg-white/20 flex items-center justify-center text-white/80 transition-transform duration-200"
          :class="isExpanded ? 'rotate-180 bg-white/20' : ''"
        >
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="3" stroke="currentColor" class="w-4 h-4">
            <path stroke-linecap="round" stroke-linejoin="round" d="m19.5 8.25-7.5 7.5-7.5-7.5" />
          </svg>
        </button>
      </div>
    </div>

    <!-- Expanded Accordion Content -->
    <div
      v-if="isExpanded"
      class="px-4 pb-4 pt-1 border-t border-emerald-800/40 bg-[#0e2e23]/90"
    >
      <!-- Mobile View: Compact Responsive Cards -->
      <div class="block md:hidden space-y-2.5 pt-2">
        <div
          v-for="attempt in item.attempts"
          :key="attempt.id"
          class="bg-emerald-950/70 border border-emerald-800/40 rounded-xl p-3 space-y-2.5 text-xs"
        >
          <!-- Top Row: Jam, Badge Tipe Transaksi & Tanggal -->
          <div class="flex items-center justify-between gap-2 border-b border-emerald-900/50 pb-2">
            <div class="flex items-center gap-2">
              <span class="text-emerald-200/90 text-[11px] font-bold font-mono">
                {{ formatTimeOnly(attempt.created_at) }}
              </span>
              <span
                :class="[
                  'text-[10px] font-extrabold px-2 py-0.5 rounded-full border transition-all',
                  attempt.is_ojol
                    ? 'bg-emerald-900/70 text-emerald-300 border-emerald-600/40'
                    : 'bg-white/10 text-gray-200 border-white/15'
                ]"
              >
                {{ attempt.is_ojol ? 'Ojol' : 'Biasa' }}
              </span>
            </div>
            <span class="text-emerald-200/80 text-[11px] font-bold">
              {{ formatDateOnly(attempt.created_at) }}
            </span>
          </div>

          <!-- Bottom Row: SPBU & Operator -->
          <div class="grid grid-cols-2 gap-2 text-emerald-100 font-semibold text-[11px] pt-1">
            <div class="flex items-center gap-1.5 truncate">
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-3.5 h-3.5 text-emerald-400 shrink-0">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
                <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z" />
              </svg>
              <span class="truncate">{{ attempt.spbu_nama }}</span>
            </div>

            <div class="flex items-center gap-1.5 truncate">
              <div class="w-4 h-4 rounded-full bg-emerald-800 text-emerald-200 flex items-center justify-center text-[9px] font-black shrink-0">
                {{ getInitials(attempt.operator_nama) }}
              </div>
              <span class="uppercase truncate">{{ attempt.operator_nama }}</span>
            </div>
          </div>

          <!-- Alasan Ditolak Row (Mobile) -->
          <div class="flex items-center justify-between text-[11px] pt-2 border-t border-emerald-900/50">
            <span class="text-emerald-200/60 font-medium">Alasan Ditolak</span>
            <span class="font-extrabold text-red-300 bg-red-950/70 px-2 py-0.5 rounded-md border border-red-700/50 text-[10px]">
              {{ attempt.reason || attempt.deskripsi || attempt.catatan || 'Kuota Harian Terlampaui' }}
            </span>
          </div>
        </div>
      </div>

      <!-- Desktop View: Clean Table -->
      <div class="hidden md:block overflow-x-auto">
        <table class="w-full text-left border-collapse min-w-[700px]">
          <thead>
            <tr class="text-[10px] font-black uppercase tracking-wider text-emerald-300/60 border-b border-emerald-800/30">
              <th class="py-2.5 px-3">JAM (WITA)</th>
              <th class="py-2.5 px-3">KATEGORI</th>
              <th class="py-2.5 px-3">LOKASI SPBU</th>
              <th class="py-2.5 px-3">OPERATOR BERTUGAS</th>
              <th class="py-2.5 px-3">ALASAN DITOLAK</th>
              <th class="py-2.5 px-3 text-right">TANGGAL</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-emerald-800/20 text-xs font-semibold">
            <tr
              v-for="attempt in item.attempts"
              :key="attempt.id"
              class="hover:bg-white/5 transition-colors"
            >
              <!-- JAM (WITA) -->
              <td class="py-3 px-3 whitespace-nowrap text-emerald-200/90 font-bold text-xs font-mono">
                {{ formatTimeOnly(attempt.created_at) }}
              </td>

              <!-- KATEGORI -->
              <td class="py-3 px-3 whitespace-nowrap">
                <span
                  :class="[
                    'text-[10px] font-extrabold px-2.5 py-0.5 rounded-full border transition-all',
                    attempt.is_ojol
                      ? 'bg-emerald-900/70 text-emerald-300 border-emerald-600/40'
                      : 'bg-white/10 text-gray-200 border-white/15'
                  ]"
                >
                  {{ attempt.is_ojol ? 'Ojol' : 'Biasa' }}
                </span>
              </td>

              <!-- LOKASI SPBU -->
              <td class="py-3 px-3 whitespace-nowrap">
                <div class="flex items-center gap-1.5 text-emerald-100 font-bold">
                  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-emerald-400 shrink-0">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0Z" />
                    <path stroke-linecap="round" stroke-linejoin="round" d="M19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z" />
                  </svg>
                  <span>{{ attempt.spbu_nama }}</span>
                </div>
              </td>

              <!-- OPERATOR BERTUGAS -->
              <td class="py-3 px-3 whitespace-nowrap">
                <div class="flex items-center gap-2 text-emerald-100 font-bold">
                  <div class="w-5 h-5 rounded-full bg-emerald-800 text-emerald-200 flex items-center justify-center text-[10px] font-black shrink-0">
                    {{ getInitials(attempt.operator_nama) }}
                  </div>
                  <span class="uppercase">{{ attempt.operator_nama }}</span>
                </div>
              </td>

              <!-- ALASAN DITOLAK -->
              <td class="py-3 px-3 whitespace-nowrap">
                <span class="inline-flex items-center px-2.5 py-0.5 rounded-md text-[10px] font-extrabold bg-red-500/20 text-red-300 border border-red-500/30">
                  {{ attempt.reason || attempt.deskripsi || attempt.catatan || 'Kuota Harian Terlampaui' }}
                </span>
              </td>

              <!-- TANGGAL -->
              <td class="py-3 px-3 text-right whitespace-nowrap text-emerald-200/90 font-bold">
                {{ formatDateOnly(attempt.created_at) }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>
