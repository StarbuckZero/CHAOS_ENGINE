package com.chaos.engine.events;

import com.chaos.engine.CommandCentral;
import com.chaos.media.SoundManager;
import com.chaos.media.event.SoundStatusEvent;

/** Per-preview audio assets, loading queue and playback; commands stay in CoreMediaPlugin. */
class EventAudio {
    public var manager(default, null):SoundManager = new SoundManager();
    public var report:String->Void;
    private var assets:Map<String,Dynamic> = new Map();
    private var loading:Map<String,Bool> = new Map();
    private var ready:Map<String,Bool> = new Map();
    private var pending:Map<String,Array<Dynamic>> = new Map();

    public function new() {
        report = function(message) trace(message);
        manager.addEventListener(SoundStatusEvent.SOUND_LOADED, loaded);
        manager.addEventListener(SoundStatusEvent.SOUND_ERROR, failed);
    }

    public static function supports(command:String):Bool {
        return ['SoundLoad','SoundPlay','SoundPause','SoundStop','SoundSeek','SoundVolume'].indexOf(command) >= 0;
    }

    public function configure(json:String):Bool {
        try {
            var data:Dynamic = haxe.Json.parse(json);
            if (!Std.isOfType(data, Array)) return false;
            var next:Map<String,Dynamic> = new Map();
            for (asset in (cast data:Array<Dynamic>)) {
                if (asset == null || !Std.isOfType(asset.name,String) || asset.name == '' || !Std.isOfType(asset.url,String) || next.exists(asset.name)) return false;
                next.set(asset.name, asset);
            }
            for (name in assets.keys()) if (!next.exists(name) || next.get(name).url != assets.get(name).url) {
                manager.stopSound(name); manager.removeSound(name); ready.remove(name); pending.remove(name); loading.remove(name);
            }
            assets = next;
            return true;
        } catch (_:Dynamic) { return false; }
    }

    public function execute(action:Dynamic):Void {
        var name:String = action.target;
        if (!supports(action.command) || !CommandCentral.hasPlugin('CoreMediaPlugin') || !CommandCentral.hasCommand(action.command)) throw 'Unsupported media command';
        if (action.targetScope != null && action.targetScope.type != 'Sound') throw 'Choose an audio asset target';
        if (!assets.exists(name) || assets.get(name).url == '') throw 'Missing sound asset ' + name;
        var properties:Dynamic = action.properties;
        if (properties == null) properties = {};
        var payload:Dynamic = {name:name, _soundManager:manager};
        if (action.command == 'SoundVolume' || action.command == 'SoundSeek') {
            var key = action.command == 'SoundVolume' ? 'volume' : 'position';
            var value:Dynamic = Reflect.field(properties, key);
            if (!Std.isOfType(value, Float) || !Math.isFinite(value) || value < 0) throw 'Invalid sound ' + key;
            if (key == 'volume' && (value > 100 || Math.floor(value) != value)) throw 'Volume must be an integer from 0 to 100';
            Reflect.setField(payload,key,value);
        }
        if (action.command == 'SoundLoad') {
            // Loading is asynchronous; never block the JSON reader or auto-play after preview stops.
            if (loading.exists(name)) throw 'Sound is already loading: ' + name;
            pending.set(name, []);
            if (properties.autoStart == true) pending.get(name).push({command:'SoundPlay',payload:payload});
            load(name, properties.repeatSound == true);
            return;
        }
        if (ready.get(name) == true) { CommandCentral.runCommand(action.command,payload); return; }
        var queued = pending.get(name);
        if (queued == null) { queued = []; pending.set(name,queued); }
        queued.push({command:action.command,payload:payload});
        if (!loading.exists(name)) load(name, assets.get(name).repeatSound == true);
    }

    private function load(name:String, repeat:Bool):Void {
        ready.remove(name); loading.set(name,true);
        CommandCentral.runCommand('SoundLoad',{name:name,url:assets.get(name).url,async:true,autoStart:false,repeatSound:repeat,_soundManager:manager});
    }

    private function loaded(event:SoundStatusEvent):Void {
        var sound = event.soundData;
        if (sound == null || manager.getSoundObj(sound.name) != sound.soundObj) return;
        loading.remove(sound.name);
        ready.set(sound.name,true);
        var queue = pending.get(sound.name);
        pending.remove(sound.name);
        if (queue != null) for (entry in queue) {
            try { CommandCentral.runCommand(entry.command,entry.payload); }
            catch (error:Dynamic) { report('Audio target=' + sound.name + ' command=' + entry.command + ': ' + Std.string(error)); }
        }
    }

    private function failed(event:SoundStatusEvent):Void {
        if (event.soundData == null) return;
        if (manager.getSoundObj(event.soundData.name) != event.soundData.soundObj) return;
        loading.remove(event.soundData.name);
        pending.remove(event.soundData.name); ready.remove(event.soundData.name);
        report('Unable to load sound ' + event.soundData.name);
    }

    public function stop():Void {
        pending = new Map();
        for (name in manager.getList()) manager.stopSound(name);
    }

    public function dispose():Void {
        stop();
        manager.removeEventListener(SoundStatusEvent.SOUND_LOADED,loaded);
        manager.removeEventListener(SoundStatusEvent.SOUND_ERROR,failed);
        for (name in manager.getList()) manager.removeSound(name);
        assets = new Map(); ready = new Map();
    }
}
