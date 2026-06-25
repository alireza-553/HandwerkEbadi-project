<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'

const canvas = ref(null)
const game = reactive({
  status: 'ready',
  score: 0,
  coins: 0,
  best: Number(localStorage.getItem('runner-best') || 0),
})

const lanes = [-1, 0, 1]
const input = {
  left: false,
  right: false,
  jump: false,
  slide: false,
}

const state = {
  ctx: null,
  width: 0,
  height: 0,
  pixelRatio: 1,
  playerLane: 1,
  targetLane: 1,
  playerY: 0,
  jumpHeight: 0,
  jumpVelocity: 0,
  slideTimer: 0,
  speed: 240,
  distance: 0,
  spawnTimer: 0,
  coinTimer: 0,
  obstacles: [],
  coins: [],
  animationId: 0,
  lastTime: 0,
}

const instruction = computed(() => {
  if (game.status === 'ready') return 'Leertaste oder Tippen startet'
  if (game.status === 'over') return 'Game Over - Leertaste startet neu'
  return 'Links/Rechts wechseln, Hoch springt, Runter rutscht'
})

function laneX(laneIndex) {
  const roadWidth = Math.min(state.width * 0.78, 520)
  const center = state.width / 2
  const gap = roadWidth / 3
  return center + lanes[laneIndex] * gap
}

function resetGame() {
  game.score = 0
  game.coins = 0
  state.playerLane = 1
  state.targetLane = 1
  state.jumpHeight = 0
  state.jumpVelocity = 0
  state.slideTimer = 0
  state.speed = 240
  state.distance = 0
  state.spawnTimer = 0.9
  state.coinTimer = 0.45
  state.obstacles = []
  state.coins = []
}

function startGame() {
  resetGame()
  game.status = 'running'
}

function endGame() {
  game.status = 'over'
  game.best = Math.max(game.best, game.score)
  localStorage.setItem('runner-best', String(game.best))
}

function moveLane(direction) {
  if (game.status !== 'running') {
    startGame()
    return
  }
  state.targetLane = Math.max(0, Math.min(2, state.targetLane + direction))
}

function jump() {
  if (game.status !== 'running') {
    startGame()
    return
  }
  if (state.jumpHeight > 2 || state.slideTimer > 0) return
  state.jumpVelocity = 540
}

function slide() {
  if (game.status !== 'running') {
    startGame()
    return
  }
  if (state.jumpHeight > 8) return
  state.slideTimer = 0.55
}

function spawnObstacle() {
  const kind = Math.random() > 0.56 ? 'high' : 'low'
  state.obstacles.push({
    kind,
    lane: Math.floor(Math.random() * 3),
    y: -80,
    width: 54,
    height: kind === 'high' ? 70 : 44,
  })
}

function spawnCoinLine() {
  const lane = Math.floor(Math.random() * 3)
  for (let i = 0; i < 4; i += 1) {
    state.coins.push({ lane, y: -80 - i * 48, radius: 12 })
  }
}

function update(delta) {
  if (game.status !== 'running') return

  state.distance += state.speed * delta
  game.score = Math.floor(state.distance / 8) + game.coins * 25
  state.speed = Math.min(420, state.speed + delta * 6)
  state.playerLane += (state.targetLane - state.playerLane) * Math.min(1, delta * 12)
  state.slideTimer = Math.max(0, state.slideTimer - delta)
  state.jumpHeight = Math.max(0, state.jumpHeight + state.jumpVelocity * delta)
  if (state.jumpHeight > 0 || state.jumpVelocity > 0) {
    state.jumpVelocity -= 1380 * delta
  }
  if (state.jumpHeight === 0 && state.jumpVelocity < 0) {
    state.jumpVelocity = 0
  }

  state.spawnTimer -= delta
  state.coinTimer -= delta
  if (state.spawnTimer <= 0) {
    spawnObstacle()
    state.spawnTimer = Math.max(0.55, 1.25 - state.speed / 520)
  }
  if (state.coinTimer <= 0) {
    spawnCoinLine()
    state.coinTimer = 1.15
  }

  state.obstacles.forEach((obstacle) => {
    obstacle.y += state.speed * delta
  })
  state.coins.forEach((coin) => {
    coin.y += state.speed * delta
  })

  checkCollisions()
  state.obstacles = state.obstacles.filter((obstacle) => obstacle.y < state.height + 80)
  state.coins = state.coins.filter((coin) => !coin.collected && coin.y < state.height + 60)
}

function checkCollisions() {
  const playerX = laneX(Math.round(state.playerLane))
  const playerY = state.playerY - state.jumpHeight
  const playerHeight = state.slideTimer > 0 ? 34 : 58
  const playerWidth = state.slideTimer > 0 ? 54 : 36

  for (const coin of state.coins) {
    const coinX = laneX(coin.lane)
    if (Math.abs(coinX - playerX) < 34 && Math.abs(coin.y - playerY) < 42) {
      coin.collected = true
      game.coins += 1
    }
  }

  for (const obstacle of state.obstacles) {
    const obstacleX = laneX(obstacle.lane)
    const xOverlap = Math.abs(obstacleX - playerX) < (obstacle.width + playerWidth) / 2 - 8
    const yOverlap = Math.abs(obstacle.y - playerY) < (obstacle.height + playerHeight) / 2 - 10
    const clearedByJump = obstacle.kind === 'low' && state.jumpHeight > 42
    const clearedBySlide = obstacle.kind === 'high' && state.slideTimer > 0
    if (xOverlap && yOverlap && !clearedByJump && !clearedBySlide) {
      endGame()
      return
    }
  }
}

function drawRoad(ctx) {
  const roadTop = state.height * 0.08
  const roadBottom = state.height
  const roadWidth = Math.min(state.width * 0.82, 560)
  const left = state.width / 2 - roadWidth / 2

  ctx.fillStyle = '#1f2937'
  ctx.beginPath()
  ctx.moveTo(left + roadWidth * 0.18, roadTop)
  ctx.lineTo(left + roadWidth * 0.82, roadTop)
  ctx.lineTo(left + roadWidth, roadBottom)
  ctx.lineTo(left, roadBottom)
  ctx.closePath()
  ctx.fill()

  ctx.strokeStyle = 'rgba(250, 204, 21, 0.55)'
  ctx.lineWidth = 3
  for (let i = 1; i < 3; i += 1) {
    const x = left + (roadWidth / 3) * i
    ctx.setLineDash([22, 18])
    ctx.beginPath()
    ctx.moveTo(x, roadTop)
    ctx.lineTo(x, roadBottom)
    ctx.stroke()
  }
  ctx.setLineDash([])
}

function drawPlayer(ctx) {
  const x = laneX(state.playerLane)
  const y = state.playerY - state.jumpHeight
  const sliding = state.slideTimer > 0
  ctx.fillStyle = 'rgba(0, 0, 0, 0.28)'
  ctx.beginPath()
  ctx.ellipse(x, y + 34, 34, 10, 0, 0, Math.PI * 2)
  ctx.fill()

  ctx.fillStyle = '#38bdf8'
  ctx.fillRect(x - (sliding ? 28 : 18), y - (sliding ? 12 : 34), sliding ? 56 : 36, sliding ? 30 : 58)
  ctx.fillStyle = '#f8fafc'
  ctx.fillRect(x - 12, y - (sliding ? 28 : 50), 24, 22)
}

function drawObstacle(ctx, obstacle) {
  const x = laneX(obstacle.lane)
  ctx.fillStyle = obstacle.kind === 'high' ? '#ef4444' : '#f97316'
  ctx.fillRect(x - obstacle.width / 2, obstacle.y - obstacle.height / 2, obstacle.width, obstacle.height)
  ctx.fillStyle = '#111827'
  ctx.font = '800 12px Inter, sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText(obstacle.kind === 'high' ? 'SLIDE' : 'JUMP', x, obstacle.y + 4)
}

function drawCoin(ctx, coin) {
  const x = laneX(coin.lane)
  ctx.fillStyle = '#facc15'
  ctx.beginPath()
  ctx.arc(x, coin.y, coin.radius, 0, Math.PI * 2)
  ctx.fill()
  ctx.strokeStyle = '#fef3c7'
  ctx.stroke()
}

function drawOverlay(ctx) {
  if (game.status === 'running') return
  ctx.fillStyle = 'rgba(15, 23, 42, 0.72)'
  ctx.fillRect(0, 0, state.width, state.height)
  ctx.fillStyle = '#ffffff'
  ctx.font = '800 34px Inter, sans-serif'
  ctx.textAlign = 'center'
  ctx.fillText(game.status === 'ready' ? 'Subway Runner' : 'Game Over', state.width / 2, state.height * 0.42)
  ctx.font = '600 16px Inter, sans-serif'
  ctx.fillText(instruction.value, state.width / 2, state.height * 0.5)
}

function render() {
  const ctx = state.ctx
  if (!ctx) return

  ctx.clearRect(0, 0, state.width, state.height)
  const sky = ctx.createLinearGradient(0, 0, 0, state.height)
  sky.addColorStop(0, '#0f172a')
  sky.addColorStop(1, '#111827')
  ctx.fillStyle = sky
  ctx.fillRect(0, 0, state.width, state.height)

  drawRoad(ctx)
  state.coins.forEach((coin) => drawCoin(ctx, coin))
  state.obstacles.forEach((obstacle) => drawObstacle(ctx, obstacle))
  drawPlayer(ctx)
  drawOverlay(ctx)
}

function loop(time) {
  const delta = Math.min((time - state.lastTime) / 1000 || 0, 0.035)
  state.lastTime = time
  update(delta)
  render()
  state.animationId = requestAnimationFrame(loop)
}

function fitCanvas() {
  const element = canvas.value
  if (!element) return

  const rect = element.getBoundingClientRect()
  state.pixelRatio = Math.min(window.devicePixelRatio || 1, 2)
  state.width = rect.width
  state.height = rect.height
  state.playerY = state.height - 110
  element.width = Math.floor(rect.width * state.pixelRatio)
  element.height = Math.floor(rect.height * state.pixelRatio)
  state.ctx = element.getContext('2d')
  state.ctx.setTransform(state.pixelRatio, 0, 0, state.pixelRatio, 0, 0)
}

function handleKeydown(event) {
  if (event.key === 'ArrowLeft' || event.key === 'a') {
    event.preventDefault()
    moveLane(-1)
  }
  if (event.key === 'ArrowRight' || event.key === 'd') {
    event.preventDefault()
    moveLane(1)
  }
  if (event.key === ' ') {
    event.preventDefault()
    jump()
  }
  if (event.key === 'ArrowUp' || event.key === 'w') {
    event.preventDefault()
    jump()
  }
  if (event.key === 'ArrowDown' || event.key === 's') {
    event.preventDefault()
    slide()
  }
}

onMounted(() => {
  fitCanvas()
  resetGame()
  window.addEventListener('resize', fitCanvas)
  window.addEventListener('keydown', handleKeydown)
  state.animationId = requestAnimationFrame(loop)
})

onBeforeUnmount(() => {
  cancelAnimationFrame(state.animationId)
  window.removeEventListener('resize', fitCanvas)
  window.removeEventListener('keydown', handleKeydown)
})
</script>

<template>
  <main class="game-shell">
    <section class="hud" aria-label="Spielstand">
      <div>
        <span>Score</span>
        <strong>{{ game.score }}</strong>
      </div>
      <div>
        <span>Coins</span>
        <strong>{{ game.coins }}</strong>
      </div>
      <div>
        <span>Best</span>
        <strong>{{ game.best }}</strong>
      </div>
    </section>

    <button class="stage" type="button" @click="startGame" aria-label="Spiel starten">
      <canvas ref="canvas" aria-label="Subway Runner"></canvas>
    </button>

    <section class="controls" aria-label="Steuerung">
      <button type="button" @click="moveLane(-1)" aria-label="Nach links">&larr;</button>
      <button type="button" @click="jump" aria-label="Springen">&uarr;</button>
      <button type="button" @click="slide" aria-label="Rutschen">&darr;</button>
      <button type="button" @click="moveLane(1)" aria-label="Nach rechts">&rarr;</button>
    </section>

    <p class="hint">{{ instruction }}</p>
  </main>
</template>
