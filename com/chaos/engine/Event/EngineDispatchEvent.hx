package com.chaos.engine.event;

import flash.events.Event;

/**
	 * Carries a UI element name, event type, and payload through the engine.
	 * @author Erick Feiling
	 */
class EngineDispatchEvent extends Event
{
    /** Name of the element that emitted the event. */
    public var elementName(get, never) : String;
    /** Original UI event type. */
    public var eventType(get, never) : String;
    /** Payload captured from the UI event. */
    public var eventData(get, never) : Dynamic;

    /** Event type listened for by engine consumers. */
    public static inline var ENGINE_EVENT : String = "engine_event";
    /** Dispatch label accepted by the constructor; instances use `ENGINE_EVENT`. */
    public static inline var ENGINE_DISPATCH : String = "engine_dispatch";
    
    private var _elementName : String;
    private var _eventType : String;
    private var _eventData : Dynamic;
    
    /** Creates an engine event with the supplied element metadata and payload. */
    public function new(engineEvent : String, elementName : String, eventType : String, eventData : Dynamic, bubbles : Bool = false, cancelable : Bool = false)
    {
        _elementName = elementName;
        _eventType = eventType;
        _eventData = eventData;
        
        super(ENGINE_EVENT, bubbles, cancelable);
    }
    
    /** Returns a copy carrying the same element metadata and payload. */
    override public function clone() : Event
    {
        return new EngineDispatchEvent(type, _elementName, _eventType, _eventData, bubbles, cancelable);
    }
    
    /** Formats the inherited event fields and element name. */
    override public function toString() : String
    {
        return formatToString("EngineDispatchEvent", "type", "elementName", "bubbles", "cancelable", "eventPhase");
    }
    
    /**
		 * The name of the object
		 */
    
    private function get_elementName() : String
    {
        return _elementName;
    }
    
    /**
		 * The type of event
		 */
    private function get_eventType() : String
    {
        return _eventType;
    }
    
    /**
		 * The data object
		 */
    
    private function get_eventData() : Dynamic
    {
        return _eventData;
    }
}

