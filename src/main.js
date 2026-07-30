import 'vue3-toastify/dist/index.css'
import './assets/style.css'

import { createApp } from 'vue'
import { createPinia } from 'pinia'
import Vue3Toastify from 'vue3-toastify'
import App from './App.vue'
import router from './router'

const app = createApp(App)

app.use(createPinia())
app.use(router)
app.use(Vue3Toastify, {
  autoClose: 3500,
  position: 'top-right',
  theme: 'colored',
  hideProgressBar: false,
  closeOnClick: true,
  pauseOnHover: true,
  clearOnUrlChange: false
})

app.mount('#app')