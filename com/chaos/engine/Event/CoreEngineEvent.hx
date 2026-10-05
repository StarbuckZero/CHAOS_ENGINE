package com.chaos.engine.event;

import flash.events.Event;

/**
	 * Reports engine lifecycle, loading, and item creation events.
	 * @author Erick Feiling
	 */
class CoreEngineEvent extends Event
{
    /** Engine initialization completed. */
    public static inline var READY : String = "ready";
    /** Reader started loading data. */
    public static inline var LOADING : String = "loading";
    /** Reader finished loading data. */
    public static inline var LOADED : String = "loaded";
    /** Reader is processing loaded data. */
    public static inline var READING : String = "reading";
    /** Reader finished processing data. */
    public static inline var DONE : String = "done";
    
    /** Loading data failed. */
    public static inline var LOAD_FAIL : String = "load_fail";
    /** Parsing or running a command failed. */
    public static inline var PASER_FAIL : String = "parse_fail";
    
    /** Item loading completed. */
    public static inline var ITEM_LOAD_COMPLETE : String = "item_load_complete";
    /** Item loading failed. */
    public static inline var ITEM_LOAD_FAIL : String = "item_load_fail";
    /** A command created an item. */
    public static inline var ITEM_CREATED : String = "item_created";

    /** An image finished loading. */
    public static inline var IMAGE_LOADED : String = "image_loaded";
    
    /** Creates a lifecycle event with the given event type. */
    public function new(type : String, bubbles : Bool = false, cancelable : Bool = false)
    {
        super(type, bubbles, cancelable);
    }
}

