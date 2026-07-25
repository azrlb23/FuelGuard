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
    value: '+62 812-3456-7890',
    description: 'Hubungi via pesan langsung',
    href: 'https://wa.me/6281234567890',
    badge: 'Chat',
  },
  {
    id: 'email',
    icon: 'email',
    label: 'Email',
    value: 'azrielalbian23@gmail.com',
    description: 'Kirim permintaan akses',
    href: 'mailto:azrielalbian23@gmail.com',
    badge: 'Email',
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
        class="modal-backdrop"
        @click.self="close"
        role="dialog"
        aria-modal="true"
        aria-labelledby="contact-modal-title"
      >
        <Transition name="modal-slide">
          <div v-if="isOpen" class="modal-panel">

            <!-- Glow dekoratif — sama persis dengan DashboardShift & DashboardStats -->
            <div class="glow-top"></div>
            <div class="glow-bottom"></div>

            <!-- Header -->
            <div class="panel-header">
              <div>
                <span class="panel-badge">Support</span>
                <h2 id="contact-modal-title" class="panel-title">Hubungi Admin</h2>
                <p class="panel-subtitle">Butuh bantuan akses atau ada kendala? Tim kami siap membantu.</p>
              </div>
              <button class="close-btn" @click="close" aria-label="Tutup">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="2.5" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            <!-- Contact List -->
            <div class="contact-list">
              <component
                v-for="contact in contacts"
                :key="contact.id"
                :is="contact.href ? 'a' : 'div'"
                :href="contact.href || undefined"
                :target="contact.href ? '_blank' : undefined"
                :rel="contact.href ? 'noopener noreferrer' : undefined"
                class="contact-item"
                :class="{ 'contact-item--link': !!contact.href }"
              >
                <!-- Icon bubble -->
                <div class="item-icon">
                  <!-- WhatsApp -->
                  <svg v-if="contact.icon === 'whatsapp'" viewBox="0 0 24 24" fill="currentColor">
                    <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 01-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 01-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 012.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0012.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 005.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 00-3.48-8.413z"/>
                  </svg>
                  <!-- Email -->
                  <svg v-else-if="contact.icon === 'email'" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M21.75 6.75v10.5a2.25 2.25 0 01-2.25 2.25h-15a2.25 2.25 0 01-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0019.5 4.5h-15a2.25 2.25 0 00-2.25 2.25m19.5 0v.243a2.25 2.25 0 01-1.07 1.916l-7.5 4.615a2.25 2.25 0 01-2.36 0L3.32 8.91a2.25 2.25 0 01-1.07-1.916V6.75" />
                  </svg>
                  <!-- Office -->
                  <svg v-else-if="contact.icon === 'office'" fill="none" viewBox="0 0 24 24" stroke-width="1.8" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 6v6h4.5m4.5 0a9 9 0 11-18 0 9 9 0 0118 0z" />
                  </svg>
                </div>

                <!-- Text content -->
                <div class="item-content">
                  <p class="item-label">{{ contact.label }}</p>
                  <p class="item-value">{{ contact.value }}</p>
                  <p class="item-desc">{{ contact.description }}</p>
                </div>

                <!-- Badge -->
                <span class="item-badge">{{ contact.badge }}</span>
              </component>
            </div>

            <!-- Footer -->
            <div class="panel-footer">
              <svg viewBox="0 0 20 20" fill="currentColor">
                <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7-4a1 1 0 11-2 0 1 1 0 012 0zM9 9a.75.75 0 000 1.5h.253a.25.25 0 01.244.304l-.459 2.066A1.75 1.75 0 0010.747 15H11a.75.75 0 000-1.5h-.253a.25.25 0 01-.244-.304l.459-2.066A1.75 1.75 0 009.253 9H9z" clip-rule="evenodd" />
              </svg>
              Admin merespons dalam 1×24 jam kerja
            </div>

          </div>
        </Transition>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
/* ─── Backdrop ─── */
.modal-backdrop {
  position: fixed;
  inset: 0;
  z-index: 9999;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  background: rgba(10, 20, 15, 0.65);
  backdrop-filter: blur(8px);
  -webkit-backdrop-filter: blur(8px);
}

/* ─── Panel ─── */
.modal-panel {
  position: relative;
  width: 100%;
  max-width: 420px;
  background: linear-gradient(135deg, #143d2e 0%, #064e3b 100%);
  border-radius: 2rem;
  padding: 1.75rem;
  box-shadow:
    0 25px 60px rgba(0, 0, 0, 0.4),
    0 0 0 1px rgba(255, 255, 255, 0.06);
  overflow: hidden;
  color: #ffffff;
}

/* ─── Glow ─── */
.glow-top {
  position: absolute;
  top: -2.5rem;
  right: -2.5rem;
  width: 8rem;
  height: 8rem;
  background: rgba(255, 255, 255, 0.05);
  border-radius: 50%;
  filter: blur(2.5rem);
  pointer-events: none;
}

.glow-bottom {
  position: absolute;
  bottom: -2.5rem;
  left: -2.5rem;
  width: 8rem;
  height: 8rem;
  background: rgba(52, 211, 153, 0.15);
  border-radius: 50%;
  filter: blur(2.5rem);
  pointer-events: none;
}

/* ─── Header ─── */
.panel-header {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 12px;
  margin-bottom: 1.25rem;
  position: relative;
  z-index: 1;
}

.panel-badge {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.15);
  color: rgba(255, 255, 255, 0.85);
  font-size: 0.625rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.1em;
  padding: 3px 10px;
  border-radius: 999px;
  margin-bottom: 6px;
}

.panel-title {
  font-size: 1.25rem;
  font-weight: 800;
  color: #ffffff;
  line-height: 1.25;
  margin: 0 0 4px;
  letter-spacing: -0.02em;
}

.panel-subtitle {
  font-size: 0.8125rem;
  color: rgba(167, 243, 208, 0.8);
  margin: 0;
  line-height: 1.5;
}

.close-btn {
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  border: 1px solid rgba(255, 255, 255, 0.2);
  border-radius: 10px;
  background: rgba(255, 255, 255, 0.1);
  color: rgba(255, 255, 255, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: background 0.15s, color 0.15s;
}

.close-btn:hover {
  background: rgba(255, 255, 255, 0.2);
  color: #ffffff;
}

.close-btn svg {
  width: 16px;
  height: 16px;
}

/* ─── Contact List ─── */
.contact-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
  position: relative;
  z-index: 1;
}

.contact-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 14px;
  border-radius: 14px;
  background: rgba(255, 255, 255, 0.08);
  border: 1px solid rgba(255, 255, 255, 0.1);
  text-decoration: none;
  transition: background 0.18s ease, transform 0.18s ease, border-color 0.18s ease;
}

.contact-item--link {
  cursor: pointer;
}

.contact-item--link:hover {
  background: rgba(255, 255, 255, 0.14);
  border-color: rgba(255, 255, 255, 0.25);
  transform: translateY(-1px);
}

.item-icon {
  flex-shrink: 0;
  width: 40px;
  height: 40px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.12);
  border: 1px solid rgba(255, 255, 255, 0.15);
  color: #ffffff;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: transform 0.18s ease, background 0.18s ease;
}

.contact-item--link:hover .item-icon {
  transform: scale(1.1);
  background: rgba(255, 255, 255, 0.2);
}

.item-icon svg {
  width: 18px;
  height: 18px;
}

.item-content {
  flex: 1;
  min-width: 0;
}

.item-label {
  font-size: 0.6875rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.08em;
  color: rgba(167, 243, 208, 0.8);
  margin: 0 0 2px;
}

.item-value {
  font-size: 0.9rem;
  font-weight: 800;
  color: #ffffff;
  margin: 0 0 1px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.item-desc {
  font-size: 0.75rem;
  color: rgba(255, 255, 255, 0.45);
  margin: 0;
}

.item-badge {
  flex-shrink: 0;
  font-size: 0.625rem;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: rgba(255, 255, 255, 0.6);
  background: rgba(255, 255, 255, 0.1);
  border: 1px solid rgba(255, 255, 255, 0.15);
  padding: 3px 8px;
  border-radius: 6px;
  transition: background 0.15s, color 0.15s;
}

.contact-item--link:hover .item-badge {
  background: rgba(52, 211, 153, 0.2);
  color: #6ee7b7;
  border-color: rgba(52, 211, 153, 0.3);
}

.panel-footer {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  margin-top: 16px;
  font-size: 0.6875rem;
  font-weight: 500;
  color: rgba(167, 243, 208, 0.5);
  position: relative;
  z-index: 1;
}

.panel-footer svg {
  width: 13px;
  height: 13px;
  flex-shrink: 0;
  color: #34d399;
}

.modal-fade-enter-active,
.modal-fade-leave-active {
  transition: opacity 0.25s ease;
}
.modal-fade-enter-from,
.modal-fade-leave-to {
  opacity: 0;
}

.modal-slide-enter-active {
  transition: opacity 0.25s ease, transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}
.modal-slide-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}
.modal-slide-enter-from {
  opacity: 0;
  transform: translateY(20px) scale(0.96);
}
.modal-slide-leave-to {
  opacity: 0;
  transform: translateY(12px) scale(0.98);
}
</style>
