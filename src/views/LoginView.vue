<script setup>
import { ref } from 'vue'
import LoginForm from '@/components/auth/LoginForm.vue'
import ContactAdminModal from '@/components/auth/ContactAdminModal.vue'

const isContactModalOpen = ref(false)
</script>

<template>
  <div>
    <!--
      Semua breakpoint: Hero panel hijau memenuhi areanya sepenuhnya (full-bleed, tanpa inner padding/rounded card)
      Mobile (<md):  Hero atas = 45vh, form bawah = sisanya
      Tablet+Desktop (md+): Hero kiri = flex-1, form kanan = 48%
    -->
    <div class="min-h-screen w-full font-sans bg-white flex flex-col md:flex-row overflow-hidden">

      <!-- ============================================================
           HERO PANEL — Full-bleed, tanpa inner card/padding
           Mobile:  atas, tinggi 30vh (rasio 30:70)
           Tablet+Desktop: kiri, penuh tinggi layar
      ============================================================ -->
      <div class="w-full h-[30vh] md:h-auto md:flex-1 shrink-0 relative bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] flex flex-col justify-center p-6 md:p-12 lg:p-16 text-white overflow-hidden">

        <!-- Ambient glows -->
        <div class="absolute -top-24 -left-24 w-96 h-96 bg-[#4ade80]/20 rounded-full blur-3xl pointer-events-none"></div>
        <div class="absolute bottom-0 right-0 w-full h-full bg-[radial-gradient(ellipse_at_top_left,_var(--tw-gradient-stops))] from-white/10 via-transparent to-black/30 pointer-events-none"></div>

        <!-- Wave decoration -->
        <div class="absolute inset-0 opacity-25 pointer-events-none overflow-hidden">
          <svg class="w-full h-full" viewBox="0 0 1000 1000" preserveAspectRatio="none" fill="none">
            <path d="M-200 300 C200 50 600 600 1200 200 L1200 1200 L-200 1200 Z" fill="url(#wg1)" />
            <path d="M-200 500 C300 200 700 800 1200 400 L1200 1200 L-200 1200 Z" fill="url(#wg2)" opacity="0.6" />
            <defs>
              <linearGradient id="wg1" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0%" stop-color="#ffffff" stop-opacity="0.35"/>
                <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
              </linearGradient>
              <linearGradient id="wg2" x1="0" y1="1" x2="1" y2="0">
                <stop offset="0%" stop-color="#4ade80" stop-opacity="0.3"/>
                <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
              </linearGradient>
            </defs>
          </svg>
        </div>

        <!-- Mobile: brand centered -->
        <div class="md:hidden relative z-10 flex flex-col items-center justify-center gap-3 text-center">
          <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] flex items-center justify-center p-2.5 shadow-md shadow-emerald-950/40 border border-white/10">
            <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
          </div>
          <div>
            <h1 class="text-2xl font-black text-white leading-none tracking-tight">FuelGuard</h1>
            <p class="text-[10px] font-bold text-emerald-300/90 uppercase tracking-widest mt-1">Management System</p>
          </div>
        </div>

        <!-- Tablet + Desktop: hero text (left-aligned) -->
        <div class="hidden md:block relative z-10 space-y-4 max-w-lg">
          <h3 class="text-4xl xl:text-5xl font-black tracking-tight leading-tight">
            Excellence in <br/> Every Drop.
          </h3>
          <p class="text-green-100/90 text-base font-medium leading-relaxed max-w-md">
            Sistem terintegrasi untuk pemantauan operasional SPBU yang presisi, efisien, dan transparan.
          </p>
        </div>

      </div>

      <!-- ============================================================
           FORM SECTION
           Mobile:  bawah, flex-1 (sisa layar)
           Tablet+Desktop: kanan, lebar fixed
      ============================================================ -->
      <div class="w-full md:w-[48%] xl:w-[44%] flex-1 flex flex-col justify-between px-6 pt-6 pb-8 md:p-10 lg:p-14 xl:p-16 bg-white overflow-y-auto">

        <!-- Brand logo — tablet/desktop only (mobile brand ada di hero atas) -->
        <div class="hidden md:flex items-center gap-3 shrink-0">
          <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-[#143d2e] via-[#1b4d3a] to-[#256a50] flex items-center justify-center p-2.5 shadow-md shadow-emerald-950/20 border border-white/10 shrink-0">
            <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
          </div>
          <div class="flex flex-col justify-center">
            <h1 class="text-2xl font-black text-[#143d2e] leading-none tracking-tight">FuelGuard</h1>
            <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mt-1">Management System</p>
          </div>
        </div>

        <!-- Form content — vertically centered on md+ -->
        <div class="space-y-6 w-full max-w-sm mx-auto md:my-auto">
          <div class="space-y-1.5">
            <div class="text-center space-y-1">
              <h2 class="text-2xl md:text-3xl xl:text-4xl font-black text-gray-900 tracking-tight">Selamat Datang</h2>
            </div>
            <p class="text-sm font-medium text-gray-500 text-center">
              Silakan masukkan kredensial akun Anda untuk masuk.
            </p>
          </div>

          <LoginForm @open-contact-modal="isContactModalOpen = true" />
        </div>

        <!-- Footer -->
        <div class="pt-5 mt-4 text-center text-[11px] font-semibold text-gray-400 border-t border-gray-100">
          <p>© 2026 FuelGuard</p>
        </div>

      </div>

    </div>

    <!-- Modal Hubungi Admin -->
    <ContactAdminModal :is-open="isContactModalOpen" @close="isContactModalOpen = false" />
  </div>
</template>