package com.chaos.engine;

import openfl.display.Sprite;

/**
* Holds the active engine's shared display and loading state.
* 
* @author Erick Feiling
*/
class Global
{
    /** Layer currently receiving parsed display items. */
    public static var currentLayer : Sprite;
    
    /** Main sprite that contains engine content. */
    public static var mainDisplyArea : Sprite;
    
    /** Current engine lifecycle status. */
    public static var status : String;
    
    /** Whether file reading is paused. */
    public static var pause : Bool = false;
    
    /** Creates a holder for shared engine state. */
    public function new()
    {
    }
}

