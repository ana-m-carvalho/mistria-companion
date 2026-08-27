function __mistria_item_details_runtime() {
    if (global[$ "__mistria_item_details"] == undefined) {
        global.__mistria_item_details = {
            registered: false,
            cache: {},
            wiki_title: "",
            wiki_hint_title: "",
            wiki_hints_enabled: true,
            legendary_day: "",
            legendary_sightings: [],
            mine_bug_floor: "",
            mine_bug_delay: -1
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

function mistria_item_details_bug_marker_think(_marker, _bug_id) {
    _marker.set_enabled(instance_exists(_bug_id));
}

function mistria_item_details_add_very_rare_bug_map_markers() {
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
        if (_bug_data == undefined || _bug_data.rarity != "very_rare") continue;

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
            [_marker, _label, "Very Rare Bug: "
                + __mistria_item_details_name(global.__item_data[_bug.item_id])]
        );
        _marker.set_think_callback(
            mistria_item_details_bug_marker_think,
            [_marker, _bug.id]
        );
        _nearest_hub.node.board_set(_marker_key, _marker);
    }
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
    mmapi_register(mistria_item_details_capture_npc_context);
    mmapi_register(mistria_item_details_update_birthday_label);
    mmapi_register(mistria_item_details_capture_quest_item_context);
    mmapi_register(mistria_item_details_capture_museum_wing_context);
    mmapi_register(mistria_item_details_add_map_labels);
    mmapi_register(mistria_item_details_add_very_rare_bug_map_markers);
    mmapi_register(mistria_item_details_track_legendary_spawns);
    mmapi_register(mistria_item_details_show_mine_bug_spawns);
}

mmapi_mod_declare("mistria_item_details", "1.0.35");
mistria_item_details_register();
