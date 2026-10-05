package com.chaos.engine.loader;

import flash.display.Stage;

/**
	 * Reader subclass reserved for XML input; parsing is not implemented here.
	 * @author Erick Feiling
	 */
class XMLReader extends Reader
{
    
    /** Registers this reader with the stage timer. */
    public function new(mainStage : Stage)
    {
        super(mainStage);
    }
}

