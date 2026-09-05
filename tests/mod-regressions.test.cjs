const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { test } = require('node:test');
const vm = require('node:vm');

const source = readFileSync(join(__dirname, '..', 'MistriaCompanion', 'gml', 'MistriaCompanion.gml'), 'utf8');
const privateName = name => `__MistriaCompanion_${name}`;
const publicName = name => `MistriaCompanion_${name}`;

// These functions use the JS-compatible subset of GML. Execute their actual
// source, with narrow game-API stand-ins; this is not a GameMaker runtime test.
function load(names, overrides = {}) {
  const context = vm.createContext({
    array_create: (count, value) => Array(count).fill(value),
    array_length: value => value.length,
    array_push: (array, value) => array.push(value),
    array_sort: (array, compare) => array.sort(compare),
    is_array: Array.isArray,
    is_real: value => typeof value === 'number' && Number.isFinite(value),
    is_string: value => typeof value === 'string',
    min: Math.min,
    max: Math.max,
    ceil: Math.ceil,
    floor: Math.floor,
    string: String,
    __MistriaCompanion_field: (value, key) => value?.[key],
    ...overrides,
  });
  for (const name of names) {
    const start = source.indexOf(`function ${name}(`);
    assert.notEqual(start, -1, `Missing source function ${name}`);
    const next = source.indexOf('\nfunction ', start + 1);
    assert.notEqual(next, -1, `Expected another declaration after ${name}`);
    vm.runInContext(source.slice(start, next), context, { filename: `${name}.gml` });
  }
  return context;
}

const searchNames = [
  'gift_slot_cost', 'copy_array', 'gift_assignment_is_better',
  'gift_priority_upper_can_beat', 'gift_capacity_upper',
  'gift_branch_can_improve', 'search_gift_assignment',
].map(privateName);
const search = load(searchNames);

function makeState(candidates, groups, birthdays, freeSlots, limit = 2048) {
  return {
    npc_ids: candidates.map((_, i) => i),
    candidates,
    groups: groups.map(group => ({
      capacity: group.capacity,
      used: 0,
      existing_room: group.existing ?? 0,
      item: { prototype: { max_stack: group.stack ?? 99 } },
    })),
    birthday_count: birthdays,
    free_slots: freeSlots,
    assignment: candidates.map(() => -1),
    best_assignment: candidates.map(() => -1),
    best_count: 0,
    best_birthdays: 0,
    search_nodes: 0,
    search_node_limit: limit,
    search_limited: false,
  };
}

function solve(state) {
  search.__MistriaCompanion_search_gift_assignment(state, 0, 0, 0, 0);
  return state;
}

function objective(assignment, birthdays) {
  const included = Array.from(assignment, value => Number(value !== -1));
  return [
    included.slice(0, birthdays).reduce((a, b) => a + b, 0),
    included.reduce((a, b) => a + b, 0),
    ...included,
  ];
}

function better(left, right) {
  for (let i = 0; i < left.length; i++) {
    if (left[i] !== right[i]) return left[i] > right[i];
  }
  return false;
}

function exhaustiveObjective(state) {
  const assignment = state.npc_ids.map(() => -1);
  const used = state.groups.map(() => 0);
  let best = objective(assignment, state.birthday_count);
  function visit(npc) {
    if (npc === assignment.length) {
      const score = objective(assignment, state.birthday_count);
      if (better(score, best)) best = score;
      return;
    }
    visit(npc + 1);
    for (const index of state.candidates[npc]) {
      const group = state.groups[index];
      if (used[index] === group.capacity) continue;
      used[index]++;
      const slots = state.groups.reduce((total, current, i) =>
        total + Math.ceil(Math.max(0, used[i] - current.existing_room) / current.item.prototype.max_stack), 0);
      if (slots <= state.free_slots) {
        assignment[npc] = index;
        visit(npc + 1);
        assignment[npc] = -1;
      }
      used[index]--;
    }
  }
  visit(0);
  return best;
}

test('birthday coverage outranks a larger non-birthday haul', () => {
  const state = solve(makeState([[0], [1], [1]], [{ capacity: 1 }, { capacity: 2 }], 1, 1));
  assert.equal(state.best_birthdays, 1);
  assert.equal(state.best_count, 1);
  assert.deepEqual(Array.from(state.best_assignment), [0, -1, -1]);
  assert.equal(state.search_limited, false);
});

test('overlapping preferences can reassign gifts to cover everyone', () => {
  const state = solve(makeState([[0, 1], [0], [2]], [
    { capacity: 1 }, { capacity: 1 }, { capacity: 1 },
  ], 1, 3));
  assert.deepEqual(Array.from(state.best_assignment), [1, 0, 2]);
  assert.equal(state.best_count, 3);
});

test('partial stacks work without empty slots and respect item stack limits', () => {
  const state = solve(makeState([[0], [0], [0]], [
    { capacity: 3, existing: 2, stack: 2 },
  ], 0, 0));
  assert.equal(state.best_count, 2);
  assert.deepEqual(Array.from(state.best_assignment), [0, 0, -1]);
  assert.equal(solve(makeState([[0]], [{ capacity: 1 }], 1, 0)).best_count, 0);
  assert.equal(solve(makeState([[0], [0], [0]], [{ capacity: 3, stack: 1 }], 0, 2)).best_count, 2);
});

test('search-budget exhaustion is reported without corrupting assignments', () => {
  const state = solve(makeState([[0], [0]], [{ capacity: 2 }], 1, 1, 2));
  assert.equal(state.search_nodes, 2);
  assert.equal(state.search_limited, true);
  assert.equal(state.best_birthdays, 1);
  assert.equal(state.best_count, 1);
  assert.deepEqual(state.assignment, [-1, -1]);
  assert.deepEqual(state.groups.map(group => group.used), [0]);
});

test('gift groups reuse capacity calculations and do not exceed available room', () => {
  let capacityReads = 0;
  const item = { partial_eq: other => other === item };
  const units = Array.from({ length: 6 }, (_, slot_index) => ({
    slot_index, item, npcs: [true, true],
  }));
  const context = load([privateName('gift_groups')], {
    ARI: { inventory: { room_for_item: () => { capacityReads++; return 2; } } },
    __MistriaCompanion_existing_room: () => 1,
  });
  const groups = context.__MistriaCompanion_gift_groups(units);
  assert.equal(groups.length, 1);
  assert.equal(groups[0].capacity, 2);
  assert.equal(groups[0].units.length, 2);
  assert.equal(groups[0].existing_room, 1);
  assert.equal(capacityReads, 1);
});

test('birthday-aware pruning matches an independent exhaustive solver', () => {
  let seed = 364836;
  function random(max) {
    seed = (Math.imul(seed, 1664525) + 1013904223) >>> 0;
    return seed % max;
  }
  for (let sample = 0; sample < 600; sample++) {
    const count = 1 + random(6);
    const groups = Array.from({ length: 1 + random(4) }, () => ({
      capacity: 1 + random(4), existing: random(3), stack: 1 + random(3),
    }));
    const candidates = Array.from({ length: count }, () =>
      groups.flatMap((_, i) => random(3) === 0 ? [] : [i]));
    const state = makeState(candidates, groups, random(count + 1), random(4), 100000);
    const expected = exhaustiveObjective(state);
    solve(state);
    assert.equal(state.search_limited, false);
    assert.deepEqual(objective(state.best_assignment, state.birthday_count), expected, `Scenario ${sample}`);
  }
});

const list = values => ({
  contains: value => values.includes(value),
  contains_any_value_from: other => values.some(value => other.contains(value)),
});

test('tooltip and picker gift rules respect infusions, void exceptions, and banned tags', () => {
  const Desire = { Loved: 4, Liked: 3, Neutral: 2, Disliked: 1 };
  const Infusion = { Loveable: 1, Likeable: 2 };
  const ItemId = { VoidNewt: 100, VoidCake: 101 };
  const NpcId = { Juniper: 1, Eiland: 2 };
  const context = load([privateName('gift_desire_for_npc')], { Desire, Infusion, ItemId, NpcId });
  const desire = context.__MistriaCompanion_gift_desire_for_npc;
  const npc = { banned_gift_tags: list(['banned']), loved_gifts: list([3]), liked_gifts: list([4]) };
  const item = (id, infusion = 0, tags = [], giftable = true) => ({
    item_id: id, infusion, prototype: { tags: list(tags), giftable },
  });
  assert.equal(desire(item(3), npc, 0), Desire.Loved);
  assert.equal(desire(item(4), npc, 0), Desire.Liked);
  assert.equal(desire(item(5, Infusion.Loveable), npc, 0), Desire.Loved);
  assert.equal(desire(item(5, Infusion.Likeable), npc, 0), Desire.Liked);
  assert.equal(desire(item(3, Infusion.Likeable), npc, 0), Desire.Loved);
  assert.equal(desire(item(ItemId.VoidNewt, Infusion.Loveable), npc, NpcId.Eiland), Desire.Disliked);
  assert.equal(desire(item(ItemId.VoidNewt), npc, NpcId.Juniper), Desire.Loved);
  assert.equal(desire(item(ItemId.VoidCake), npc, NpcId.Eiland), Desire.Loved);
  assert.equal(desire(item(3, Infusion.Loveable, ['banned']), npc, 0), undefined);
  assert.equal(desire(item(3, 0, [], false), npc, 0), undefined);
});

test('clock release preserves the incoming engine/filter result and save reset clears ownership', () => {
  const runtime = { clock_paused: true, bindings: { wiki: 'F7' }, all_bug_markers_enabled: true };
  const context = load([publicName('clock_advance'), publicName('reset_save')], {
    __MistriaCompanion_runtime: () => runtime,
  });
  assert.equal(context.MistriaCompanion_clock_advance(12, {}), 0);
  assert.equal(context.MistriaCompanion_clock_advance(undefined, {}), undefined);
  context.MistriaCompanion_reset_save({});
  assert.equal(runtime.clock_paused, false);
  assert.equal(context.MistriaCompanion_clock_advance(0, {}), undefined);
  assert.equal(context.MistriaCompanion_clock_advance(12, {}), undefined);
  assert.equal(runtime.bindings.wiki, 'F7');
  assert.equal(runtime.all_bug_markers_enabled, true);
  assert.equal(runtime.dig_spots.length, 0);
  assert.equal(runtime.legendary_sightings.length, 0);
});

function wikiHarness() {
  const runtime = { wiki_title: 'Old fish', map_wiki_nodes: [] };
  const menus = {};
  const open = [];
  const Menu = { Map: 'map', Store: 'store', Crafting: 'crafting' };
  const context = load([privateName('set_wiki_title'), privateName('resolve_wiki_title')], {
    Menu,
    ANCHOR: { open_menus: { count: () => open.length, get: i => open[i] } },
    __MistriaCompanion_runtime: () => runtime,
    __MistriaCompanion_ready: () => true,
    __MistriaCompanion_menu: kind => menus[kind],
    __MistriaCompanion_name: prototype => prototype.name,
    __MistriaCompanion_fit_node: () => {},
    MistriaCompanion_capture_npc_context: () => {},
    MistriaCompanion_capture_quest_item_context: () => {},
    MistriaCompanion_capture_museum_wing_context: () => {},
  });
  return { runtime, menus, open, resolve: context.__MistriaCompanion_resolve_wiki_title };
}

test('wiki resolution never reuses a stale or unhovered tooltip', () => {
  const { open, resolve } = wikiHarness();
  assert.equal(resolve(), '');
  const tooltip = {
    is_tooltip: true, hide_requests: 0, item: { prototype: { name: 'Butterfly' } },
    source_node: { freed: false, is_hovered: () => true },
  };
  open.push(tooltip);
  assert.equal(resolve(), 'Butterfly');
  tooltip.source_node.is_hovered = () => false;
  assert.equal(resolve(), '');
  tooltip.source_node.is_hovered = () => true;
  tooltip.hide_requests = 1;
  assert.equal(resolve(), '');
  tooltip.hide_requests = 0;
  tooltip.close_requested = true;
  assert.equal(resolve(), '');
});

test('source-less wiki tooltips must belong to the current store; crafting uses its live selection', () => {
  const { open, menus, resolve } = wikiHarness();
  const tooltip = { is_tooltip: true, hide_requests: 0, item: { prototype: { name: 'Apple' } } };
  open.push(tooltip);
  assert.equal(resolve(), '');
  menus.store = { tooltip };
  assert.equal(resolve(), 'Apple');
  menus.store.hide_requests = 1;
  assert.equal(resolve(), '');
  menus.store.hide_requests = 0;
  menus.store.tooltip = {};
  menus.crafting = { hide_requests: 0, item: { prototype: { name: 'Apple Pie' } } };
  assert.equal(resolve(), 'Apple Pie');
  menus.crafting.hide_requests = 1;
  assert.equal(resolve(), '');
});

class Node {
  constructor() { this.board = new Map(); this.enabled = true; this.alpha = 1; this.children = []; }
  board_get(key) { return this.board.get(key); }
  board_set(key, value) { this.board.set(key, value); return this; }
  set_xy(x, y) { this.x = x; this.y = y; return this; }
  set_lut() { return this; }
  listen_for_hovers() { return this; }
  set_sprite(sprite) { this.sprite = sprite; return this; }
  set_outline_sprite(sprite) { this.outline = sprite; return this; }
  set_text(text) { this.text = text; return this; }
  set_alpha(alpha) { this.alpha = alpha; return this; }
  enable() { this.enabled = true; return this; }
  disable() { this.enabled = false; return this; }
  get_enabled() { return this.enabled; }
  is_hovered() { return this.hovered ?? false; }
  measure() {}
}

function settingsHarness() {
  class SettingsNode extends Node {
    constructor(width = 170, height = 24) {
      super();
      Object.assign(this, { width, height, unlocked: true });
    }
    set_sprites_from_key(key) { this.style = key; return this; }
    set_align() { return this; }
    set_max_width(width) { this.maxWidth = width; return this; }
    allow_line_breaks() { return this; }
    get_width() { return this.width; }
    get_height() { return this.height; }
    is_unlocked() { return this.unlocked; }
    measure() {
      // Deterministic layout stand-in, not the game's font metrics.
      const columns = Math.max(1, Math.floor((this.maxWidth ?? this.width) / 6));
      this.height = this.text.split('\n').reduce((sum, line) =>
        sum + Math.max(1, Math.ceil(line.length / columns)), 0) * 10;
    }
  }
  const runtime = {};
  const menu = {
    journal: { right_full_body: new SettingsNode(185, 211) },
    hide_requests: 0,
    active_page: undefined,
    option_scroller: undefined,
    category_pilot: {},
  };
  let pilot = menu.category_pilot;
  const created = [];
  const callbacks = [
    'toggle_clock', 'show_legendary_sightings', 'open_wiki',
    'toggle_wiki_hints', 'toggle_all_bug_markers', 'toggle_dig_spot_notifications',
  ];
  const context = load([
    privateName('hotkey_actions'), privateName('keybind_names'),
    privateName('settings_keybind_row'), publicName('update_settings_keybinds'),
  ], {
    ...Object.fromEntries(callbacks.map(name => [publicName(name), () => name])),
    __MistriaCompanion_runtime: () => runtime,
    __MistriaCompanion_menu: () => menu.close_requested ? undefined : menu,
    Menu: { Settings: 'settings' },
    Align: { Center: 0, Middle: 0 },
    COMMON_LUT: 0,
    CommonLutIndex: { Dark: 0, Header: 1 },
    ON_GAMEPAD: false,
    INPUT: { gp_right_stick: { y: 0 } },
    string_replace_all: (text, from, to) => text.split(from).join(to),
    ANCHOR: {
      text: parent => { const node = new SettingsNode(); parent.children.push(node); return node; },
      get_active_pilot: () => pilot,
    },
    create_scroller: () => {
      const scroller = {
        canvas: new SettingsNode(170, 211),
        rows: [], bottom: 0, scroll: 0,
        new_element(height) {
          const row = new SettingsNode(170, height);
          row.y = this.bottom;
          this.bottom += height - 1;
          this.rows.push(row);
          return row;
        },
        add_height_to_element(row, amount) {
          row.height += amount;
          this.bottom += amount;
          for (const next of this.rows.slice(this.rows.indexOf(row) + 1)) next.y += amount;
        },
        scroll_by_amount(amount) { this.scroll += amount; },
        free() { this.canvas.freed = true; },
      };
      created.push(scroller);
      return scroller;
    },
  });
  const actions = context.__MistriaCompanion_hotkey_actions();
  runtime.keybind_rows = Array.from(actions, action => ({
    title: action.title, bindings: [action.default_key],
  }));
  return {
    context, runtime, menu, created, actions,
    update: context.MistriaCompanion_update_settings_keybinds,
    setPilot: value => { pilot = value; },
  };
}

test('Settings reference uses the six registered actions and does not duplicate or replace native pages', () => {
  const { actions, runtime, menu, created, update } = settingsHarness();
  assert.deepEqual(Array.from(actions, action => action.default_key), ['F5', 'F6', 'F7', 'F8', 'F9', 'F10']);
  assert.equal(actions[3].callback(), 'toggle_wiki_hints');
  update();
  update();
  assert.equal(created.length, 1);
  const first = menu.option_scroller;
  assert.equal(first.rows.length, 8);
  assert.equal(first.rows[0].children[0].text, 'Mistria Companion');
  assert.deepEqual(first.rows.slice(1, 7).map(row => row.children[0].text), ['F5', 'F6', 'F7', 'F8', 'F9', 'F10']);
  assert.deepEqual(first.rows.slice(1, 7).map(row => row.children[1].text), runtime.keybind_rows.map(row => row.title));
  assert.ok(first.rows[6].y + first.rows[6].height <= 211, 'default shortcuts fit in the page in the layout fixture');

  // This is the native SettingsMenu category/back lifecycle.
  first.free();
  const nativeOptions = { canvas: new Node() };
  menu.option_scroller = nativeOptions;
  menu.active_page = 'controls';
  update();
  assert.equal(created.length, 1);
  assert.equal(menu.option_scroller, nativeOptions);
  menu.active_page = undefined;
  update();
  assert.equal(menu.option_scroller, nativeOptions, 'do not overwrite another owner of the blank page');
  nativeOptions.canvas.freed = true;
  update();
  assert.equal(created.length, 2);
  assert.notEqual(menu.option_scroller, first);
  menu.close_requested = true;
  menu.option_scroller.free();
  update();
  assert.equal(created.length, 2);
});

test('Settings reference renders alternates and unbound actions with expanding, non-overlapping rows', () => {
  const { context, runtime, menu, update } = settingsHarness();
  runtime.keybind_rows[2].bindings = ['HOME', 'SHIFT+F7'];
  runtime.keybind_rows[3].bindings = [];
  runtime.keybind_rows[4].bindings = ['GAMEPAD_LEFT_SHOULDER+GAMEPAD_RIGHT_TRIGGER'];
  update();
  const rows = menu.option_scroller.rows;
  assert.equal(rows[3].children[0].text, 'HOME\nSHIFT + F7');
  assert.equal(rows[4].children[0].text, 'Not bound');
  assert.equal(rows[5].children[0].text, 'PAD LEFT SHOULDER + PAD RIGHT TRIGGER');
  assert.ok(rows[5].height > 24);
  for (const row of rows.slice(1, 7)) {
    for (const label of row.children) assert.ok(label.height + 8 <= row.height);
  }
  for (let i = 1; i < rows.length; i++) {
    assert.equal(rows[i].y, rows[i - 1].y + rows[i - 1].height - 1);
  }
  assert.equal(context.__MistriaCompanion_keybind_names(['F7']), 'F7');
});

test('Settings reference scrolls with the right stick only when its landing page has control', () => {
  const { context, menu, update, setPilot } = settingsHarness();
  update();
  context.ON_GAMEPAD = true;
  context.INPUT.gp_right_stick.y = 0.75;
  update();
  assert.equal(menu.option_scroller.scroll, 3);
  setPilot({});
  update();
  assert.equal(menu.option_scroller.scroll, 3);
  setPilot(menu.category_pilot);
  menu.hide_requests = 1;
  update();
  assert.equal(menu.option_scroller.scroll, 3);
  menu.hide_requests = 0;
  menu.option_scroller.canvas.unlocked = false;
  update();
  assert.equal(menu.option_scroller.scroll, 3);
});

test('Mist Spot lookup reads the active index, including zero, and rejects invalid saved positions', () => {
  const spot = { location_id: 1, pos: { x: 100, y: 200 } };
  const warnings = [];
  const context = load([privateName('active_mist_spot')], {
    MIST_SIGHT_ACTIVE_INDEX: 0,
    MIST_SIGHT_LIST: { count: () => 1, get: () => spot },
    LOCATIONS: [{}, {}],
    mmapi_warn_rate_limited: (...args) => warnings.push(args),
  });
  const lookup = context.__MistriaCompanion_active_mist_spot;
  assert.equal(lookup(), spot);
  assert.equal(context.MIST_SIGHT_ACTIVE_INDEX, 0);
  context.MIST_SIGHT_ACTIVE_INDEX = undefined;
  assert.equal(lookup(), undefined);
  assert.equal(warnings.length, 0);
  for (const invalid of [-1, 1, 0.5, '0']) {
    context.MIST_SIGHT_ACTIVE_INDEX = invalid;
    assert.equal(lookup(), undefined);
  }
  assert.equal(warnings.length, 4);
  context.MIST_SIGHT_ACTIVE_INDEX = 0;
  spot.location_id = 2;
  assert.equal(lookup(), undefined);
  spot.location_id = 1;
  spot.pos = undefined;
  assert.equal(lookup(), undefined);
  context.MIST_SIGHT_LIST = undefined;
  assert.equal(lookup(), undefined);
});

test('Mist Spots appear in unvisited map areas, link to the wiki, and follow consumption and daily changes', () => {
  const runtime = {
    all_bug_markers_enabled: false, dig_spot_notifications_enabled: false,
    map_menu: { selected_location_id: 1, hide_requests: 0 },
    map_wiki_nodes: [], map_signature: '', dig_spot_visit_key: '', dig_spots: [],
  };
  const spots = [
    { location_id: 1, pos: { x: 100, y: 200 } },
    { location_id: 2, pos: { x: 300, y: 400 } },
  ];
  const clipboard = [];
  const routes = [];
  let queueCount = 0;
  let destroyed = 0;
  runtime.map_menu.find_hub_for = (hubs, position, queue, selected) => {
    routes.push(position);
    return position.location_id === selected ? hubs[0] : 0;
  };
  const context = load([
    privateName('active_mist_spot'), privateName('hub_index'),
    publicName('refresh_map_markers'), privateName('set_wiki_title'),
    privateName('resolve_wiki_title'), publicName('open_wiki'),
  ], {
    __MistriaCompanion_runtime: () => runtime,
    __MistriaCompanion_ready: () => true,
    __MistriaCompanion_menu: kind => kind === 'map' ? runtime.map_menu : undefined,
    __MistriaCompanion_location_name: id => `Area ${id}`,
    __MistriaCompanion_hover_label: () => new Node().set_alpha(0),
    __MistriaCompanion_notify: () => {},
    MistriaCompanion_add_map_labels: () => {},
    MistriaCompanion_capture_npc_context: () => {},
    MistriaCompanion_capture_quest_item_context: () => {},
    MistriaCompanion_capture_museum_wing_context: () => {},
    MIST_SIGHT_ACTIVE_INDEX: 0,
    MIST_SIGHT_LIST: { count: () => spots.length, get: index => spots[index] },
    CURRENT_LOCATION_ID: 0,
    CURRENT_DYN_INDEX: 77,
    LOCATIONS: [{ map_location: 0 }, { map_location: 1 }, { map_location: 2 }],
    LocationPosition: class {
      constructor(location_id, pos, dyn_index) { Object.assign(this, { location_id, pos, dyn_index }); }
    },
    Vec2: (x, y) => ({ x, y }),
    obj_bug: 'bug',
    instance_number: () => 0,
    ds_priority_create: () => ++queueCount,
    ds_priority_destroy: () => destroyed++,
    Menu: { Map: 'map', Store: 'store', Crafting: 'crafting' },
    ANCHOR: {
      sprite: parent => { const node = new Node(); parent.children.push(node); return node; },
      open_menus: { count: () => 0 },
    },
    COMMON_LUT: 0,
    spr_ui_skills_archaeology_icon_mist_sight: 14,
    string_replace_all: (text, from, to) => text.split(from).join(to),
    clipboard_set_text: text => clipboard.push(text),
    mmapi_warn_rate_limited: () => assert.fail('Unexpected invalid Mist Spot data'),
  });
  let hubs = [{ node: new Node() }];
  const refresh = () => context.MistriaCompanion_refresh_map_markers(hubs);
  refresh();
  const marker = hubs[0].node.board_get('mistria_item_details_mist_marker');
  assert.equal(marker.enabled, true);
  assert.equal(marker.sprite, 14);
  assert.deepEqual([marker.x, marker.y], [-10, 10]);
  assert.equal(marker.board_get('label').text, 'Mist Spot\nArea 1');
  assert.equal(marker.board_get('label').alpha, 0);
  assert.equal(routes[0].location_id, 1, 'routes from the spot, not the player');
  assert.equal(routes[0].dyn_index, undefined, 'does not inherit the player dungeon instance');
  assert.deepEqual(routes[0].pos, spots[0].pos);
  assert.equal(context.MIST_SIGHT_ACTIVE_INDEX, 0, 'revealing does not consume the spot');
  refresh();
  assert.equal(queueCount, 1, 'unchanged snapshots do not rebuild markers');
  marker.hovered = true;
  context.MistriaCompanion_open_wiki();
  assert.deepEqual(clipboard, ['https://fieldsofmistria.wiki.gg/wiki/Mist_Spot']);

  context.MIST_SIGHT_ACTIVE_INDEX = 1;
  refresh();
  assert.equal(marker.enabled, false, 'new daily location clears the old area');
  assert.equal(runtime.map_wiki_nodes.length, 0);
  runtime.map_menu.selected_location_id = 2;
  runtime.map_signature = '';
  hubs = [{ node: new Node() }];
  refresh();
  const next = hubs[0].node.board_get('mistria_item_details_mist_marker');
  assert.equal(next.enabled, true);
  assert.equal(next.board_get('label').text, 'Mist Spot\nArea 2');

  context.MIST_SIGHT_ACTIVE_INDEX = undefined;
  refresh();
  assert.equal(next.enabled, false);
  assert.equal(next.board_get('label').alpha, 0);
  assert.equal(runtime.map_wiki_nodes.length, 0);
  context.MistriaCompanion_open_wiki();
  assert.equal(clipboard.length, 1, 'consumed spot cannot supply a stale wiki link');
  assert.equal(destroyed, queueCount);

  context.__MistriaCompanion_hub_index(hubs, 7, 8, 0);
  assert.equal(routes.at(-1).location_id, 0, 'existing bug/dig calls still use the current area');
  assert.equal(routes.at(-1).dyn_index, 77);
});

test('map markers group bug species and counts while preserving native-size hover-only dig markers', () => {
  const runtime = {
    all_bug_markers_enabled: true, map_menu: { selected_location_id: 0 },
    map_wiki_nodes: [], map_signature: '', dig_spot_visit_key: 'visit',
    dig_spots: [{ x: 10, y: 10, grid_x: 1, grid_y: 1 }, { x: 12, y: 10, grid_x: 2, grid_y: 1 }],
  };
  let bugs = [{ id: 1, item_id: 0, x: 10, y: 10 }, { id: 2, item_id: 0, x: 10, y: 10 }, { id: 3, item_id: 1, x: 10, y: 10 }];
  let destroyed = 0;
  const hubs = [{ node: new Node() }];
  const context = load([privateName('name_index'), publicName('refresh_map_markers'), publicName('map_label_think')], {
    __MistriaCompanion_runtime: () => runtime,
    __MistriaCompanion_active_mist_spot: () => undefined,
    __MistriaCompanion_dig_spot_visit_key: () => 'visit',
    __MistriaCompanion_dig_spot_active: () => true,
    __MistriaCompanion_hub_index: () => 0,
    __MistriaCompanion_name: item => item.name,
    __MistriaCompanion_hover_label: () => new Node().set_alpha(0),
    __MistriaCompanion_fit_node: () => {},
    MistriaCompanion_add_map_labels: () => {},
    CURRENT_LOCATION_ID: 0,
    LOCATIONS: [{ map_location: 0 }],
    obj_bug: 'bug',
    instance_number: () => bugs.length,
    instance_find: (_, index) => bugs[index],
    BUGS: { get: id => ({ rarity: id === 1 ? 'very_rare' : 'common' }) },
    ITEM_PROTOTYPES: [{ name: 'Ant', icon_sprite: 10 }, { name: 'Luna Moth', icon_sprite: 11 }],
    ds_priority_create: () => 1,
    ds_priority_destroy: () => destroyed++,
    ANCHOR: { sprite: parent => { const node = new Node(); parent.children.push(node); return node; } },
    COMMON_LUT: 0,
    spr_ui_item_tool_rusty_shovel: 12,
    spr_ui_item_tool_rusty_shovel_outline: 13,
  });
  const refresh = () => context.MistriaCompanion_refresh_map_markers(hubs);
  refresh();
  const bug = hubs[0].node.board_get('mistria_item_details_bug_marker');
  const dig = hubs[0].node.board_get('mistria_item_details_dig_marker');
  assert.equal(hubs[0].node.children.length, 2);
  assert.equal(bug.board_get('label').text, 'Ant x2\nLuna Moth x1');
  assert.equal(bug.sprite, 11);
  assert.equal(runtime.map_wiki_nodes[0].title, 'Bugs');
  assert.deepEqual([bug.x, bug.y, dig.x, dig.y], [-10, -10, 10, -10]);
  assert.equal(dig.outline, 13);
  assert.equal(dig.board_get('label').text, 'Dig spots: 2');
  assert.equal(dig.board_get('label').alpha, 0);
  dig.hovered = true;
  context.MistriaCompanion_map_label_think(dig, dig.board_get('label'), '');
  assert.equal(dig.board_get('label').alpha, 1);
  refresh();
  assert.equal(destroyed, 1, 'unchanged maps reuse their snapshot');
  runtime.all_bug_markers_enabled = false;
  refresh();
  assert.equal(bug.board_get('label').text, 'Luna Moth x1');
  assert.equal(runtime.map_wiki_nodes[0].title, 'Luna Moth');
  bugs = [];
  runtime.dig_spots = [];
  refresh();
  assert.equal(bug.enabled, false);
  assert.equal(dig.enabled, false);
  assert.equal(runtime.map_wiki_nodes.length, 0);
});

test('a rejected inventory add never removes the source gift and does not claim a full backpack', () => {
  const messages = [];
  let removed = 0;
  let remainder = 1;
  let limited = false;
  const item = { partial_eq: other => other === item, clone: () => ({ copy: true }) };
  const slot = { item, count: 1, remove: () => { removed++; slot.count--; } };
  const menu = {
    left: { slot: () => slot },
    left_menu: { hand: { size: () => 1, slot: () => ({ item: undefined }) }, refresh: () => {} },
    right_menu: { refresh: () => {} },
  };
  const context = load([publicName('collect_loved_gifts')], {
    Menu: { Storage: 'storage' },
    ARI: { inventory: { can_add: () => true, add: () => remainder } },
    ANCHOR: { wrap_for_local: value => value },
    __MistriaCompanion_menu: () => menu,
    __MistriaCompanion_gift_plan: () => ({
      eligible_count: 1, matched_count: 1, search_limited: limited,
      entries: [{ npc_id: 0, slot_index: 0, item }],
    }),
    __MistriaCompanion_notify: text => messages.push(text),
    create_notification: text => messages.push(text),
  });
  context.MistriaCompanion_collect_loved_gifts(menu);
  assert.equal(removed, 0);
  assert.equal(slot.count, 1);
  assert.match(messages.at(-1), /planned transfers/);
  assert.doesNotMatch(messages.at(-1), /backpack is full/);
  limited = true;
  context.MistriaCompanion_collect_loved_gifts(menu);
  assert.equal(removed, 0);
  assert.match(messages.at(-1), /planned transfers.*search limit/);
  limited = false;
  remainder = 0;
  context.MistriaCompanion_collect_loved_gifts(menu);
  assert.equal(removed, 1);
  assert.equal(slot.count, 0);
  assert.equal(messages.at(-1), 'Grabbed 1 loved gift.');
});

test('tooltip bounds keep a store tooltip inside the screen without erasing its text', () => {
  const plate = new Node();
  Object.assign(plate, {
    x: 230, y: 270, width: 100, height: 120,
    get_size() { return { x: this.width, y: this.height }; },
    add_x(value) { this.x += value; return this; },
    add_y(value) { this.y += value; return this; },
  });
  const context = load([privateName('fit_node')], {
    ANCHOR: {
      screen_canvas: { get_size: () => ({ x: 320, y: 360 }) },
      get_screen_position: node => ({ x: node.x, y: node.y }),
    },
  });
  context.__MistriaCompanion_fit_node(plate);
  assert.deepEqual([plate.x, plate.y], [216, 236]);
});

test('tick retries initialization, resets visit/day observations, and throttles map work', () => {
  const runtime = {};
  let ready = false;
  let day = '1';
  let scans = 0;
  let refreshes = 0;
  const grid = { node_counter: 1 };
  const context = load([publicName('reset_save'), publicName('tick')], {
    GRID: grid,
    __MistriaCompanion_runtime: () => runtime,
    __MistriaCompanion_register_hotkeys: () => {},
    MistriaCompanion_update_settings_keybinds: () => {},
    __MistriaCompanion_ready: () => ready,
    local_language: () => 'en',
    __MistriaCompanion_legendary_day_key: () => day,
    __MistriaCompanion_map_hubs: () => [],
    MistriaCompanion_detect_dig_spots: () => { scans++; runtime.dig_spot_delay = -1; },
    MistriaCompanion_show_mine_bug_spawns: () => { runtime.mine_bug_delay = -1; },
    MistriaCompanion_track_legendary_spawns: () => {},
    MistriaCompanion_update_birthday_label: () => {},
    MistriaCompanion_add_map_labels: () => {},
    MistriaCompanion_refresh_map_markers: () => refreshes++,
    MistriaCompanion_add_chest_gift_button: () => {},
    __MistriaCompanion_resolve_wiki_title: () => { runtime.wiki_title = ''; },
    __MistriaCompanion_show_wiki_hint: () => {},
  });
  context.MistriaCompanion_reset_save({});
  runtime.frame = 0;
  const tick = context.MistriaCompanion_tick;
  tick();
  assert.equal(scans, 0);
  ready = true;
  tick();
  assert.equal(scans, 1);
  assert.equal(refreshes, 1);
  runtime.seen_spawns.fish = true;
  for (let i = 0; i < 11; i++) tick();
  assert.equal(scans, 1);
  assert.equal(refreshes, 1);
  assert.equal(runtime.seen_spawns.fish, true);
  tick();
  assert.equal(refreshes, 2);
  grid.node_counter++;
  tick();
  assert.equal(scans, 2);
  assert.equal(runtime.seen_spawns.fish, undefined);
  runtime.legendary_sightings.push('Yesterday');
  day = '2';
  tick();
  assert.equal(runtime.legendary_sightings.length, 0);
  assert.equal(scans, 3);
});
