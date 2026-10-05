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
* Provides shared helpers for engine commands and display lookup.
* @author Erick Feiling
*/
class CoreCommandPlugin
{
    private static var unNameCount : Int = 0;
    
    
    /** Creates a command helper; operations are exposed statically. */
    public function new()
    {
        
    }
        
    /**
    * Adds a UI object's display object to the resolved display area.
    * @param UIObject UI object to add.
    * @param data Command data used to resolve the display area.
    */
    
    public static function displayUpdate(UIObject : IBaseUI, data : Dynamic) : Void
    {
        var displayArea : Sprite = getDisplayObject(data);
        displayArea.addChild(UIObject.displayObject);
    }

    /**
    * Resolves the display area from command data, the current layer, or the root.
    * @param data Command data that may contain `displayArea`.
    */

    public static function getDisplayObject( data : Dynamic ) : Sprite 
    {
        // First check to see if display area was passed in if not just grab layer or main timeline
        if(Reflect.hasField(data,"displayArea")) 
        {
            return Reflect.field(data,"displayArea");
        }
        else 
        {
            if (null != Global.currentLayer)
                return Global.currentLayer;
            else
                return Global.mainDisplyArea;    
        }
    }
    
    /** Applies component data and optionally redraws the UI object. */
    public static function setComponentData(data : Dynamic, UIObject : IBaseUI) : Void
    {
        UIObject.setComponentData(Std.isOfType(UIObject, com.chaos.ui.chart.ChartBase) ? CoreChartSupport.componentData(data) : data);

        if(Reflect.hasField(data,"redraw") && Reflect.field(data,"redraw"))
            UIObject.draw();
    }
    
    
    /** Removes forwarded engine listeners recursively from container children. */
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
    
    /** Looks up a screen through the registered framework command. */
    public static function getScreen(screenName : String) : DisplayObject
    {
        if(!CommandCentral.hasPlugin("CoreFrameworkPlugin"))
            Debug.print("[CoreFrameworkPlugin::initialize] Require CoreFrameworkPlugin 1.0 or higher");

        return try cast(CommandCentral.runCommand(EngineTypes.GET_SCREEN, {name : screenName}), DisplayObject);
    }
    
    /** Looks up a UI element through the registered framework command. */
    public static function getElement(elementName : String) : DisplayObject
    {
        if(!CommandCentral.hasPlugin("CoreFrameworkPlugin"))
            Debug.print("[CoreFrameworkPlugin::initialize] Require CoreFrameworkPlugin 1.0 or higher");

        return cast(CommandCentral.runCommand(EngineTypes.GET_ELEMENT, {name : elementName}), DisplayObject);
    }
    
    /** Looks up bitmap data through the registered image command. */
    public static function getImage(elementName : String) : BitmapData
    {
        if(!CommandCentral.hasPlugin("CoreFrameworkPlugin"))
            Debug.print("[CoreFrameworkPlugin::initialize] Require CoreFrameworkPlugin 1.0 or higher");

        return cast(CommandCentral.runCommand(EngineTypes.GET_IMAGE, {name : elementName}), BitmapData);
    }
    
    /** Looks up a named item through the registered framework command. */
    public static function getItem(elementName : String) : DisplayObject
    {
        if(!CommandCentral.hasPlugin("CoreFrameworkPlugin"))
            Debug.print("[CoreFrameworkPlugin::initialize] Require CoreFrameworkPlugin 1.0 or higher");

        return cast(CommandCentral.runCommand(EngineTypes.GET_ITEM, {name : elementName}), DisplayObject);
    }
    
    /** Sends items to a named data provider, replacing or appending as requested. */
    public static function setDataProvider(elementName : String, append : Bool = false, items : Array<Dynamic> = null) : DisplayObject
    {
        if(!CommandCentral.hasPlugin("CoreFrameworkPlugin"))
            Debug.print("[CoreFrameworkPlugin::initialize] Require CoreFrameworkPlugin 1.0 or higher");

        return cast(CommandCentral.runCommand(EngineTypes.DATA_UPDATE, {name : elementName,append : append, items : ((null != items)) ? items : []}), DisplayObject);
    }
}
