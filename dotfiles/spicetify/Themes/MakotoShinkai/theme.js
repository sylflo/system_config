// ===== SHINKAI THEME CONFIGURATION =====
const SHINKAI_CONFIG_KEY = 'shinkai-theme-config';

// Default configuration
const defaultConfig = {
  stars: true,
  shootingStars: true,
  lightParticles: true,
  fallingPetals: true,
};

// Load saved config or use defaults
function loadConfig() {
  const saved = localStorage.getItem(SHINKAI_CONFIG_KEY);
  return saved ? { ...defaultConfig, ...JSON.parse(saved) } : { ...defaultConfig };
}

// Save config to localStorage
function saveConfig(config) {
  localStorage.setItem(SHINKAI_CONFIG_KEY, JSON.stringify(config));
}

function waitForElement(els, func, timeout = 100) {
  const queries = els.map((el) => document.querySelector(el));
  if (queries.every((a) => a)) {
    func(queries);
  } else if (timeout > 0) {
    setTimeout(waitForElement, 300, els, func, --timeout);
  }
}

function random(min, max) {
  // min inclusive max exclusive
  return Math.random() * (max - min) + min;
}

waitForElement(['.Root__top-container'], ([topContainer]) => {
  const r = document.documentElement;
  const rs = window.getComputedStyle(r);

  // Load configuration
  let config = loadConfig();

  const backgroundContainer = document.createElement('div');
  backgroundContainer.className = 'starrynight-bg-container';
  topContainer.appendChild(backgroundContainer);

  // to position stars and shooting stars between the background and everything else
  const rootElement = document.querySelector('.Root__top-container');
  rootElement.style.zIndex = '0';

  // create the stars (conditional)
  const canvasSize =
    backgroundContainer.clientWidth * backgroundContainer.clientHeight;

  if (config.stars) {
    const starsFraction = canvasSize / 4000;
    for (let i = 0; i < starsFraction; i++) {
      const size = Math.random() < 0.5 ? 1 : 2;

      const star = document.createElement('div');
      star.style.position = 'absolute';
      star.style.left = `${random(0, 99)}%`;
      star.style.top = `${random(0, 99)}%`;
      star.style.opacity = random(0.5, 1);
      star.style.width = `${size}px`;
      star.style.height = `${size}px`;
      star.style.backgroundColor = rs.getPropertyValue('--spice-star');
      star.style.zIndex = '-1';
      star.style.borderRadius = '50%';

      if (Math.random() < 1 / 5) {
        star.style.setProperty("animation", `twinkle${Math.floor(Math.random() * 4) + 1} 5s infinite`, "important");
      }

      backgroundContainer.appendChild(star);
    }
  }


  /*
  Pure CSS Shooting Star Animation Effect Copyright (c) 2021 by Delroy Prithvi (https://codepen.io/delroyprithvi/pen/LYyJROR)

  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  */
  if (config.shootingStars) {
    for (let i = 0; i < 4; i++) {
    const shootingstar = document.createElement('span');
    shootingstar.className = 'shootingstar';
    if (Math.random() < 0.75) {
      shootingstar.style.top = '-4px'; // hidden off screen when animation is delayed
      shootingstar.style.right = `${random(0, 90)}%`;
    } else {
      shootingstar.style.top = `${random(0, 50)}%`;
      shootingstar.style.right = '-4px'; // hidden when animation is delayed
    }

    const shootingStarGlowColor = `rgba(${rs.getPropertyValue(
      '--spice-rgb-shooting-star-glow'
    )},${0.1})`;
    shootingstar.style.boxShadow = `0 0 0 4px ${shootingStarGlowColor}, 0 0 0 8px ${shootingStarGlowColor}, 0 0 20px ${shootingStarGlowColor}`;

    shootingstar.style.animationDuration = `${
      Math.floor(Math.random() * 3) + 3
    }s`;
    shootingstar.style.animationDelay = `${Math.floor(Math.random() * 7)}s`;

    backgroundContainer.appendChild(shootingstar);

    shootingstar.addEventListener('animationend', () => {
      if (Math.random() < 0.75) {
        shootingstar.style.top = '-4px'; // hidden off screen when animation is delayed
        shootingstar.style.right = `${random(0, 90)}%`;
      } else {
        shootingstar.style.top = `${random(0, 50)}%`;
        shootingstar.style.right = '-4px'; // hidden when animation is delayed
      }

      shootingstar.style.animation = 'none'; // Remove animation

      void shootingstar.offsetWidth;

      shootingstar.style.animation = '';
      shootingstar.style.setProperty("animation-duration", `${Math.floor(Math.random() * 4) + 3}s`, "important");
    });
    }
  }

  // ===== MAKOTO SHINKAI ATMOSPHERIC EFFECTS =====

  // Create falling sakura petals (cherry blossoms)
  if (config.fallingPetals) {
    const petalCount = Math.floor(canvasSize / 6000);
    // Sakura petal color variations
    const sakuraColors = [
      '#FFB7C5', // Light pink
      '#FFC0CB', // Pink
      '#FFD1DC', // Pale pink
      '#FFF0F5', // Lavender blush (almost white)
      '#FFE4E1', // Misty rose
      '#FFAEC9'  // Cherry blossom pink
    ];

    for (let i = 0; i < petalCount; i++) {
    const petal = document.createElement('div');
    petal.className = 'falling-petal';
    petal.style.position = 'absolute';
    petal.style.left = `${random(0, 100)}%`;
    // Start above viewport for falling animation
    petal.style.top = `${random(-20, -5)}%`;
    petal.style.opacity = random(0.7, 0.95);
    petal.style.zIndex = '2'; // Above background, below UI

    // Realistic sakura petal sizes
    const size = random(10, 18);
    petal.style.width = `${size}px`;
    petal.style.height = `${size * 1.2}px`;

    // Random sakura color
    const color = sakuraColors[Math.floor(Math.random() * sakuraColors.length)];
    petal.style.setProperty('--sakura-color', color);

    // Random rotation for variety (will be animated)
    const startRotation = random(0, 360);
    petal.style.setProperty('--start-rotation', `${startRotation}deg`);

    // Enable falling animation
    petal.style.animationDuration = `${random(8, 15)}s`;
    petal.style.animationDelay = `${random(0, 10)}s`;

    // Add horizontal drift variation
    petal.style.setProperty('--drift-offset', `${random(-100, 100)}px`);

    backgroundContainer.appendChild(petal);
    }
  }

  // ===== SETTINGS UI =====

  // Create settings button
  const settingsBtn = document.createElement('button');
  settingsBtn.className = 'shinkai-settings-btn';
  settingsBtn.innerHTML = '⚙️';
  settingsBtn.title = 'Shinkai Theme Settings';
  document.body.appendChild(settingsBtn);

  // Create settings modal
  const modal = document.createElement('div');
  modal.className = 'shinkai-settings-modal';
  modal.innerHTML = `
    <div class="shinkai-settings-content">
      <h2>Makoto Shinkai Theme Settings</h2>
      <p class="shinkai-settings-subtitle">Configure atmospheric effects</p>

      <div class="shinkai-settings-options">
        <label class="shinkai-toggle">
          <input type="checkbox" id="toggle-stars" ${config.stars ? 'checked' : ''}>
          <span class="shinkai-toggle-label">
            <span class="shinkai-toggle-title">⭐ Twinkling Stars</span>
            <span class="shinkai-toggle-desc">Starfield with twinkling animation</span>
          </span>
        </label>

        <label class="shinkai-toggle">
          <input type="checkbox" id="toggle-shooting-stars" ${config.shootingStars ? 'checked' : ''}>
          <span class="shinkai-toggle-label">
            <span class="shinkai-toggle-title">💫 Shooting Stars</span>
            <span class="shinkai-toggle-desc">Meteor showers (like "Your Name")</span>
          </span>
        </label>

        <label class="shinkai-toggle">
          <input type="checkbox" id="toggle-particles" ${config.lightParticles ? 'checked' : ''}>
          <span class="shinkai-toggle-label">
            <span class="shinkai-toggle-title">✨ Light Particles</span>
            <span class="shinkai-toggle-desc">Floating dust motes</span>
          </span>
        </label>

        <label class="shinkai-toggle">
          <input type="checkbox" id="toggle-petals" ${config.fallingPetals ? 'checked' : ''}>
          <span class="shinkai-toggle-label">
            <span class="shinkai-toggle-title">🌸 Falling Petals</span>
            <span class="shinkai-toggle-desc">Seasonal atmosphere</span>
          </span>
        </label>
      </div>

      <div class="shinkai-settings-actions">
        <button class="shinkai-btn shinkai-btn-secondary" id="shinkai-close">Close</button>
        <button class="shinkai-btn shinkai-btn-primary" id="shinkai-apply">Apply & Reload</button>
      </div>
    </div>
  `;
  document.body.appendChild(modal);

  // Settings button click handler
  settingsBtn.addEventListener('click', () => {
    modal.classList.add('shinkai-modal-open');
  });

  // Close button handler
  document.getElementById('shinkai-close').addEventListener('click', () => {
    modal.classList.remove('shinkai-modal-open');
  });

  // Apply button handler
  document.getElementById('shinkai-apply').addEventListener('click', () => {
    const newConfig = {
      stars: document.getElementById('toggle-stars').checked,
      shootingStars: document.getElementById('toggle-shooting-stars').checked,
      lightParticles: document.getElementById('toggle-particles').checked,
      fallingPetals: document.getElementById('toggle-petals').checked,
    };

    saveConfig(newConfig);
    location.reload(); // Reload to apply changes
  });

  // Close modal on background click
  modal.addEventListener('click', (e) => {
    if (e.target === modal) {
      modal.classList.remove('shinkai-modal-open');
    }
  });

    // Close modal on Escape key
  document.addEventListener('keydown', (e) => {
    if (
      e.key === 'Escape' &&
      modal.classList.contains('shinkai-modal-open')
    ) {
      modal.classList.remove('shinkai-modal-open');
    }
  });
  

});
