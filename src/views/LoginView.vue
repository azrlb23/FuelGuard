<script setup>
import { ref } from 'vue'
import LoginForm from '@/components/auth/LoginForm.vue'
import ContactAdminModal from '@/components/auth/ContactAdminModal.vue'

const isContactModalOpen = ref(false)
</script>

<template>
  <div class="h-screen w-screen bg-white flex overflow-hidden font-sans relative">

    <!-- Left Column: Side Hero Panel (Kini di Sebelah Kiri) -->
    <div class="hidden lg:flex flex-1 h-full p-3 xl:p-4 bg-white">
      <div class="w-full h-full rounded-[2.5rem] xl:rounded-[3rem] relative overflow-hidden bg-gradient-to-br from-[#143d2e] via-[#1a4a38] to-[#258f62] p-10 xl:p-16 flex flex-col justify-center text-white shadow-xl">
        
        <!-- Ambient Glowing Graphic Overlays -->
        <div class="absolute -top-20 -left-20 w-96 h-96 bg-[#4ade80]/20 rounded-full blur-3xl pointer-events-none"></div>
        <div class="absolute bottom-0 right-0 w-full h-full bg-[radial-gradient(ellipse_at_top_left,_var(--tw-gradient-stops))] from-white/10 via-transparent to-black/30 pointer-events-none"></div>

        <!-- Abstract Decorative Wave Shape -->
        <div class="absolute inset-0 opacity-25 pointer-events-none overflow-hidden">
          <svg class="w-full h-full" viewBox="0 0 1000 1000" preserveAspectRatio="none" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M-200 300 C200 50 600 600 1200 200 L1200 1200 L-200 1200 Z" fill="url(#wave-grad-full-1)" />
            <path d="M-200 500 C300 200 700 800 1200 400 L1200 1200 L-200 1200 Z" fill="url(#wave-grad-full-2)" opacity="0.6" />
            <defs>
              <linearGradient id="wave-grad-full-1" x1="0" y1="0" x2="1" y2="1">
                <stop offset="0%" stop-color="#ffffff" stop-opacity="0.35"/>
                <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
              </linearGradient>
              <linearGradient id="wave-grad-full-2" x1="0" y1="1" x2="1" y2="0">
                <stop offset="0%" stop-color="#4ade80" stop-opacity="0.3"/>
                <stop offset="100%" stop-color="#ffffff" stop-opacity="0"/>
              </linearGradient>
            </defs>
          </svg>
        </div>

        <!-- Hero Main Message -->
        <div class="relative z-10 space-y-4 max-w-lg my-auto">
          <h3 class="text-4xl xl:text-5xl font-black tracking-tight leading-tight">
            Excellence in <br/> Every Drop.
          </h3>
          <p class="text-green-100/90 text-base font-medium leading-relaxed max-w-md">
            Sistem terintegrasi untuk pemantauan operasional SPBU yang presisi, efisien, dan transparan.
          </p>
        </div>

      </div>
    </div>

    <!-- Right Column: Form & Brand Section (Kini di Sebelah Kanan) -->
    <div class="w-full lg:w-[48%] xl:w-[44%] h-full flex flex-col justify-between p-6 sm:p-10 lg:p-14 xl:p-16 bg-white z-10 overflow-y-auto hide-scrollbar shrink-0">
      
      <!-- Top Logo & Brand Name -->
      <div class="flex items-center gap-3">
        <!-- PATH LOGO: Gantilah src gambar di bawah ini sesuai lokasi logo FuelGuard Anda (Contoh: '@/assets/fuelguard_logo.png' atau '@/assets/HJ_logo.png') -->
        <div class="w-14 h-14 rounded-2xl bg-[#143d2e] flex items-center justify-center p-2.5 shadow-md shadow-green-900/20 shrink-0">
          <img src="@/assets/fuelguard_logo.png" alt="FuelGuard Logo" class="w-full h-full object-contain brightness-0 invert" />
        </div>
        <div class="flex flex-col justify-center">
          <h1 class="text-2xl font-black text-[#143d2e] leading-none tracking-tight">FuelGuard</h1>
          <p class="text-[10px] font-bold text-gray-400 uppercase tracking-widest mt-1">Management System</p>
        </div>
      </div>

      <!-- Center Welcome & Login Form -->
      <div class="my-auto py-6 space-y-6 w-full max-w-md mx-auto">
        <div class="space-y-1.5 text-center">
          <h2 class="text-3xl sm:text-4xl font-black text-gray-900 tracking-tight">
            Selamat Datang
          </h2>
          <p class="text-sm font-medium text-gray-500">
            Silakan masukkan kredensial akun Anda untuk masuk.
          </p>
        </div>

        <LoginForm @open-contact-modal="isContactModalOpen = true" />
      </div>

      <!-- Bottom Footer -->
      <div class="flex items-center justify-center text-center text-xs font-medium text-gray-400 pt-4 border-t border-gray-100">
        <p>© {{ new Date().getFullYear() }} FuelGuard. All rights reserved.</p>
      </div>

    </div>

  </div>

  <!-- Modal Hubungi Admin -->
  <ContactAdminModal :is-open="isContactModalOpen" @close="isContactModalOpen = false" />
</template>