package com.chaos.engine.events;

import haxe.Json;
import openfl.display.DisplayObject;
import openfl.events.Event;

/** Sends the small, public event payload from a running CHAOS project. */
class ServerEventService {
    public var active:Bool = false;
    public var report:String->Void = function(message) trace(message);
    /** Delivers the `data` object returned by the server to the runtime owner. */
    public var onData:Dynamic->Void = function(_) {};
    private var config:Dynamic;
    #if js
    private var socket:js.html.WebSocket;
    private var reconnectGeneration:Int = 0;
    #end

    public function new() {}

    public function configure(json:String):Bool {
        try {
            var next:Dynamic = Json.parse(json);
            var transport:String = next.transport;
            if (transport != "none" && transport != "rest" && transport != "websocket") return false;
            var url:String = transport == "rest" ? next.restEndpoint : next.websocketUrl;
            if (transport != "none" && !validUrl(url, transport)) return false;
            close();
            config = next;
            if (active) connect();
            return true;
        } catch (_:Dynamic) { return false; }
    }

    private function validUrl(url:String, transport:String):Bool {
        #if js
        try {
            var parsed = new js.html.URL(url);
            return parsed.hostname != "" && parsed.username == "" && parsed.password == ""
                && (transport == "rest" ? parsed.protocol == "http:" || parsed.protocol == "https:"
                    : parsed.protocol == "ws:" || parsed.protocol == "wss:");
        } catch (_:Dynamic) { return false; }
        #else
        return false;
        #end
    }

    public function start():Void { active = true; connect(); }
    public function stop():Void { active = false; close(); }
    public function dispose():Void { stop(); config = null; }

    private function close():Void {
        #if js
        reconnectGeneration++;
        if (socket != null) {
            socket.onclose = null;
            socket.onerror = null;
            try socket.close() catch (_:Dynamic) {}
            socket = null;
        }
        #end
    }

    private function connect():Void {
        #if js
        if (!active || config == null || config.transport != "websocket" || socket != null) return;
        var generation = reconnectGeneration;
        try {
            var connection = new js.html.WebSocket(config.websocketUrl);
            socket = connection;
            connection.onclose = function(_) {
                if (socket == connection) socket = null;
                if (active && generation == reconnectGeneration)
                    haxe.Timer.delay(function() { if (active && generation == reconnectGeneration) connect(); }, 2000);
            };
            connection.onerror = function(_) report("ServerEventService: WebSocket connection failed");
            connection.onmessage = function(message) {
                if (active && socket == connection) receive(Std.string(message.data));
            };
        } catch (error:Dynamic) { report("ServerEventService: " + Std.string(error)); }
        #end
    }

    public function send(component:DisplayObject, componentType:String, eventType:String, incoming:Event, settings:Dynamic):Void {
        if (!active || config == null || config.transport == "none" || settings == null || settings.enabled != true) return;
        var selected:Dynamic = settings.events == null ? null : Reflect.field(settings.events, eventType);
        if (selected == false) return;
        var data:Dynamic = {};
        if (eventType == "OnChange") {
            var input:Dynamic = Reflect.getProperty(component, "textField");
            if (input != null) {
                var text:Dynamic = Reflect.getProperty(input, "text");
                if (Std.isOfType(text, String)) Reflect.setField(data, "value", text);
            }
            for (field in ["value", "selected", "selectedIndex", "text"]) {
                var value:Dynamic = Reflect.getProperty(component, field);
                if (Std.isOfType(value, String) || Std.isOfType(value, Bool) || Std.isOfType(value, Int) || Std.isOfType(value, Float))
                    Reflect.setField(data, field == "text" ? "value" : field, value);
            }
        }
        var payload:Dynamic = {
            event: eventType == "OnChange" ? "change" : eventType.charAt(0).toLowerCase() + eventType.substr(1),
            component: {id: component.name, name: component.name, type: componentType},
            project: config.project,
            timestamp: Date.now().toString(),
            data: data
        };
        #if js
        payload.timestamp = new js.lib.Date().toISOString();
        try {
            if (config.transport == "websocket") payload.type = "ui-event";
            var body = Json.stringify(payload);
            if (config.transport == "websocket") {
                if (socket != null && socket.readyState == 1) socket.send(body);
                else connect();
            } else if (config.transport == "rest") {
                var request = new haxe.Http(config.restEndpoint);
                request.setHeader("Content-Type", "application/json");
                request.setPostData(body);
                request.onData = function(response) { if (active) receive(response); };
                request.onError = function(error) report("ServerEventService: " + error);
                request.request(true);
            }
        } catch (error:Dynamic) { report("ServerEventService: " + Std.string(error)); }
        #end
    }

    private function receive(response:String):Void {
        try {
            var envelope:Dynamic = Json.parse(response);
            var data:Dynamic = Reflect.field(envelope, "data");
            if (data == null || !Reflect.isObject(data) || Std.isOfType(data, Array)) {
                report("ServerEventService: response must contain a data object");
                return;
            }
            onData(data);
        } catch (error:Dynamic) {
            report("ServerEventService: invalid response JSON: " + Std.string(error));
        }
    }
}
