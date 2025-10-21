package com.chaos.engine.plugin;

import com.chaos.engine.CommandDispatch;
import com.chaos.engine.EngineTypes;
import com.chaos.engine.Global;
import com.chaos.ui.BaseUI;
import com.chaos.ui.classInterface.IBaseUI;
import com.chaos.ui.layout.FitContainer;
import com.chaos.ui.layout.GridContainer;
import com.chaos.ui.layout.HorizontalContainer;
import com.chaos.ui.layout.classInterface.IAlignmentContainer;
import com.chaos.ui.layout.classInterface.IFitContainer;
import com.chaos.ui.layout.classInterface.IGridContainer;
import com.chaos.ui.layout.VerticalContainer;
import com.chaos.utils.Utils;
import com.chaos.utils.Debug;
import com.chaos.media.DisplayImage;
import com.chaos.media.DisplayVideo;
import com.chaos.utils.ThreadManager;
import com.chaos.utils.classInterface.ITask;
import com.chaos.utils.data.TaskDataObject;
import com.chaos.engine.CommandCentral;
import com.chaos.ui.layout.BaseContainer;
import com.chaos.ui.layout.classInterface.IBaseContainer;

import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.errors.Error;
import openfl.display.Bitmap;
import openfl.display.BitmapData;


/**
* This adds the CHAOS Media Framework to Command Central which is used to call functions
* @author Erick Feiling
*/
class CoreFrameworkPlugin
{
    
    private static var screen : Dynamic = {};
    private static var screenCache : Dynamic = {};
    
    private static var element : Dynamic = {};
    
    public function new()
    {
    }

    /**
    * This addes the core CHAOS framework to the engine to be used
    */
    
    public static function initialize() : Void
    {
        // Add plugin name
        CommandCentral.addPluginName("CoreFrameworkPlugin",1.0);

        // Core Engine Functions
        CommandCentral.addCommand(EngineTypes.LAYER, createLayer);
        CommandCentral.addCommand(EngineTypes.SCREEN, createScreen);
        CommandCentral.addCommand(EngineTypes.ELEMENT, createElement);
        
        // Get Screen and Element from stored data objects
        CommandCentral.addCommand(EngineTypes.GET_SCREEN, getScreen);
        CommandCentral.addCommand(EngineTypes.GET_ELEMENT, getElement);
        
        CommandCentral.addCommand(EngineTypes.REMOVE_ELEMENT, removeElement);
        CommandCentral.addCommand(EngineTypes.REMOVE_SCREEN, removeScreen);
        CommandCentral.addCommand(EngineTypes.REMOVE_LAYER, removeLayer);
        
        CommandCentral.addCommand(EngineTypes.ADD_LAYER_ITEM, addLayerItem);
        
        // Layout
        CommandCentral.addCommand(EngineTypes.CONTAINER, createContainer);
        CommandCentral.addCommand(EngineTypes.FIT_CONTAINER, createFitContainer);
        CommandCentral.addCommand(EngineTypes.GRID_CONTAINER, createGridContainer);
        CommandCentral.addCommand(EngineTypes.HORIZONTAL_CONTAINER, createHorizontalContainer);
        CommandCentral.addCommand(EngineTypes.VERTICAL_CONTAINER, createVerticalContainer);
    }
    
    private static function createContainer(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, BaseContainer))
        {
            var baseContainer : IBaseContainer = cast(displayObj, IBaseContainer);
            CoreCommandPlugin.setComponentData(data, baseContainer);

            return displayObj;
        }
        else
        {
            var baseContainer : IBaseContainer = new BaseContainer(data);
            
            // Add items in the background
            ThreadManager.createTaskManager(EngineTypes.CONTAINER, CoreCommandPlugin.getDisplayObject(data) );
            ThreadManager.addTask(EngineTypes.CONTAINER, new TaskDataObject(Reflect.field(data,"name"), 0, data.items.length, subThread, [Reflect.field(data,"items"), baseContainer.content]));
            
            CoreCommandPlugin.displayUpdate(baseContainer, data); 

            return baseContainer;
        }
        
    } 
    
    private static function createFitContainer(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, FitContainer))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj,IBaseUI));
            
            return displayObj;
        }
        else
        {
            var fitContainer : IFitContainer = new FitContainer(data);
            
            buildContentArea(EngineTypes.FIT_CONTAINER, fitContainer, data);
                        
            CoreCommandPlugin.displayUpdate(fitContainer, data);

            return fitContainer;
        }
    }
    
    private static function createGridContainer(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, GridContainer))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj,IBaseUI));

            return displayObj;
        }
        else
        {
            var row : Int = 1;
            var col : Int = 1; 

            if(!Reflect.hasField(data,"column"))
                Reflect.setField(data,"column",col);
            
            if(!Reflect.hasField(data,"row"))
                Reflect.setField(data,"row",row);

            var gridContainer : IGridContainer = new GridContainer(data);
            
            CoreCommandPlugin.displayUpdate(gridContainer, data);

            return gridContainer;
        }
    }
    
    private static function createHorizontalContainer(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, HorizontalContainer))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj,IBaseUI));
            return displayObj;
        }
        else
        {
            var hozContainer : IAlignmentContainer = new HorizontalContainer(data);
            
            buildContentArea(EngineTypes.HORIZONTAL_CONTAINER, hozContainer, data);
            
            CoreCommandPlugin.displayUpdate(hozContainer, data);

            return hozContainer;
        }
    }
    
    private static function createVerticalContainer(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, VerticalContainer))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj,IBaseUI));
            return displayObj;
        }
        else
        {
            var vertContainer : IAlignmentContainer = new VerticalContainer(data);
            
            buildContentArea(EngineTypes.VERTICAL_CONTAINER, vertContainer, data);

            CoreCommandPlugin.displayUpdate(vertContainer, data);

            return vertContainer;
        }
    }
    

    
    
    private static function createScreen(data : Dynamic) : Dynamic
    {
        if ( Reflect.hasField(data,"name") && !Reflect.hasField(screen, Reflect.field(data,"name")) )
        {
            var newScreen : IBaseUI = null;

            if ( Reflect.hasField(data,"cache") && Reflect.field(data,"cache") )
            {
                newScreen = buildScreen(data);
                
                if (null != newScreen)
                    Reflect.setField(screenCache, Reflect.field(data,"name"), newScreen);
            }

            Reflect.setField(screen, Reflect.field(data,"name"), data);

            return newScreen;

        }
        else
        {
            Debug.print("[CoreFrameworkPlugin::createScreen] Unable to create new screen! Either doesn't have name or already in list.");
        }
        
        return null;
    }
    
    private static function createElement(data : Dynamic) : Dynamic
    {
        if (  Reflect.hasField(data,"name") && !Reflect.hasField(element, Reflect.field(data,"name")))
        {
            Reflect.setField(element, Reflect.field(data,"name"), data);

            var displayArea : Sprite = CoreCommandPlugin.getDisplayObject(data);
            var newElement : DisplayObject = getElement(data);
            
            if (null != newElement)
                displayArea.addChild(newElement);
        }
        else
        {
            Debug.print("[CoreFrameworkPlugin::createElement] Unable to create new element! Either doesn't have name value or already in list.");
        }
        
        return null;
    }
    
    private static function removeElement(data : Dynamic) : Dynamic
    {
        if (Reflect.hasField(data,"name") && Reflect.field(element, Reflect.field(data,"name")) )
            Reflect.deleteField(element, Reflect.field(data,"name"));
        
        return null;
    }
    
    
    private static function createLayer(data : Dynamic) : Dynamic
    {
        if (Reflect.hasField(data,"name"))
        {
            var newLayer : IBaseUI = new BaseUI(data);
            var displayArea : Sprite  = Global.mainDisplyArea;
            displayArea.addChild(newLayer.displayObject);
            
            return newLayer;
        }
        
        Debug.print("[CoreFrameworkPlugin::createLayer] Unable to create new layer because of missing name value on data object.");
        
        return null;
    }
    
    private static function addLayerItem(data : Dynamic) : Dynamic
    {
        if (Reflect.hasField(data,"name") && Reflect.hasField(data,"item"))
        {
            var item : Dynamic = Reflect.field(data,"item");
            var itemArray:Array<String> = Reflect.fields(item);
            var newLayer : Sprite = cast(Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name")), Sprite);
            var displayObj : DisplayObject = null;
            
            // Run command on item at the root of data object
            for (i in 0...itemArray.length)
            {
                displayObj = CommandCentral.runCommand(itemArray[i], Reflect.field(item, itemArray[i]) );
            }
            
            // Add item to the layer
            if (null != displayObj)
            {
                newLayer.addChild(displayObj);

                return displayObj;
            }
            
        }
        
        Debug.print("[CoreFrameworkPlugin::addLayerItem] Unable to add item to layer because of missing name value on data object.");
        
        return null;
    }
    
    private static function removeLayer(data : Dynamic) : DisplayObject
    {
        var oldLayer : BaseUI = cast(Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name")), BaseUI); //cast(getScreen(data), BaseUI);
        
        // Remove all attached events.
        for (i in 0...oldLayer.numChildren)
        {
            var element : DisplayObject = oldLayer.getChildAt(i);
            
            if (null != element && Std.isOfType(element, IBaseUI))
                CommandDispatch.removeAllEvents(cast(element, IBaseUI));
            
            if (null != element && Std.isOfType(element, IBaseContainer))
                CoreCommandPlugin.removeContainerEvents(cast(element, IBaseContainer));
        }
        
        // Remove off state
        if (null != oldLayer.parent)
            return oldLayer.parent.removeChild(oldLayer);
                
        return null;
    }
    
    public static function getScreen(data : Dynamic) : DisplayObject
    {
        if (Reflect.field(screenCache, Reflect.field(data,"name")))
            return Reflect.field(screenCache, Reflect.field(data,"name"));
        else if ( Reflect.hasField(screen, Reflect.field(data,"name")) )
            return cast( buildScreen( Reflect.field(screen, Reflect.field(data,"name")) ), DisplayObject);
        
        
        Debug.print("[CoreFrameworkPlugin::getScreen] Did not find screen " + Reflect.field(data,"name") + ".");
        
        return null;
    }

    public static function hasScreen(name : String) : Bool
    {
        if (Reflect.field(screenCache, name))
            return true;
        else if ( Reflect.hasField(screen, name) )
            return return true;
        
        return false;
    }    
    
    public static function removeScreen(data : Dynamic) : DisplayObject
    {
        var screen : DisplayObject = null;
        
        // Remove item out of cache
        if ( Reflect.hasField(screenCache, Reflect.field(data,"name") ) )
        {
            screen = Reflect.field(screenCache, Reflect.field(data,"name"));
            
            // Remove out of the display
            if (null != screen.parent)
                screen.parent.removeChild(screen);
            
            Reflect.deleteField(screenCache, Reflect.field(data,"name"));
            screen = null;
        }
        
        if ( Reflect.hasField(screen, Reflect.field(data,"name")))
            Reflect.deleteField(data, Reflect.field(data,"name"));
        
        return screen;
    }
    
    public static function getElement(data : Dynamic) : DisplayObject
    {
        if ( Reflect.hasField(data,"name") && Reflect.hasField(element, Reflect.field(data,"name")))
            return cast(buildElement(Reflect.field(element, Reflect.field(data,"name"))), DisplayObject);
        
        Debug.print("[CoreFrameworkPlugin::getElement] Didn't find element " + Reflect.field(data,"name") + ".");
        
        return null;
    }
    
    public static function buildScreen(data : Dynamic) : IBaseUI
    {

        if(!Reflect.hasField(data,"width"))
            Reflect.setField(data,"width",400);

        if(!Reflect.hasField(data,"height"))
            Reflect.setField(data,"height",300);

        Reflect.setField(data,"backgroundAlpha",0);
        
        var newScreen : IBaseUI = new BaseUI(data);
        
        // Cache screen
        Reflect.setField(screenCache, Reflect.field(data,"name"), newScreen);
        
        // Add items in the background
        if (Reflect.hasField(data,"items")) {
            
            var items:Array<Dynamic> = Reflect.field(data,"items");

            ThreadManager.createTaskManager(EngineTypes.SCREEN, CoreCommandPlugin.getDisplayObject(data));
            ThreadManager.addTask(EngineTypes.SCREEN, new TaskDataObject(data.name, 0, data.items.length, subThread, [items, newScreen]));
        }
        
        return newScreen;
    }
    
    public static function buildElement(data : Dynamic) : IBaseUI
    {
        if(!Reflect.hasField(data,"width"))
            Reflect.setField(data,"width",400);

        if(!Reflect.hasField(data,"height"))
            Reflect.setField(data,"height",300);
                
        var items:Array<Dynamic> = Reflect.field(data,"items");
        var newElement : IBaseUI = new BaseUI(data);
                
        // Add items in the background
        ThreadManager.createTaskManager(EngineTypes.ELEMENT, CoreCommandPlugin.getDisplayObject(data));
        ThreadManager.addTask(EngineTypes.ELEMENT, new TaskDataObject(data.name, 0, data.items.length, subThread, [items, newElement]));
        
        return newElement;
    }
    
    private static function buildContentArea(contentType : String, contentArea : IAlignmentContainer, data : Dynamic) : Void
    {
        var items:Array<Dynamic> = Reflect.field(data,"items");

        // Add items in the background
        ThreadManager.createTaskManager(contentType, CoreCommandPlugin.getDisplayObject(data));
        ThreadManager.addTask(contentType, new TaskDataObject(Reflect.field(data,"name"), 0, items.length, containerThread, [items, contentArea]));
    }
    
    private static function containerThread(task : ITask) : Void
    {
        var items : Array<Dynamic> = task.data[0];
        var contentArea : IAlignmentContainer = task.data[1];
        var dataObj : Dynamic = items[task.index - 1];
        
        for (index in Reflect.fields(dataObj))
        {
            // Run command long as it's not another screen or layer
            try
            {
                
                if (EngineTypes.LAYER != index && EngineTypes.SCREEN != index)
                    var element : IBaseUI = CommandCentral.runCommand(index, Reflect.field(dataObj, index));
                
                if (null != element)
                    contentArea.addElement(element);
            }
            catch (error : Error)
            {
                Debug.print("[CoreFrameworkPlugin::containerThread] Couldn't run command " + index + ".");
            }
        }
    }
    
    
    private static function subThread(task : ITask) : Void
    {
        
        var items : Array<Dynamic> = task.data[0];
        var displayObj : DisplayObject = task.data[1];

        var dataObj : Dynamic = items[task.index - 1];
        
        for (index in Reflect.fields(dataObj))
        {
             Debug.print("[CoreFrameworkPlugin::subThread] Object -> " + index + ".");
            // Run command long as it's not another screen or layer
            try {
                
                if (EngineTypes.LAYER != index && EngineTypes.SCREEN != index) {
                    CommandCentral.runCommand(index, Reflect.field(dataObj, index), cast(displayObj, Sprite));
                }else {
                    Debug.print("[CoreFrameworkPlugin::subThread] Couldn't run command " + index + ".");
                }
            }
            catch (error : Error)
            {
                Debug.print("[CoreFrameworkPlugin::subThread] Error on command " + index + ".");
            }
        }
    }
    
    private static function removeContainerEvents(baseContainer : IBaseContainer) : Void
    {
                
        var containerArea : Sprite = cast(baseContainer.content, Sprite);
        
        for (i in 0...containerArea.numChildren)
        {
            var subElement : DisplayObject = containerArea.getChildAt(i);
            
            if (Std.isOfType(subElement, IBaseUI))
                CommandDispatch.removeAllEvents(cast(subElement, IBaseUI));
            
            if (Std.isOfType(subElement, IBaseContainer))
                CoreCommandPlugin.removeContainerEvents(cast(subElement, IBaseContainer));
        }
    }


}

