const canvas = document.querySelector("#game");
const ctx = canvas.getContext("2d");

const ui = {
  hpMeter: document.querySelector("#hpMeter"),
  xpMeter: document.querySelector("#xpMeter"),
  waveText: document.querySelector("#waveText"),
  oreText: document.querySelector("#oreText"),
  timeText: document.querySelector("#timeText"),
  weaponStrip: document.querySelector("#weaponStrip"),
  startOverlay: document.querySelector("#startOverlay"),
  choiceOverlay: document.querySelector("#choiceOverlay"),
  choiceCards: document.querySelector("#choiceCards"),
  choiceEyebrow: document.querySelector("#choiceEyebrow"),
  choiceTitle: document.querySelector("#choiceTitle"),
  gameOverOverlay: document.querySelector("#gameOverOverlay"),
  gameOverTitle: document.querySelector("#gameOverTitle"),
  gameOverStats: document.querySelector("#gameOverStats"),
  startButton: document.querySelector("#startButton"),
  restartButton: document.querySelector("#restartButton"),
};

const world = {
  width: 1280,
  height: 720,
  margin: 34,
};

const keys = new Set();
const mouse = { x: world.width / 2, y: world.height / 2, down: false };

const statRewards = [
  { name: "Iron Lungs", desc: "+18 max HP and a small heal.", tag: "survival", apply: (s) => { s.player.maxHp += 18; s.player.hp = Math.min(s.player.maxHp, s.player.hp + 24); } },
  { name: "Spring Boots", desc: "+12% move speed.", tag: "mobility", apply: (s) => { s.player.speed *= 1.12; } },
  { name: "Magnet Vein", desc: "+34% pickup range.", tag: "economy", apply: (s) => { s.player.pickupRange *= 1.34; } },
  { name: "Serrated Rounds", desc: "+16% weapon damage.", tag: "offense", apply: (s) => { s.damageMultiplier *= 1.16; } },
  { name: "Quick Hands", desc: "+14% faster attacks.", tag: "offense", apply: (s) => { s.cooldownMultiplier *= 0.86; } },
  { name: "Ore Sense", desc: "+40% ore from pickups.", tag: "economy", apply: (s) => { s.oreMultiplier *= 1.4; } },
  { name: "Reinforced Jacket", desc: "+2 armor against contact hits.", tag: "survival", apply: (s) => { s.player.armor += 2; } },
  { name: "Surveyor Focus", desc: "+20% XP from crystals.", tag: "growth", apply: (s) => { s.xpMultiplier *= 1.2; } },
];

const shopItems = [
  {
    name: "Twin Flintlock",
    desc: "Short cooldown pistol that fires at the nearest target.",
    cost: 18,
    buy: (s) => addWeapon(s, "flintlock"),
  },
  {
    name: "Shard Drill",
    desc: "Slow piercing shot. A future hook for mining tools.",
    cost: 26,
    buy: (s) => addWeapon(s, "drill"),
  },
  {
    name: "Spark Coil",
    desc: "Close-range arc that tags several nearby enemies.",
    cost: 32,
    buy: (s) => addWeapon(s, "coil"),
  },
  {
    name: "Field Rations",
    desc: "Restore 35 HP.",
    cost: 14,
    buy: (s) => { s.player.hp = Math.min(s.player.maxHp, s.player.hp + 35); },
  },
  {
    name: "Tempered Barrel",
    desc: "+12% weapon damage.",
    cost: 22,
    buy: (s) => { s.damageMultiplier *= 1.12; },
  },
  {
    name: "Pocket Magnet",
    desc: "+24% pickup range.",
    cost: 16,
    buy: (s) => { s.player.pickupRange *= 1.24; },
  },
];

const weaponCatalog = {
  spitter: {
    name: "Ore Spitter",
    cooldown: 0.72,
    damage: 14,
    range: 470,
    speed: 640,
    color: "#e6b85c",
    fire: fireBullet,
  },
  flintlock: {
    name: "Twin Flintlock",
    cooldown: 0.46,
    damage: 9,
    range: 390,
    speed: 760,
    color: "#f0643b",
    fire: fireBullet,
  },
  drill: {
    name: "Shard Drill",
    cooldown: 1.28,
    damage: 34,
    range: 560,
    speed: 500,
    color: "#93c96d",
    pierce: 3,
    fire: fireBullet,
  },
  coil: {
    name: "Spark Coil",
    cooldown: 1.08,
    damage: 16,
    range: 170,
    color: "#6cc3c0",
    fire: fireArc,
  },
};

let state = makeState();
let last = performance.now();

function makeState() {
  const next = {
    mode: "start",
    paused: false,
    elapsed: 0,
    wave: 1,
    waveTimer: 35,
    spawnTimer: 0,
    ore: 0,
    level: 1,
    xp: 0,
    xpToNext: 18,
    damageMultiplier: 1,
    cooldownMultiplier: 1,
    oreMultiplier: 1,
    xpMultiplier: 1,
    screenShake: 0,
    dashCooldown: 0,
    player: {
      x: world.width / 2,
      y: world.height / 2,
      r: 18,
      hp: 100,
      maxHp: 100,
      speed: 255,
      armor: 0,
      pickupRange: 95,
      hurtCooldown: 0,
      dashTime: 0,
    },
    weapons: [],
    enemies: [],
    bullets: [],
    pickups: [],
    sparks: [],
    floatingText: [],
    pendingShop: false,
  };

  addWeapon(next, "spitter");
  return next;
}

function addWeapon(targetState, id) {
  const template = weaponCatalog[id];
  const existing = targetState.weapons.find((weapon) => weapon.id === id);

  if (existing) {
    existing.level += 1;
    existing.damage *= 1.18;
    existing.cooldown *= 0.94;
    return;
  }

  targetState.weapons.push({
    id,
    name: template.name,
    level: 1,
    cooldown: template.cooldown,
    timer: Math.random() * 0.25,
    damage: template.damage,
    range: template.range,
    speed: template.speed,
    pierce: template.pierce || 0,
    color: template.color,
    fire: template.fire,
  });
}

function startRun() {
  state = makeState();
  state.mode = "play";
  closeAllOverlays();
  renderWeapons();
}

function closeAllOverlays() {
  ui.startOverlay.classList.remove("is-open");
  ui.choiceOverlay.classList.remove("is-open");
  ui.gameOverOverlay.classList.remove("is-open");
}

function update(dt) {
  if (state.mode !== "play" || state.paused) return;

  state.elapsed += dt;
  state.waveTimer -= dt;
  state.spawnTimer -= dt;
  state.screenShake = Math.max(0, state.screenShake - dt * 10);
  state.dashCooldown = Math.max(0, state.dashCooldown - dt);
  state.player.hurtCooldown = Math.max(0, state.player.hurtCooldown - dt);
  state.player.dashTime = Math.max(0, state.player.dashTime - dt);

  movePlayer(dt);
  spawnEnemies(dt);
  updateWeapons(dt);
  updateBullets(dt);
  updateEnemies(dt);
  updatePickups(dt);
  updateSparks(dt);
  updateFloatingText(dt);

  if (state.waveTimer <= 0 && state.enemies.length === 0) {
    openShop();
  } else if (state.waveTimer <= 0) {
    state.spawnTimer = Math.max(state.spawnTimer, 0.8);
  }

  if (state.player.hp <= 0) {
    gameOver();
  }
}

function movePlayer(dt) {
  const p = state.player;
  let dx = 0;
  let dy = 0;

  if (keys.has("KeyW") || keys.has("ArrowUp")) dy -= 1;
  if (keys.has("KeyS") || keys.has("ArrowDown")) dy += 1;
  if (keys.has("KeyA") || keys.has("ArrowLeft")) dx -= 1;
  if (keys.has("KeyD") || keys.has("ArrowRight")) dx += 1;

  const len = Math.hypot(dx, dy) || 1;
  const dashBoost = p.dashTime > 0 ? 2.6 : 1;
  p.x += (dx / len) * p.speed * dashBoost * dt;
  p.y += (dy / len) * p.speed * dashBoost * dt;
  p.x = clamp(p.x, world.margin, world.width - world.margin);
  p.y = clamp(p.y, world.margin, world.height - world.margin);
}

function spawnEnemies(dt) {
  if (state.waveTimer <= 0 || state.spawnTimer > 0) return;

  const wavePressure = Math.min(0.28, state.wave * 0.018);
  state.spawnTimer = Math.max(0.18, 0.9 - wavePressure - state.elapsed * 0.0018);
  const packSize = 1 + Math.floor(state.wave / 3) + (Math.random() < state.wave * 0.06 ? 1 : 0);

  for (let i = 0; i < packSize; i += 1) {
    state.enemies.push(makeEnemy());
  }
}

function makeEnemy() {
  const side = Math.floor(Math.random() * 4);
  let x = 0;
  let y = 0;

  if (side === 0) { x = -30; y = Math.random() * world.height; }
  if (side === 1) { x = world.width + 30; y = Math.random() * world.height; }
  if (side === 2) { x = Math.random() * world.width; y = -30; }
  if (side === 3) { x = Math.random() * world.width; y = world.height + 30; }

  const bruiser = Math.random() < Math.min(0.28, state.wave * 0.035);
  const skitter = !bruiser && Math.random() < 0.32;
  const baseHp = 18 + state.wave * 5.2 + state.elapsed * 0.04;

  return {
    x,
    y,
    vx: 0,
    vy: 0,
    r: bruiser ? 23 : skitter ? 12 : 16,
    hp: bruiser ? baseHp * 2.4 : skitter ? baseHp * 0.7 : baseHp,
    maxHp: bruiser ? baseHp * 2.4 : skitter ? baseHp * 0.7 : baseHp,
    speed: bruiser ? 72 + state.wave * 3 : skitter ? 152 + state.wave * 5 : 105 + state.wave * 4,
    damage: bruiser ? 20 : skitter ? 8 : 12,
    color: bruiser ? "#8d5746" : skitter ? "#93c96d" : "#b95b4b",
    ore: bruiser ? 4 : 1,
    xp: bruiser ? 7 : skitter ? 2 : 4,
  };
}

function updateWeapons(dt) {
  for (const weapon of state.weapons) {
    weapon.timer -= dt;
    const cooldown = weapon.cooldown * state.cooldownMultiplier;
    if (weapon.timer <= 0) {
      const target = nearestEnemy(weapon.range);
      if (target) {
        weapon.fire(weapon, target);
        weapon.timer = cooldown;
      }
    }
  }
}

function nearestEnemy(range) {
  let best = null;
  let bestDistance = range * range;

  for (const enemy of state.enemies) {
    const distance = distanceSq(enemy.x, enemy.y, state.player.x, state.player.y);
    if (distance < bestDistance) {
      best = enemy;
      bestDistance = distance;
    }
  }

  return best;
}

function fireBullet(weapon, target) {
  const p = state.player;
  const angle = Math.atan2(target.y - p.y, target.x - p.x);

  state.bullets.push({
    x: p.x + Math.cos(angle) * 18,
    y: p.y + Math.sin(angle) * 18,
    vx: Math.cos(angle) * weapon.speed,
    vy: Math.sin(angle) * weapon.speed,
    r: weapon.id === "drill" ? 7 : 5,
    life: weapon.range / weapon.speed,
    damage: weapon.damage * state.damageMultiplier,
    color: weapon.color,
    pierce: weapon.pierce,
    hit: new Set(),
  });

  addSpark(p.x, p.y, weapon.color, 6);
}

function fireArc(weapon) {
  const p = state.player;
  const targets = state.enemies
    .filter((enemy) => distanceSq(enemy.x, enemy.y, p.x, p.y) <= weapon.range * weapon.range)
    .sort((a, b) => distanceSq(a.x, a.y, p.x, p.y) - distanceSq(b.x, b.y, p.x, p.y))
    .slice(0, 4);

  for (const target of targets) {
    hurtEnemy(target, weapon.damage * state.damageMultiplier, target.x, target.y);
    state.sparks.push({ x1: p.x, y1: p.y, x2: target.x, y2: target.y, life: 0.16, maxLife: 0.16, color: weapon.color, line: true });
  }
}

function updateBullets(dt) {
  for (let i = state.bullets.length - 1; i >= 0; i -= 1) {
    const bullet = state.bullets[i];
    bullet.x += bullet.vx * dt;
    bullet.y += bullet.vy * dt;
    bullet.life -= dt;

    for (const enemy of state.enemies) {
      if (bullet.hit.has(enemy)) continue;
      if (distanceSq(bullet.x, bullet.y, enemy.x, enemy.y) <= (bullet.r + enemy.r) ** 2) {
        bullet.hit.add(enemy);
        hurtEnemy(enemy, bullet.damage, bullet.x, bullet.y);
        bullet.pierce -= 1;
        if (bullet.pierce < 0) {
          bullet.life = 0;
          break;
        }
      }
    }

    if (bullet.life <= 0) {
      state.bullets.splice(i, 1);
    }
  }
}

function updateEnemies(dt) {
  const p = state.player;

  for (let i = state.enemies.length - 1; i >= 0; i -= 1) {
    const enemy = state.enemies[i];
    const angle = Math.atan2(p.y - enemy.y, p.x - enemy.x);
    enemy.vx = Math.cos(angle) * enemy.speed;
    enemy.vy = Math.sin(angle) * enemy.speed;
    enemy.x += enemy.vx * dt;
    enemy.y += enemy.vy * dt;

    const touchDistance = p.r + enemy.r;
    if (distanceSq(enemy.x, enemy.y, p.x, p.y) <= touchDistance * touchDistance) {
      if (p.hurtCooldown <= 0) {
        const damage = Math.max(1, enemy.damage - p.armor);
        p.hp -= damage;
        p.hurtCooldown = 0.55;
        state.screenShake = 1;
        addFloatingText(`-${Math.round(damage)}`, p.x, p.y - 28, "#f0643b");
      }

      const push = Math.atan2(enemy.y - p.y, enemy.x - p.x);
      enemy.x += Math.cos(push) * 70 * dt;
      enemy.y += Math.sin(push) * 70 * dt;
    }

    if (enemy.hp <= 0) {
      dropPickups(enemy);
      addSpark(enemy.x, enemy.y, enemy.color, 14);
      state.enemies.splice(i, 1);
    }
  }
}

function hurtEnemy(enemy, damage, x, y) {
  enemy.hp -= damage;
  addFloatingText(Math.round(damage).toString(), x, y - 8, "#f5efe3");
  addSpark(x, y, "#f5efe3", 4);
}

function dropPickups(enemy) {
  const oreValue = Math.ceil(enemy.ore * state.oreMultiplier);
  state.pickups.push({ x: enemy.x, y: enemy.y, r: 8, type: "xp", value: enemy.xp, color: "#6cc3c0" });

  for (let i = 0; i < oreValue; i += 1) {
    state.pickups.push({
      x: enemy.x + randomBetween(-12, 12),
      y: enemy.y + randomBetween(-12, 12),
      r: 6,
      type: "ore",
      value: 1,
      color: "#e6b85c",
    });
  }
}

function updatePickups(dt) {
  const p = state.player;

  for (let i = state.pickups.length - 1; i >= 0; i -= 1) {
    const item = state.pickups[i];
    const dx = p.x - item.x;
    const dy = p.y - item.y;
    const dist = Math.hypot(dx, dy);

    if (dist < p.pickupRange) {
      const pull = 1 - dist / p.pickupRange;
      item.x += (dx / Math.max(1, dist)) * (180 + pull * 520) * dt;
      item.y += (dy / Math.max(1, dist)) * (180 + pull * 520) * dt;
    }

    if (dist < p.r + item.r) {
      if (item.type === "ore") {
        state.ore += item.value;
      } else {
        addXp(item.value * state.xpMultiplier);
      }
      state.pickups.splice(i, 1);
    }
  }
}

function addXp(amount) {
  state.xp += amount;

  if (state.xp >= state.xpToNext) {
    state.xp -= state.xpToNext;
    state.level += 1;
    state.xpToNext = Math.floor(state.xpToNext * 1.32 + 9);
    openLevelUp();
  }
}

function updateSparks(dt) {
  for (let i = state.sparks.length - 1; i >= 0; i -= 1) {
    state.sparks[i].life -= dt;
    if (state.sparks[i].life <= 0) state.sparks.splice(i, 1);
  }
}

function updateFloatingText(dt) {
  for (let i = state.floatingText.length - 1; i >= 0; i -= 1) {
    const text = state.floatingText[i];
    text.y -= 38 * dt;
    text.life -= dt;
    if (text.life <= 0) state.floatingText.splice(i, 1);
  }
}

function addSpark(x, y, color, count) {
  for (let i = 0; i < count; i += 1) {
    const angle = Math.random() * Math.PI * 2;
    const speed = randomBetween(40, 190);
    state.sparks.push({
      x,
      y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      life: randomBetween(0.18, 0.36),
      maxLife: 0.36,
      color,
    });
  }
}

function addFloatingText(text, x, y, color) {
  state.floatingText.push({ text, x, y, color, life: 0.55 });
}

function openLevelUp() {
  state.mode = "choice";
  ui.choiceEyebrow.textContent = `level ${state.level}`;
  ui.choiceTitle.textContent = "Choose a reward";
  renderChoices(sample(statRewards, 3), (reward) => {
    reward.apply(state);
    closeAllOverlays();
    state.mode = "play";
  });
}

function openShop() {
  state.mode = "choice";
  state.wave += 1;
  state.waveTimer = 35 + Math.min(20, state.wave * 2);
  state.player.hp = Math.min(state.player.maxHp, state.player.hp + 18);
  const options = sample(shopItems, 3);

  ui.choiceEyebrow.textContent = "between waves";
  ui.choiceTitle.textContent = "Spend ore or skip";
  renderChoices([
    ...options,
    { name: "Keep Moving", desc: "Save your ore and start the next wave.", tag: "free", cost: 0, buy: () => {} },
  ], (item) => {
    const cost = item.cost || 0;
    if (state.ore < cost) {
      addFloatingText("need ore", state.player.x, state.player.y - 34, "#f0643b");
      return;
    }
    state.ore -= cost;
    item.buy(state);
    renderWeapons();
    closeAllOverlays();
    state.mode = "play";
  });
}

function renderChoices(options, onPick) {
  ui.choiceCards.innerHTML = "";
  ui.choiceOverlay.classList.add("is-open");

  for (const option of options) {
    const card = document.createElement("button");
    card.className = "choice-card";
    const costText = typeof option.cost === "number" ? `${option.cost} ore` : option.tag;
    const disabled = typeof option.cost === "number" && option.cost > state.ore;

    card.disabled = disabled;
    card.innerHTML = `<strong>${option.name}</strong><p>${option.desc}</p><small>${disabled ? `${costText} - short` : costText}</small>`;
    card.addEventListener("click", () => onPick(option));
    ui.choiceCards.append(card);
  }
}

function renderWeapons() {
  ui.weaponStrip.innerHTML = "";
  for (const weapon of state.weapons) {
    const card = document.createElement("div");
    card.className = "weapon-card";
    card.innerHTML = `<b>${weapon.name}</b><span>Lv ${weapon.level} / ${Math.round(weapon.damage * state.damageMultiplier)} dmg</span>`;
    ui.weaponStrip.append(card);
  }
}

function gameOver() {
  state.mode = "gameover";
  ui.gameOverTitle.textContent = "You were overrun";
  ui.gameOverStats.textContent = `Wave ${state.wave}, level ${state.level}, ${state.ore} ore recovered, ${formatTime(state.elapsed)} survived.`;
  ui.gameOverOverlay.classList.add("is-open");
}

function draw() {
  const shakeX = state.screenShake ? randomBetween(-4, 4) * state.screenShake : 0;
  const shakeY = state.screenShake ? randomBetween(-4, 4) * state.screenShake : 0;

  ctx.save();
  ctx.clearRect(0, 0, world.width, world.height);
  ctx.translate(shakeX, shakeY);
  drawGround();
  drawPickups();
  drawBullets();
  drawEnemies();
  drawPlayer();
  drawSparks();
  drawFloatingText();
  drawWaveState();
  ctx.restore();
  updateHud();
}

function drawGround() {
  ctx.fillStyle = "#171a15";
  ctx.fillRect(0, 0, world.width, world.height);

  ctx.strokeStyle = "rgba(245, 239, 227, 0.045)";
  ctx.lineWidth = 1;
  for (let x = 0; x < world.width; x += 44) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x - 120, world.height);
    ctx.stroke();
  }

  ctx.fillStyle = "rgba(230, 184, 92, 0.08)";
  for (let i = 0; i < 80; i += 1) {
    const x = (i * 97) % world.width;
    const y = (i * 181) % world.height;
    ctx.fillRect(x, y, 3 + (i % 3), 3 + (i % 4));
  }
}

function drawPlayer() {
  const p = state.player;
  const aim = Math.atan2(mouse.y - p.y, mouse.x - p.x);

  ctx.save();
  ctx.translate(p.x, p.y);
  ctx.rotate(aim);
  ctx.fillStyle = p.hurtCooldown > 0 ? "#f5efe3" : "#d4a44e";
  roundedRect(-18, -14, 34, 28, 8);
  ctx.fill();
  ctx.fillStyle = "#2f332a";
  roundedRect(2, -7, 25, 14, 5);
  ctx.fill();
  ctx.fillStyle = "#f0643b";
  ctx.beginPath();
  ctx.arc(-8, -11, 5, 0, Math.PI * 2);
  ctx.arc(-8, 11, 5, 0, Math.PI * 2);
  ctx.fill();
  ctx.restore();

  ctx.strokeStyle = "rgba(230, 184, 92, 0.15)";
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.arc(p.x, p.y, p.pickupRange, 0, Math.PI * 2);
  ctx.stroke();
}

function drawEnemies() {
  for (const enemy of state.enemies) {
    const hpRatio = clamp(enemy.hp / enemy.maxHp, 0, 1);
    ctx.fillStyle = enemy.color;
    ctx.beginPath();
    ctx.arc(enemy.x, enemy.y, enemy.r, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "rgba(0, 0, 0, 0.28)";
    ctx.beginPath();
    ctx.arc(enemy.x - enemy.r * 0.25, enemy.y - enemy.r * 0.2, enemy.r * 0.35, 0, Math.PI * 2);
    ctx.fill();
    ctx.fillStyle = "#111412";
    ctx.fillRect(enemy.x - enemy.r, enemy.y - enemy.r - 9, enemy.r * 2, 4);
    ctx.fillStyle = "#e6b85c";
    ctx.fillRect(enemy.x - enemy.r, enemy.y - enemy.r - 9, enemy.r * 2 * hpRatio, 4);
  }
}

function drawBullets() {
  for (const bullet of state.bullets) {
    ctx.fillStyle = bullet.color;
    ctx.beginPath();
    ctx.arc(bullet.x, bullet.y, bullet.r, 0, Math.PI * 2);
    ctx.fill();
  }
}

function drawPickups() {
  for (const item of state.pickups) {
    ctx.fillStyle = item.color;
    ctx.beginPath();
    ctx.moveTo(item.x, item.y - item.r);
    ctx.lineTo(item.x + item.r, item.y);
    ctx.lineTo(item.x, item.y + item.r);
    ctx.lineTo(item.x - item.r, item.y);
    ctx.closePath();
    ctx.fill();
  }
}

function drawSparks() {
  for (const spark of state.sparks) {
    const alpha = clamp(spark.life / spark.maxLife, 0, 1);
    ctx.globalAlpha = alpha;
    ctx.strokeStyle = spark.color;
    ctx.fillStyle = spark.color;

    if (spark.line) {
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.moveTo(spark.x1, spark.y1);
      ctx.lineTo(spark.x2, spark.y2);
      ctx.stroke();
    } else {
      spark.x += spark.vx * 0.016;
      spark.y += spark.vy * 0.016;
      ctx.beginPath();
      ctx.arc(spark.x, spark.y, 3, 0, Math.PI * 2);
      ctx.fill();
    }
    ctx.globalAlpha = 1;
  }
}

function drawFloatingText() {
  ctx.font = "700 16px Trebuchet MS";
  ctx.textAlign = "center";

  for (const text of state.floatingText) {
    ctx.globalAlpha = clamp(text.life / 0.55, 0, 1);
    ctx.fillStyle = text.color;
    ctx.fillText(text.text, text.x, text.y);
  }
  ctx.globalAlpha = 1;
}

function drawWaveState() {
  if (state.paused) {
    ctx.fillStyle = "rgba(0, 0, 0, 0.34)";
    ctx.fillRect(0, 0, world.width, world.height);
    ctx.fillStyle = "#f5efe3";
    ctx.font = "800 54px Trebuchet MS";
    ctx.textAlign = "center";
    ctx.fillText("Paused", world.width / 2, world.height / 2);
  }
}

function updateHud() {
  ui.hpMeter.style.width = `${clamp(state.player.hp / state.player.maxHp, 0, 1) * 100}%`;
  ui.xpMeter.style.width = `${clamp(state.xp / state.xpToNext, 0, 1) * 100}%`;
  ui.waveText.textContent = state.wave;
  ui.oreText.textContent = state.ore;
  ui.timeText.textContent = formatTime(state.elapsed);
}

function loop(now) {
  const dt = Math.min(0.033, (now - last) / 1000);
  last = now;
  update(dt);
  draw();
  requestAnimationFrame(loop);
}

function formatTime(seconds) {
  const mins = Math.floor(seconds / 60).toString().padStart(2, "0");
  const secs = Math.floor(seconds % 60).toString().padStart(2, "0");
  return `${mins}:${secs}`;
}

function sample(items, count) {
  return [...items].sort(() => Math.random() - 0.5).slice(0, count);
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function randomBetween(min, max) {
  return min + Math.random() * (max - min);
}

function distanceSq(ax, ay, bx, by) {
  return (ax - bx) ** 2 + (ay - by) ** 2;
}

function roundedRect(x, y, width, height, radius) {
  if (typeof ctx.roundRect === "function") {
    ctx.beginPath();
    ctx.roundRect(x, y, width, height, radius);
    return;
  }

  const r = Math.min(radius, width / 2, height / 2);
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + width - r, y);
  ctx.quadraticCurveTo(x + width, y, x + width, y + r);
  ctx.lineTo(x + width, y + height - r);
  ctx.quadraticCurveTo(x + width, y + height, x + width - r, y + height);
  ctx.lineTo(x + r, y + height);
  ctx.quadraticCurveTo(x, y + height, x, y + height - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}

window.addEventListener("keydown", (event) => {
  keys.add(event.code);

  if (event.code === "Space" && state.mode === "play" && state.dashCooldown <= 0) {
    state.player.dashTime = 0.16;
    state.dashCooldown = 1.7;
  }

  if (event.code === "KeyP" && state.mode === "play") {
    state.paused = !state.paused;
  }
});

window.addEventListener("keyup", (event) => {
  keys.delete(event.code);
});

canvas.addEventListener("pointermove", (event) => {
  const rect = canvas.getBoundingClientRect();
  mouse.x = ((event.clientX - rect.left) / rect.width) * world.width;
  mouse.y = ((event.clientY - rect.top) / rect.height) * world.height;
});

ui.startButton.addEventListener("click", startRun);
ui.restartButton.addEventListener("click", startRun);

renderWeapons();
requestAnimationFrame(loop);
