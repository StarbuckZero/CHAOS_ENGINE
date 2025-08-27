package com.chaos.engine.plugin;

import haxe.Json;
import haxe.macro.Type.Ref;
import openfl.display.BitmapData;
import com.chaos.ui.data.BaseObjectData;
import com.chaos.engine.CommandDispatch;
import com.chaos.form.FormBuilder;
import com.chaos.form.ui.CheckBoxList;
import com.chaos.form.ui.DateField;
import com.chaos.form.ui.DropDownMenu;
import com.chaos.form.ui.EmailField;
import com.chaos.form.ui.InputField;
import com.chaos.form.ui.PasswordField;
import com.chaos.form.ui.PhoneNumberField;
import com.chaos.form.ui.RadioButtonList;
import com.chaos.form.ui.Select;
import com.chaos.form.ui.TextLabel;
import com.chaos.form.classInterface.IFormBuilder;
import com.chaos.form.ui.classInterface.IFormUI;

import com.chaos.media.DisplayImage;
import com.chaos.ui.event.ComboBoxEvent;
import com.chaos.ui.event.GridPaneEvent;
import com.chaos.ui.event.MenuEvent;
import com.chaos.ui.event.SliderEvent;
import com.chaos.ui.event.WindowEvent;
import com.chaos.ui.ScrollPolicy;
import com.chaos.ui.Alert;
import com.chaos.ui.CheckBox;
import com.chaos.ui.CheckBoxGroup;
import com.chaos.ui.ComboBox;
import com.chaos.ui.Label;
import com.chaos.ui.TextInput;
import com.chaos.ui.ToolTip;
import com.chaos.ui.ListBox;
import com.chaos.ui.RadioButtonGroup;
import com.chaos.ui.Button;
import com.chaos.ui.ToggleButton;
import com.chaos.ui.RadioButton;
import com.chaos.ui.ScrollBar;
import com.chaos.ui.ItemPane;
import com.chaos.ui.Slider;
import com.chaos.ui.GridPane;
import com.chaos.ui.Menu;
import com.chaos.ui.TabPane;
import com.chaos.ui.ScrollPane;
import com.chaos.ui.Window;
import com.chaos.ui.WindowManager;
import com.chaos.ui.ProgressBar;

import com.chaos.ui.BaseUI;
import com.chaos.ui.layout.BaseContainer;
import com.chaos.ui.layout.GridCellLayout;

import com.chaos.mobile.ui.Breadcrumb;
import com.chaos.mobile.ui.Carousel;
import com.chaos.mobile.ui.MobileButtonList;
import com.chaos.mobile.ui.NavigationMenu;
import com.chaos.mobile.ui.MobileDropDown;
import com.chaos.mobile.ui.ToggleSwitch;

import com.chaos.ui.classInterface.IRadioButtonGroup;
import com.chaos.ui.classInterface.IBaseUI;
import com.chaos.ui.classInterface.IToggleButton;
import com.chaos.ui.classInterface.IButton;
import com.chaos.ui.classInterface.IListBox;
import com.chaos.ui.classInterface.ICheckBoxGroup;
import com.chaos.ui.classInterface.IComboBox;
import com.chaos.ui.classInterface.IItemPane;
import com.chaos.ui.classInterface.ITextInput;
import com.chaos.ui.classInterface.ILabel;

import com.chaos.ui.classInterface.ISlider;
import com.chaos.ui.classInterface.IGridPane;
import com.chaos.ui.classInterface.IMenu;
import com.chaos.ui.classInterface.ITabPane;

import com.chaos.mobile.ui.classInterface.IBreadcrumb;
import com.chaos.mobile.ui.classInterface.IDragContainer;
import com.chaos.mobile.ui.classInterface.INavigationMenu;
import com.chaos.mobile.ui.classInterface.IToggleSwitch;


import com.chaos.ui.classInterface.IWindow;
import com.chaos.ui.classInterface.IScrollPane;
import com.chaos.ui.classInterface.IScrollBar;
import com.chaos.ui.classInterface.IProgressBar;
import com.chaos.ui.layout.classInterface.IBaseContainer;
import com.chaos.ui.data.ComboBoxObjectData;
import com.chaos.ui.data.ListObjectData;
import com.chaos.ui.data.ItemPaneObjectData;
import com.chaos.ui.data.MenuItemObjectData;
import com.chaos.data.DataProvider;
import com.chaos.utils.ThreadManager;
import com.chaos.utils.classInterface.ITask;
import com.chaos.utils.data.TaskDataObject;
import com.chaos.engine.CommandCentral;
import com.chaos.engine.EngineTypes;
import com.chaos.engine.Global;
import com.chaos.engine.loader.ThemeLoader;
import com.chaos.utils.Debug;
import com.chaos.utils.Utils;

import openfl.display.Sprite;
import openfl.display.DisplayObject;
import openfl.events.EventDispatcher;
import openfl.display.Bitmap;
import openfl.display.Shape;
import openfl.events.Event;
import openfl.events.FocusEvent;
import openfl.events.MouseEvent;
import openfl.events.ProgressEvent;

/**
* All of the UI elements
* @author Erick Feiling
*/
class CoreUIFrameworkPlugin
{
    
    
    private static var winManagers : Dynamic = {};
    
    private var _eventDispatcher : EventDispatcher = new EventDispatcher();
    
    public function new()
    {
    }
    
    // Core UI Classes
    public static function initialize() : Void
    {
        // Default UI
        CommandCentral.addCommand("Button", createButton);
        CommandCentral.addCommand("ToggleButton", createToggleButton);
        CommandCentral.addCommand("RadioButton", createRadioButton);
        CommandCentral.addCommand("CheckBox", createCheckBox);
        CommandCentral.addCommand("ComboBox", createComboBox);
        CommandCentral.addCommand("ListBox", createListBox);
        CommandCentral.addCommand("ItemPane", createItemPane);
        CommandCentral.addCommand("Label", createLabel);
        CommandCentral.addCommand("TextInput", createTextInput);
        CommandCentral.addCommand("Alert", createAlertBox);
        CommandCentral.addCommand("Slider", createSlider);
        CommandCentral.addCommand("GridPane", createGridPane);
        CommandCentral.addCommand("Menu", createMenu);
        CommandCentral.addCommand("TabPane", createTabPane);
        CommandCentral.addCommand("ScrollPane", createScrollPane);
        CommandCentral.addCommand("Window", createWindow);
        CommandCentral.addCommand("WindowManager", createWindowManager);
        CommandCentral.addCommand("ToolTip", updateToolTip);
        CommandCentral.addCommand("ProgressBar", createProgressBar);
        CommandCentral.addCommand("FormBuilder", createForm);

        // Mobile
        CommandCentral.addCommand("Breadcrumb", createBreadcrumb);
        CommandCentral.addCommand("Carousel", createCarousel);
        CommandCentral.addCommand("ButtonList", createButtonList);
        CommandCentral.addCommand("NavigationMenu", createNavigationMenu);
        CommandCentral.addCommand("MobileDropDown", createMobileDropDown);
        CommandCentral.addCommand("ToggleSwitch", createToggleSwitch);

        // Theme <- Redo to use plugins
        CommandCentral.addCommand(EngineTypes.LOAD_THEME, loadTheme);
        CommandCentral.addCommand(EngineTypes.SET_THEME, setTheme);
        
        // Get Object
        CommandCentral.addCommand(EngineTypes.GET_ITEM, getItem);
        CommandCentral.addCommand(EngineTypes.REMOVE_ITEM, removeItem);
        CommandCentral.addCommand(EngineTypes.UPDATE_ITEM, updateItem);
        
        // Data
        //CommandCentral.addCommand(EngineTypes.DATA_UPDATE, updateItemData);
    }
    
    
    private static function loadTheme(data : Dynamic) : Dynamic
    {
        
        if (Reflect.hasField(data,"url"))
            ThemeLoader.load(Reflect.field(data,"url"));

        return null;
    }
    
    
    private static function setTheme(data : Dynamic) : Dynamic
    {
        ThemeLoader.setTheme(data);

        return null;
    }
    
    private static function getItem(data : Dynamic) : Dynamic
    {
        return Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
    }
    
    private static function updateItem(data : Dynamic) : Dynamic {

        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        var objectType : String = "";
        var itemData : Dynamic = Reflect.field(data,"data");

        // Get type of object
        for( type in Reflect.fields(itemData)) {
            Debug.print("[CoreUIFrameworkPlugin::updateItem] UI Object Type: " + type );
            objectType = type;
        }


        if(objectType != "") {
            CoreCommandPlugin.setComponentData(Reflect.field(itemData,objectType), cast(displayObj, IBaseUI));
        }

        return displayObj;
    }
     
    private static function removeItem(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (Std.isOfType(displayObj, IBaseUI))
            CommandDispatch.removeAllEvents(try cast(displayObj, IBaseUI) catch(e:Dynamic) null);
        
        
        if (Std.isOfType(displayObj, IBaseContainer))
            CoreCommandPlugin.removeContainerEvents(try cast(displayObj, IBaseContainer) catch(e:Dynamic) null);
        
        if (null != displayObj.parent)
            return displayObj.parent.removeChild(displayObj);
        
        return null;
    }

    private static function createBreadcrumb(data : Dynamic) : Dynamic {

        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, Breadcrumb))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
            
            var breadcrumb : IBreadcrumb = new Breadcrumb(data);
            
            // Add to display
            CoreCommandPlugin.displayUpdate(breadcrumb, data);
                        
            return breadcrumb;
        }
        
        return null;        
    }


    private static function createCarousel(data : Dynamic) : Dynamic {

        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, Carousel))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
            
            var carousel : IBaseContainer = new Carousel(data);
            
            // Add to display
            CoreCommandPlugin.displayUpdate(carousel, data);
                        
            return carousel;
        }
        
        return null;        
    }

    private static function createButtonList(data : Dynamic) : Dynamic {

        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, MobileButtonList))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
            
            var buttonList : IBaseContainer = new MobileButtonList(data);
            
            // Add to display
            CoreCommandPlugin.displayUpdate(buttonList, data);
                        
            return buttonList;
        }
        
        return null;        
    }    

    private static function createNavigationMenu(data : Dynamic) : Dynamic {

        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, Carousel))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
            
            var navigationMenu : IBaseContainer = new NavigationMenu(data);
            
            // Add to display
            CoreCommandPlugin.displayUpdate(navigationMenu, data);
                        
            return navigationMenu;
        }
        
        return null;  
    }

    private static function createMobileDropDown(data : Dynamic) : Dynamic {

        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, MobileDropDown))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
            
            var mobileDropDown : IBaseUI = new MobileDropDown(data);
            
            // Add to display
            CoreCommandPlugin.displayUpdate(mobileDropDown, data);
                        
            return mobileDropDown;
        }
        
        return null;  
    }

    private static function createToggleSwitch(data : Dynamic) : Dynamic {

        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, ToggleSwitch))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
            
            var toggleSwitch : IBaseUI = new ToggleSwitch(data);
            
            // Add to display
            CoreCommandPlugin.displayUpdate(toggleSwitch, data);
                        
            return toggleSwitch;
        }
        
        return null;  
    }
    
    private static function updateToolTip(data : Dynamic) : Dynamic
    {
        if ( Reflect.hasField(data,"text") && Reflect.hasField(data,"attach"))
        {
            var objWidth : Int =  Reflect.hasField(data,"width") ? Reflect.field(data,"width") : -1;
            var objHeight : Int = Reflect.hasField(data,"height") ? Reflect.field(data,"height") : -1;
            var objTextColor : Int = Reflect.hasField(data,"textColor") ? Reflect.field(data,"textColor") : -1;
            var border : Bool = Reflect.hasField(data,"border") ? Reflect.field(data,"border") : false;
            var borderColor : Int = Reflect.hasField(data,"borderColor") ? Reflect.field(data,"borderColor") : -1;
            var backgroundColor : Int =  Reflect.hasField(data,"backgroundColor") ? Reflect.field(data,"backgroundColor") : -1;
            
            if (Reflect.hasField(data,"delay"))
                ToolTip.delay = Reflect.field(data,"delay");
            
            if (Reflect.hasField(data,"followMouse"))
                ToolTip.followMouse = Reflect.field(data,"followMouse");
                        
            ToolTip.attach( Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"attach")), Reflect.field(data,"text"), objWidth, objHeight, objTextColor, backgroundColor, border, borderColor);
        }
        
        if (Reflect.hasField(data,"remove"))
            ToolTip.remove(Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"remove")));

        return null;
    }
    
    
    private static function createForm(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, FormBuilder))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj,BaseUI));

            if(Reflect.hasField(data,"data"))
                updateForm(Reflect.field(data,"data"), cast(displayObj,FormBuilder));

            return displayObj;
        }
        else
        {
            var form : IFormBuilder = new FormBuilder(data);

            if(Reflect.hasField(data,"data"))
                updateForm(Reflect.field(data,"data"), form);
    
            CoreCommandPlugin.displayUpdate(form, data);
            return form;
        }


    }
    
    private static function createProgressBar(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, ProgressBar))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
            
            var progress : IProgressBar = new ProgressBar(data);
            
            // Add to display
            CoreCommandPlugin.displayUpdate(progress, data);
            
            
            CommandDispatch.attachEvent(progress, ProgressEvent.PROGRESS);
            CommandDispatch.attachEvent(progress, Event.COMPLETE);
            
            return progress;
        }
        
        return null;
    }
    
    private static function createWindowManager(data : Dynamic) : Dynamic
    {

        var newWindowManagerHolder : IBaseContainer = new BaseContainer(data);
        var windowManager : WindowManager = new WindowManager();
        windowManager.name = "window_manager";
        
        newWindowManagerHolder.background = false;
        
        Reflect.setField(winManagers, Std.string(newWindowManagerHolder.name), windowManager);
        
        cast(newWindowManagerHolder.content, Sprite).addChildAt(windowManager, 0);
        
        return windowManager;
    }
    
    private static function createWindow(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, Window))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));

            return displayObj;
        }
        else
        {
    
            var window : IWindow = new Window(data);
            
            
            if (Reflect.hasField(data,"manager"))
            {
                if (Reflect.hasField(winManagers, Reflect.field(data,"manager"))) {
                    var windowManager : WindowManager = Reflect.field(winManagers, Reflect.field(data,"manager"));
                    windowManager.addChild(window.displayObject);
                }
                else
                    Debug.print("[UIFrameworkPlugin::createWindow] Couldn't find window manager by the name of " + Reflect.field(data,"manager") + ".");
            }
            
            // Add to display
            CoreCommandPlugin.displayUpdate(window, data);
            
            CommandDispatch.attachEvent(window, WindowEvent.WINDOW_CLOSE_BTN);
            CommandDispatch.attachEvent(window, WindowEvent.WINDOW_MAX_BTN);
            CommandDispatch.attachEvent(window, WindowEvent.WINDOW_MIN_BTN);
            CommandDispatch.attachEvent(window, WindowEvent.WINDOW_RESIZE);
            
            CommandDispatch.attachEvent(window, MouseEvent.MOUSE_UP);
            
            return window;
        }
        
        return null;
    }
    
    private static function createTabPane(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, TabPane))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            return displayObj;
        }
        else
        {

            var tabPane : ITabPane = new TabPane(data);
            
            // Add to display
            CoreCommandPlugin.displayUpdate(tabPane, data);
            CommandDispatch.attachEvent(tabPane, Event.CHANGE);
            
            return tabPane;
        }
        
        return null;
    }
    
    private static function createScrollPane(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, ScrollPane))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            return displayObj;
        }
        else
        {
            


            var scrollPane : IScrollPane = new ScrollPane(data);
            
            CoreCommandPlugin.displayUpdate(scrollPane, data);
            
            return scrollPane;
        }
        
        return null;
    }
    
    private static function createButton(data : Dynamic) : Dynamic
    {        
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (displayObj != null && Std.isOfType(displayObj, Button))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
   
            var button : IButton = new Button(data);
            
            CommandDispatch.attachEvent(button, MouseEvent.CLICK);
            CoreCommandPlugin.displayUpdate(button, data);
            
            return button;
        }
        
        return null;
    }
    
    private static function createToggleButton(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));

        if (displayObj != null && Std.isOfType(displayObj, ToggleButton))
            {
                CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
                
                return displayObj;
            }
            else
            {
                
                var toggleBtn : IToggleButton = new ToggleButton(data);
        
                CoreCommandPlugin.displayUpdate(toggleBtn, data);
                CommandDispatch.attachEvent(toggleBtn, MouseEvent.CLICK);

                return toggleBtn;
            }

            return null;
    }
    
    
    private static function createMenu(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name") );
        
        if (null != displayObj && Std.isOfType(displayObj, Menu))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));

            return displayObj;
        }
        else
        {
            

            
            // Do check for in data obj reverse
            var menu : IMenu = new Menu(data);
            
            CoreCommandPlugin.displayUpdate(menu, data);
            CommandDispatch.attachEvent(menu, MenuEvent.MENU_BUTTON_CLICK);
            
            return menu;
        }
        
        return null;
    }
    
    private static function createGridPane(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name") );
        
        if (null != displayObj && Std.isOfType(displayObj, GridPane))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));

            if(Reflect.hasField(data,"column"))
                updateGridPane(Reflect.field(data,"column"), cast(displayObj,GridPane));

            return displayObj;
        }
        else
        {

            
            var gridPane : IGridPane = new GridPane(data);

            if(Reflect.hasField(data,"column"))
                updateGridPane(Reflect.field(data,"column"), cast(gridPane,GridPane));
            
            CoreCommandPlugin.displayUpdate(gridPane, data);
            
            CommandDispatch.attachEvent(gridPane, GridPaneEvent.SELECT);
            CommandDispatch.attachEvent(gridPane, GridPaneEvent.CHANGE);
            
            gridPane.draw();
            
            return gridPane;
        }
        
        return null;
    }
    
    private static function createSlider(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name") );
        
        if (null != displayObj && Std.isOfType(displayObj, Slider))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));

            return displayObj;
        }
        else
        {

            
            var slider : ISlider = new Slider(data);

            CoreCommandPlugin.displayUpdate(slider, data);
            CommandDispatch.attachEvent(slider, SliderEvent.CHANGE);
            
            return slider;
        }
        
        return null;
    }
    
    private static function createAlertBox(data : Dynamic) : Dynamic
    {
        // Must have everything
        if (Reflect.hasField(data,"message") && Reflect.hasField(data,"title") && Reflect.hasField(data,"displayArea"))
        {
            var alertBoxIcon : BitmapData = null;
            var windowIcon : BitmapData = null;
            
            if (Reflect.hasField(data,"alertBoxIcon"))
                alertBoxIcon = Reflect.field(data,"alertBoxIcon");
            
            if (Reflect.hasField(data,"windowIcon"))
                windowIcon = Reflect.field(data,"windowIcon");


            var displayArea:Sprite = Reflect.field(data,"windowIcon");
            var message : String = Reflect.field(data,"message");
            var title : String = Reflect.field(data,"title");

            var buttonArray:Array<AlertButtonType> = alertButtonType( Reflect.field(data,"button") );
                        
            var alert : Sprite = Alert.create( message, title, buttonArray, alertBoxIcon , windowIcon, onAlertButtonClick);
            
            displayArea.addChild(alert);
            return alert;
        }
        
        setAlertBox(data);
        
        
        return null;
    }
    
    private static function createLabel(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name") );
        
        if (null != displayObj && Std.isOfType(displayObj, Label))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            return displayObj;
        }
        else
        {

            
            var label : ILabel = new Label(data);
            
            CoreCommandPlugin.displayUpdate(label, data);
            CommandDispatch.attachEvent(label, MouseEvent.CLICK);
            
            return label;
        }
        
        return null;
    }
    
    private static function createTextInput(data : Dynamic) : Dynamic
    {
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name") );
        
        if (null != displayObj && Std.isOfType(displayObj, TextInput))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));

            return displayObj;
        }
        else
        {
        
            
            var label : ITextInput = new TextInput(data);
            
            CoreCommandPlugin.displayUpdate(label, data);
            
            
            CommandDispatch.attachEvent(label, FocusEvent.FOCUS_IN);
            CommandDispatch.attachEvent(label, FocusEvent.FOCUS_OUT);
            
            return label;
        }
        
        return null;
    }
    
    
    
    
    
    private static function createRadioButton(data : Dynamic) : Dynamic    
    {
        //{"RadioButton":{"name":"radioButtonGroup","group":"groupName","width":200,"height":300,"items":[{"name":"Radio2","text":"Radio 1","selected":false},{"name":"Radio2","text":"Radio 2","selected":false},{"name":"Radio3","text":"Radio 3","selected":false}]}}
        
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, RadioButtonGroup))
        {
            // Remove old stuff
            cast(displayObj, BaseContainer).removeAll();

            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {

            if(!Reflect.hasField(data,"group"))
                Reflect.setField(data,"group", Reflect.field(data,"group"));
            else
                Reflect.setField(data,"group", "radioButtonGroup");
    
            var radioGroup : IRadioButtonGroup = new RadioButtonGroup( data );
    
            CoreCommandPlugin.displayUpdate(radioGroup, data);
            CommandDispatch.attachEvent(radioGroup, Event.CHANGE);

            return radioGroup;
    
        }
        
        
        return null;
    }
    
    private static function createCheckBox(data : Dynamic) : Dynamic
    {
        //{"CheckBox":{"name":"checkBoxGroup","group":"checkGroup","width":200,"height":300,"items":[{"name":"check1","text":"Check 1","selected":false},{"name":"check2","text":"Check 2","selected":true},{"name":"check3","text":"Check 3","selected":false}]}}
        
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));

        if (null != displayObj && Std.isOfType(displayObj, CheckBoxGroup)) 
        {

            cast(displayObj, BaseContainer).removeAll();
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
            var checkGroup : ICheckBoxGroup = new CheckBoxGroup(data);
        
            CoreCommandPlugin.displayUpdate(checkGroup, data);
            CommandDispatch.attachEvent(checkGroup, Event.CHANGE);
            
            return checkGroup;
        }

        return null;
        

    }
    
    private static function createComboBox(data : Dynamic) : Dynamic
    {
        // {"ComboBox":{"name":"OSDropDown","width":100,"height":20,"items":[{"id":1,"text":"Linux","value":"Linux","selected":false},{"id":2,"text":"Windows","value":"Win","selected":false},{"id":3,"text":"Mac","value":"OSX","selected":false}]}}
        
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, Reflect.field(data,"name"));
        
        if (null != displayObj && Std.isOfType(displayObj, ComboBox))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
            

            var comboBox : IComboBox = new ComboBox(data);
                        
            CoreCommandPlugin.displayUpdate(comboBox, data);
            CommandDispatch.attachEvent(comboBox, ComboBoxEvent.CHANGE);
            
            return comboBox;
        }
        
        return null;
    }
    
    private static function createListBox(data : Dynamic) : Dynamic
    {
        // {"List":{"name":"OSDropDown","width":100,"height":20,"data":[{"id":1,"text":"Linux","value":"Linux","selected":false},{"id":2,"text":"Windows","value":"Win","selected":false},{"id":3,"text":"Mac","value":"OSX","selected":false}]}}

        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, data.name);
        
        if (null != displayObj && Std.isOfType(displayObj, ListBox))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {

            var listBox : IListBox = new ListBox(data);
            
            CoreCommandPlugin.displayUpdate(listBox, data);
            CommandDispatch.attachEvent(listBox, Event.CHANGE);
            
            return listBox;
        }
        
        return null;
    }
    
    private static function createItemPane(data : Dynamic) : Dynamic    
    {
        // {"ItemPane":{"name":"ImageGallery","width":400,"height":300,"data":[{"id":1,"text":"Photo 1","value":"1","tooltip":"Photo 1","selected":false},{"id":2,"text":"Photo 2","value":"2","tooltip":"Photo 2","selected":false},{"id":3,"text":"Photo 3","tooltip":"Photo 2","value":"3","selected":false}]}}
        
        var displayObj : DisplayObject = Utils.getNestedChild(Global.mainDisplyArea, data.name);
        
        if (null != displayObj && Std.isOfType(displayObj, ItemPane))
        {
            CoreCommandPlugin.setComponentData(data, cast(displayObj, IBaseUI));
            
            return displayObj;
        }
        else
        {
            
            var itemPane : IItemPane = new ItemPane(data);
            
            CoreCommandPlugin.displayUpdate(itemPane, data);
            CommandDispatch.attachEvent(itemPane, Event.CHANGE);
            
            return itemPane;
        }
        
        return null;
    }
    
    private static function updateForm(data:Dynamic, formBuilder:IFormBuilder ) : Void {

        for(item in Reflect.fields(Reflect.field(data,"data"))) {

            var elementClass : Class<Dynamic> = null;
            var elementParams : Dynamic = null;
            var layoutClass : Dynamic = null;
            var params : Dynamic = null;

            if(Reflect.hasField(item,"elementClass"))
                elementClass = getFormClass(Reflect.field(item,"elementClass"));

            if(Reflect.hasField(item,"elementClass"))
                elementParams = Reflect.field(item,"elementParams");

            if(Reflect.hasField(item,"layoutClass"))
                layoutClass = getCellLayout(Reflect.field(item,"layoutClass"));

            if(Reflect.hasField(item,"layoutClass"))
                params = Reflect.field(item,"params");

            formBuilder.addFormElement(Reflect.field(item,"labelName"), Reflect.field(item,"elementName"), elementClass , elementParams , layoutClass , params );

        }

    }

    private static function updateGridPane(column:Array<Dynamic>, gridPane:IGridPane ) : Void {

        /*
        for(i in column ... column.length) {

            var colData:Dynamic = column[i];

            if(Reflect.hasField(colData,"colName") && Reflect.hasField(colData,"element") && Reflect.hasField(colData,"dataRowName")) {

                var colName : String = Reflect.field(colData,"colName");
                var element : Class<Dynamic> = getFormClass(Reflect.field(colData,"element"));
                var dataRowName : String = Reflect.field(colData,"dataRowName");
                var gridLayout : Class<Dynamic> = null;
                var data : Dynamic = {};

                if(Reflect.hasField(colData,"gridLayout"))
                    gridLayout = getCellLayout(Reflect.field(colData,"gridLayout"));

                if(Reflect.hasField(colData,"data"))
                    data = getCellLayout(Reflect.field(colData,"data"));

                gridPane.addColumn(colName, element, dataRowName, gridLayout, data);
    
            }
                
        }
        */

        
    }
    
    private static function setAlertBox(data : Dynamic) : Void
    {
        /*
        if (Reflect.hasField(data,"tintAlpha"))
            Alert.tintAlpha = Reflect.field(data,"tintAlpha");
        
        if (Reflect.hasField(data,"tintBackgroundColor"))
            Alert.tintBackgroundColor = Reflect.field(data,"tintBackgroundColor");
        
        if (Reflect.hasField(data,"alignWindowToCenter"))
            Alert.alignWindowToCenter = Reflect.field(data,"alignWindowToCenter");
        */
    }
    
    
    private static function getFormClass(type : String) : Dynamic
    {
        switch (type)
        {
            case "CheckBoxList":
                return CheckBoxList;
            
            case "DateField":
                return DateField;
            
            case "DropDownMenu":
                return DropDownMenu;
            
            case "EmailField":
                return EmailField;
            
            case "InputField":
                return InputField;
            
            case "PasswordField":
                return PasswordField;
            
            case "PhoneNumberField":
                return PhoneNumberField;
            
            case "RadioButtonList":
                return RadioButtonList;
            
            case "Select":
                return Select;
            
            case "TextLabel":
                return TextLabel;
            default:
                Debug.print("[CoreFrameworkPlugin::getFormClass] Did not find type " + type + " using TextLabel.");
                return TextLabel;
        }
        
        return null;
    }
    
    private static function getCellLayout(layout : String) : Dynamic
    {
        switch (layout.toUpperCase())
        {
            case "FIT":
                return GridCellLayout.FIT;
            
            case "HORIZONTAL":
                return GridCellLayout.HORIZONTAL;
            
            case "VERTICAL":
                return GridCellLayout.VERTICAL;
            default:
                return GridCellLayout.FIT;
        }
        
        
        return null;
    }
    
    private static function alertButtonType(buttonData:Array<String>) : Array<AlertButtonType> {

        var buttonArray:Array<AlertButtonType> = new Array<AlertButtonType>();

        
        for (i in 0 ... buttonData.length) {

            if(buttonData[i].toUpperCase() == "CANCEL")
                buttonArray.push(AlertButtonType.CANCEL);

            if(buttonData[i].toUpperCase() == "OK")
                buttonArray.push(AlertButtonType.OK);

            if(buttonData[i].toUpperCase() == "YES")
                buttonArray.push(AlertButtonType.YES);

            if(buttonData[i].toUpperCase() == "NO")
                buttonArray.push(AlertButtonType.NO);

            if(buttonData[i].toUpperCase() == "MAYBE")
                buttonArray.push(AlertButtonType.MAYBE);

            if(buttonData[i].toUpperCase() == "NONMODAL")
                buttonArray.push(AlertButtonType.NONMODAL);            
        }	        

        return buttonArray;
    }

    private static function onAlertButtonClick(event : MouseEvent) : Void
    {
        if(Std.isOfType(event.currentTarget,DisplayObject))
        {
            var displayObj:DisplayObject = cast(event.currentTarget, DisplayObject);

            //TODO: Fix later
            //CommandDispatch.dispatch(Alert.TYPE, "click", {button :displayObj.name});
        }

    }
}

