package com.chaos.engine;


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
* This is the core or base for the engine.
* @author Erick Feiling
*/

class CoreEngine extends Sprite
{
    public var useBackground (get, set) : Bool;
    public var backgroundColor(get, set):Int;
    public var reader(get, never) : IReader;

    private var _reader : IReader;
    
    private var _useBackground : Bool = false;

    private var _backgroundShape : Shape;
    private var _backgroundColor : Int = 0;

    /**
    * Where all UI objects are displayed
    */
    
    public var displayArea : Sprite;
    
    private var _currentLayer : Sprite;
    
    public function new()
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
    * The data that is coming back from reader. Override if need be.
    * @param	dataObj A normal object
    */
    public function onDataPaser(dataObj : Dynamic) : Void
    {
        var object : Dynamic;
        
        for (index in Reflect.fields(dataObj))
        {
            try
            {
                object = CommandCentral.runCommand(index, Reflect.field(dataObj, index), ((null != _currentLayer)) ? _currentLayer : displayArea);

                CommandDispatch.dispatch("CoreEngine", CoreEngineEvent.ITEM_CREATED, {type : index, item : object});
                
                if (index == EngineTypes.LAYER && null != object)
                    Global.currentLayer = _currentLayer = cast(object, Sprite);
            }
            catch (error : Error)
            {
                onPaserError(Reflect.field(dataObj, index));
            }
        }
    }
    
    /**
    * The data that is cause an error
    * @param	dataObj A normal object
    */
    
    public function onPaserError(dataObj : Dynamic) : Void
    {
        Debug.print("[CoreEngine::onPaserError] Was unable to run command: ");
        //TODO: Write detail output
        
        Global.status = CoreEngineEvent.PASER_FAIL;
        dispatchEvent(new CoreEngineEvent(CoreEngineEvent.PASER_FAIL));
    }
    
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
    * Make it so the background layer is visible
    * @param	value show or hide background
    */

	public function setBackground ( value:Bool ) :Void {
		_useBackground = value;
        onResize();
	}    

    /**
    * Change the color of the background layer
    * @param	value color of layer
    */

	public function setBackgroundColor ( value:Int ) :Void {
		_backgroundColor = value;
        onResize();
        
	}     
}

