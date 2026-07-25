# 🎨 UI Style Guide & Design System Context (Habi Jaya Management)

> Documentasi ini dirancang khusus sebagai **prompt / context context reference** untuk **Figma Make**, **Figma AI**, atau tim desainer UI/UX yang akan membuat / mereplikasi komponen UI dari project **Habi Jaya Management System**.

---

## 🏛️ 1. Design Philosophy & Overview
* **Brand Name:** Habi Jaya Management System
* **Domain:** SPBU Operations, Fuel Transaction Tracking, Admin & Operator Dashboard
* **Visual Theme:** Modern, Enterprise, Clean, High-Contrast & Premium Feel
* **Key Characteristic:** Deep Emerald Green primary colors combined with soft off-white canvas (`#f5f5f5`), extra-rounded container cards (`rounded-[2rem]`), smooth gradients, dynamic micro-interactions, and high contrast typography.

---

## 🎨 2. Color Palette

### 🟢 Primary Brand Colors (Emerald Palette)
* **Primary Deep Emerald:** `#143d2e` (Digunakan pada Navbar Header, Login Page, Main Action Buttons, Primary Brand elements)
* **Primary Gradient Start:** `#143d2e`
* **Primary Gradient End:** `#258f62`
* **Secondary Emerald / Hover:** `#1e5c45` / `#0f2e23`
* **Accent Green:** `#22c55e` (Tailwind `green-500`) & `#4ade80` (Tailwind `green-400`)

### ⚪ Neutral & Background Colors
* **App Canvas Background:** `#f5f5f5` (Soft Off-White)
* **Card / Container Background:** `#ffffff` (Pure White)
* **Dark Mode / Dark Hero Canvas:** `#143d2e` (Full dark green screen for auth pages)
* **Borders:** `#e5e7eb` (`border-gray-200/60`), `#f3f4f6` (`border-gray-100`)

### 📝 Typography / Text Colors
* **Primary Text (Dark):** `#111827` (`text-gray-900`), `#143d2e` (Brand Dark Green)
* **Secondary Text:** `#4b5563` (`text-gray-700`), `#6b7280` (`text-gray-500`)
* **Muted / Caption Text:** `#9ca3af` (`text-gray-400`)
* **Text On Dark (Light):** `#ffffff` (White), `#dcfce7` (`text-green-100`), `#bbf7d0` (`text-green-200`)

### 🚦 Semantic Status Colors
* **Success / Growth Positive:** Green (`#22c55e`, `bg-green-500/20`, `text-green-200`)
* **Danger / Drop / Delete:** Red (`#ef4444`, `bg-red-50`, `text-red-500`, `bg-red-500/20`)
* **Warning / Alert:** Amber (`#f59e0b`)

---

## 🔤 3. Typography System

* **Font Family:** `Plus Jakarta Sans`, sans-serif (Google Fonts)
* **Scale & Hierarchy:**
  * **Hero Title:** `text-5xl font-extrabold tracking-tight`
  * **Page / Section Heading:** `text-3xl` s.d. `text-4xl font-extrabold tracking-tight text-[#143d2e]`
  * **Card Title / Stat Header:** `text-xl font-black text-[#143d2e]`
  * **Subtitle / Section Sub-header:** `text-sm font-bold uppercase tracking-widest text-gray-400`
  * **Body Text:** `text-sm` / `text-base font-medium text-gray-700`
  * **Caption / Badge Text:** `text-xs` / `text-[11px] font-bold uppercase tracking-wider`

---

## 📐 4. Layout, Spacing & Corner Radii (Design Tokens)

### 🔳 Corner Radii (Border Radius)
* **Cards & Stat Widgets:** `32px` (`rounded-[2rem]`) - Signature look!
* **Secondary Containers & Modals:** `24px` (`rounded-3xl`) / `16px` (`rounded-2xl`)
* **Inputs & Standard Action Buttons:** `16px` (`rounded-2xl`)
* **Badges, Avatars, Search Bar & Pill Buttons:** `9999px` (`rounded-full`)

### 🌑 Shadows & Depth
* **Card Shadow Primary:** `shadow-xl shadow-green-900/10`
* **Header / Floating Elements:** `shadow-lg shadow-green-900/20`
* **Soft Card Elevation:** `shadow-sm` / `shadow-md`

---

## 🧩 5. UI Component Guidelines for Figma

### 💳 1. Hero Stat Cards (Emerald Gradient)
* **Background:** `linear-gradient(135deg, #143d2e 0%, #258f62 100%)`
* **Border Radius:** `32px` (`rounded-[2rem]`)
* **Padding:** `24px` (Mobile) / `32px` (Desktop)
* **Typography:** White title (`text-green-100 uppercase text-sm font-bold`), massive white metric number (`36px - 48px font-bold`).
* **Visual Detail:** Translucent glowing ambient circle at bottom right (`w-32 h-32 bg-white/10 rounded-full blur-2xl`).

### ⚪ 2. Standard Content Cards
* **Background:** Solid White (`#ffffff`)
* **Border Radius:** `32px` (`rounded-[2rem]`)
* **Border:** `1px solid #f3f4f6`
* **Shadow:** Soft subtle shadow (`shadow-xl`)

### 🔘 3. Buttons & Interactive Elements
* **Primary Button:**
  * Background: Solid Deep Emerald (`#143d2e`) or Gradient (`#143d2e` to `#258f62`)
  * Text: White (`font-black text-lg`)
  * Corner Radius: `16px` (`rounded-2xl`) or Pill (`rounded-full`)
  * Padding: `py-4 px-6`
  * Micro-interaction: Scale down on click (`active:scale-95`), slight elevation on hover (`hover:-translate-y-0.5`).
* **Secondary / Ghost Button:**
  * Background: `bg-gray-200/50` or `transparent`
  * Text: `text-gray-700` or `text-[#143d2e]`
* **Danger Button:**
  * Background: `hover:bg-red-50`
  * Text: `text-red-500 font-medium`

### ✏️ 4. Form Inputs & Text Fields
* **Input Box:**
  * Background: `bg-gray-50` (Light mode) or `bg-white/10` (Dark mode)
  * Border: `1px solid #e5e7eb`
  * Radius: `16px` (`rounded-2xl`)
  * Padding: `py-4 pl-11 pr-4` (Includes left icon)
  * Focus State: `ring-2 ring-[#143d2e]/20 border-transparent`
* **Labels:** `text-[11px] font-bold uppercase tracking-wider text-gray-700`

### 🏷️ 5. Badges & Indicators
* **Pill Badge:** `rounded-full px-3 py-1 text-xs font-bold`
* **Growth Indicator (Positive):** `bg-green-500/20 text-green-200` dengan icon `↗`
* **Growth Indicator (Negative):** `bg-red-500/20 text-red-200` dengan icon `↘`

### 🔍 6. Search Bar (Global Header Search)
* **Style:** Pill shape (`rounded-full`)
* **Background:** `linear-gradient(to right, #143d2e, #1e5c45)`
* **Text & Placeholder:** White / Semi-transparent white (`placeholder-white/70`)

### 🖼️ 7. Icons
* **Icon Style:** Modern minimalist line-art (Heroicons / Lucide style), stroke width `1.5px` - `2px`.

---

## 🤖 6. Prompt Context Siap Pakai untuk Figma Make / AI

> **Salin teks di bawah ini sebagai prompt context ke Figma Make / AI Prompt:**

```text
Design System & Style Guidelines:
- Project Name: Habi Jaya Management System (Fuel Station & SPBU Management Platform)
- Primary Brand Color: Deep Emerald Green #143d2e
- Secondary Accent Color: Emerald Gradient (#143d2e to #258f62)
- Canvas / App Background: Soft Off-White #f5f5f5
- Card Background: Pure White #ffffff with border-radius of 32px (extra rounded cards)
- Font Family: Plus Jakarta Sans
- Design Vibe: Modern enterprise dashboard, clean, highly tactile, rounded geometry, glassmorphism accents, soft drop-shadows (shadow-xl shadow-green-900/10).
- Buttons: 16px or full-pill border radius, bold typography, rich click states.
- Form Elements: Rounded 16px text fields with icon prefixes, soft gray backgrounds, subtle emerald focus rings.
- Badges & Pills: Fully rounded pills for statuses, vehicle types, and financial metrics.
```
