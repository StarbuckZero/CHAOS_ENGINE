package com.chaos.engine.events;

import haxe.Json;

/** Stores validated event configurations and pending commands for one runtime. */
class EventConfigurationStore {
    /** Command name used to submit an event configuration to the engine. */
    public static inline var COMMAND:String = "SetComponentEvents";
    private var pending:Map<String, Dynamic> = new Map();
    private var configurations:Map<String, Dynamic> = new Map();

    /** Callback invoked after an accepted configuration changes. */
    public var onChanged:Dynamic->Void;
    /** Creates an empty event configuration store. */
    public function new() {}

    /** Parses and queues valid JSON configuration, returning false on invalid input. */
    public function enqueue(json:String):Bool {
        try {
            var data:Dynamic = Json.parse(json);
            if (!valid(data)) return false;
            pending.set(key(data.scope, data.name), copy(data));
            return true;
        } catch (error:Dynamic) { return false; }
    }

    /** Returns queued command objects and clears the pending queue. */
    public function takePendingCommands():Array<Dynamic> {
        var commands:Array<Dynamic> = [];
        for (data in pending) {
            var command:Dynamic = {};
            Reflect.setField(command, COMMAND, data);
            commands.push(command);
        }
        pending = new Map();
        return commands;
    }

    /** The owning engine injects the receiver after JSON parsing, before dispatch. */
    public static function applyCommand(data:Dynamic):Dynamic {
        if (data == null || !Reflect.isObject(data)) return null;
        var receiver:Dynamic = Reflect.field(data, "_eventConfigurationStore");
        if (Std.isOfType(receiver, EventConfigurationStore)) {
            var store:EventConfigurationStore = cast receiver;
            store.accept(data);
        }
        return null;
    }

    /** Saves a valid configuration and optionally notifies the change callback. */
    public function accept(data:Dynamic, notify:Bool = true):Bool {
        if (!valid(data)) return false;
        configurations.set(key(data.scope, data.name), copy(data));
        if (notify && onChanged != null) onChanged(copy(data));
        return true;
    }

    /** Returns a copy of the configuration identified by scope and name. */
    public function get(scope:Dynamic, name:String):Dynamic {
        var data:Dynamic = configurations.get(key(scope, name));
        return data == null ? null : copy(data);
    }

    /** Returns copies of every accepted configuration. */
    public function all():Array<Dynamic> {
        return [for (data in configurations) copy(data)];
    }

    /** Removes matching accepted and pending configurations. */
    public function remove(scope:Dynamic, name:String):Void {
        var id = key(scope, name);
        pending.remove(id);
        configurations.remove(id);
    }

    /** Rekey accepted and queued configurations together so late delivery cannot restore old names. */
    public function renameSource(scope:Dynamic, oldName:String, newName:String):Void {
        for (map in [configurations, pending]) {
            var oldKey = key(scope, oldName);
            var data = map.get(oldKey);
            if (data != null) {
                map.remove(oldKey);
                data.name = newName;
                map.set(key(scope, newName), data);
            }
        }
    }

    /** Renames a scope and matching action targets in accepted and pending data. */
    public function renameScope(type:String, oldName:String, newName:String):Void {
        for (map in [configurations, pending]) {
            var entries = [for (data in map) data];
            map.clear();
            for (data in entries) {
                if (data.scope.type == type && data.scope.name == oldName) data.scope.name = newName;
                for (event in (cast data.events:Array<Dynamic>)) for (action in (cast event.actions:Array<Dynamic>)) {
                    if (action != null && action.targetScope != null && action.targetScope.type == type && action.targetScope.name == oldName)
                        action.targetScope.name = newName;
                }
                map.set(key(data.scope, data.name), data);
            }
        }
    }

    /** Clears all accepted configurations and pending commands. */
    public function clear():Void {
        pending = new Map();
        configurations = new Map();
    }

    private static function key(scope:Dynamic, name:String):String {
        return Json.stringify([scope == null ? null : scope.type, scope == null ? null : scope.name, name]);
    }

    private static function valid(data:Dynamic):Bool {
        if (data == null || !Reflect.isObject(data) || data.schemaVersion != 1) return false;
        if (!Std.isOfType(data.name, String) || data.name == "" || !Std.isOfType(data.componentType, String) || data.componentType == "") return false;
        var scope:Dynamic = data.scope;
        if (scope == null || !Reflect.isObject(scope) || !Std.isOfType(scope.name, String)) return false;
        if (scope.type != "DisplayEngine" && scope.type != "Screen" && scope.type != "Element") return false;
        if (scope.type != "DisplayEngine" && scope.name == "") return false;
        if (!Std.isOfType(data.events, Array)) return false;
        for (event in (cast data.events:Array<Dynamic>)) {
            if (event == null || !Reflect.isObject(event) || !Std.isOfType(event.type, String) || !Std.isOfType(event.actions, Array)) return false;
        }
        return true;
    }

    private static function copy(data:Dynamic):Dynamic {
        // Exclude dispatcher-injected runtime fields from the stored snapshot.
        return Json.parse(Json.stringify({schemaVersion: 1, name: data.name, componentType: data.componentType,
            scope: {type: data.scope.type, name: data.scope.name}, events: data.events,
            serverEvents: data.serverEvents}));
    }
}
