/**
 * @module Inventory
 * Simple inventory system for THE LAST REVENGE.
 */

/** Item type definitions */
export const ItemType = Object.freeze({
  FLASHLIGHT: 'FLASHLIGHT',
  BASEBALL_BAT: 'BASEBALL_BAT',
  WALKIE_TALKIE: 'WALKIE_TALKIE',
  DEVILS_BIBLE: 'DEVILS_BIBLE',
  BLOOD_BAG: 'BLOOD_BAG',
  KEYCARD: 'KEYCARD',
});

/** Default item data catalogue */
const ITEM_DATA = {
  [ItemType.FLASHLIGHT]: {
    name: 'Flashlight',
    description: 'A flickering flashlight. Batteries not included... oh wait.',
    stackable: false,
    maxStack: 1,
    icon: '🔦',
    equippable: true,
    consumable: false,
  },
  [ItemType.BASEBALL_BAT]: {
    name: 'Baseball Bat',
    description: 'A bloodied wooden bat. Swings hard.',
    stackable: false,
    maxStack: 1,
    icon: '🏏',
    equippable: true,
    consumable: false,
  },
  [ItemType.WALKIE_TALKIE]: {
    name: 'Walkie-Talkie',
    description: 'Crackles with static... and something else.',
    stackable: false,
    maxStack: 1,
    icon: '📻',
    equippable: false,
    consumable: false,
  },
  [ItemType.DEVILS_BIBLE]: {
    name: "Devil's Bible",
    description: 'Ancient pages filled with forbidden knowledge.',
    stackable: false,
    maxStack: 1,
    icon: '📖',
    equippable: false,
    consumable: false,
  },
  [ItemType.BLOOD_BAG]: {
    name: 'Blood Bag',
    description: 'Medical blood bag. Restores 25 HP.',
    stackable: true,
    maxStack: 5,
    icon: '🩸',
    equippable: false,
    consumable: true,
    healAmount: 25,
  },
  [ItemType.KEYCARD]: {
    name: 'Keycard',
    description: 'An access keycard. The label is smeared with blood.',
    stackable: false,
    maxStack: 1,
    icon: '🪪',
    equippable: false,
    consumable: false,
  },
};

/**
 * @class Inventory
 * Manages the player's items, equipment, and flashlight battery.
 */
export class Inventory {
  /**
   * @param {object} [opts]
   * @param {number} [opts.maxSlots=8] - Maximum inventory slots.
   */
  constructor({ maxSlots = 8 } = {}) {
    /** @type {number} */
    this.maxSlots = maxSlots;

    /**
     * Inventory slots.
     * Each slot: { type: string, data: object, count: number } | null
     * @type {Array<object|null>}
     */
    this.slots = new Array(maxSlots).fill(null);

    /** Currently selected slot index */
    this.selectedIndex = 0;

    /** Flashlight battery (0-100) */
    this.flashlightBattery = 100;
    /** Battery drain rate (units per second while on) */
    this.batteryDrainRate = 2;
    /** Whether flashlight is on */
    this.flashlightOn = false;
    /** Whether flashlight has been found */
    this.hasFlashlight = false;

    /** Whether bat is equipped */
    this.batEquipped = false;

    /** Bat swing animation state */
    this._swingTimer = 0;
    this._swinging = false;
    this.swingDuration = 0.4; // seconds

    /** Lore pages collected from Devil's Bible */
    this.lorePages = [];

    /** Keycard IDs collected */
    this.keycards = new Set();

    /** Health reference (set externally) */
    this.health = 100;
    this.maxHealth = 100;

    /** Event callbacks */
    this.onItemAdded = null;
    this.onItemRemoved = null;
    this.onItemUsed = null;
    this.onHealthChanged = null;
    this.onChange = null;
  }

  /* ────────────────────── Core Operations ────────────────────── */

  /**
   * Add an item to the inventory.
   * @param {string} type - ItemType constant.
   * @param {object} [extraData] - Additional data (e.g. keycardId, lorePage).
   * @returns {boolean} True if successfully added.
   */
  addItem(type, extraData = {}) {
    const data = { ...ITEM_DATA[type], ...extraData };

    // Special handling for flashlight
    if (type === ItemType.FLASHLIGHT) {
      this.hasFlashlight = true;
      this.flashlightOn = true;
      this._emit('onItemAdded', type, data);
      return true;
    }

    // Special handling for keycards
    if (type === ItemType.KEYCARD && extraData.keycardId) {
      this.keycards.add(extraData.keycardId);
    }

    // Special handling for devil's bible pages
    if (type === ItemType.DEVILS_BIBLE && extraData.lorePage) {
      this.lorePages.push(extraData.lorePage);
    }

    // Stackable: try to find existing stack
    if (data.stackable) {
      for (let i = 0; i < this.maxSlots; i++) {
        const slot = this.slots[i];
        if (slot && slot.type === type && slot.count < data.maxStack) {
          slot.count++;
          this._emit('onItemAdded', type, data);
          return true;
        }
      }
    }

    // Find empty slot
    const emptyIdx = this.slots.findIndex((s) => s === null);
    if (emptyIdx === -1) return false; // Inventory full

    this.slots[emptyIdx] = { type, data, count: 1 };
    this._emit('onItemAdded', type, data);
    return true;
  }

  /**
   * Remove an item by type (reduces stack or clears slot).
   * @param {string} type
   * @returns {boolean}
   */
  removeItem(type) {
    for (let i = 0; i < this.maxSlots; i++) {
      const slot = this.slots[i];
      if (slot && slot.type === type) {
        slot.count--;
        if (slot.count <= 0) this.slots[i] = null;
        this._emit('onItemRemoved', type);
        return true;
      }
    }
    return false;
  }

  /**
   * Check whether the player has at least one of an item type.
   * @param {string} type
   * @returns {boolean}
   */
  hasItem(type) {
    if (type === ItemType.FLASHLIGHT) return this.hasFlashlight;
    return this.slots.some((s) => s && s.type === type);
  }

  /**
   * Check if a specific keycard has been collected.
   * @param {string} keycardId
   * @returns {boolean}
   */
  hasKeycard(keycardId) {
    return this.keycards.has(keycardId);
  }

  /**
   * Use the currently selected item (blood bag → heal).
   * @returns {boolean}
   */
  useSelectedItem() {
    const slot = this.slots[this.selectedIndex];
    if (!slot) return false;

    if (slot.type === ItemType.BLOOD_BAG) {
      return this.useBloodBag();
    }
    if (slot.type === ItemType.BASEBALL_BAT) {
      this.swingBat();
      return true;
    }
    return false;
  }

  /**
   * Select inventory slot by index.
   * @param {number} index
   */
  selectSlot(index) {
    if (index < 0 || index >= this.maxSlots) return;
    this.selectedIndex = index;
    const slot = this.slots[index];
    this.batEquipped = slot?.type === ItemType.BASEBALL_BAT;
    this._emit('onChange');
  }

  /* ────────────────────── Flashlight ────────────────────── */

  /** Toggle flashlight on/off. */
  toggleFlashlight() {
    if (!this.hasFlashlight) return;
    this.flashlightOn = !this.flashlightOn;
  }

  /* ────────────────────── Bat ────────────────────── */

  /** Trigger a bat swing. */
  swingBat() {
    if (!this.batEquipped || this._swinging) return;
    this._swinging = true;
    this._swingTimer = 0;
    this._emit('onItemUsed', ItemType.BASEBALL_BAT);
  }

  /**
   * Whether the bat is currently mid-swing.
   * @returns {boolean}
   */
  get isSwinging() {
    return this._swinging;
  }

  /* ────────────────────── Update ────────────────────── */

  /**
   * Call every frame.
   * @param {number} delta - Seconds since last frame.
   */
  update(delta) {
    // Battery drain
    if (this.hasFlashlight && this.flashlightOn) {
      this.flashlightBattery = Math.max(0, this.flashlightBattery - this.batteryDrainRate * delta);
      if (this.flashlightBattery <= 0) {
        this.flashlightOn = false;
      }
    }

    // Swing animation timer
    if (this._swinging) {
      this._swingTimer += delta;
      if (this._swingTimer >= this.swingDuration) {
        this._swinging = false;
      }
    }
  }

  /**
   * Get the bat swing progress (0-1).
   * @returns {number}
   */
  getSwingProgress() {
    if (!this._swinging) return 0;
    return Math.min(1, this._swingTimer / this.swingDuration);
  }

  /* ────────────────────── Internal ────────────────────── */

  /** Use a blood bag from any inventory slot to heal 25 HP. */
  useBloodBag() {
    if (!this.hasItem(ItemType.BLOOD_BAG) || this.health >= this.maxHealth) return false;
    const healAmt = 25;
    this.health = Math.min(this.maxHealth, this.health + healAmt);
    this.removeItem(ItemType.BLOOD_BAG);
    this._emit('onItemUsed', ItemType.BLOOD_BAG);
    if (this.onHealthChanged) this.onHealthChanged(this.health, this.maxHealth);
    return true;
  }

  /** @private Fire an event callback if set. */
  _emit(name, ...args) {
    if (typeof this[name] === 'function') {
      this[name](...args);
    }
  }

  /* ────────────────────── Serialization ────────────────────── */

  /** Reset all run-specific state for a new game. */
  reset() {
    this.slots.fill(null);
    this.selectedIndex = 0;
    this.flashlightBattery = 100;
    this.flashlightOn = false;
    this.hasFlashlight = false;
    this.batEquipped = false;
    this._swingTimer = 0;
    this._swinging = false;
    this.lorePages = [];
    this.keycards.clear();
    this.health = this.maxHealth;
    this._emit('onHealthChanged', this.health, this.maxHealth);
    this._emit('onChange');
  }

  /** Serialize inventory state to plain object. */
  toJSON() {
    return {
      slots: this.slots,
      selectedIndex: this.selectedIndex,
      flashlightBattery: this.flashlightBattery,
      flashlightOn: this.flashlightOn,
      hasFlashlight: this.hasFlashlight,
      health: this.health,
      lorePages: this.lorePages,
      keycards: [...this.keycards],
    };
  }

  /** Restore inventory state from plain object. */
  fromJSON(data) {
    if (!data) return;
    this.slots = data.slots || this.slots;
    this.selectedIndex = data.selectedIndex ?? 0;
    this.flashlightBattery = data.flashlightBattery ?? 100;
    this.flashlightOn = data.flashlightOn ?? false;
    this.hasFlashlight = data.hasFlashlight ?? false;
    this.health = data.health ?? 100;
    this.lorePages = data.lorePages || [];
    this.keycards = new Set(data.keycards || []);
  }
}
