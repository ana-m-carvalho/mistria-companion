function __mistria_item_details_runtime() {
    if (global[$ "__mistria_item_details"] == undefined) {
        global.__mistria_item_details = {
            registered: false,
            cache: {},
            wiki_title: "",
            wiki_hint_title: "",
            wiki_hints_enabled: true,
            all_bug_markers_enabled: false,
            legendary_day: "",
            legendary_sightings: [],
            mine_bug_floor: "",
            mine_bug_delay: -1,
            dig_spot_notifications_enabled: true,
            dig_spot_visit_key: "",
            dig_spot_delay: -1,
            dig_spots: []
        };
    }
    return global.__mistria_item_details;
}

function __mistria_item_details_field(_value, _field) {
    if (_value == undefined) return undefined;
    if (!is_struct(_value) && !instance_exists(_value)) return undefined;
    return _value[$ _field];
}

function __mistria_item_details_as_array(_value) {
    if (is_array(_value)) return _value;
    if (is_struct(_value)) {
        var _buffer = __mistria_item_details_field(_value, "__buffer");
        if (is_array(_buffer)) return _buffer;
    }
    return [];
}

function __mistria_item_details_name(_item_data) {
    if (_item_data == undefined) return "Unknown";
    var _name_key = __mistria_item_details_field(_item_data, "name_key");
    if (_name_key != undefined) {
        var _name = local_get(_name_key);
        if (is_string(_name)) return _name;
    }
    var _recipe_key = __mistria_item_details_field(_item_data, "recipe_key");
    if (_recipe_key != undefined) {
        return string_replace(_recipe_key, "_", " ");
    }
    return "Unknown";
}

function __mistria_item_details_npc_name(_npc_data, _fallback) {
    var _name = __mistria_item_details_field(_npc_data, "name");
    if (is_string(_name)) {
        var _localized_name = local_get(_name);
        if (is_string(_localized_name) && _localized_name != _name) return _localized_name;

        var _name_parts = string_split(_name, "/");
        if (array_length(_name_parts) >= 2) {
            var _internal_name = _name_parts[array_length(_name_parts) - 2];
            return string_upper(string_char_at(_internal_name, 1))
                + string_copy(_internal_name, 2, string_length(_internal_name));
        }
        return _name;
    }
    var _name_key = __mistria_item_details_field(_npc_data, "name_key");
    if (_name_key != undefined) {
        var _localized_name = local_get(_name_key);
        if (is_string(_localized_name)) return _localized_name;
    }
    return string_replace(_fallback, "_", " ");
}

function __mistria_item_details_component_matches(_component, _item_id, _item_key) {
    if (!is_struct(_component)) return false;
    var _component_item_id = __mistria_item_details_field(_component, "item_id");
    if (_component_item_id != undefined && _component_item_id == _item_id) return true;

    var _ingredient = __mistria_item_details_field(_component, "item");
    if (_ingredient == undefined) return false;
    if (_ingredient == _item_id || _ingredient == _item_key) return true;
    if (is_struct(_ingredient)) {
        return __mistria_item_details_component_matches(_ingredient, _item_id, _item_key);
    }
    return false;
}

function __mistria_item_details_recipe_uses_item(_recipe_data, _item_id, _item_key) {
    if (!is_struct(_recipe_data)) return false;

    var _components = __mistria_item_details_field(_recipe_data, "recipe");
    if (_components == undefined) return false;
    var _nested_components = __mistria_item_details_field(_components, "components");
    if (_nested_components != undefined) {
        _components = _nested_components;
    }
    _components = __mistria_item_details_as_array(_components);
    for (var _index = 0; _index < array_length(_components); _index++) {
        if (__mistria_item_details_component_matches(_components[_index], _item_id, _item_key)) {
            return true;
        }
    }
    return false;
}

function __mistria_item_details_contains(_gifts, _item_id, _item_key) {
    if (_gifts == undefined) return false;
    var _is_array = is_array(_gifts);
    var _count = _is_array ? array_length(_gifts) : _gifts.count();
    for (var _index = 0; _index < _count; _index++) {
        var _gift = _is_array ? _gifts[_index] : _gifts.get(_index);
        if (_gift == _item_id || _gift == _item_key) return true;
        if (is_struct(_gift)) {
            var _gift_id = __mistria_item_details_field(_gift, "item_id");
            var _gift_key = __mistria_item_details_field(_gift, "item");
            if (_gift_id == _item_id || _gift_id == _item_key) return true;
            if (_gift_key == _item_id || _gift_key == _item_key) return true;
        }
    }
    return false;
}

function __mistria_item_details_join(_names) {
    var _result = "";
    for (var _index = 0; _index < array_length(_names); _index++) {
        if (_index > 0) _result += ", ";
        _result += _names[_index];
    }
    return _result;
}

function __mistria_item_details_has_name(_names, _name) {
    for (var _index = 0; _index < array_length(_names); _index++) {
        if (_names[_index] == _name) return true;
    }
    return false;
}

function __mistria_item_details_name_index(_names, _name) {
    for (var _index = 0; _index < array_length(_names); _index++) {
        if (_names[_index] == _name) return _index;
    }
    return -1;
}

function __mistria_item_details_recipe_summary(_recipes) {
    var _count = array_length(_recipes);
    if (_count == 0) return "";
    if (_count == 1) return _recipes[0];
    if (string_length(_recipes[0]) > 20) return string(_count) + " recipes";
    return _recipes[0] + " (+" + string(_count - 1) + ")";
}

function __mistria_item_details_location_name(_location_id) {
    var _key = location_id_to_string(_location_id);
    var _words = string_split(_key, "_");
    var _result = "";
    for (var _index = 0; _index < array_length(_words); _index++) {
        if (_index > 0) _result += " ";
        var _word = _words[_index];
        _result += string_upper(string_char_at(_word, 1))
            + string_copy(_word, 2, string_length(_word));
    }
    return _result;
}

function __mistria_item_details_dig_spot_visit_key() {
    var _key = string(CALENDAR.year()) + ":"
        + string(CALENDAR.season()) + ":"
        + string(CALENDAR.day()) + ":"
        + string(CURRENT_LOCATION_ID) + ":"
        + string(room()) + ":"
        + string(__mistria_item_details_field(GRID, "node_counter"));
    if (DUNGEON_RUNNER != undefined) {
        var _level = DUNGEON_RUNNER.current_level();
        _key += ":" + string(DUNGEON_RUNNER.current_floor)
            + ":" + string(_level.impl);
    }
    return _key;
}

function __mistria_item_details_scan_dig_spots() {
    var _spots = [];
    if (GRID == undefined) return _spots;

    var _node_len = __mistria_item_details_field(GRID, "node_len");
    var _object_ids = __mistria_item_details_field(GRID, "node_object_id");
    var _top_left_x = __mistria_item_details_field(GRID, "node_top_left_x");
    var _top_left_y = __mistria_item_details_field(GRID, "node_top_left_y");
    if (_node_len == undefined
        || !is_array(_object_ids)
        || !is_array(_top_left_x)
        || !is_array(_top_left_y))
    {
        return _spots;
    }

    var _scan_length = min(_node_len, array_length(_object_ids));
    _scan_length = min(_scan_length, array_length(_top_left_x));
    _scan_length = min(_scan_length, array_length(_top_left_y));
    for (var _index = 0; _index < _scan_length; _index++) {
        if (_object_ids[_index] != ObjectId.DigSite) continue;

        var _x = _top_left_x[_index];
        var _y = _top_left_y[_index];
        if (_x == undefined || _y == undefined) continue;
        var _parent_index = GRID.try_node_index_for_cell(_x, _y);
        if (_parent_index == undefined || _index != _parent_index) continue;

        array_push(_spots, {
            grid_x: _x,
            grid_y: _y,
            x: (_x * 8) + 8,
            y: (_y * 8) + 8
        });
    }
    return _spots;
}

function __mistria_item_details_dig_spot_active(_spot) {
    if (GRID == undefined) return false;
    var _index = GRID.try_node_index_for_cell(_spot.grid_x, _spot.grid_y);
    return _index != undefined && GRID.node_object_id[_index] == ObjectId.DigSite;
}

function __mistria_item_details_dig_spot_location_name() {
    var _name = __mistria_item_details_location_name(CURRENT_LOCATION_ID);
    if (DUNGEON_RUNNER != undefined) {
        _name += " Floor " + string(DUNGEON_RUNNER.current_floor + 1);
    }
    return _name;
}

function mistria_item_details_detect_dig_spots() {
    var _runtime = __mistria_item_details_runtime();
    if (GRID == undefined) {
        _runtime.dig_spot_visit_key = "";
        _runtime.dig_spot_delay = -1;
        _runtime.dig_spots = [];
        return;
    }

    var _visit_key = __mistria_item_details_dig_spot_visit_key();
    if (_runtime.dig_spot_visit_key != _visit_key) {
        _runtime.dig_spot_visit_key = _visit_key;
        _runtime.dig_spot_delay = 20;
        _runtime.dig_spots = [];
        return;
    }

    if (__mistria_item_details_field(GRID, "is_setup") == false) return;
    if (_runtime.dig_spot_delay > 0) {
        _runtime.dig_spot_delay--;
        return;
    }
    if (_runtime.dig_spot_delay != 0) return;
    _runtime.dig_spot_delay = -1;

    _runtime.dig_spots = __mistria_item_details_scan_dig_spots();
    var _count = array_length(_runtime.dig_spots);
    if (_count == 0 || !_runtime.dig_spot_notifications_enabled) return;

    create_notification(
        ANCHOR.wrap_for_local(
            "Dig spots: " + string(_count) + " - "
                + __mistria_item_details_dig_spot_location_name()
        ),
        60 * 3
    );
}

function __mistria_item_details_legendary_day_key() {
    return string(CALENDAR.year()) + ":"
        + string(CALENDAR.season()) + ":"
        + string(CALENDAR.day());
}

function __mistria_item_details_track_legendary(_kind, _item_id) {
    var _runtime = __mistria_item_details_runtime();
    var _day = __mistria_item_details_legendary_day_key();
    if (_runtime.legendary_day != _day) {
        _runtime.legendary_day = _day;
        _runtime.legendary_sightings = [];
    }

    var _item_data = global[$ "__item_data"];
    if (!is_array(_item_data) || _item_id < 0 || _item_id >= array_length(_item_data)) return;

    var _location = __mistria_item_details_location_name(CURRENT_LOCATION_ID);
    var _name = __mistria_item_details_name(_item_data[_item_id]);
    var _entry = _kind + ": " + _name + " - " + _location;
    if (__mistria_item_details_has_name(_runtime.legendary_sightings, _entry)) return;

    array_push(_runtime.legendary_sightings, _entry);
    create_notification(ANCHOR.wrap_for_local("Legendary " + _entry), 60 * 4);
}

function __mistria_item_details_track_legendary_fish(_fish) {
    var _prototype = __mistria_item_details_field(_fish, "prototype");
    if (_prototype == undefined || _prototype.legendary != true) return;
    __mistria_item_details_track_legendary("Fish", _prototype.item);
}

function mistria_item_details_track_legendary_spawns() {
    if (BUGS == undefined || FISH == undefined) return;

    for (var _index = 0; _index < instance_number(obj_bug); _index++) {
        var _bug = instance_find(obj_bug, _index);
        if (_bug.item_id == undefined) continue;
        var _bug_data = BUGS.get(_bug.item_id);
        if (_bug_data != undefined && _bug_data.rarity == "very_rare") {
            __mistria_item_details_track_legendary("Very Rare Bug", _bug.item_id);
        }
    }

    for (var _index = 0; _index < instance_number(obj_fishy); _index++) {
        var _fish = instance_find(obj_fishy, _index);
        if (_fish.fish_loot != undefined) {
            __mistria_item_details_track_legendary_fish(_fish.fish_loot);
        }
    }

    for (var _index = 0; _index < instance_number(obj_fish_school); _index++) {
        var _school = instance_find(obj_fish_school, _index);
        if (_school.fish_in_school == undefined) continue;
        for (var _fish_index = 0; _fish_index < _school.fish_in_school.count(); _fish_index++) {
            __mistria_item_details_track_legendary_fish(_school.fish_in_school.get(_fish_index));
        }
    }
}

function mistria_item_details_show_mine_bug_spawns() {
    var _runtime = __mistria_item_details_runtime();
    if (DUNGEON_RUNNER == undefined) {
        _runtime.mine_bug_floor = "";
        _runtime.mine_bug_delay = -1;
        return;
    }

    var _level = DUNGEON_RUNNER.current_level();
    var _floor_key = string(DUNGEON_RUNNER.current_floor) + ":"
        + string(room()) + ":" + string(_level.impl);
    if (_runtime.mine_bug_floor != _floor_key) {
        _runtime.mine_bug_floor = _floor_key;
        // Dungeon construction creates bugs before the next few game frames.
        _runtime.mine_bug_delay = 20;
        return;
    }

    if (_runtime.mine_bug_delay > 0) {
        _runtime.mine_bug_delay--;
        return;
    }
    if (_runtime.mine_bug_delay != 0) return;
    _runtime.mine_bug_delay = -1;

    var _item_data = global[$ "__item_data"];
    if (BUGS == undefined || !is_array(_item_data)) return;

    var _names = [];
    var _counts = [];
    for (var _index = 0; _index < instance_number(obj_bug); _index++) {
        var _bug = instance_find(obj_bug, _index);
        var _item_id = __mistria_item_details_field(_bug, "item_id");
        if (_item_id == undefined || _item_id < 0 || _item_id >= array_length(_item_data)) continue;

        var _name = __mistria_item_details_name(_item_data[_item_id]);
        var _name_index = __mistria_item_details_name_index(_names, _name);
        if (_name_index == -1) {
            array_push(_names, _name);
            array_push(_counts, 1);
        } else {
            _counts[_name_index]++;
        }
    }

    if (array_length(_names) == 0) return;

    var _summary = "";
    for (var _index = 0; _index < array_length(_names); _index++) {
        if (_index > 0) _summary += ", ";
        _summary += _names[_index];
        if (_counts[_index] > 1) _summary += " x" + string(_counts[_index]);
    }

    create_notification(
        ANCHOR.wrap_for_local("Mine bugs: " + _summary),
        60 * 3
    );
}

function mistria_item_details_show_legendary_sightings() {
    var _runtime = __mistria_item_details_runtime();
    if (_runtime.legendary_day != __mistria_item_details_legendary_day_key()
        || array_length(_runtime.legendary_sightings) == 0)
    {
        create_notification(ANCHOR.wrap_for_local("No legendary spawns seen today."), 60 * 3);
        return;
    }

    for (var _index = 0; _index < array_length(_runtime.legendary_sightings); _index++) {
        create_notification(
            ANCHOR.wrap_for_local("Legendary " + _runtime.legendary_sightings[_index]),
            60 * 4
        );
    }
}

function mistria_item_details_toggle_clock() {
    CLOCK.time_stopped = !CLOCK.time_stopped;
    create_notification(
        ANCHOR.wrap_for_local(CLOCK.time_stopped ? "Clock paused." : "Clock resumed."),
        60 * 2
    );
}

function mistria_item_details_open_wiki() {
    var _title = __mistria_item_details_runtime().wiki_title;
    if (_title == "") return;
    clipboard_set_text("https://fieldsofmistria.wiki.gg/wiki/" + string_replace_all(_title, " ", "_"));
    create_notification(ANCHOR.wrap_for_local("Wiki link copied to clipboard."), 60 * 3);
}

function mistria_item_details_toggle_wiki_hints() {
    var _runtime = __mistria_item_details_runtime();
    _runtime.wiki_hints_enabled = !_runtime.wiki_hints_enabled;
}

function mistria_item_details_toggle_all_bug_markers() {
    var _runtime = __mistria_item_details_runtime();
    _runtime.all_bug_markers_enabled = !_runtime.all_bug_markers_enabled;
    create_notification(
        ANCHOR.wrap_for_local(
            _runtime.all_bug_markers_enabled
                ? "Ordinary bug map markers enabled."
                : "Ordinary bug map markers disabled."
        ),
        60 * 2
    );
}

function mistria_item_details_toggle_dig_spot_notifications() {
    var _runtime = __mistria_item_details_runtime();
    _runtime.dig_spot_notifications_enabled = !_runtime.dig_spot_notifications_enabled;
    create_notification(
        ANCHOR.wrap_for_local(
            _runtime.dig_spot_notifications_enabled
                ? "Dig spot notifications enabled."
                : "Dig spot notifications disabled."
        ),
        60 * 2
    );
}

function __mistria_item_details_show_wiki_hint(_toasts_menu) {
    create_notification(ANCHOR.wrap_for_local("F7 Wiki"), 60);
    var _hint = _toasts_menu.toasts.get(_toasts_menu.toasts.count() - 1);
    var _y_chain = _hint.board_get("y_chain");
    if (_y_chain != undefined) CHAINS.cancel_chain(_y_chain);
    _hint.board_set("y_chain", undefined);
    _hint.set_y(4);
}

function __mistria_item_details_set_wiki_title(_title) {
    if (_title == "") return;

    var _runtime = __mistria_item_details_runtime();
    _runtime.wiki_title = _title;
    if (!_runtime.wiki_hints_enabled) return;
    if (_runtime.wiki_hint_title == _title) return;

    var _toasts_menu = ANCHOR.get_menu(Menu.InfoToasts);
    if (_toasts_menu != undefined && _toasts_menu.toasts.count() > 0) return;

    _runtime.wiki_hint_title = _title;
    __mistria_item_details_show_wiki_hint(_toasts_menu);
}

function __mistria_item_details_set_npc_wiki_title(_npc_id) {
    var _prototypes = __mistria_item_details_as_array(global[$ "__npc_prototypes"]);
    if (_npc_id < 0 || _npc_id >= array_length(_prototypes)) return;

    var _name = __mistria_item_details_npc_name(_prototypes[_npc_id], "");
    if (_name != "") {
        __mistria_item_details_set_wiki_title(_name);
    }
}

function mistria_item_details_capture_npc_context() {
    var _relationships = ANCHOR.get_menu(Menu.Relationships);
    if (_relationships != undefined && _relationships.npc_id_current != undefined) {
        __mistria_item_details_set_npc_wiki_title(_relationships.npc_id_current);
        return;
    }

    var _calendar = ANCHOR.get_menu(Menu.Calendar);
    if (_calendar == undefined || _calendar.grid_area == undefined) return;

    var _day_index = 0;
    for (var _index = 0; _index < array_length(_calendar.grid_area.children); _index++) {
        var _tile = _calendar.grid_area.children[_index];
        if (_tile.get_width() != 40 || _tile.get_height() != 40) continue;
        if (_tile.is_hovered()) {
            var _prototypes = __mistria_item_details_as_array(global[$ "__npc_prototypes"]);
            var _season = get_seasons(_calendar.time);
            for (var _npc_id = 0; _npc_id < array_length(_prototypes); _npc_id++) {
                var _prototype = _prototypes[_npc_id];
                if (_prototype.birthday.season == _season && _prototype.birthday.day == _day_index + 1) {
                    __mistria_item_details_set_npc_wiki_title(_npc_id);
                    return;
                }
            }
            return;
        }
        _day_index++;
    }
}

function mistria_item_details_update_birthday_label() {
    var _vitals = ANCHOR.get_menu(Menu.Vitals);
    if (_vitals == undefined || _vitals.mana_icon == undefined) return;

    var _label = _vitals.mana_icon.board_get("mistria_item_details_birthday_label");
    if (_label == undefined) {
        _label = ANCHOR.text(_vitals.mana_icon)
            .set_align(Align.LeftIn, Align.BottomOut)
            .set_xy(0, 3)
            .set_lut(COMMON_LUT)
            .set_text_align(TextAlign.Left)
            .disable();
        _vitals.mana_icon.board_set("mistria_item_details_birthday_label", _label);
    }

    var _names = [];
    var _prototypes = __mistria_item_details_as_array(global[$ "__npc_prototypes"]);
    for (var _npc_id = 0; _npc_id < array_length(_prototypes); _npc_id++) {
        var _birthday = __mistria_item_details_field(_prototypes[_npc_id], "birthday");
        if (_birthday == undefined
            || _birthday.season != CALENDAR.season()
            || _birthday.day != CALENDAR.day() + 1)
        {
            continue;
        }

        var _name = __mistria_item_details_npc_name(_prototypes[_npc_id], "");
        if (_name != "" && !__mistria_item_details_has_name(_names, _name)) {
            array_push(_names, _name);
        }
    }

    if (array_length(_names) == 0) {
        _label.disable();
        return;
    }

    _label.set_text("Birthday: " + __mistria_item_details_join(_names));
    _label.enable();
}

function mistria_item_details_capture_quest_item_context() {
    var _quest_log = ANCHOR.get_menu(Menu.QuestLog);
    if (_quest_log == undefined || _quest_log.right_scroller == undefined
        || _quest_log.active_quest == undefined)
    {
        return;
    }

    var _item_data = global[$ "__item_data"];
    if (!is_array(_item_data)) return;

    var _quest = QUESTS.get_unwrap(_quest_log.active_quest);
    var _active_quest = QUEST_LOG.active.get(_quest_log.active_quest);
    var _blackboard = _active_quest == undefined ? undefined : _active_quest.blackboard;
    if (_quest.tasks.is_empty()
        || !ANCHOR.point_in_node(_quest_log.right_scroller.canvas, MOUSE_GUI_X, MOUSE_GUI_Y))
    {
        return;
    }

    var _task_index = _quest_log.context == QuestLogContext.Journal
        ? min(_active_quest.current_stage, _quest.tasks.count() - 1)
        : 0;
    var _listings = gather_listings_from_requirements(
        _quest.tasks.get(_task_index).requirements,
        _blackboard
    );
    var _objective_item = undefined;
    for (var _listing_index = 0; _listing_index < _listings.count(); _listing_index++) {
        var _item = __mistria_item_details_field(_listings.get(_listing_index), "item");
        if (_item == undefined) continue;
        if (_objective_item != undefined) return;
        _objective_item = _item;
    }

    if (_objective_item == undefined) return;
    var _item_id = _objective_item.item_id;
    if (_item_id >= 0 && _item_id < array_length(_item_data)) {
        __mistria_item_details_set_wiki_title(
            __mistria_item_details_name(_item_data[_item_id])
        );
    }
}

function mistria_item_details_capture_museum_wing_context() {
    var _museum = ANCHOR.get_menu(Menu.Museum);
    if (_museum == undefined) return;

    var _title = "";
    switch _museum.canvas.board_get("selected_wing") {
        case MuseumWing.Archaeology: _title = "Archaeology Wing"; break;
        case MuseumWing.Fish: _title = "Fish Wing"; break;
        case MuseumWing.Flora: _title = "Flora Wing"; break;
        case MuseumWing.Insect: _title = "Insects Wing"; break;
    }

    if (_title != ""
        && ANCHOR.point_in_node(_museum.right_body, MOUSE_GUI_X, MOUSE_GUI_Y))
    {
        __mistria_item_details_set_wiki_title(_title);
    }
}

function mistria_item_details_map_label_think(_marker, _label, _name) {
    var _hovered = _marker.is_hovered();
    _label.set_alpha(_hovered ? 1 : 0);
    if (_hovered) {
        __mistria_item_details_set_wiki_title(_name);
    }
}

function mistria_item_details_add_map_labels() {
    var _map_menu = ANCHOR.get_menu(Menu.Map);
    if (_map_menu == undefined || _map_menu.selected_location_id == undefined) return;

    var _hubs = global[$ "__map_hubs"];
    if (!is_array(_hubs)) return;
    if (_map_menu.selected_location_id < 0
        || _map_menu.selected_location_id >= array_length(_hubs))
    {
        return;
    }
    var _location_hubs = _hubs[_map_menu.selected_location_id];
    if (!is_array(_location_hubs)) return;

    var _prototypes = __mistria_item_details_as_array(global[$ "__npc_prototypes"]);
    for (var _npc_id = 0; _npc_id < array_length(_prototypes); _npc_id++) {
        if (!is_array(NPCS) || _npc_id >= array_length(NPCS)) continue;
        if (!npc_is_unlocked(_npc_id) || !NPCS[_npc_id].has_met()) continue;

        var _icon = get_small_npc_icon(_npc_id);
        var _name = __mistria_item_details_npc_name(_prototypes[_npc_id], "");
        for (var _hub_index = 0; _hub_index < array_length(_location_hubs); _hub_index++) {
            var _hub_node = _location_hubs[_hub_index].node;
            if (_hub_node == undefined || _hub_node.freed) continue;

            for (var _child_index = 0; _child_index < array_length(_hub_node.children); _child_index++) {
                var _marker = _hub_node.children[_child_index];
                if (__mistria_item_details_field(_marker, "sprite") != _icon
                    || _marker.board_get("mistria_item_details_name_label") != undefined)
                {
                    continue;
                }

                _marker.listen_for_hovers();
                var _label = ANCHOR.text(_marker)
                    .set_text(_name)
                    .set_lut(COMMON_LUT)
                    .set_align(Align.Center, Align.BottomOut)
                    .set_y(-1)
                    .set_alpha(0);
                _label.set_think_callback(
                    mistria_item_details_map_label_think,
                    [_marker, _label, _name]
                );
                _marker.board_set("mistria_item_details_name_label", _label);
                break;
            }
        }
    }
}

function mistria_item_details_bug_marker_think(_marker, _bug_id, _is_very_rare) {
    _marker.set_enabled(
        instance_exists(_bug_id)
            && (_is_very_rare || __mistria_item_details_runtime().all_bug_markers_enabled)
    );
}

function mistria_item_details_dig_marker_label_think(_marker, _label) {
    var _count = _marker.board_get("mistria_item_details_dig_count");
    _label.set_alpha(_count > 0 && _marker.is_hovered() ? 1 : 0);
}

function mistria_item_details_add_dig_spot_map_markers() {
    var _map_menu = ANCHOR.get_menu(Menu.Map);
    if (_map_menu == undefined || _map_menu.selected_location_id == undefined) return;

    var _hubs = global[$ "__map_hubs"];
    if (!is_array(_hubs) || _map_menu.selected_location_id < 0
        || _map_menu.selected_location_id >= array_length(_hubs))
    {
        return;
    }

    var _location_hubs = _hubs[_map_menu.selected_location_id];
    if (!is_array(_location_hubs)) return;

    var _counts = array_create(array_length(_location_hubs), 0);
    var _runtime = __mistria_item_details_runtime();
    var _location = __mistria_item_details_field(LOCATIONS[CURRENT_LOCATION_ID], "map_location");
    if (_location == _map_menu.selected_location_id
        && _runtime.dig_spot_visit_key == __mistria_item_details_dig_spot_visit_key())
    {
        var _sorting_prio_queue = ds_priority_create();
        for (var _spot_index = 0;
            _spot_index < array_length(_runtime.dig_spots);
            _spot_index++)
        {
            var _spot = _runtime.dig_spots[_spot_index];
            if (!__mistria_item_details_dig_spot_active(_spot)) continue;

            var _nearest_hub = _map_menu.find_hub_for(
                _location_hubs,
                new LocationPosition(
                    CURRENT_LOCATION_ID,
                    Vec2(_spot.x, _spot.y),
                    CURRENT_DYN_INDEX
                ),
                _sorting_prio_queue,
                _map_menu.selected_location_id
            );
            if (_nearest_hub == 0) continue;

            for (var _hub_index = 0;
                _hub_index < array_length(_location_hubs);
                _hub_index++)
            {
                if (_location_hubs[_hub_index] == _nearest_hub) {
                    _counts[_hub_index]++;
                    break;
                }
            }
        }
        ds_priority_destroy(_sorting_prio_queue);
    }

    for (var _hub_index = 0;
        _hub_index < array_length(_location_hubs);
        _hub_index++)
    {
        var _hub = _location_hubs[_hub_index];
        if (_hub.node == undefined || _hub.node.freed) {
            continue;
        }

        var _marker = _hub.node.board_get("mistria_item_details_dig_marker");
        var _label = _marker == undefined
            ? undefined
            : _marker.board_get("mistria_item_details_dig_label");
        var _count = _counts[_hub_index];
        if (_count == 0) {
            if (_marker != undefined) {
                _marker.board_set("mistria_item_details_dig_count", 0);
                _marker.set_enabled(false);
            }
            if (_label != undefined) _label.set_alpha(0);
            continue;
        }

        if (_marker == undefined) {
            _marker = ANCHOR.sprite(_hub.node)
                .set_sprite(spr_ui_item_tool_rusty_shovel)
                .set_outline_sprite(spr_ui_item_tool_rusty_shovel_outline)
                .set_xy(10, -10)
                .set_lut(COMMON_LUT)
                .listen_for_hovers();
            _label = ANCHOR.text(_marker)
                .set_lut(COMMON_LUT)
                .set_align(Align.Center, Align.BottomOut)
                .set_y(-1)
                .set_alpha(0);
            _label.set_think_callback(
                mistria_item_details_dig_marker_label_think,
                [_marker, _label]
            );
            _marker.board_set("mistria_item_details_dig_label", _label);
            _hub.node.board_set("mistria_item_details_dig_marker", _marker);
        }
        _marker.board_set("mistria_item_details_dig_count", _count);
        _marker.board_set("mistria_item_details_dig_count", _count);
        _marker.board_set("mistria_item_details_dig_count", _count);
        _marker.set_enabled(true);
    }
}

function mistria_item_details_add_bug_map_markers() {
    var _map_menu = ANCHOR.get_menu(Menu.Map);
    if (_map_menu == undefined || _map_menu.selected_location_id == undefined
        || BUGS == undefined)
    {
        return;
    }

    if (LOCATIONS[CURRENT_LOCATION_ID].map_location != _map_menu.selected_location_id) {
        return;
    }

    var _hubs = global[$ "__map_hubs"];
    if (!is_array(_hubs) || _map_menu.selected_location_id < 0
        || _map_menu.selected_location_id >= array_length(_hubs))
    {
        return;
    }

    var _location_hubs = _hubs[_map_menu.selected_location_id];
    if (!is_array(_location_hubs)) return;

    for (var _bug_index = 0; _bug_index < instance_number(obj_bug); _bug_index++) {
        var _bug = instance_find(obj_bug, _bug_index);
        if (_bug.item_id == undefined) continue;

        var _bug_data = BUGS.get(_bug.item_id);
        if (_bug_data == undefined) continue;
        var _is_very_rare = _bug_data.rarity == "very_rare";
        if (!_is_very_rare
            && !__mistria_item_details_runtime().all_bug_markers_enabled)
        {
            continue;
        }

        var _nearest_hub = undefined;
        var _nearest_distance = infinity;
        for (var _hub_index = 0; _hub_index < array_length(_location_hubs); _hub_index++) {
            var _hub = _location_hubs[_hub_index];
            if (_hub.type != MapHub.Position || _hub.node == undefined || _hub.node.freed) {
                continue;
            }

            var _distance = point_distance(_hub.x, _hub.y, _bug.x, _bug.y);
            if (_distance < _nearest_distance) {
                _nearest_distance = _distance;
                _nearest_hub = _hub;
            }
        }

        if (_nearest_hub == undefined) continue;
        var _marker_key = "mistria_item_details_bug_marker_" + string(_bug.id);
        if (_nearest_hub.node.board_get(_marker_key) != undefined) continue;

        var _marker = ANCHOR.sprite(_nearest_hub.node)
            .set_sprite(ITEM_PROTOTYPES[_bug.item_id].icon_sprite)
            .set_xy(0, -10)
            .set_lut(COMMON_LUT)
            .listen_for_hovers();
        var _label = ANCHOR.text(_marker)
            .set_text(__mistria_item_details_name(global.__item_data[_bug.item_id]))
            .set_lut(COMMON_LUT)
            .set_align(Align.Center, Align.BottomOut)
            .set_y(-1)
            .set_alpha(0);
        _label.set_think_callback(
            mistria_item_details_map_label_think,
            [_marker, _label, (_is_very_rare ? "Very Rare Bug: " : "Bug: ")
                + __mistria_item_details_name(global.__item_data[_bug.item_id])]
        );
        _marker.set_think_callback(
            mistria_item_details_bug_marker_think,
            [_marker, _bug.id, _is_very_rare]
        );
        _nearest_hub.node.board_set(_marker_key, _marker);
    }
}

function __mistria_item_details_npc_needs_gift(_npc_id) {
    if (!is_array(NPCS) || _npc_id < 0 || _npc_id >= array_length(NPCS)) return false;

    var _npc = NPCS[_npc_id];
    if (_npc == undefined) return false;
    return npc_is_unlocked(_npc_id) && _npc.has_met() && _npc.gift_flag;
}

function __mistria_item_details_is_loved_gift(_item, _npc_id) {
    if (_item == undefined || !__mistria_item_details_npc_needs_gift(_npc_id)) {
        return false;
    }

    var _npc = NPCS[_npc_id];
    var _prototype = __mistria_item_details_field(_item, "prototype");
    if (_prototype == undefined || _prototype.giftable != true) return false;
    if (_prototype.tags.contains_any_value_from(_npc.prototype.banned_gift_tags)) {
        return false;
    }

    switch _item.item_id {
        case ItemId.VoidNewt: return _npc_id == NpcId.Juniper;
        case ItemId.VoidCake: return _npc_id == NpcId.Eiland;
    }

    return _item.infusion == Infusion.Loveable
        || _npc.prototype.loved_gifts.contains(_item.item_id);
}

function __mistria_item_details_gift_npcs() {
    var _result = [];
    if (!is_array(NPCS)) return _result;

    // Keep birthdays first while preserving the game's stable NPC order.
    for (var _birthday_pass = 0; _birthday_pass < 2; _birthday_pass++) {
        for (var _npc_id = 0; _npc_id < array_length(NPCS); _npc_id++) {
            if (!__mistria_item_details_npc_needs_gift(_npc_id)) continue;

            var _is_birthday = NPCS[_npc_id].is_birthday();
            if (_is_birthday != (_birthday_pass == 0)) continue;
            array_push(_result, _npc_id);
        }
    }
    return _result;
}

function __mistria_item_details_existing_room(_inventory, _item) {
    var _room = 0;
    for (var _index = 0; _index < _inventory.size(); _index++) {
        var _slot = _inventory.slot(_index);
        if (_slot.count <= 0 || _slot.item == undefined) continue;
        if (_slot.item.partial_eq(_item)) {
            _room += _slot.room_for_item(_item);
        }
    }
    return _room;
}

function __mistria_item_details_gift_units(_inventory, _npc_ids) {
    var _result = [];
    var _npc_count = array_length(_npc_ids);

    // Favor gifts that already stack in the backpack, then chest stacks that
    // can cover the most NPCs. The matching remains maximum-cardinality, while
    // this order avoids spending a scarce empty slot on a less efficient choice.
    for (var _existing_pass = 0; _existing_pass < 2; _existing_pass++) {
        for (var _score = _npc_count; _score > 0; _score--) {
            for (var _slot_index = 0; _slot_index < _inventory.size(); _slot_index++) {
                var _slot = _inventory.slot(_slot_index);
                if (_slot.count <= 0 || _slot.item == undefined) continue;

                var _loved_count = 0;
                for (var _npc_index = 0; _npc_index < _npc_count; _npc_index++) {
                    if (__mistria_item_details_is_loved_gift(
                        _slot.item,
                        _npc_ids[_npc_index]
                    )) {
                        _loved_count++;
                    }
                }

                var _unit_count = min(_slot.count, _loved_count);
                if (_unit_count != _score) continue;

                var _has_existing_room = __mistria_item_details_existing_room(
                    ARI.inventory,
                    _slot.item
                ) > 0;
                if (_has_existing_room != (_existing_pass == 0)) continue;

                for (var _unit_index = 0; _unit_index < _unit_count; _unit_index++) {
                    array_push(_result, {
                        slot_index: _slot_index,
                        item: _slot.item
                    });
                }
            }
        }
    }
    return _result;
}

function __mistria_item_details_match_gift(
    _npc_index,
    _npc_ids,
    _units,
    _unit_owners,
    _seen_units
) {
    var _npc_id = _npc_ids[_npc_index];
    for (var _unit_index = 0; _unit_index < array_length(_units); _unit_index++) {
        if (_seen_units[_unit_index]) continue;
        if (!__mistria_item_details_is_loved_gift(_units[_unit_index].item, _npc_id)) {
            continue;
        }

        _seen_units[_unit_index] = true;
        var _owner = _unit_owners[_unit_index];
        if (_owner == -1
            || __mistria_item_details_match_gift(
                _owner,
                _npc_ids,
                _units,
                _unit_owners,
                _seen_units
            ))
        {
            _unit_owners[_unit_index] = _npc_index;
            return true;
        }
    }
    return false;
}

function __mistria_item_details_gift_groups(_units) {
    var _groups = [];
    for (var _unit_index = 0; _unit_index < array_length(_units); _unit_index++) {
        var _unit = _units[_unit_index];
        var _group = undefined;
        for (var _group_index = 0; _group_index < array_length(_groups); _group_index++) {
            if (_groups[_group_index].item.partial_eq(_unit.item)) {
                _group = _groups[_group_index];
                break;
            }
        }

        if (_group == undefined) {
            var _room = ARI.inventory.room_for_item(_unit.item);
            if (_room <= 0) continue;

            _group = {
                item: _unit.item,
                units: [],
                capacity: 0,
                used: 0,
                existing_room: min(
                    _room,
                    __mistria_item_details_existing_room(ARI.inventory, _unit.item)
                )
            };
            array_push(_groups, _group);
        }

        if (_group.capacity < ARI.inventory.room_for_item(_group.item)) {
            array_push(_group.units, _unit);
            _group.capacity++;
        }
    }
    return _groups;
}

function __mistria_item_details_gift_slot_cost(_group, _count) {
    var _needs_slots = max(0, _count - _group.existing_room);
    return ceil(_needs_slots / _group.item.prototype.max_stack);
}

function __mistria_item_details_copy_array(_source) {
    var _copy = array_create(array_length(_source), -1);
    for (var _index = 0; _index < array_length(_source); _index++) {
        _copy[_index] = _source[_index];
    }
    return _copy;
}

function __mistria_item_details_gift_assignment_is_better(_state, _count) {
    if (_count > _state.best_count) return true;
    if (_count < _state.best_count) return false;

    // NPCs are birthday-first, then stable game order. At equal coverage,
    // prefer the assignment that includes the earliest eligible NPC.
    for (var _index = 0; _index < array_length(_state.assignment); _index++) {
        var _current_has_gift = _state.assignment[_index] != -1;
        var _best_has_gift = _state.best_assignment[_index] != -1;
        if (_current_has_gift != _best_has_gift) return _current_has_gift;
    }
    return false;
}

function __mistria_item_details_gift_priority_upper_can_beat(
    _state,
    _npc_index,
    _count
) {
    // Fixed choices form the prefix. Optimistically give every still-needed
    // gift to the earliest remaining NPC; if even that vector cannot outrank
    // the best assignment, no equal-count completion of this branch can.
    var _needed = _state.best_count - _count;
    for (var _index = 0; _index < array_length(_state.assignment); _index++) {
        var _optimistic_has_gift;
        if (_index < _npc_index) {
            _optimistic_has_gift = _state.assignment[_index] != -1;
        } else {
            _optimistic_has_gift = _needed > 0;
            if (_optimistic_has_gift) _needed--;
        }

        var _best_has_gift = _state.best_assignment[_index] != -1;
        if (_optimistic_has_gift != _best_has_gift) {
            return _optimistic_has_gift;
        }
    }
    return false;
}

function __mistria_item_details_gift_capacity_upper(
    _state,
    _npc_index,
    _count,
    _slots_used
) {
    var _group_count = array_length(_state.groups);
    var _extra_slots = array_create(_group_count, 0);
    var _additional_units = 0;

    // Count capacity already paid for by existing partial stacks or slots that
    // earlier assignments opened. This deliberately ignores NPC compatibility,
    // making it an admissible upper bound rather than a second matching pass.
    for (var _group_index = 0; _group_index < _group_count; _group_index++) {
        var _group = _state.groups[_group_index];
        var _paid_slots = __mistria_item_details_gift_slot_cost(
            _group,
            _group.used
        );
        var _paid_capacity = min(
            _group.capacity,
            _group.existing_room
                + _paid_slots * _group.item.prototype.max_stack
        );
        _additional_units += max(0, _paid_capacity - _group.used);
    }

    // Spend each remaining empty slot where it could add the most units. A
    // group's marginal capacity never increases, so taking the largest next
    // marginal produces the optimistic maximum across all groups.
    var _slots_left = _state.free_slots - _slots_used;
    for (var _slot = 0; _slot < _slots_left; _slot++) {
        var _best_group = -1;
        var _best_gain = 0;
        for (var _group_index = 0; _group_index < _group_count; _group_index++) {
            var _group = _state.groups[_group_index];
            var _paid_slots = __mistria_item_details_gift_slot_cost(
                _group,
                _group.used
            ) + _extra_slots[_group_index];
            var _before = min(
                _group.capacity,
                _group.existing_room
                    + _paid_slots * _group.item.prototype.max_stack
            );
            var _after = min(
                _group.capacity,
                _group.existing_room
                    + (_paid_slots + 1) * _group.item.prototype.max_stack
            );
            var _gain = _after - _before;
            if (_gain > _best_gain) {
                _best_gain = _gain;
                _best_group = _group_index;
            }
        }

        if (_best_group == -1) break;
        _extra_slots[_best_group]++;
        _additional_units += _best_gain;
    }

    var _npcs_left = array_length(_state.npc_ids) - _npc_index;
    return _count + min(_npcs_left, _additional_units);
}

function __mistria_item_details_search_gift_assignment(
    _state,
    _npc_index,
    _count,
    _slots_used
) {
    if (_state.search_nodes >= _state.search_node_limit) return;
    _state.search_nodes++;

    if (__mistria_item_details_gift_assignment_is_better(_state, _count)) {
        _state.best_count = _count;
        _state.best_assignment = __mistria_item_details_copy_array(_state.assignment);
    }
    var _capacity_upper = __mistria_item_details_gift_capacity_upper(
        _state,
        _npc_index,
        _count,
        _slots_used
    );
    if (_capacity_upper < _state.best_count
        || (_capacity_upper == _state.best_count
            && !__mistria_item_details_gift_priority_upper_can_beat(
                _state,
                _npc_index,
                _count
            )))
    {
        return;
    }
    if (_npc_index >= array_length(_state.npc_ids)) return;

    var _candidates = _state.candidates[_npc_index];
    for (var _index = 0; _index < array_length(_candidates); _index++) {
        var _group_index = _candidates[_index];
        var _group = _state.groups[_group_index];
        if (_group.used >= _group.capacity) continue;

        var _old_cost = __mistria_item_details_gift_slot_cost(_group, _group.used);
        var _new_cost = __mistria_item_details_gift_slot_cost(_group, _group.used + 1);
        var _new_slots_used = _slots_used + _new_cost - _old_cost;
        if (_new_slots_used > _state.free_slots) continue;

        _group.used++;
        _state.assignment[_npc_index] = _group_index;
        __mistria_item_details_search_gift_assignment(
            _state,
            _npc_index + 1,
            _count + 1,
            _new_slots_used
        );
        _state.assignment[_npc_index] = -1;
        _group.used--;

        if (_state.search_nodes >= _state.search_node_limit) return;
        _capacity_upper = __mistria_item_details_gift_capacity_upper(
            _state,
            _npc_index,
            _count,
            _slots_used
        );
        if (_capacity_upper < _state.best_count
            || (_capacity_upper == _state.best_count
                && !__mistria_item_details_gift_priority_upper_can_beat(
                    _state,
                    _npc_index,
                    _count
                )))
        {
            return;
        }
    }

    __mistria_item_details_search_gift_assignment(
        _state,
        _npc_index + 1,
        _count,
        _slots_used
    );
}

function __mistria_item_details_gift_plan(_chest_inventory) {
    var _npc_ids = __mistria_item_details_gift_npcs();
    var _npc_count = array_length(_npc_ids);
    var _units = __mistria_item_details_gift_units(_chest_inventory, _npc_ids);
    var _unit_count = array_length(_units);
    var _unit_owners = array_create(_unit_count, -1);

    for (var _npc_index = 0; _npc_index < _npc_count; _npc_index++) {
        __mistria_item_details_match_gift(
            _npc_index,
            _npc_ids,
            _units,
            _unit_owners,
            array_create(_unit_count, false)
        );
    }

    var _unit_for_npc = array_create(_npc_count, -1);
    var _matched_count = 0;
    for (var _unit_index = 0; _unit_index < _unit_count; _unit_index++) {
        var _owner = _unit_owners[_unit_index];
        if (_owner == -1) continue;
        _unit_for_npc[_owner] = _unit_index;
        _matched_count++;
    }

    var _groups = __mistria_item_details_gift_groups(_units);
    var _candidates = array_create(_npc_count, undefined);
    for (var _npc_index = 0; _npc_index < _npc_count; _npc_index++) {
        _candidates[_npc_index] = [];
        for (var _group_index = 0; _group_index < array_length(_groups); _group_index++) {
            if (__mistria_item_details_is_loved_gift(
                _groups[_group_index].item,
                _npc_ids[_npc_index]
            )) {
                array_push(_candidates[_npc_index], _group_index);
            }
        }
    }

    var _free_slots = 0;
    for (var _slot_index = 0; _slot_index < ARI.inventory.size(); _slot_index++) {
        var _slot = ARI.inventory.slot(_slot_index);
        if (_slot.count == 0 && _slot.item == undefined) _free_slots++;
    }

    var _state = {
        npc_ids: _npc_ids,
        groups: _groups,
        candidates: _candidates,
        free_slots: _free_slots,
        target_count: _matched_count,
        assignment: array_create(_npc_count, -1),
        best_assignment: array_create(_npc_count, -1),
        best_count: 0,
        // Exact search is fast for ordinary chest contents, but fixed-charge
        // backpack slots make adversarial preference sets combinatorial. Keep
        // the click bounded and retain the best birthday-first plan found.
        search_nodes: 0,
        search_node_limit: 2048
    };
    __mistria_item_details_search_gift_assignment(_state, 0, 0, 0);

    var _used_by_group = array_create(array_length(_groups), 0);
    var _plan = [];
    for (var _npc_index = 0; _npc_index < _npc_count; _npc_index++) {
        var _group_index = _state.best_assignment[_npc_index];
        if (_group_index == -1) continue;

        var _group = _groups[_group_index];
        var _unit = _group.units[_used_by_group[_group_index]];
        _used_by_group[_group_index]++;
        array_push(_plan, {
            npc_id: _npc_ids[_npc_index],
            slot_index: _unit.slot_index,
            item: _unit.item
        });
    }

    return {
        eligible_count: _npc_count,
        matched_count: _matched_count,
        capacity_count: _state.best_count,
        entries: _plan
    };
}

function mistria_item_details_collect_loved_gifts(_menu) {
    if (ANCHOR.get_menu(Menu.Storage) != _menu) return;

    var _left_menu = __mistria_item_details_field(_menu, "left_menu");
    var _right_menu = __mistria_item_details_field(_menu, "right_menu");
    if (_left_menu == undefined || _right_menu == undefined) return;

    var _hand = __mistria_item_details_field(_left_menu, "hand");
    if (_hand == undefined || _hand.size() == 0) return;
    if (_hand.slot(0).item != undefined) {
        create_notification(
            ANCHOR.wrap_for_local("Put down the held item before grabbing gifts."),
            60 * 3
        );
        return;
    }

    var _chest_inventory = __mistria_item_details_field(_menu, "left");
    if (_chest_inventory == undefined) return;

    var _gift_plan = __mistria_item_details_gift_plan(_chest_inventory);
    if (_gift_plan.eligible_count == 0) {
        create_notification(
            ANCHOR.wrap_for_local("Every met villager has already received a gift today."),
            60 * 3
        );
        return;
    }
    if (_gift_plan.matched_count == 0) {
        create_notification(
            ANCHOR.wrap_for_local("This chest has no loved gifts for ungifted villagers."),
            60 * 3
        );
        return;
    }

    var _moved = 0;
    for (var _index = 0; _index < array_length(_gift_plan.entries); _index++) {
        var _entry = _gift_plan.entries[_index];
        var _slot = _chest_inventory.slot(_entry.slot_index);
        if (_slot.count <= 0 || _slot.item == undefined) continue;
        if (!_slot.item.partial_eq(_entry.item)) continue;
        if (!ARI.inventory.can_add(_slot.item, 1)) continue;
        if (ARI.inventory.add(_slot.item.clone(), 1) != 0) continue;

        _slot.remove(1);
        _moved++;
    }

    _left_menu.refresh();
    _right_menu.refresh();

    if (_moved == 0) {
        create_notification(
            ANCHOR.wrap_for_local("No loved gifts fit in your backpack."),
            60 * 3
        );
    } else if (_moved < _gift_plan.matched_count) {
        create_notification(
            ANCHOR.wrap_for_local(
                "Grabbed " + string(_moved) + " of "
                    + string(_gift_plan.matched_count)
                    + " loved gifts; your backpack is full."
            ),
            60 * 3
        );
    } else {
        create_notification(
            ANCHOR.wrap_for_local(
                "Grabbed " + string(_moved) + " loved gift"
                    + (_moved == 1 ? "" : "s") + "."
            ),
            60 * 3
        );
    }
}

function mistria_item_details_chest_gift_button_think(_button, _label) {
    _label.set_alpha(_button.is_hovered() ? 1 : 0);
}

function mistria_item_details_add_chest_gift_button() {
    var _menu = ANCHOR.get_menu(Menu.Storage);
    if (_menu == undefined) return;

    var _node = __mistria_item_details_field(_menu, "node");
    var _left = __mistria_item_details_field(_menu, "left");
    var _right = __mistria_item_details_field(_menu, "right");
    var _left_box = __mistria_item_details_field(_menu, "left_box");
    var _left_menu = __mistria_item_details_field(_menu, "left_menu");
    var _left_banner = __mistria_item_details_field(_menu, "left_banner");
    if (_node == undefined || _left == undefined || _right != ARI.inventory
        || _left_box == undefined || _left_menu == undefined || _left_banner == undefined)
    {
        return;
    }
    if (__mistria_item_details_field(_menu, "recipe") != undefined) return;
    if (__mistria_item_details_field(_node, "inventory") != _left) return;
    var _object_id = __mistria_item_details_field(_node, "object_id");
    if (_object_id == ObjectId.AutoFeeder || _object_id == ObjectId.TurnInBox) return;

    var _prototype = __mistria_item_details_field(_node, "prototype");
    var _chest = __mistria_item_details_field(_prototype, "interaction_chest");
    if (_chest == undefined || __mistria_item_details_field(_chest, "shipping_bin") == true) {
        return;
    }

    var _canvas = __mistria_item_details_field(_menu, "canvas");
    if (_canvas == undefined
        || _canvas.board_get("mistria_item_details_gift_button") != undefined)
    {
        return;
    }

    var _button = ANCHOR.sprite(_left_box)
        .set_align(Align.RightIn, Align.TopOut)
        .set_xy(-2, 0)
        .set_size(22)
        .set_sprites_from_key("spr_ui_button")
        .set_tap_sound("SoundEffects/UI/UIExtraPositiveClick")
        .add_hover_outline()
        .add_to_pilot(_left_menu.pilot)
        .set_tap_callback(mistria_item_details_collect_loved_gifts, [_menu]);

    ANCHOR.sprite(_button)
        .set_sprite(spr_ui_journal_relationship_gift_icon)
        .set_align(Align.Center, Align.Middle);

    var _label = ANCHOR.text(_button)
        .set_text("Grab loved gifts")
        .set_lut(COMMON_LUT)
        .set_text_align(TextAlign.Center)
        .set_align(Align.Center, Align.TopOut)
        .set_y(-2)
        .set_alpha(0);
    _label.set_think_callback(
        mistria_item_details_chest_gift_button_think,
        [_button, _label]
    );

    _canvas.board_set("mistria_item_details_gift_button", _button);
}

function __mistria_item_details_for_item(_item_id) {
    var _item_data = global[$ "__item_data"];
    if (!is_array(_item_data) || _item_id < 0 || _item_id >= array_length(_item_data)) return undefined;

    var _target = _item_data[_item_id];
    var _item_key = __mistria_item_details_field(_target, "recipe_key");
    if (_item_key == undefined) _item_key = "";
    var _recipes = [];
    for (var _recipe_id = 0; _recipe_id < array_length(_item_data); _recipe_id++) {
        if (__mistria_item_details_recipe_uses_item(_item_data[_recipe_id], _item_id, _item_key)) {
            var _recipe_name = __mistria_item_details_name(_item_data[_recipe_id]);
            if (!__mistria_item_details_has_name(_recipes, _recipe_name)) {
                array_push(_recipes, _recipe_name);
            }
        }
    }

    var _liked = [];
    var _loved = [];
    var _npc_data = __mistria_item_details_as_array(global[$ "__npc_prototypes"]);
    if (array_length(_npc_data) > 0) {
        var _count = array_length(_npc_data);
        for (var _npc_id = 0; _npc_id < _count; _npc_id++) {
                var _npc = _npc_data[_npc_id];
                var _name = __mistria_item_details_npc_name(_npc, "Unknown");
                var _loved_gifts = __mistria_item_details_field(_npc, "loved_gifts");
                var _liked_gifts = __mistria_item_details_field(_npc, "liked_gifts");
                if (__mistria_item_details_contains(_loved_gifts, _item_id, _item_key)) {
                    array_push(_loved, _name);
                } else if (__mistria_item_details_contains(_liked_gifts, _item_id, _item_key)) {
                    array_push(_liked, _name);
                }
        }
    }

    return {
        recipes: __mistria_item_details_recipe_summary(_recipes),
        liked: __mistria_item_details_join(_liked),
        loved: __mistria_item_details_join(_loved)
    };
}

function mistria_item_details_description(_value, _ctx) {
    if (_value == undefined || _ctx == undefined) return undefined;
    var _item = __mistria_item_details_field(_ctx, "item");
    var _item_id = __mistria_item_details_field(_item, "item_id");
    if (_item_id == undefined) return undefined;

    var _cache_key = string(_item_id);
    var _runtime = __mistria_item_details_runtime();
    var _item_data = global[$ "__item_data"];
    if (is_array(_item_data) && _item_id >= 0 && _item_id < array_length(_item_data)) {
        __mistria_item_details_set_wiki_title(__mistria_item_details_name(_item_data[_item_id]));
    }
    var _details = __mistria_item_details_field(_runtime.cache, _cache_key);
    if (_details == undefined) {
        _details = __mistria_item_details_for_item(_item_id);
        _runtime.cache[$ _cache_key] = _details;
    }

    if (_details == undefined) return undefined;
    if (_details.recipes == "" && _details.liked == "" && _details.loved == "") return undefined;

    // The shop tooltip has limited vertical space; retain actionable mod data
    // there and let the game's health/stamina footer remain visible.
    var _result = ANCHOR.get_menu(Menu.Store) != undefined ? "" : _value;
    if (_details.recipes != "") {
        if (_result != "") _result += "\n";
        _result += "Uses: " + _details.recipes;
    }
    if (_details.liked != "") {
        if (_result != "") _result += "\n";
        _result += "Liked by: " + _details.liked;
    }
    if (_details.loved != "") {
        if (_result != "") _result += "\n";
        _result += "Loved by: " + _details.loved;
    }
    return _result;
}

function mistria_item_details_register() {
    var _runtime = __mistria_item_details_runtime();
    if (_runtime.registered) return;
    _runtime.registered = true;
    mmapi_filter("item.display_description", mistria_item_details_description);
    var _wiki_binding = mmapi_hotkey_binding_from_name("F7");
    if (_wiki_binding != undefined) {
        mmapi_hotkey_register_binding(_wiki_binding, mistria_item_details_open_wiki);
    }
    var _wiki_hints_binding = mmapi_hotkey_binding_from_name("F8");
    if (_wiki_hints_binding != undefined) {
        mmapi_hotkey_register_binding(_wiki_hints_binding, mistria_item_details_toggle_wiki_hints);
    }
    var _legendary_binding = mmapi_hotkey_binding_from_name("F6");
    if (_legendary_binding != undefined) {
        mmapi_hotkey_register_binding(_legendary_binding, mistria_item_details_show_legendary_sightings);
    }
    var _clock_binding = mmapi_hotkey_binding_from_name("F5");
    if (_clock_binding != undefined) {
        mmapi_hotkey_register_binding(_clock_binding, mistria_item_details_toggle_clock);
    }
    var _bug_markers_binding = mmapi_hotkey_binding_from_name("F9");
    if (_bug_markers_binding != undefined) {
        mmapi_hotkey_register_binding(
            _bug_markers_binding,
            mistria_item_details_toggle_all_bug_markers
        );
    }
    var _dig_notifications_binding = mmapi_hotkey_binding_from_name("F10");
    if (_dig_notifications_binding != undefined) {
        mmapi_hotkey_register_binding(
            _dig_notifications_binding,
            mistria_item_details_toggle_dig_spot_notifications
        );
    }
    mmapi_register(mistria_item_details_capture_npc_context);
    mmapi_register(mistria_item_details_update_birthday_label);
    mmapi_register(mistria_item_details_capture_quest_item_context);
    mmapi_register(mistria_item_details_capture_museum_wing_context);
    mmapi_register(mistria_item_details_add_map_labels);
    mmapi_register(mistria_item_details_detect_dig_spots);
    mmapi_register(mistria_item_details_add_dig_spot_map_markers);
    mmapi_register(mistria_item_details_add_bug_map_markers);
    mmapi_register(mistria_item_details_add_chest_gift_button);
    mmapi_register(mistria_item_details_track_legendary_spawns);
    mmapi_register(mistria_item_details_show_mine_bug_spawns);
}

mmapi_mod_declare("mistria_item_details", "1.0.36");
mistria_item_details_register();
