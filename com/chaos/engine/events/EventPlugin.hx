package com.chaos.engine.events;

import haxe.Json;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.events.Event;
import openfl.events.IEventDispatcher;
import com.chaos.engine.CommandCentral;
import com.chaos.engine.plugin.CoreCommandPlugin;

/** One instance per display runtime. Commands receive resolved targets, never global lookup results. */
class EventPlugin {
    private static var commandAdapters:Map<String, DisplayObject->Dynamic->Dynamic> = new Map();

    /** Plugins register a payload builder; execution always goes through CommandCentral. */
    public static function registerCommandAdapter(plugin:String, command:String, adapter:DisplayObject->Dynamic->Dynamic):Void {
        commandAdapters.set(Json.stringify([plugin, command]), adapter);
    }

    public static function removeCommandAdapter(plugin:String, command:String):Void {
        commandAdapters.remove(Json.stringify([plugin, command]));
    }

    public var audio(default, null):EventAudio = new EventAudio();
    public var enabled:Bool = true;
    public var report:String->Void;
    public var afterAction:Void->Void;
    public var ownerScope:Dynamic = {type:"DisplayEngine", name:""};
    private var root:DisplayObjectContainer;
    private var listeners:Map<String, Array<{receiver:IEventDispatcher, name:String, callback:Event->Void}>> = new Map();
    private var executing:Bool = false;

    public function new(root:DisplayObjectContainer) {
        this.root = root;
        audio.report = function(message) report(message);
        report = function(message) { trace(message); };
    }

    public function clear():Void {
        for (key in listeners.keys()) remove(key);
    }

    public function refresh(store:EventConfigurationStore):Void {
        clear();
        for (config in store.all()) replace(config);
    }

    /** Remove definitions belonging to a deleted subtree, including queued edits. */
    public function forgetSubtree(name:String, store:EventConfigurationStore):Void {
        var target:DisplayObject;
        try { target = resolve(name, null); } catch (_:Dynamic) { return; }
        for (config in store.all()) {
            try {
                var source = resolve(config.name, config.scope);
                var node:DisplayObject = source;
                while (node != null && node != target) node = node.parent;
                if (node == target) store.remove(config.scope, config.name);
            } catch (_:Dynamic) {}
        }
        clear();
    }

    public function dispose():Void { audio.dispose(); clear(); enabled = false; root = null; afterAction = null; }

    private function remove(key:String):Void {
        var entries = listeners.get(key);
        if (entries != null) for (entry in entries) entry.receiver.removeEventListener(entry.name, entry.callback);
        listeners.remove(key);
    }

    private function matches(node:DisplayObject, name:String, found:Array<DisplayObject>):Void {
        if (node.name == name) found.push(node);
        if (Std.isOfType(node, DisplayObjectContainer)) {
            var container:DisplayObjectContainer = cast node;
            for (i in 0...container.numChildren) matches(container.getChildAt(i), name, found);
        }
    }

    private function resolve(name:String, scope:Dynamic):DisplayObject {
        if (root == null || name == null || name == '') throw 'Missing target name';
        if (scope != null && scope.type == 'DisplayEngine' && ownerScope.type != 'DisplayEngine')
            throw 'Root project scope is not active in this editor';
        var area:DisplayObject = root;
        if (scope != null && scope.type != 'DisplayEngine' && !(scope.type == ownerScope.type && scope.name == ownerScope.name)) {
            if (scope.type != 'Screen' && scope.type != 'Element') throw 'Unsupported scope';
            var scopes:Array<DisplayObject> = [];
            matches(root, scope.name, scopes);
            if (scopes.length != 1) throw 'Missing or ambiguous active scope ' + scope.name;
            area = scopes[0];
        }
        var found:Array<DisplayObject> = [];
        matches(area, name, found);
        if (found.length != 1) throw 'Missing or ambiguous target ' + name;
        return found[0];
    }

    public function replace(config:Dynamic):Void {
        var key = Json.stringify([config.scope.type, config.scope.name, config.name]);
        remove(key);
        var entries:Array<{receiver:IEventDispatcher, name:String, callback:Event->Void}> = [];
        listeners.set(key, entries);
        try {
            if ((cast config.events:Array<Dynamic>).length == 0) return;
            var source = resolve(config.name, config.scope);
            var capability:Dynamic = Reflect.field(EventCapabilities.catalog, config.componentType);
            if (capability == null) throw 'Unsupported component ' + config.componentType;
            var seen:Map<String,Bool> = new Map();
            for (event in (cast config.events:Array<Dynamic>)) {
                if (seen.exists(event.type)) throw 'Duplicate event ' + event.type;
                seen.set(event.type, true);
            }
            for (event in (cast config.events:Array<Dynamic>)) {
                if (event.enabled == false) continue;
                var binding:Dynamic = null;
                for (candidate in (cast capability.events:Array<Dynamic>)) if (candidate.type == event.type) binding = candidate;
                if (binding == null) { report('EventPlugin ' + key + ': unsupported event ' + event.type); continue; }
                var receiver:IEventDispatcher = binding.receiver == '' ? cast source : cast Reflect.getProperty(source, binding.receiver);
                if (receiver == null) throw 'Missing event receiver ' + binding.receiver;
                var direct:Bool = binding.source == 'receiver';
                var callback:Event->Void = function(incoming) {
                    if (!enabled || executing || (direct && incoming.target != receiver)) return;
                    // Detached/replaced sources must never keep executing old configurations.
                    try { if (resolve(config.name, config.scope) != source) return; } catch (_:Dynamic) { return; }
                    executing = true;
                    try { execute(config, event); } catch (error:Dynamic) { report('EventPlugin ' + key + ': ' + Std.string(error)); }
                    executing = false;
                };
                receiver.addEventListener(binding.eventName, callback);
                entries.push({receiver:receiver, name:binding.eventName, callback:callback});
            }
        } catch (error:Dynamic) { remove(key); report('EventPlugin ' + key + ': ' + Std.string(error)); }
    }

    private function execute(config:Dynamic, event:Dynamic):Void {
        var ordered:Array<{action:Dynamic,index:Int,order:Float}> = [];
        var actions:Array<Dynamic> = cast event.actions;
        for (i in 0...actions.length) {
            var action = actions[i];
            if (action == null || action.enabled == false) continue;
            var order:Float = Std.isOfType(action.order, Float) ? action.order : i;
            if (!Math.isFinite(order)) order = i;
            ordered.push({action:action,index:i,order:order});
        }
        ordered.sort(function(a,b) return a.order < b.order ? -1 : a.order > b.order ? 1 : a.index - b.index);
        for (entry in ordered) {
            var action = entry.action;
            try {
                if (action.plugin == 'CoreMediaPlugin' && EventAudio.supports(action.command)) {
                    audio.execute(action);
                    continue;
                }
                var adapter = commandAdapters.get(Json.stringify([action.plugin, action.command]));
                var uiUpdate = action.plugin == 'CoreUIFrameworkPlugin' && action.command == 'UpdateItem';
                if ((!uiUpdate && adapter == null) || !CommandCentral.hasPlugin(action.plugin)
                    || !CommandCentral.hasCommand(action.command)) throw 'Unsupported plugin/command';
                var target = resolve(action.target, action.targetScope);
                var properties:Dynamic = Json.parse(Json.stringify(action.properties));
                if (properties == null || !Reflect.isObject(properties) || Std.isOfType(properties, Array)) throw 'Invalid properties';
                if (adapter != null) {
                    CommandCentral.runCommand(action.command, adapter(target, properties));
                    if (afterAction != null) afterAction();
                    continue;
                }
                if (Reflect.hasField(properties, 'name')) throw 'Renaming through event actions is unsupported';
                if (Std.isOfType(Reflect.field(properties, 'image'), String)) {
                    var image = CommandCentral.runCommand("GetImage", {image:properties.image});
                    if (image == null) throw 'Missing image ' + properties.image;
                    properties.image = image;
                }
                Reflect.setField(properties, 'redraw', true);
                var wrapped:Dynamic = {};
                Reflect.setField(wrapped, Type.getClassName(Type.getClass(target)).split('.').pop(), properties);
                CommandCentral.runCommand(action.command, {name:action.target, data:wrapped, _resolvedEventTarget:target});
                if (afterAction != null) afterAction();
            } catch (error:Dynamic) {
                report('EventPlugin source=' + config.name + ' event=' + event.type + ' action=' + action.id
                    + ' target=' + action.target + ' plugin=' + action.plugin + ' command=' + action.command + ': ' + Std.string(error));
            }
        }
    }
}
