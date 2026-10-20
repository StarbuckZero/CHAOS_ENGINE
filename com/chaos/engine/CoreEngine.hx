package com.chaos.engine;


import com.chaos.engine.events.EventCapabilities;
import com.chaos.engine.events.EventConfigurationStore;
import com.chaos.engine.events.EventPlugin;
#if sys
import haxe.io.Path;
import sys.io.File;
#end

import openfl.events.Event;
import openfl.display.Shape;
import com.chaos.engine.event.EngineDispatchEvent;
import com.chaos.engine.loader.JSONReader;
import com.chaos.engine.loader.classInterface.IReader;
import com.chaos.engine.event.CoreEngineEvent;

import com.chaos.utils.Debug;

import openfl.errors.Error;
import openfl.display.DisplayObject;
import openfl.display.Sprite;

/**
* Provides the engine display area, command dispatch, and data reader.
* @author Erick Feiling
*/

class CoreEngine extends Sprite
{
    /** Whether the background shape is visible. */
    public var useBackground (get, set) : Bool;
    /** Fill color used when the background shape is redrawn. */
    public var backgroundColor(get, set):Int;
    /** Reader that parses incoming engine data. */
    public var reader(get, never) : IReader;

    private var _reader : IReader;
    
    private var _useBackground : Bool = false;

    private var _backgroundShape : Shape;
    private var _backgroundColor : Int = 0;

    /**
    * Sprite that contains engine display objects.
    */
    
    public var displayArea : Sprite;
    
    private var _currentLayer : Sprite;
    private var eventConfigurations:EventConfigurationStore;
    private var eventPlugin:EventPlugin;
    
    /** Sets up the engine. Authoring hosts can opt out of automatic project startup. */
    public function new(autoLoadProject:Bool = true)
    {
        super();
        

        // Add in background
        _backgroundShape = new Shape();
        _backgroundShape.visible = _useBackground;

        stage.addEventListener(Event.RESIZE, onResize, false, 0, true);

        addChild(_backgroundShape);

        //NOTE: Extend class and add plugins there


        _reader = new JSONReader(stage);
        _reader.onDataParse = onDataPaser;
        _reader.onError = onPaserError;
        
        Global.mainDisplyArea = displayArea = cast(this, Sprite);
        
        Global.status = CoreEngineEvent.READY;
        dispatchEvent(new CoreEngineEvent(CoreEngineEvent.READY));
        
        // For all UI events
        CommandDispatch.addEngineListener(onEngineEvent);

        // Wait until subclass constructors have registered their plugins.
        if (autoLoadProject) addEventListener(Event.ADDED_TO_STAGE, startRuntime);
    }

    private function startRuntime(event:Event):Void {
        removeEventListener(Event.ADDED_TO_STAGE, startRuntime);
        eventConfigurations = new EventConfigurationStore();
        eventPlugin = new EventPlugin(displayArea);
        eventPlugin.afterAction = function() eventPlugin.refresh(eventConfigurations);
        displayArea.addEventListener(Event.ADDED, function(event) {
            if (Std.isOfType(event.target, com.chaos.ui.chart.ChartBase))
                eventPlugin.refresh(eventConfigurations);
        });

        #if sys
        // Resolve project.json and asset paths beside the executable, regardless of launch directory.
        Sys.setCwd(Path.directory(Sys.programPath()));
        var projectData = File.getContent("project.json");
        #if desktop
        configureWindow(haxe.Json.parse(projectData).runtime);
        #end
        reader.setData(projectData);
        #else
        reader.load(js.Syntax.code("window.CHAOS_PROJECT_URL || 'project.json'"));
        #end
    }

    #if desktop
    private function configureWindow(config:Dynamic):Void {
        // Older exports have no runtime block and retain their existing startup behavior.
        if (config == null) return;
        var width:Float = config.width;
        var height:Float = config.height;
        if (!Math.isFinite(width) || !Math.isFinite(height) || width <= 0 || height <= 0
            || width != Math.floor(width) || height != Math.floor(height)
            || width > 2147483647 || height > 2147483647)
            throw "Desktop window dimensions must be positive integers.";
        var logicalWidth = Std.int(width);
        var logicalHeight = Std.int(height);
        var window = stage.window;
        // OpenFL exposes logical sizing internally; SHOW_ALL preserves layout and aspect ratio.
        @:privateAccess stage.__setLogicalSize(logicalWidth, logicalHeight);
        stage.scaleMode = openfl.display.StageScaleMode.SHOW_ALL;
        stage.align = openfl.display.StageAlign.TOP_LEFT;
        var restore = function() {
            window.resize(logicalWidth, logicalHeight);
            var display = lime.system.System.getDisplay(0);
            if (display != null) {
                var bounds = display.bounds;
                window.move(Std.int(bounds.x + (bounds.width - window.width) / 2),
                    Std.int(bounds.y + (bounds.height - window.height) / 2));
            }
        };
        window.fullscreen = false;
        restore();
        stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, function(event:openfl.events.KeyboardEvent) {
            if (event.altKey && event.keyCode == openfl.ui.Keyboard.ENTER) {
                window.fullscreen = !window.fullscreen;
                if (!window.fullscreen) restore();
            }
        });
        stage.addEventListener(openfl.events.FullScreenEvent.FULL_SCREEN, function(event:openfl.events.FullScreenEvent) {
            if (!event.fullScreen) restore();
        });
        if (config.fullscreen == true) window.fullscreen = true;
    }
    #end

    private function captureRuntimeEventDefinitions(data:Dynamic, scope:Dynamic):Void {
        if (data == null || !Reflect.isObject(data)) return;
        if (Std.isOfType(data, Array)) {
            for (item in (cast data:Array<Dynamic>)) captureRuntimeEventDefinitions(item, scope);
            return;
        }
        for (type in Reflect.fields(data)) {
            var value:Dynamic = Reflect.field(data, type);
            if (value == null || !Reflect.isObject(value)) continue;
            if (type == "items") { captureRuntimeEventDefinitions(value, scope); continue; }
            if (type == "AddLayerItem") { captureRuntimeEventDefinitions(value.item, scope); continue; }
            if (type == "ContainerAddItem") { captureRuntimeEventDefinitions(value.items, scope); continue; }
            var childScope:Dynamic = scope;
            if (type == "Screen" || type == "Element") childScope = {type:type, name:value.name};
            if (Reflect.hasField(EventCapabilities.catalog, type) && Std.isOfType(value.name, String))
                eventConfigurations.accept({schemaVersion:1, name:value.name, componentType:type,
                    scope:scope, events:Reflect.hasField(value, "events") ? value.events : [],
                    serverEvents:Reflect.field(value, "serverEvents")}, false);
            if (type == "Layer" || type == "Screen" || type == "Element"
                || Reflect.hasField(EventCapabilities.catalog, type))
                captureRuntimeEventDefinitions(Reflect.field(value, "items"), childScope);
        }
    }

    private function onResize(event:Event = null) : Void {

        _backgroundShape.graphics.clear();
        _backgroundShape.graphics.beginFill(_backgroundColor,1);
        _backgroundShape.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
        _backgroundShape.graphics.endFill();
    }

    private function get_backgroundColor():Int {
        return _backgroundColor;
     }
     
     private function set_backgroundColor(value:Int):Int {

        _backgroundColor = value;

        return _backgroundColor;
     }    

    private function set_useBackground( value:Bool ) : Bool {

        _backgroundShape.visible = _useBackground = value;

        return _useBackground;
    }

    private function get_useBackground() : Bool {
        return _useBackground;
    }
    
    /**
    * Get the reader that is being used
    */
    private function get_reader() : IReader
    {
        return _reader;
    }
    
    
    
    /**
    * Runs each command parsed by the reader and dispatches item-created events.
    * @param dataObj An object whose fields are command names and payloads.
    */
    public function onDataPaser(dataObj : Dynamic) : Void
    {
        if (eventPlugin != null && dataObj != null && Reflect.hasField(dataObj, "SetServerEvents")) {
            if (eventPlugin.serverEvents.configure(haxe.Json.stringify(Reflect.field(dataObj, "SetServerEvents"))))
                eventPlugin.serverEvents.start();
            else trace("Invalid server event settings");
            return;
        }
        var object : Dynamic;
        
        for (index in Reflect.fields(dataObj))
        {
            try
            {
                if (_currentLayer != null && _currentLayer.parent == null) Global.currentLayer = _currentLayer = null;
                var targetArea = index == EngineTypes.LAYER || index == EngineTypes.ADD_LAYER_ITEM || index == EngineTypes.REMOVE_LAYER
                    ? displayArea : ((null != _currentLayer) ? _currentLayer : displayArea);
                object = CommandCentral.runCommand(index, Reflect.field(dataObj, index), targetArea);

                CommandDispatch.dispatch("CoreEngine", CoreEngineEvent.ITEM_CREATED, {type : index, item : object});
                
                if (index == EngineTypes.LAYER && null != object)
                    Global.currentLayer = _currentLayer = cast(object, Sprite);
            }
            catch (error : Error)
            {
                onPaserError(Reflect.field(dataObj, index));
            }
        }
        if (eventPlugin != null) {
            captureRuntimeEventDefinitions(dataObj, {type:"DisplayEngine", name:""});
            eventPlugin.refresh(eventConfigurations);
        }
    }
    
    /**
    * Reports a reader or command error by dispatching a parser-failure event.
    * @param dataObj The data associated with the failure.
    */
    
    public function onPaserError(dataObj : Dynamic) : Void
    {
        Debug.print("[CoreEngine::onPaserError] Was unable to run command: ");
        //TODO: Write detail output
        
        Global.status = CoreEngineEvent.PASER_FAIL;
        dispatchEvent(new CoreEngineEvent(CoreEngineEvent.PASER_FAIL));
    }
    
    /** Prints a received engine event and its data fields for debugging. */
    public function onEngineEvent(event : EngineDispatchEvent) : Void
    {
        Debug.print("[CoreEngine::onEngineEvent] Event: " + event.eventType + " Element: " + event.elementName);
        Debug.print("----------------------- eventData -----------------------");
        
        for (key in Reflect.fields(event.eventData))
        {
           
            Debug.print("key: " + key + " value: " + Reflect.field(event.eventData, key ));
        }
        
        Debug.print("----------------------------------------------------------");
    }


    /**
    * Sets the background flag and redraws the shape.
    * @param value Whether the background should be shown.
    */

	public function setBackground ( value:Bool ) :Void {
		_useBackground = value;
        onResize();
	}    

    /**
    * Changes the background fill color and redraws the shape.
    * @param value New background color.
    */

	public function setBackgroundColor ( value:Int ) :Void {
		_backgroundColor = value;
        onResize();
        
	}     
}
