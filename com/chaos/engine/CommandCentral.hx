package com.chaos.engine;

import openfl.display.Sprite;

/**
* CommandCentral calls a function based on the key value that was passed in.
* @author Erick Feiling
*/
class CommandCentral
{
    private static var list : Dynamic = {};
    private static var pluginNameList : Dynamic = {};
    
    /**
    * Add name and version plugin
    * @param	name The name of the plugin
    * @param	ver The major and minor version number of the plugin
    */
    public static function addPluginName(name : String, ver : Float) : Void
    {
        Reflect.setField(pluginNameList, name, ver);
    }
    
    /**
    * Check to see if the plugin is being used
    * @param	name The name of the plugin
    * @param	ver The major and minor version number of the plugin
    * @return	True if plubin is being used
    */

    public static function hasPlugin(name : String, ver : Float = 0) : Bool
    {
        // If version number is 0 just make sure plugin is there else make sure number stroed is greater than number stored
        if(Reflect.hasField(pluginNameList, name) && ver <= 0) {
            return true;
        }
        else if(Reflect.hasField(pluginNameList, name) && Reflect.field(pluginNameList, name) >= ver) {
            return true;
        }

        return false;
    }
    
    /**
    * Check to see if command is being used
    * @param	key This is a name that will be used to call the function.
    * @return	True if command has been found
    */
    public static function hasCommand(key : String) : Bool
    {
        return Reflect.hasField(list, key);
    }

    /**
    * Adds a function to be called
    * @param	key This is a name that will be used to call the function.
    * @param	func Calls a function with the data object and display area. This is so things can be added to it.
    */
    public static function addCommand(key : String, func : Dynamic->Dynamic) : Void
    {
        Reflect.setField(list, key, func);
    }
    
    /**
    * Remove function call from list
    * @param	key The name of the call that will be removed
    */
    public static function removeCommand(key : String) : Void
    {
        if (Reflect.hasField(list,key))
            Reflect.deleteField(list, key);
    }
    
    /**
    * Run command based on key name
    * 
    * @param	key The name of the command in list
    * @param	dataObj The data object that is used to help run the command
    * @param	displayArea The display area the command can update
    * @return	The command output in most cases a display object of some kind
    */
    public static function runCommand(key : String, dataObj : Dynamic, displayArea:Sprite = null) : Dynamic
    {
        if (Reflect.hasField(list,key))
        {
            var func:Dynamic->Dynamic = Reflect.field(list, key);

            if(displayArea != null)
                Reflect.setField(dataObj, "displayArea", displayArea);

            return func(dataObj);
        }

        return null;
    }
}

