/**
 * @module HUD
 * Game HUD overlay for THE LAST REVENGE.
 * Pure HTML/CSS positioned over the Three.js canvas.
 */

/**
 * @class HUD
 * Creates and manages all in-game HUD elements.
 */
export class HUD {
  /**
   * @param {object} [deps]
   * @param {object} [deps.inventory] - Inventory instance.
   * @param {object} [deps.horrorEffects] - HorrorEffects instance.
   */
  constructor({ inventory = null, horrorEffects = null } = {}) {
    this.inventory = inventory;
    this.horrorEffects = horrorEffects;

    /** DOM root */
    this.root = document.createElement('div');
    this.root.id = 'game-hud';
    this.root.style.cssText =
      'position:fixed;inset:0;z-index:950;pointer-events:none;font-family:"Special Elite",monospace;';
    document.body.appendChild(this.root);

    this._buildHealthBar();
    this._buildBatteryIndicator();
    this._buildCrosshair();
    this._buildInteractionPrompt();
    this._buildInventoryBar();
    this._buildControlsHelper();
    this._buildSanityIndicator();
    this._buildSubtitles();
  }

  /* ────────────────── Health Bar ────────────────── */

  _buildHealthBar() {
    const wrap = document.createElement('div');
    wrap.style.cssText =
      'position:absolute;bottom:34px;left:24px;width:180px;';
    wrap.innerHTML = `
      <div style="font-size:0.65rem;color:#888;letter-spacing:0.1rem;margin-bottom:4px;">HEALTH</div>
      <div id="hud-health-bg" style="width:100%;height:6px;background:#1a1a1a;border:1px solid #333;border-radius:3px;overflow:hidden;">
        <div id="hud-health-fill" style="width:100%;height:100%;background:linear-gradient(90deg,#8B0000,#cc0000);transition:width 0.3s;"></div>
      </div>`;
    this.root.appendChild(wrap);
    this._healthFill = document.getElementById('hud-health-fill');
    this._healthWrap = wrap;
  }

  /* ────────────────── Battery ────────────────── */

  _buildBatteryIndicator() {
    const wrap = document.createElement('div');
    wrap.style.cssText =
      'position:absolute;bottom:34px;left:220px;width:100px;';
    wrap.innerHTML = `
      <div style="font-size:0.65rem;color:#888;letter-spacing:0.1rem;margin-bottom:4px;">🔦 BATTERY</div>
      <div style="width:100%;height:6px;background:#1a1a1a;border:1px solid #333;border-radius:3px;overflow:hidden;">
        <div id="hud-battery-fill" style="width:100%;height:100%;background:linear-gradient(90deg,#b8860b,#ffd700);transition:width 0.3s;"></div>
      </div>`;
    this.root.appendChild(wrap);
    this._batteryFill = document.getElementById('hud-battery-fill');
    this._batteryWrap = wrap;
  }

  /* ────────────────── Crosshair ────────────────── */

  _buildCrosshair() {
    // Use existing crosshair from index.html if present, otherwise create
    this._crosshair = document.getElementById('crosshair');
    if (!this._crosshair) {
      this._crosshair = document.createElement('div');
      this._crosshair.id = 'crosshair';
      this._crosshair.style.cssText =
        'position:fixed;top:50%;left:50%;transform:translate(-50%,-50%);' +
        'z-index:100;width:3px;height:3px;background:rgba(200,200,200,0.5);' +
        'border-radius:50%;box-shadow:0 0 4px rgba(200,200,200,0.3);pointer-events:none;';
      document.body.appendChild(this._crosshair);
    }
  }

  /* ────────────────── Interaction Prompt ────────────────── */

  _buildInteractionPrompt() {
    // Managed by InteractionSystem — just ensure element exists
    this._interactPrompt = document.getElementById('interact-prompt');
  }

  /* ────────────────── Inventory Quick-select ────────────────── */

  _buildInventoryBar() {
    const bar = document.createElement('div');
    bar.id = 'hud-inventory-bar';
    bar.style.cssText =
      'position:absolute;bottom:34px;left:50%;transform:translateX(-50%);' +
      'display:flex;gap:4px;';

    this._invSlots = [];
    const slotCount = this.inventory ? this.inventory.maxSlots : 8;

    for (let i = 0; i < slotCount; i++) {
      const slot = document.createElement('div');
      slot.style.cssText =
        'width:44px;height:44px;background:rgba(10,10,10,0.7);' +
        'border:1px solid #333;border-radius:4px;display:flex;' +
        'align-items:center;justify-content:center;font-size:1.2rem;' +
        'position:relative;transition:border-color 0.2s;';
      // Slot number label
      const num = document.createElement('span');
      num.textContent = String(i + 1);
      num.style.cssText =
        'position:absolute;top:2px;left:4px;font-size:0.5rem;color:#555;';
      slot.appendChild(num);
      bar.appendChild(slot);
      this._invSlots.push(slot);
    }
    this.root.appendChild(bar);
  }

  /* ────────────────── Controls Helper Bar ────────────────── */

  _buildControlsHelper() {
    const bar = document.createElement('div');
    bar.id = 'hud-controls-helper';
    bar.style.cssText =
      'position:absolute;bottom:8px;left:50%;transform:translateX(-50%);' +
      'display:flex;gap:10px;align-items:center;font-size:0.72rem;color:#ccc;' +
      'font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,monospace;' +
      'background:rgba(10,8,8,0.92);padding:5px 18px;border-radius:6px;' +
      'border:1px solid rgba(255,255,255,0.2);pointer-events:none;white-space:nowrap;' +
      'box-shadow:0 4px 14px rgba(0,0,0,0.85);backdrop-filter:blur(4px);z-index:1000;';
    bar.innerHTML = `
      <span><b style="background:#221a10;border:1px solid #e0a030;border-radius:3px;padding:1px 5px;color:#ffbb33;font-size:0.7rem;margin-right:2px;">WASD</b> Move</span>
      <span><b style="background:#221a10;border:1px solid #e0a030;border-radius:3px;padding:1px 5px;color:#ffbb33;font-size:0.7rem;margin-right:2px;">Mouse/Drag</b> Look</span>
      <span><b style="background:#1a1a24;border:1px solid #6688cc;border-radius:3px;padding:1px 5px;color:#88bbff;font-size:0.7rem;margin-right:2px;">Shift</b> Sprint</span>
      <span><b style="background:#1a1a24;border:1px solid #6688cc;border-radius:3px;padding:1px 5px;color:#88bbff;font-size:0.7rem;margin-right:2px;">C</b> Crouch</span>
      <span><b style="background:#281010;border:1px solid #ff4444;border-radius:3px;padding:1px 5px;color:#ff5555;font-size:0.7rem;margin-right:2px;">E</b> Interact</span>
      <span><b style="background:#242010;border:1px solid #ffd700;border-radius:3px;padding:1px 5px;color:#ffea55;font-size:0.7rem;margin-right:2px;">F</b> Flashlight</span>
      <span><b style="background:#2c0c0c;border:1px solid #ff2222;border-radius:3px;padding:1px 5px;color:#ff4444;font-size:0.7rem;margin-right:2px;">Q</b> Blood Bag (Heal)</span>
      <span><b style="background:#1a1a1a;border:1px solid #666;border-radius:3px;padding:1px 5px;color:#ccc;font-size:0.7rem;margin-right:2px;">1-8</b> Items</span>
      <span><b style="background:#1a1a1a;border:1px solid #555;border-radius:3px;padding:1px 5px;color:#aaa;font-size:0.7rem;margin-right:2px;">Esc</b> Pause</span>
    `;
    this.root.appendChild(bar);
  }

  /* ────────────────── Sanity Indicator ────────────────── */

  _buildSanityIndicator() {
    const wrap = document.createElement('div');
    wrap.id = 'hud-sanity';
    wrap.style.cssText =
      'position:absolute;top:24px;right:24px;text-align:center;';
    wrap.innerHTML = `
      <div id="hud-sanity-eye" style="font-size:2rem;line-height:1;transition:opacity 0.3s;">👁️</div>
      <div style="font-size:0.55rem;color:#666;letter-spacing:0.08rem;margin-top:2px;">SANITY</div>`;
    this.root.appendChild(wrap);
    this._sanityEye = document.getElementById('hud-sanity-eye');
  }

  /* ────────────────── Subtitles ────────────────── */

  _buildSubtitles() {
    this._subtitleBox = document.createElement('div');
    this._subtitleBox.id = 'hud-subtitles';
    this._subtitleBox.style.cssText =
      'position:absolute;bottom:90px;left:50%;transform:translateX(-50%);' +
      'max-width:600px;text-align:center;font-size:0.85rem;color:#c8c8c8;' +
      'text-shadow:0 0 8px rgba(0,0,0,0.9);opacity:0;transition:opacity 0.4s;' +
      'padding:8px 20px;background:rgba(0,0,0,0.5);border-radius:4px;';
    this.root.appendChild(this._subtitleBox);
    this._subtitleTimer = null;
  }

  /* ────────────────── Public API ────────────────── */

  /**
   * Show a subtitle message for a duration.
   * @param {string} text
   * @param {number} [duration=4000] ms
   */
  showSubtitle(text, duration = 4000) {
    this._subtitleBox.textContent = text;
    this._subtitleBox.style.opacity = '1';
    clearTimeout(this._subtitleTimer);
    this._subtitleTimer = setTimeout(() => {
      this._subtitleBox.style.opacity = '0';
    }, duration);
  }

  /** Hide subtitles immediately. */
  hideSubtitle() {
    this._subtitleBox.style.opacity = '0';
    clearTimeout(this._subtitleTimer);
  }

  /**
   * Update all HUD elements. Call every frame.
   */
  update() {
    // Health
    if (this.inventory) {
      const hpPct = (this.inventory.health / this.inventory.maxHealth) * 100;
      this._healthFill.style.width = `${hpPct}%`;
      // Pulse when low
      if (hpPct < 25) {
        this._healthFill.style.animation = 'hud-pulse 0.6s ease-in-out infinite';
      } else {
        this._healthFill.style.animation = 'none';
      }

      // Battery
      const batPct = this.inventory.flashlightBattery;
      this._batteryFill.style.width = `${batPct}%`;
      this._batteryWrap.style.opacity = this.inventory.hasFlashlight ? '1' : '0.3';

      // Inventory slots
      for (let i = 0; i < this._invSlots.length; i++) {
        const slotEl = this._invSlots[i];
        const slotData = this.inventory.slots[i];
        // Highlight selected
        slotEl.style.borderColor = i === this.inventory.selectedIndex ? '#8B0000' : '#333';
        // Icon
        const existingIcon = slotEl.querySelector('.inv-icon');
        if (slotData) {
          if (!existingIcon) {
            const ic = document.createElement('span');
            ic.className = 'inv-icon';
            ic.style.fontSize = '1.3rem';
            ic.textContent = slotData.data.icon || '?';
            slotEl.appendChild(ic);
          } else {
            existingIcon.textContent = slotData.data.icon || '?';
          }
          // Stack count
          if (slotData.count > 1) {
            let badge = slotEl.querySelector('.inv-count');
            if (!badge) {
              badge = document.createElement('span');
              badge.className = 'inv-count';
              badge.style.cssText =
                'position:absolute;bottom:2px;right:4px;font-size:0.5rem;color:#aaa;';
              slotEl.appendChild(badge);
            }
            badge.textContent = `x${slotData.count}`;
          }
        } else {
          if (existingIcon) existingIcon.remove();
          const badge = slotEl.querySelector('.inv-count');
          if (badge) badge.remove();
        }
      }
    }

    // Sanity eye
    if (this.horrorEffects) {
      const s = this.horrorEffects.sanity; // 0-100
      // Eye closes as sanity drops
      const scale = 0.4 + (s / 100) * 0.6;
      const opacity = 0.3 + (s / 100) * 0.7;
      this._sanityEye.style.transform = `scaleY(${scale})`;
      this._sanityEye.style.opacity = String(opacity);
    }
  }

  /* ────────────────── Visibility ────────────────── */

  show() {
    this.root.style.display = 'block';
  }

  hide() {
    this.root.style.display = 'none';
  }

  /* ────────────────── Cleanup ────────────────── */

  dispose() {
    clearTimeout(this._subtitleTimer);
    this.root.remove();
  }
}
