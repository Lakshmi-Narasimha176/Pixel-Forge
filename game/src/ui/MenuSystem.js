/**
 * @module MenuSystem
 * Full game menu system for THE LAST REVENGE.
 * Main menu, pause, settings, death screen, victory, and loading.
 */

/**
 * @class MenuSystem
 */
export class MenuSystem {
  /**
   * @param {object} [deps]
   * @param {Function} [deps.onNewGame] - Called when user clicks NEW GAME.
   * @param {Function} [deps.onRestart] - Called when user clicks RESTART.
   * @param {Function} [deps.onResume] - Called when user resumes from pause.
   * @param {object} [deps.audioManager] - AudioManager for menu sounds.
   */
  constructor({ onNewGame, onRestart, onResume, audioManager } = {}) {
    this.onNewGame = onNewGame || (() => {});
    this.onRestart = onRestart || (() => {});
    this.onResume = onResume || (() => {});
    this.audioManager = audioManager || null;

    /** Current visible screen */
    this.activeScreen = 'main'; // main | pause | settings | death | victory | loading | none

    /** Settings state */
    this.settings = {
      masterVolume: 80,
      sfxVolume: 80,
      musicVolume: 60,
      sensitivity: 50,
      brightness: 50,
    };

    this._container = document.createElement('div');
    this._container.id = 'menu-system';
    this._container.style.cssText =
      'position:fixed;inset:0;z-index:900;font-family:"Creepster","Special Elite",cursive;';
    document.body.appendChild(this._container);

    this._buildMainMenu();
    this._buildPauseMenu();
    this._buildSettingsMenu();
    this._buildDeathScreen();
    this._buildVictoryScreen();
    this._buildLoadingScreen();

    // Keyboard listener for ESC → pause toggle
    this._onKeyDown = (e) => {
      if (e.code === 'Escape') {
        if (this.activeScreen === 'none') this.showPause();
        else if (this.activeScreen === 'pause') this.resume();
        else if (this.activeScreen === 'settings') this.showPause();
      }
    };
    window.addEventListener('keydown', this._onKeyDown);

    // Show main menu by default
    this.showMain();
  }

  /* ══════════════════════════════════════════════════════════
     SCREEN BUILDERS
     ══════════════════════════════════════════════════════════ */

  _buildMainMenu() {
    this._mainMenu = this._screen('main-menu');
    this._mainMenu.innerHTML = `
      <div class="menu-backdrop">
        <h1 class="menu-title">THE LAST REVENGE</h1>
        <div class="blood-drip"></div>
        <div class="menu-buttons">
          <button id="btn-new-game" class="menu-btn">NEW GAME</button>
          <button id="btn-settings-main" class="menu-btn">SETTINGS</button>
        </div>
        <p class="menu-footer">— A tale of darkness —</p>
      </div>`;
    this._container.appendChild(this._mainMenu);

    this._mainMenu.querySelector('#btn-new-game').addEventListener('click', () => {
      this._hideAll();
      this.activeScreen = 'none';
      this.onNewGame();
    });
    this._mainMenu.querySelector('#btn-settings-main').addEventListener('click', () => {
      this.showSettings();
    });
  }

  _buildPauseMenu() {
    this._pauseMenu = this._screen('pause-menu');
    this._pauseMenu.innerHTML = `
      <div class="menu-backdrop" style="background:rgba(0,0,0,0.85);">
        <h2 class="menu-subtitle">PAUSED</h2>
        <div class="menu-buttons">
          <button id="btn-resume" class="menu-btn">RESUME</button>
          <button id="btn-settings-pause" class="menu-btn">SETTINGS</button>
          <button id="btn-quit" class="menu-btn menu-btn-danger">QUIT TO MENU</button>
        </div>
      </div>`;
    this._container.appendChild(this._pauseMenu);

    this._pauseMenu.querySelector('#btn-resume').addEventListener('click', () => this.resume());
    this._pauseMenu.querySelector('#btn-settings-pause').addEventListener('click', () => this.showSettings());
    this._pauseMenu.querySelector('#btn-quit').addEventListener('click', () => this.showMain());
  }

  _buildSettingsMenu() {
    this._settingsMenu = this._screen('settings-menu');
    this._settingsMenu.innerHTML = `
      <div class="menu-backdrop" style="background:rgba(0,0,0,0.9);">
        <h2 class="menu-subtitle">SETTINGS</h2>
        <div class="settings-grid">
          ${this._slider('Master Volume', 'masterVolume')}
          ${this._slider('SFX Volume', 'sfxVolume')}
          ${this._slider('Music Volume', 'musicVolume')}
          ${this._slider('Mouse Sensitivity', 'sensitivity')}
          ${this._slider('Brightness', 'brightness')}
        </div>
        <div class="menu-buttons" style="margin-top:24px;">
          <button id="btn-settings-back" class="menu-btn">BACK</button>
        </div>
      </div>`;
    this._container.appendChild(this._settingsMenu);

    this._settingsMenu.querySelector('#btn-settings-back').addEventListener('click', () => {
      if (this._prevScreen === 'main') this.showMain();
      else this.showPause();
    });

    // Bind sliders
    for (const key of Object.keys(this.settings)) {
      const input = this._settingsMenu.querySelector(`#setting-${key}`);
      const display = this._settingsMenu.querySelector(`#val-${key}`);
      if (input) {
        input.value = String(this.settings[key]);
        input.addEventListener('input', () => {
          this.settings[key] = Number(input.value);
          if (display) display.textContent = input.value;
          this._applySettings();
        });
      }
    }
  }

  _buildDeathScreen() {
    this._deathScreen = this._screen('death-screen');
    this._deathScreen.innerHTML = `
      <div class="menu-backdrop death-bg">
        <h1 class="death-title">YOU DIED</h1>
        <div class="blood-splatter-bg"></div>
        <div class="menu-buttons">
          <button id="btn-restart" class="menu-btn menu-btn-danger">RESTART</button>
          <button id="btn-death-quit" class="menu-btn">QUIT TO MENU</button>
        </div>
      </div>`;
    this._container.appendChild(this._deathScreen);

    this._deathScreen.querySelector('#btn-restart').addEventListener('click', () => {
      this._hideAll();
      this.activeScreen = 'none';
      this.onRestart();
    });
    this._deathScreen.querySelector('#btn-death-quit').addEventListener('click', () => this.showMain());
  }

  _buildVictoryScreen() {
    this._victoryScreen = this._screen('victory-screen');
    this._victoryScreen.innerHTML = `
      <div class="menu-backdrop">
        <h1 class="victory-title">YOU ESCAPED</h1>
        <p class="menu-footer">...or did you?</p>
        <div class="menu-buttons" style="margin-top:30px;">
          <button id="btn-victory-menu" class="menu-btn">MAIN MENU</button>
        </div>
      </div>`;
    this._container.appendChild(this._victoryScreen);

    this._victoryScreen.querySelector('#btn-victory-menu').addEventListener('click', () => this.showMain());
  }

  _buildLoadingScreen() {
    // Re-use existing loading screen in index.html if present
    this._loadingScreen = document.getElementById('loading-screen');
    if (!this._loadingScreen) {
      this._loadingScreen = this._screen('loading-screen-menu');
      this._loadingScreen.innerHTML = `
        <div class="menu-backdrop">
          <h1 class="menu-title" style="font-size:2rem;">THE LAST REVENGE</h1>
          <div id="menu-loading-bar-bg" style="width:280px;height:4px;background:#1a1a1a;border:1px solid #333;border-radius:2px;overflow:hidden;margin-top:20px;">
            <div id="menu-loading-bar" style="width:0%;height:100%;background:linear-gradient(90deg,#8B0000,#cc0000);transition:width 0.3s;"></div>
          </div>
          <p id="menu-loading-text" style="margin-top:10px;font-size:0.7rem;color:#555;letter-spacing:0.12rem;">LOADING...</p>
        </div>`;
      this._container.appendChild(this._loadingScreen);
    }
    this._loadingBar = document.getElementById('loading-bar') || document.getElementById('menu-loading-bar');
    this._loadingText = document.getElementById('loading-text') || document.getElementById('menu-loading-text');
  }

  /* ══════════════════════════════════════════════════════════
     PUBLIC API
     ══════════════════════════════════════════════════════════ */

  showMain() {
    this._hideAll();
    this._mainMenu.style.display = 'flex';
    this.activeScreen = 'main';
  }

  showPause() {
    this._hideAll();
    this._pauseMenu.style.display = 'flex';
    this.activeScreen = 'pause';
  }

  showSettings() {
    this._prevScreen = this.activeScreen;
    this._hideAll();
    this._settingsMenu.style.display = 'flex';
    this.activeScreen = 'settings';
  }

  showDeath() {
    this._hideAll();
    this._deathScreen.style.display = 'flex';
    this.activeScreen = 'death';
  }

  showVictory() {
    this._hideAll();
    this._victoryScreen.style.display = 'flex';
    this.activeScreen = 'victory';
  }

  /**
   * Show loading screen and update progress.
   * @param {number} progress 0-100
   * @param {string} [text]
   */
  showLoading(progress = 0, text = 'LOADING...') {
    if (this.activeScreen !== 'loading') {
      this._hideAll();
      if (this._loadingScreen) this._loadingScreen.style.display = 'flex';
      this.activeScreen = 'loading';
    }
    if (this._loadingBar) this._loadingBar.style.width = `${progress}%`;
    if (this._loadingText) this._loadingText.textContent = text;
  }

  hideLoading() {
    if (this._loadingScreen) {
      this._loadingScreen.classList?.add('hidden');
      this._loadingScreen.style.display = 'none';
    }
    if (this.activeScreen === 'loading') this.activeScreen = 'none';
  }

  resume() {
    this._hideAll();
    this.activeScreen = 'none';
    this.onResume();
  }

  /** Whether any menu screen is blocking gameplay. */
  get isActive() {
    return this.activeScreen !== 'none';
  }

  /* ══════════════════════════════════════════════════════════
     INTERNAL
     ══════════════════════════════════════════════════════════ */

  /** @private Create a full-screen overlay div */
  _screen(id) {
    const el = document.createElement('div');
    el.id = id;
    el.className = 'menu-screen';
    el.style.cssText =
      'position:absolute;inset:0;display:none;align-items:center;justify-content:center;z-index:910;';
    return el;
  }

  /** @private Build a slider HTML snippet */
  _slider(label, key) {
    return `
      <div class="setting-row">
        <label>${label}</label>
        <input id="setting-${key}" type="range" min="0" max="100" value="${this.settings[key]}" class="setting-slider" />
        <span id="val-${key}" class="setting-val">${this.settings[key]}</span>
      </div>`;
  }

  /** @private Hide all menu screens */
  _hideAll() {
    [this._mainMenu, this._pauseMenu, this._settingsMenu, this._deathScreen, this._victoryScreen].forEach((el) => {
      if (el) el.style.display = 'none';
    });
    if (this._loadingScreen) this._loadingScreen.style.display = 'none';
  }

  /** @private Apply current settings */
  _applySettings() {
    if (this.audioManager) {
      if (typeof this.audioManager.setMasterVolume === 'function') {
        this.audioManager.setMasterVolume(this.settings.masterVolume / 100);
      }
      if (typeof this.audioManager.setCategoryVolume === 'function') {
        this.audioManager.setCategoryVolume('SFX', this.settings.sfxVolume / 100);
        this.audioManager.setCategoryVolume('MUSIC', this.settings.musicVolume / 100);
      }
    }
    // Brightness: apply CSS filter to canvas
    const canvas = document.querySelector('canvas');
    if (canvas) {
      const brightness = 0.5 + (this.settings.brightness / 100) * 1.0; // 0.5 – 1.5
      canvas.style.filter = `brightness(${brightness})`;
    }
  }

  /* ────────────────── Cleanup ────────────────── */

  dispose() {
    window.removeEventListener('keydown', this._onKeyDown);
    this._container.remove();
  }
}
