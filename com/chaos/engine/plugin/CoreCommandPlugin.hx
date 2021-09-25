package com.chaos.engine.plugin;

import com.chaos.utils.Utils;
import openfl.display.BitmapData;
import com.chaos.engine.Global;
import com.chaos.engine.CommandDispatch;
import com.chaos.ui.classInterface.IBaseUI;
import com.chaos.ui.layout.classInterface.IBaseContainer;
import com.chaos.ui.classInterface.ILabel;
import openfl.display.DisplayObject;
import openfl.display.Bitmap;
import openfl.display.Sprite;
import com.chaos.engine.CommandCentral;
import com.chaos.engine.EngineTypes;
import com.chaos.utils.Debug;

/**
* Just call commands that should already be loaded
* @author Erick Feiling
*/
class CoreCommandPlugin
{
    private static var unNameCount : Int = 0;
    
    
    public function new()
    {
        
    }
        
    /**
    * Adds object to layer if there is one set. If none is set then the display area passed in
    * @param	UIObject The UI object you want to add to the display
    * @param	displayArea The object that the UIObject will be added to if there isn't a layer set
    */
    
    public static function displayUpdate(UIObject : IBaseUI, data : Dynamic) : Void
    {
        var displayArea : Sprite = getDisplayObject(data);
        displayArea.addChild(UIObject.displayObject);
    }

    /**
    * Try to find display area
    * @param	data The UI object you want to add to the display
    */

    public static function getDisplayObject( data : Dynamic ) : Sprite 
    {
        // First check to see if display area was passed in if not just grab layer or main timeline
        if(Reflect.hasField(data,"displayArea")) 
        {
            return Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"displayArea"));
        }
        else 
        {
            if (null != Global.currentLayer)
                return Global.currentLayer;
            else
                return Global.mainDisplyArea;    
        }
    }
    
    public static function setComponentData(data : Dynamic, UIObject : IBaseUI) : Void
    {
        UIObject.setComponentData(data);

        if(Reflect.hasField(data,"redraw") && Reflect.field(data,"redraw"))
            UIObject.draw();
    }
    
    
    public static function removeContainerEvents(baseContainer : IBaseContainer) : Void
    {
        
        var containerArea : Sprite = cast(baseContainer.content, Sprite);
        
        for (i in 0...containerArea.numChildren)
        {
            var subElement : DisplayObject = containerArea.getChildAt(i);
            
            if (Std.isOfType(subElement, IBaseUI))
                CommandDispatch.removeAllEvents(cast(subElement, IBaseUI));
            
            if (Std.isOfType(subElement, IBaseContainer))
                removeContainerEvents(cast(subElement, IBaseContainer));
        }
    }
    
    public static function getScreen(screenName : String) : DisplayObject
    {
        if(!CommandCentral.hasPlugin("CoreFrameworkPlugin"))
            Debug.print("[CoreFrameworkPlugin::initialize] Require CoreFrameworkPlugin 1.0 or higher");

        return try cast(CommandCentral.runCommand(EngineTypes.GET_SCREEN, {name : screenName}), DisplayObject);
    }
    
    public static function getElement(elementName : String) : DisplayObject
    {
        if(!CommandCentral.hasPlugin("CoreFrameworkPlugin"))
            Debug.print("[CoreFrameworkPlugin::initialize] Require CoreFrameworkPlugin 1.0 or higher");

        return cast(CommandCentral.runCommand(EngineTypes.GET_ELEMENT, {name : elementName}), DisplayObject);
    }
    
    public static function getImage(elementName : String) : BitmapData
    {
        if(!CommandCentral.hasPlugin("CoreFrameworkPlugin"))
            Debug.print("[CoreFrameworkPlugin::initialize] Require CoreFrameworkPlugin 1.0 or higher");

        return cast(CommandCentral.runCommand(EngineTypes.GET_IMAGE, {name : elementName}), BitmapData);
    }
    
    public static function getItem(elementName : String) : DisplayObject
    {
        if(!CommandCentral.hasPlugin("CoreFrameworkPlugin"))
            Debug.print("[CoreFrameworkPlugin::initialize] Require CoreFrameworkPlugin 1.0 or higher");

        return cast(CommandCentral.runCommand(EngineTypes.GET_ITEM, {name : elementName}), DisplayObject);
    }
    
    public static function setDataProvider(elementName : String, append : Bool = false, items : Array<Dynamic> = null) : DisplayObject
    {
        if(!CommandCentral.hasPlugin("CoreFrameworkPlugin"))
            Debug.print("[CoreFrameworkPlugin::initialize] Require CoreFrameworkPlugin 1.0 or higher");

        return cast(CommandCentral.runCommand(EngineTypes.DATA_UPDATE, {name : elementName,append : append, items : ((null != items)) ? items : []}), DisplayObject);
    }
}

