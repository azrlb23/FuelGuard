<script setup>
defineEmits(['exportExcel', 'exportPdf'])
</script>

<template>
  <div class="bg-white rounded-3xl p-5 md:p-6 border border-gray-200/90 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
    <div>
      <h4 class="text-base font-extrabold text-[#143d2e]">Unduh Laporan</h4>
    </div>

    <div class="flex flex-col sm:flex-row items-stretch sm:items-center gap-3 w-full sm:w-auto">
      <button
        type="button"
        @click="$emit('exportExcel')"
        class="flex-1 sm:flex-none flex items-center justify-center gap-2 px-5 py-3 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-700 hover:bg-emerald-100 text-xs font-bold transition-all shadow-xs cursor-pointer active:scale-95"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-emerald-600 shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M3.375 19.5h17.25m-17.25 0a1.125 1.125 0 0 1-1.125-1.125M3.375 19.5h7.5c.621 0 1.125-.504 1.125-1.125m-8.625 1.125L12 10.5m0 0 4.5 4.5M12 10.5V3" />
        </svg>
        <span>Ekspor (.xlsx)</span>
      </button>

      <button
        type="button"
        @click="$emit('exportPdf')"
        class="flex-1 sm:flex-none flex items-center justify-center gap-2 px-6 py-3 rounded-full bg-[#143d2e] hover:bg-[#1e5c45] text-white text-xs font-bold transition-all shadow-md shadow-green-900/10 cursor-pointer active:scale-95"
      >
        <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2" stroke="currentColor" class="w-4 h-4 text-green-300 shrink-0">
          <path stroke-linecap="round" stroke-linejoin="round" d="M6.72 13.829c-.24.03-.48.062-.72.096m.72-.096a42.415 42.415 0 0 1 10.56 0m-10.56 0L6.34 18m10.94-4.171c.24.03.48.062.72.096m-.72-.096L17.66 18m0 0 .229 2.523a1.125 1.125 0 0 1-1.12 1.227H7.231a1.125 1.125 0 0 1-1.12-1.227L6.34 18m11.318 0h1.091A2.25 2.25 0 0 0 21 15.75V9.456c0-1.081-.768-2.015-1.837-2.175a48.055 48.055 0 0 0-1.913-.247M3 9.456c0-1.081.768-2.015 1.837-2.175a48.087 48.087 0 0 1 1.913-.247m0 0a48.1 48.1 0 0 1 10.5 0" />
        </svg>
        <span>Export Laporan PDF</span>
      </button>
    </div>
  </div>
</template>
