package com.chaos.engine;

import openfl.display.Sprite;

/**
* Registers named commands and invokes them with a data object.
* @author Erick Feiling
*/
class CommandCentral
{
    private static var list : Dynamic = {};
    private static var pluginNameList : Dynamic = {};
    
    /**
    * Records a plugin's name and version.
    * @param name Plugin name.
    * @param ver Plugin version.
    */
    public static function addPluginName(name : String, ver : Float) : Void
    {
        Reflect.setField(pluginNameList, name, ver);
    }
    
    /**
    * Checks whether a plugin is registered at the requested version or later.
    * @param	name The name of the plugin
    * @param	ver The major and minor version number of the plugin
    * @return True if the plugin is registered and satisfies the version requirement.
    */

    public static function hasPlugin(name : String, ver : Float = 0) : Bool
    {
        // With no version requirement, check presence; otherwise compare registered versions.
        if(Reflect.hasField(pluginNameList, name) && ver <= 0) {
            return true;
        }
        else if(Reflect.hasField(pluginNameList, name) && Reflect.field(pluginNameList, name) >= ver) {
            return true;
        }

        return false;
    }
    
    /**
    * Checks whether a command key has a registered callback.
    * @param key Command name.
    * @return True if the command is registered.
    */
    public static function hasCommand(key : String) : Bool
    {
        return Reflect.hasField(list, key);
    }

    /**
    * Registers or replaces the callback associated with a command key.
    * @param key Command name.
    * @param func Callback invoked with the command data object.
    */
    public static function addCommand(key : String, func : Dynamic->Dynamic) : Void
    {
        Reflect.setField(list, key, func);
    }
    
    /**
    * Removes a registered command callback, if present.
    * @param key Command name to remove.
    */
    public static function removeCommand(key : String) : Void
    {
        if (Reflect.hasField(list,key))
            Reflect.deleteField(list, key);
    }
    
    /**
    * Invokes a registered command and optionally adds `displayArea` to its data.
    * 
    * @param key Command name.
    * @param dataObj Data passed to the callback.
    * @param displayArea Optional display area added to `dataObj` before invocation.
    * @return The callback result, or null when no command is registered.
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

