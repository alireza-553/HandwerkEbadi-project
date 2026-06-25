<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'

const canvas = ref(null)
const game = reactive({
  status: 'ready',
  score: 0,
  lives: 3,
  wave: 1,
  charge: 0,
  online: 1,
  multiplayer: import.meta.hot ? 'LAN' : 'Local',
  host: false,
  best: Number(localStorage.getItem('shooter-best') || 0),
  message: '',
})

const input = { up: false, down: false, left: false, right: false, fire: false }

const state = {
  ctx: null,
  width: 0,
  height: 0,
  pixelRatio: 1,
  player: { x: 0, y: 0, radius: 17, cooldown: 0, invulnerable: 0 },
  playerId: localStorage.getItem('shooter-player-id') || '',
  playerName: 'P' + Math.floor(100 + Math.random() * 900),
  remotePlayers: new Map(),
  networkTimer: 0,
  worldTimer: 0,
  bullets: [],
  enemies: [],
  enemyBullets: [],
  powerups: [],
  particles: [],
  stars: [],
  spawnTimer: 0,
  waveTimer: 0,
  shake: 0,
  messageTimer: 0,
  lastTime: 0,
  animationId: 0,
}

const instruction = computed(() => {
  if (game.status === 'ready') return 'Leertaste oder Fire startet'
  if (game.status === 'over') return 'Game Over - Leertaste startet neu'
  return 'WASD/Pfeile bewegen, Leertaste schiesst'
})

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value))
}

function showMessage(text, duration = 1) {
  game.message = text
  state.messageTimer = duration
}

function ensurePlayerId() {
  if (state.playerId) return
  state.playerId = crypto.randomUUID ? crypto.randomUUID() : String(Date.now() + Math.random())
  localStorage.setItem('shooter-player-id', state.playerId)
}

function localPlayerPayload() {
  return {
    id: state.playerId,
    name: state.playerName,
    x: state.width ? state.player.x / state.width : 0.5,
    y: state.height ? state.player.y / state.height : 0.85,
    lives: game.lives,
    score: game.score,
    wave: game.wave,
    status: game.status,
  }
}

function sendPlayerUpdate(force = false) {
  if (!import.meta.hot || !state.playerId || (!force && state.networkTimer > 0)) return
  state.networkTimer = 0.06
  import.meta.hot.send('shooter:update', localPlayerPayload())
}

function normalizeEntity(entity) {
  return {
    ...entity,
    x: state.width ? entity.x / state.width : entity.x,
    y: state.height ? entity.y / state.height : entity.y,
    vx: state.width && entity.vx !== undefined ? entity.vx / state.width : entity.vx,
    vy: state.height && entity.vy !== undefined ? entity.vy / state.height : entity.vy,
  }
}

function denormalizeEntity(entity) {
  return {
    ...entity,
    x: entity.x * state.width,
    y: entity.y * state.height,
    vx: entity.vx !== undefined ? entity.vx * state.width : entity.vx,
    vy: entity.vy !== undefined ? entity.vy * state.height : entity.vy,
  }
}

function hostPayload() {
  return {
    hostId: state.playerId,
    wave: game.wave,
    enemies: state.enemies.map(normalizeEntity),
    enemyBullets: state.enemyBullets.map(normalizeEntity),
    powerups: state.powerups.map(normalizeEntity),
    spawnTimer: state.spawnTimer,
    waveTimer: state.waveTimer,
  }
}

function sendWorldUpdate(force = false) {
  if (!import.meta.hot || !game.host || (!force && state.worldTimer > 0)) return
  state.worldTimer = 0.08
  import.meta.hot.send('shooter:world', hostPayload())
}

function applyWorld(world) {
  if (!world || world.hostId === state.playerId) return
  game.wave = world.wave
  state.enemies = (world.enemies || []).map(denormalizeEntity)
  state.enemyBullets = (world.enemyBullets || []).map(denormalizeEntity)
  state.powerups = (world.powerups || []).map(denormalizeEntity)
  state.spawnTimer = world.spawnTimer || 0
  state.waveTimer = world.waveTimer || 0
}

function setupMultiplayer() {
  ensurePlayerId()
  if (!import.meta.hot) {
    game.multiplayer = 'Local'
    return
  }

  game.multiplayer = 'LAN'
  import.meta.hot.on('shooter:players', (players) => {
    const nextPlayers = new Map()
    players.forEach((player) => {
      if (player.id !== state.playerId) nextPlayers.set(player.id, player)
    })
    state.remotePlayers = nextPlayers
    game.online = nextPlayers.size + 1
  })

  import.meta.hot.on('shooter:shot', (shot) => {
    if (shot.id === state.playerId) return
    state.bullets.push({
      x: shot.x * state.width,
      y: shot.y * state.height,
      vx: shot.vx * state.width,
      vy: shot.vy * state.height,
      radius: 5,
      damage: 1,
      remote: true,
    })
  })

  import.meta.hot.on('shooter:host', (host) => {
    const wasHost = game.host
    game.host = host.id === state.playerId
    if (game.host && !wasHost) {
      showMessage('HOST')
      sendWorldUpdate(true)
    }
  })

  import.meta.hot.on('shooter:world', applyWorld)

  import.meta.hot.send('shooter:join', localPlayerPayload())
  sendPlayerUpdate(true)
}

function resetWorld() {
  state.player.x = state.width / 2
  state.player.y = state.height - 95
  state.player.cooldown = 0
  state.player.invulnerable = 1.2
  state.bullets = []
  state.enemies = []
  state.enemyBullets = []
  state.powerups = []
  state.particles = []
  state.spawnTimer = 0.35
  state.waveTimer = 0
  state.shake = 0
  game.score = 0
  game.lives = 3
  game.wave = 1
  game.charge = 0
  createStars()
}

function startGame() {
  resetWorld()
  game.status = 'running'
  showMessage('Wave 1')
}

function endGame() {
  game.status = 'over'
  game.best = Math.max(game.best, game.score)
  localStorage.setItem('shooter-best', String(game.best))
  sendPlayerUpdate(true)
}

function createStars() {
  state.stars = Array.from({ length: 90 }, () => ({
    x: Math.random() * state.width,
    y: Math.random() * state.height,
    speed: 20 + Math.random() * 80,
    size: 1 + Math.random() * 2.4,
  }))
}

function spawnEnemy() {
  const roll = Math.random()
  const kind = roll > 0.82 ? 'tank' : roll > 0.56 ? 'zigzag' : 'scout'
  const health = kind === 'tank' ? 4 + Math.floor(game.wave / 3) : kind === 'zigzag' ? 2 : 1
  state.enemies.push({
    kind,
    x: 48 + Math.random() * (state.width - 96),
    y: -36,
    radius: kind === 'tank' ? 25 : 18,
    health,
    maxHealth: health,
    speed: (kind === 'tank' ? 58 : 95) + game.wave * 7,
    drift: Math.random() > 0.5 ? 1 : -1,
    phase: Math.random() * Math.PI * 2,
    shotTimer: 0.9 + Math.random() * 1.2,
  })
}

function fireBullet() {
  if (game.status === 'ready' || game.status === 'over') {
    startGame()
    return
  }
  if (game.status !== 'running' || state.player.cooldown > 0) return

  const spread = game.charge >= 100 ? [-13, 0, 13] : [0]
  spread.forEach((offset) => {
    state.bullets.push({
      x: state.player.x + offset,
      y: state.player.y - 24,
      vx: offset * 0.8,
      vy: -570,
      radius: 5,
      damage: game.charge >= 100 ? 2 : 1,
    })
    if (import.meta.hot) {
      import.meta.hot.send('shooter:shot', {
        id: state.playerId,
        x: (state.player.x + offset) / state.width,
        y: (state.player.y - 24) / state.height,
        vx: (offset * 0.8) / state.width,
        vy: -570 / state.height,
      })
    }
  })

  state.player.cooldown = game.charge >= 100 ? 0.12 : 0.18
  if (game.charge >= 100) {
    game.charge = 0
    state.shake = 5
    showMessage('TRIPLE SHOT')
  }
}

function addExplosion(x, y, color = '#f97316', amount = 18) {
  for (let i = 0; i < amount; i += 1) {
    const angle = Math.random() * Math.PI * 2
    const speed = 70 + Math.random() * 220
    state.particles.push({
      x,
      y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      life: 0.45 + Math.random() * 0.35,
      color,
      size: 2 + Math.random() * 5,
    })
  }
}

function maybeDropPowerup(x, y) {
  if (Math.random() > 0.18) return
  state.powerups.push({
    x,
    y,
    radius: 13,
    vy: 115,
    kind: Math.random() > 0.55 ? 'life' : 'charge',
  })
}

function damagePlayer() {
  if (state.player.invulnerable > 0) return
  game.lives -= 1
  state.player.invulnerable = 1.25
  state.shake = 9
  addExplosion(state.player.x, state.player.y, '#38bdf8', 24)
  if (game.lives <= 0) endGame()
}

function update(delta) {
  if (game.status !== 'running') return

  state.player.cooldown = Math.max(0, state.player.cooldown - delta)
  state.player.invulnerable = Math.max(0, state.player.invulnerable - delta)
  state.networkTimer = Math.max(0, state.networkTimer - delta)
  state.worldTimer = Math.max(0, state.worldTimer - delta)
  state.shake = Math.max(0, state.shake - 24 * delta)
  state.messageTimer = Math.max(0, state.messageTimer - delta)
  if (state.messageTimer === 0) game.message = ''
  game.charge = Math.min(100, game.charge + delta * 7)

  const moveX = Number(input.right) - Number(input.left)
  const moveY = Number(input.down) - Number(input.up)
  const length = Math.hypot(moveX, moveY) || 1
  const speed = 285
  state.player.x = clamp(state.player.x + (moveX / length) * speed * delta, 25, state.width - 25)
  state.player.y = clamp(state.player.y + (moveY / length) * speed * delta, state.height * 0.45, state.height - 42)
  if (input.fire) fireBullet()
  sendPlayerUpdate()

  state.stars.forEach((star) => {
    star.y += star.speed * delta
    if (star.y > state.height) {
      star.y = -4
      star.x = Math.random() * state.width
    }
  })

  state.bullets.forEach((bullet) => {
    bullet.x += bullet.vx * delta
    bullet.y += bullet.vy * delta
  })

  if (!game.host && import.meta.hot) {
    checkPlayerDamage()
    state.bullets = state.bullets.filter((bullet) => bullet.y > -20)
    return
  }

  state.spawnTimer -= delta
  state.waveTimer += delta
  if (state.spawnTimer <= 0) {
    spawnEnemy()
    state.spawnTimer = Math.max(0.28, 0.95 - game.wave * 0.045) + Math.random() * 0.3
  }
  if (state.waveTimer > 18) {
    game.wave += 1
    state.waveTimer = 0
    state.spawnTimer = 0.1
    showMessage('Wave ' + game.wave)
  }

  state.enemies.forEach((enemy) => {
    enemy.phase += delta * 4
    enemy.y += enemy.speed * delta
    if (enemy.kind === 'zigzag') enemy.x += Math.sin(enemy.phase) * enemy.drift * 95 * delta
    enemy.x = clamp(enemy.x, 24, state.width - 24)
    enemy.shotTimer -= delta
    if (enemy.shotTimer <= 0 && enemy.y > 20 && enemy.y < state.height * 0.68) {
      const angle = Math.atan2(state.player.y - enemy.y, state.player.x - enemy.x)
      state.enemyBullets.push({ x: enemy.x, y: enemy.y + 16, vx: Math.cos(angle) * 185, vy: Math.sin(angle) * 185, radius: 6 })
      enemy.shotTimer = enemy.kind === 'tank' ? 1.2 : 1.6
    }
  })
  state.enemyBullets.forEach((bullet) => {
    bullet.x += bullet.vx * delta
    bullet.y += bullet.vy * delta
  })
  state.powerups.forEach((powerup) => {
    powerup.y += powerup.vy * delta
  })

  checkCollisions()
  state.bullets = state.bullets.filter((bullet) => bullet.y > -20)
  state.enemyBullets = state.enemyBullets.filter((bullet) => bullet.y < state.height + 30)
  state.enemies = state.enemies.filter((enemy) => enemy.y < state.height + 55 && enemy.health > 0)
  state.powerups = state.powerups.filter((powerup) => powerup.y < state.height + 30)
  state.particles.forEach((particle) => {
    particle.life -= delta
    particle.x += particle.vx * delta
    particle.y += particle.vy * delta
    particle.vx *= 1 - delta * 1.8
    particle.vy *= 1 - delta * 1.8
  })
  state.particles = state.particles.filter((particle) => particle.life > 0)
  sendWorldUpdate()
}

function checkCollisions() {
  for (const bullet of state.bullets) {
    for (const enemy of state.enemies) {
      if (Math.hypot(bullet.x - enemy.x, bullet.y - enemy.y) < bullet.radius + enemy.radius) {
        bullet.y = -999
        enemy.health -= bullet.damage
        addExplosion(bullet.x, bullet.y, '#facc15', 5)
        if (enemy.health <= 0) {
          game.score += enemy.kind === 'tank' ? 180 : enemy.kind === 'zigzag' ? 120 : 75
          game.charge = Math.min(100, game.charge + 12)
          state.shake = Math.max(state.shake, enemy.kind === 'tank' ? 8 : 4)
          addExplosion(enemy.x, enemy.y, enemy.kind === 'tank' ? '#ef4444' : '#f97316', 24)
          maybeDropPowerup(enemy.x, enemy.y)
        }
      }
    }
  }

  checkPlayerDamage()
}

function checkPlayerDamage() {
  state.enemies.forEach((enemy) => {
    if (Math.hypot(enemy.x - state.player.x, enemy.y - state.player.y) < enemy.radius + state.player.radius) {
      if (game.host || !import.meta.hot) enemy.health = 0
      damagePlayer()
    }
  })
  state.enemyBullets.forEach((bullet) => {
    if (Math.hypot(bullet.x - state.player.x, bullet.y - state.player.y) < bullet.radius + state.player.radius) {
      if (game.host || !import.meta.hot) bullet.y = state.height + 999
      damagePlayer()
    }
  })
  state.powerups.forEach((powerup) => {
    if (Math.hypot(powerup.x - state.player.x, powerup.y - state.player.y) < powerup.radius + state.player.radius) {
      if (game.host || !import.meta.hot) powerup.y = state.height + 999
      if (powerup.kind === 'life') game.lives = Math.min(5, game.lives + 1)
      else game.charge = 100
      showMessage(powerup.kind === 'life' ? '+1 LIFE' : 'CHARGE READY')
      addExplosion(powerup.x, powerup.y, '#22c55e', 18)
    }
  })
}

function drawBackground(ctx) {
  const gradient = ctx.createLinearGradient(0, 0, 0, state.height)
  gradient.addColorStop(0, '#101827')
  gradient.addColorStop(0.58, '#1f2a44')
  gradient.addColorStop(1, '#101113')
  ctx.fillStyle = gradient
  ctx.fillRect(0, 0, state.width, state.height)
  state.stars.forEach((star) => {
    ctx.fillStyle = 'rgba(226, 232, 240, 0.76)'
    ctx.fillRect(star.x, star.y, star.size, star.size * 2.4)
  })
}

function drawPlayer(ctx) {
  const blink = state.player.invulnerable > 0 && Math.floor(performance.now() / 90) % 2 === 0
  if (blink) return
  const { x, y } = state.player
  ctx.fillStyle = '#38bdf8'
  ctx.beginPath()
  ctx.moveTo(x, y - 28)
  ctx.lineTo(x - 22, y + 22)
  ctx.lineTo(x, y + 12)
  ctx.lineTo(x + 22, y + 22)
  ctx.closePath()
  ctx.fill()
  ctx.fillStyle = '#f8fafc'
  ctx.beginPath()
  ctx.moveTo(x, y - 16)
  ctx.lineTo(x - 8, y + 6)
  ctx.lineTo(x + 8, y + 6)
  ctx.closePath()
  ctx.fill()
}

function drawRemotePlayers(ctx) {
  for (const player of state.remotePlayers.values()) {
    if (player.status === 'over') continue
    const x = player.x * state.width
    const y = player.y * state.height
    ctx.fillStyle = '#22c55e'
    ctx.beginPath()
    ctx.moveTo(x, y - 24)
    ctx.lineTo(x - 19, y + 19)
    ctx.lineTo(x, y + 9)
    ctx.lineTo(x + 19, y + 19)
    ctx.closePath()
    ctx.fill()
    ctx.fillStyle = '#dcfce7'
    ctx.font = '700 12px Inter, sans-serif'
    ctx.textAlign = 'center'
    ctx.fillText(player.name || 'Ally', x, y - 34)
  }
}

function drawEnemy(ctx, enemy) {
  ctx.save()
  ctx.translate(enemy.x, enemy.y)
  ctx.fillStyle = enemy.kind === 'tank' ? '#dc2626' : enemy.kind === 'zigzag' ? '#a855f7' : '#f97316'
  ctx.beginPath()
  ctx.moveTo(0, enemy.radius + 8)
  ctx.lineTo(-enemy.radius, -enemy.radius * 0.55)
  ctx.lineTo(0, -enemy.radius)
  ctx.lineTo(enemy.radius, -enemy.radius * 0.55)
  ctx.closePath()
  ctx.fill()
  ctx.fillStyle = '#111827'
  ctx.fillRect(-enemy.radius * 0.55, -4, enemy.radius * 1.1, 8)
  ctx.fillStyle = '#facc15'
  ctx.fillRect(-enemy.radius * 0.7, enemy.radius + 9, enemy.radius * 1.4 * (enemy.health / enemy.maxHealth), 4)
  ctx.restore()
}

function drawPowerup(ctx, powerup) {
  ctx.fillStyle = powerup.kind === 'life' ? '#22c55e' : '#facc15'
  ctx.beginPath()
  ctx.arc(powerup.x, powerup.y, powerup.radius, 0, Math.PI * 2)
  ctx.fill()
}

function drawProjectiles(ctx) {
  state.bullets.forEach((bullet) => {
    ctx.fillStyle = '#67e8f9'
    ctx.fillRect(bullet.x - 3, bullet.y - 14, 6, 18)
  })
  state.enemyBullets.forEach((bullet) => {
    ctx.fillStyle = '#fb7185'
    ctx.beginPath()
    ctx.arc(bullet.x, bullet.y, bullet.radius, 0, Math.PI * 2)
    ctx.fill()
  })
}

function drawParticles(ctx) {
  state.particles.forEach((particle) => {
    ctx.globalAlpha = Math.max(0, particle.life)
    ctx.fillStyle = particle.color
    ctx.beginPath()
    ctx.arc(particle.x, particle.y, particle.size, 0, Math.PI * 2)
    ctx.fill()
  })
  ctx.globalAlpha = 1
}

function drawFeedback(ctx) {
  ctx.fillStyle = 'rgba(15, 23, 42, 0.62)'
  ctx.fillRect(18, state.height - 22, state.width - 36, 8)
  ctx.fillStyle = '#facc15'
  ctx.fillRect(18, state.height - 22, (state.width - 36) * (game.charge / 100), 8)
  if (game.message) {
    ctx.fillStyle = '#ffffff'
    ctx.textAlign = 'center'
    ctx.font = '800 28px Inter, sans-serif'
    ctx.fillText(game.message, state.width / 2, state.height * 0.2)
  }
}

function drawOverlay(ctx) {
  if (game.status === 'running') return
  ctx.fillStyle = 'rgba(8, 13, 24, 0.74)'
  ctx.fillRect(0, 0, state.width, state.height)
  ctx.fillStyle = '#ffffff'
  ctx.textAlign = 'center'
  ctx.font = '800 38px Inter, sans-serif'
  ctx.fillText(game.status === 'ready' ? 'Neon Shooter' : 'Game Over', state.width / 2, state.height * 0.42)
  ctx.font = '600 16px Inter, sans-serif'
  ctx.fillText(instruction.value, state.width / 2, state.height * 0.5)
}

function render() {
  const ctx = state.ctx
  if (!ctx) return
  const shakeX = state.shake ? (Math.random() - 0.5) * state.shake : 0
  const shakeY = state.shake ? (Math.random() - 0.5) * state.shake : 0
  ctx.clearRect(0, 0, state.width, state.height)
  ctx.save()
  ctx.translate(shakeX, shakeY)
  drawBackground(ctx)
  state.powerups.forEach((powerup) => drawPowerup(ctx, powerup))
  state.enemies.forEach((enemy) => drawEnemy(ctx, enemy))
  drawProjectiles(ctx)
  drawParticles(ctx)
  drawRemotePlayers(ctx)
  drawPlayer(ctx)
  ctx.restore()
  drawFeedback(ctx)
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
  const el = canvas.value
  if (!el) return
  const rect = el.getBoundingClientRect()
  state.pixelRatio = Math.min(window.devicePixelRatio || 1, 2)
  state.width = rect.width
  state.height = rect.height
  el.width = Math.floor(rect.width * state.pixelRatio)
  el.height = Math.floor(rect.height * state.pixelRatio)
  state.ctx = el.getContext('2d')
  state.ctx.setTransform(state.pixelRatio, 0, 0, state.pixelRatio, 0, 0)
  if (game.status !== 'running') {
    state.player.x = state.width / 2
    state.player.y = state.height - 95
  }
  createStars()
}

function setInput(key, pressed) {
  const map = {
    ArrowLeft: 'left', a: 'left', A: 'left',
    ArrowRight: 'right', d: 'right', D: 'right',
    ArrowUp: 'up', w: 'up', W: 'up',
    ArrowDown: 'down', s: 'down', S: 'down',
    ' ': 'fire',
  }
  const action = map[key]
  if (!action) return false
  input[action] = pressed
  return true
}

function handleKeydown(event) {
  if (!setInput(event.key, true)) return
  event.preventDefault()
  if (event.key === ' ') fireBullet()
}

function handleKeyup(event) {
  if (!setInput(event.key, false)) return
  event.preventDefault()
}

function press(action, pressed) {
  input[action] = pressed
  if (action === 'fire' && pressed) fireBullet()
}

onMounted(() => {
  fitCanvas()
  resetWorld()
  setupMultiplayer()
  window.addEventListener('resize', fitCanvas)
  window.addEventListener('keydown', handleKeydown)
  window.addEventListener('keyup', handleKeyup)
  state.animationId = requestAnimationFrame(loop)
})

onBeforeUnmount(() => {
  if (import.meta.hot) import.meta.hot.send('shooter:leave', { id: state.playerId })
  cancelAnimationFrame(state.animationId)
  window.removeEventListener('resize', fitCanvas)
  window.removeEventListener('keydown', handleKeydown)
  window.removeEventListener('keyup', handleKeyup)
})
</script>

<template>
  <main class="game-shell">
    <section class="hud" aria-label="Spielstand">
      <div><span>Score</span><strong>{{ game.score }}</strong></div>
      <div><span>Lives</span><strong>{{ game.lives }}</strong></div>
      <div><span>Wave</span><strong>{{ game.wave }}</strong></div>
      <div><span>Online</span><strong>{{ game.online }}</strong></div>
      <div><span>Mode</span><strong>{{ game.host ? 'Host' : game.multiplayer }}</strong></div>
      <div><span>Best</span><strong>{{ game.best }}</strong></div>
    </section>

    <button class="stage" type="button" @click="fireBullet" aria-label="Spiel starten oder schiessen">
      <canvas ref="canvas" aria-label="Neon Shooter"></canvas>
    </button>

    <section class="controls shooter-controls" aria-label="Steuerung">
      <button type="button" @pointerdown="press('left', true)" @pointerup="press('left', false)" @pointerleave="press('left', false)" aria-label="Links">&larr;</button>
      <button type="button" @pointerdown="press('up', true)" @pointerup="press('up', false)" @pointerleave="press('up', false)" aria-label="Hoch">&uarr;</button>
      <button type="button" @pointerdown="press('down', true)" @pointerup="press('down', false)" @pointerleave="press('down', false)" aria-label="Runter">&darr;</button>
      <button type="button" @pointerdown="press('right', true)" @pointerup="press('right', false)" @pointerleave="press('right', false)" aria-label="Rechts">&rarr;</button>
      <button class="fire" type="button" @pointerdown="press('fire', true)" @pointerup="press('fire', false)" @pointerleave="press('fire', false)" aria-label="Schiessen">FIRE</button>
    </section>

    <p class="hint">{{ instruction }}</p>
  </main>
</template>
