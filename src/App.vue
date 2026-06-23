<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

const canvas = ref(null)
const statusText = ref('Canvas shell bereit')

let ctx = null
let frameId = 0
let resizeObserver = null

function resizeCanvas() {
  const element = canvas.value
  if (!element || !ctx) return

  const ratio = Math.min(window.devicePixelRatio || 1, 2)
  const rect = element.getBoundingClientRect()

  element.width = Math.max(1, Math.floor(rect.width * ratio))
  element.height = Math.max(1, Math.floor(rect.height * ratio))
  ctx.setTransform(ratio, 0, 0, ratio, 0, 0)
}

function render() {
  const element = canvas.value
  if (!element || !ctx) return

  const width = element.clientWidth
  const height = element.clientHeight
  const gradient = ctx.createLinearGradient(0, 0, 0, height)
  gradient.addColorStop(0, '#0f172a')
  gradient.addColorStop(0.55, '#172554')
  gradient.addColorStop(1, '#111827')

  ctx.clearRect(0, 0, width, height)
  ctx.fillStyle = gradient
  ctx.fillRect(0, 0, width, height)

  ctx.strokeStyle = 'rgba(125, 211, 252, 0.22)'
  ctx.lineWidth = 2
  for (let x = 0; x < width; x += 80) {
    ctx.beginPath()
    ctx.moveTo(x, 0)
    ctx.lineTo(x + width * 0.18, height)
    ctx.stroke()
  }

  ctx.fillStyle = 'rgba(15, 23, 42, 0.68)'
  ctx.beginPath()
  ctx.roundRect(width * 0.18, height * 0.22, width * 0.64, height * 0.42, 18)
  ctx.fill()

  ctx.strokeStyle = 'rgba(250, 204, 21, 0.6)'
  ctx.strokeRect(width * 0.18, height * 0.22, width * 0.64, height * 0.42)

  ctx.fillStyle = '#f8fafc'
  ctx.font = '800 30px Inter, system-ui, sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText('Handwerk Ebadi', width / 2, height * 0.42)

  ctx.fillStyle = 'rgba(226, 232, 240, 0.78)'
  ctx.font = '600 16px Inter, system-ui, sans-serif'
  ctx.fillText('Canvas-Spiel-Shell', width / 2, height * 0.49)

  frameId = requestAnimationFrame(render)
}

onMounted(() => {
  const element = canvas.value
  if (!element) return

  ctx = element.getContext('2d')
  if (!ctx) return

  resizeCanvas()
  resizeObserver = new ResizeObserver(resizeCanvas)
  resizeObserver.observe(element)
  window.addEventListener('resize', resizeCanvas)
  render()
})

onBeforeUnmount(() => {
  cancelAnimationFrame(frameId)
  window.removeEventListener('resize', resizeCanvas)
  resizeObserver?.disconnect()
})
</script>

<template>
  <main class="game-shell">
    <section class="hud" aria-label="Spielstatus">
      <div>
        <span>Spiel</span>
        <strong>Handwerk Ebadi</strong>
      </div>
      <p>{{ statusText }}</p>
    </section>

    <section class="stage" aria-label="Spielbereich">
      <canvas ref="canvas" aria-label="Canvas-Spielbereich"></canvas>
    </section>

    <section class="controls" aria-label="Steuerung">
      <div>
        <span>Tastatur</span>
        <strong>Pfeiltasten, Leertaste</strong>
      </div>
      <div>
        <span>Mobil</span>
        <strong>Touch-Steuerung folgt</strong>
      </div>
    </section>
  </main>
</template>
