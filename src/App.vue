<script setup>
import { onBeforeUnmount, onMounted, ref } from "vue";

const canvas = ref(null);
const statusText = ref("Canvas shell bereit");

let animationFrameId = 0;
let context = null;
let resizeObserver = null;

function resizeCanvas() {
  const element = canvas.value;

  if (!element) {
    return;
  }

  const devicePixelRatio = window.devicePixelRatio || 1;
  const { width, height } = element.getBoundingClientRect();

  element.width = Math.max(1, Math.round(width * devicePixelRatio));
  element.height = Math.max(1, Math.round(height * devicePixelRatio));

  if (context) {
    context.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0);
  }
}

function render() {
  const element = canvas.value;

  if (!element || !context) {
    return;
  }

  const width = element.clientWidth;
  const height = element.clientHeight;

  const sky = context.createLinearGradient(0, 0, 0, height);
  sky.addColorStop(0, "#08111f");
  sky.addColorStop(0.55, "#0f1d33");
  sky.addColorStop(1, "#13253f");

  context.clearRect(0, 0, width, height);
  context.fillStyle = sky;
  context.fillRect(0, 0, width, height);

  context.fillStyle = "rgba(255, 255, 255, 0.06)";
  for (let x = 0; x < width; x += 80) {
    context.fillRect(x, 0, 2, height);
  }

  context.fillStyle = "rgba(120, 220, 255, 0.12)";
  context.fillRect(width * 0.15, height * 0.2, width * 0.7, height * 0.58);

  context.strokeStyle = "rgba(255, 255, 255, 0.16)";
  context.lineWidth = 2;
  context.strokeRect(width * 0.15, height * 0.2, width * 0.7, height * 0.58);

  context.fillStyle = "rgba(255, 255, 255, 0.08)";
  context.beginPath();
  context.roundRect(
    width * 0.22,
    height * 0.28,
    width * 0.56,
    height * 0.28,
    20,
  );
  context.fill();

  context.fillStyle = "#e8f7ff";
  context.font = "700 28px Inter, system-ui, sans-serif";
  context.textAlign = "center";
  context.fillText("Handwerk Ebadi", width / 2, height * 0.45);

  context.fillStyle = "rgba(232, 247, 255, 0.75)";
  context.font = "500 16px Inter, system-ui, sans-serif";
  context.fillText("Canvas-Spiel-Shell", width / 2, height * 0.5);

  animationFrameId = window.requestAnimationFrame(render);
}

onMounted(() => {
  const element = canvas.value;

  if (!element) {
    return;
  }

  context = element.getContext("2d");

  if (!context) {
    return;
  }

  resizeCanvas();

  resizeObserver = new ResizeObserver(() => {
    resizeCanvas();
  });

  resizeObserver.observe(element);
  window.addEventListener("resize", resizeCanvas);
  render();
});

onBeforeUnmount(() => {
  window.cancelAnimationFrame(animationFrameId);
  window.removeEventListener("resize", resizeCanvas);
  resizeObserver?.disconnect();
});
</script>

<template>
  <main class="game-shell">
    <section class="hud" aria-label="Spielstatus">
      <div>
        <p class="hud-label">Spiel</p>
        <h1>Handwerk Ebadi</h1>
      </div>
      <p class="status">{{ statusText }}</p>
    </section>

    <section class="stage" aria-label="Spielbereich">
      <canvas ref="canvas" class="game-canvas" aria-label="Canvas-Spiel" />
    </section>

    <section class="controls" aria-label="Steuerungshinweise">
      <div>
        <span>Tastatur</span>
        <strong>Pfeiltasten, Leertaste</strong>
      </div>
      <div>
        <span>Mobil</span>
        <strong>Touch-Bedienung folgt im naechsten Schritt</strong>
      </div>
    </section>
  </main>
</template>
