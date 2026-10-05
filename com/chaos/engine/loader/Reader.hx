package com.chaos.engine.loader;

import com.chaos.engine.loader.classInterface.IReader;
import com.chaos.utils.ThreadManager;
import openfl.display.Stage;

/**
* Base reader that schedules data parsing on the engine timer.
* @author Erick Feiling
*/

class Reader implements IReader
{
    /** Whether timer-driven processing is suspended. */
    public var lock(get, set) : Bool;
    /** Callback invoked with parsed data. */
    public var onDataParse(get, set) : Dynamic->Void;
    /** Callback invoked for reader errors. */
    public var onError(get, set) : Dynamic->Void;

    /** Items waiting to be processed by the reader. */
    public var list : Array<Dynamic> = new Array<Dynamic>();
    
    private var _lock : Bool = false;
    
    private var _onDataParse : Dynamic->Void;
    private var _onError : Dynamic->Void;
    
    
    
    /**
    * Registers the reader's processing callback with the shared stage timer.
    * @param mainStage Stage used by the timer manager.
    */
    
    public function new(mainStage : Stage)
    {
        ThreadManager.stage = mainStage;
        ThreadManager.addEventTimer(thread);
    }
    
    /**
    * Placeholder for loading data from a URL in subclasses.
    * @param fileURL URL to load.
    */
    
    public function load(fileURL : String) : Void
    {
    }
    
    /**
    * Placeholder for accepting raw data in subclasses.
    * @param data Data to parse.
    */
    
    public function setData(data : Dynamic) : Void
    {
    }
    
    
    
    /**
    * If true will not run anything in thread
    */
    private function set_lock(value : Bool) : Bool
    {
        _lock = value;
        return value;
    }
    
    /**
    * If true main thread is locked and false if not
    */
    private function get_lock() : Bool
    {
        return _lock;
    }
    
    /**
    * The function called once data is parsed
    */
    private function set_onDataParse(value : Dynamic->Void) : Dynamic->Void
    {
        _onDataParse = value;
        return value;
    }
    
    /**
    * What is going to be used to parse the data read in by the file
    */
    private function get_onDataParse() : Dynamic->Void
    {
        return _onDataParse;
    }
    
    /**
    * If there is something wrong the item being created
    */
    
    private function set_onError(value : Dynamic->Void) : Dynamic->Void
    {
        _onError = value;
        return value;
    }
    
    /**
    * The function that is being used
    */
    private function get_onError() : Dynamic->Void
    {
        return _onError;
    }
    
    /**
    * Placeholder for processing one timer tick in subclasses.
    */
    
    public function thread(value:Dynamic) : Void
    {

    }
}

