package com.chaos.engine;


/**
* Names of commands and component types understood by engine plugins.
* @author Erick Feiling
*/
class EngineTypes
{
    
    // Core plugin
    /** Component type for a display layer. */
    public static inline var LAYER : String = "Layer";
    /** Component type for a screen. */
    public static inline var SCREEN : String = "Screen";
    /** Component type for a UI element. */
    public static inline var ELEMENT : String = "Element";
    
    /** Command that looks up a screen. */
    public static inline var GET_SCREEN : String = "GetScreen";
    /** Command that looks up an element. */
    public static inline var GET_ELEMENT : String = "GetElement";
    
    /** Command that removes an element. */
    public static inline var REMOVE_ELEMENT : String = "RemoveElement";
    /** Command that removes a screen. */
    public static inline var REMOVE_SCREEN : String = "RemoveScreen";
    /** Command that removes a layer. */
    public static inline var REMOVE_LAYER : String = "RemoveLayer";
    
    /** Command that adds an item to a layer. */
    public static inline var ADD_LAYER_ITEM : String = "AddLayerItem";
    
    /** Command that updates component data. */
    public static inline var DATA_UPDATE : String = "DataUpdate";
    
    // UI and theme plugin
    /** Command that looks up an item. */
    public static inline var GET_ITEM : String = "GetItem";
    /** Command that removes an item. */
    public static inline var REMOVE_ITEM : String = "RemoveItem";
    /** Command that updates an item. */
    public static inline var UPDATE_ITEM : String = "UpdateItem";
    
    /** Command that loads a theme. */
    public static inline var LOAD_THEME : String = "LoadTheme";
    /** Command that applies a theme. */
    public static inline var SET_THEME : String = "SetTheme";
    
    // Media plugin
    /** Command that looks up an image. */
    public static inline var GET_IMAGE : String = "GetImage";
    /** Command that adds an image. */
    public static inline var ADD_IMAGE : String = "AddImage";
    /** Command that removes an image. */
    public static inline var REMOVE_IMAGE : String = "RemoveImage";
    /** Command that displays an image. */
    public static inline var DISPLAY_IMAGE : String = "DisplayImage";
    
    /** Command that loads video. */
    public static inline var VIDEO_LOAD : String = "VideoLoad";
    /** Command that starts video playback. */
    public static inline var VIDEO_PLAY : String = "VideoPlay";
    /** Command that pauses video playback. */
    public static inline var VIDEO_PAUSE : String = "VideoPause";
    /** Command that stops video playback. */
    public static inline var VIDEO_STOP : String = "VideoStop";
    /** Command that seeks within video. */
    public static inline var VIDEO_SEEK : String = "VideoSeek";
    /** Command that changes video volume. */
    public static inline var VIDEO_VOLUME : String = "VideoVolume";
    
    /** Command that loads a sound. */
    public static inline var SOUND_LOAD : String = "SoundLoad";
    /** Command that starts sound playback. */
    public static inline var SOUND_PLAY : String = "SoundPlay";
    /** Command that pauses sound playback. */
    public static inline var SOUND_PAUSE : String = "SoundPause";
    /** Command that stops sound playback. */
    public static inline var SOUND_STOP : String = "SoundStop";
    /** Command that seeks within a sound. */
    public static inline var SOUND_SEEK : String = "SoundSeek";
    /** Command that changes sound volume. */
    public static inline var SOUND_VOLUME : String = "SoundVolume";
    
    /** Component type for a two-dimensional panorama. */
    public static inline var PANORAMA_2D : String = "Panorama2D";
        
    
    // Layouts
    /** Component type for a container. */
    public static inline var CONTAINER : String = "Container";
    /** Component type for a fitted container. */
    public static inline var FIT_CONTAINER : String = "FitContainer";
    /** Component type for a grid container. */
    public static inline var GRID_CONTAINER : String = "GridContainer";
    /** Component type for a horizontal container. */
    public static inline var HORIZONTAL_CONTAINER : String = "HorizontalContainer";
    /** Component type for a vertical container. */
    public static inline var VERTICAL_CONTAINER : String = "VerticalContainer";

    /** Command that adds an item to a container. */
    public static inline var CONTAINER_ADD_ITEM : String = "ContainerAddItem";
    /** Command that removes an item from a container. */
    public static inline var CONTAINER_REMOVE_ITEM : String = "ContainerRemoveItem";
    
    /** Creates the command and component type registry. */
    public function new()
    {
    }
}

