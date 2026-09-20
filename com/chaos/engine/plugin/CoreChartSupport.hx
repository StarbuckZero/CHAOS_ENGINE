package com.chaos.engine.plugin;

import com.chaos.ui.chart.*;
import com.chaos.ui.event.ChartEvent;
import com.chaos.engine.CommandCentral;
import com.chaos.engine.CommandDispatch;
import com.chaos.engine.events.EventCapabilities;
import com.chaos.utils.Utils;
import openfl.display.DisplayObject;
import openfl.display.DisplayObjectContainer;
import openfl.display.BitmapData;

/** Runtime-only chart registration; Studio factories and panels are independent. */
class CoreChartSupport {
    public static var types(default, null):Array<String> = ["ColumnChart", "BarChart", "GroupedBarChart", "StackedBarChart", "LineChart", "AreaChart", "ScatterPlot", "PieChart", "DonutChart", "Histogram", "Heatmap"];

    private static var pendingBuilds:haxe.ds.ObjectMap<DisplayObject, {id:String, task:com.chaos.utils.classInterface.ITask}> = new haxe.ds.ObjectMap();

    /** Track deferred children so removing an unfinished screen/container cannot recreate them. */
    public static function queueBuild(id:String, node:DisplayObject, items:Array<Dynamic>, callback:com.chaos.utils.classInterface.ITask->Void):Void {
        if (items.length == 0) return;
        var task = new com.chaos.utils.data.TaskDataObject(node.name, 0, items.length, function(task) {
            callback(task);
            if (task.index >= task.end) pendingBuilds.remove(node);
        }, [items, node]);
        pendingBuilds.set(node, {id:id, task:task});
        com.chaos.utils.ThreadManager.addTask(id, task);
    }

    public static function initialize():Void {
        var names = ["Rollover", "Rollout", "MouseDown", "MouseUp", "Clicked", "OnChange"];
        var events = [ChartEvent.ROLL_OVER, ChartEvent.ROLL_OUT, ChartEvent.MOUSE_DOWN, ChartEvent.MOUSE_UP, ChartEvent.CLICK, ChartEvent.CHANGE];
        for (type in types) {
            CommandCentral.addCommand(type, data -> create(type, data));
            if (Reflect.hasField(EventCapabilities.catalog, type)) continue;
            // Extend the generated legacy catalog without modifying its generated source.
            Reflect.setField(EventCapabilities.catalog, type, {runtimeClass:"com.chaos.ui.chart." + type,
                events:[for (i in 0...names.length) {type:names[i], eventName:events[i], receiver:"", source:"receiver"}],
                note:"Chart mark events; payload preserves data identity. Raw mouse events are not bindings."});
        }
    }

    public static function componentData(data:Dynamic):Dynamic {
        var result:Dynamic = {};
        for (field in Reflect.fields(data))
            if (["displayArea", "events", "redraw", "_resolvedEventTarget", "_eventPayload"].indexOf(field) < 0)
                Reflect.setField(result, field, Reflect.field(data, field));
        return result;
    }

    static function create(type:String, data:Dynamic):ChartBase {
        var area = CoreCommandPlugin.getDisplayObject(data);
        var name:String = Reflect.field(data, "name");
        var previous = name == null ? null : Utils.getNestedChild(area, name);
        if (Std.isOfType(previous, ChartBase) && cast(previous, ChartBase).chartType == type) {
            cast(previous, ChartBase).setComponentData(componentData(data));
            return cast previous;
        }
        var index = previous != null && previous.parent != null ? previous.parent.getChildIndex(previous) : -1;
        var parent = previous == null ? null : previous.parent;
        if (previous != null) {
            disposeTree(previous);
            if (parent != null) parent.removeChild(previous);
        }
        var chart:ChartBase = switch type {
            case "ColumnChart": new ColumnChart();
            case "BarChart": new BarChart();
            case "GroupedBarChart": new GroupedBarChart();
            case "StackedBarChart": new StackedBarChart();
            case "LineChart": new LineChart();
            case "AreaChart": new AreaChart();
            case "ScatterPlot": new ScatterPlot();
            case "PieChart": new PieChart();
            case "DonutChart": new DonutChart();
            case "Histogram": new Histogram();
            case "Heatmap": new Heatmap();
            default: throw "Unsupported chart " + type;
        };
        var frameworkResolver = chart.textureResolver;
        chart.textureResolver = function(key, complete, failed) {
            frameworkResolver(key, complete, function(_) {
                var config = chart.toChartData();
                var reference:String = key;
                if (config.Bitmap != null && Std.isOfType(Reflect.field(config.Bitmap, key), String)) reference = Reflect.field(config.Bitmap, key);
                var projectImage:BitmapData = CommandCentral.runCommand("GetImage", {image:reference});
                if (projectImage != null) { complete(projectImage); return; }
                // Same OpenFL decoders as DisplayImage, with explicit failure and ownership handling.
                function loaded(bitmap:BitmapData):Void {
                    if (bitmap == null) { failed("Empty texture: " + reference); return; }
                    complete(bitmap);
                    bitmap.dispose(); // ChartTexture synchronously clones the borrowed image.
                }
                try {
                    if (StringTools.startsWith(reference, "data:image/")) {
                        var comma = reference.indexOf(",");
                        if (comma < 0 || reference.substring(0, comma).indexOf(";base64") < 0) throw "Invalid base64 image";
                        BitmapData.loadFromBytes(haxe.crypto.Base64.decode(reference.substr(comma + 1)))
                            .onComplete(loaded).onError(error -> failed(Std.string(error)));
                    } else {
                        BitmapData.loadFromFile(reference).onComplete(loaded).onError(error -> failed(Std.string(error)));
                    }
                } catch (error:Dynamic) { failed(Std.string(error)); }
            });
        };
        chart.setComponentData(componentData(data));
        if (parent != null) parent.addChildAt(chart, index); else CoreCommandPlugin.displayUpdate(chart, data);
        return chart;
    }

    /** Dispose chart resources throughout arbitrary display/container trees, without destroying other controls. */
    public static function disposeTree(node:DisplayObject):Void {
        if (node == null) return;
        var pending = pendingBuilds.get(node);
        if (pending != null) {
            com.chaos.utils.ThreadManager.removeTask(pending.id, pending.task);
            pending.task.clear(); pendingBuilds.remove(node);
        }
        com.chaos.engine.events.EventPlugin.detachTree(node);
        if (Std.isOfType(node, com.chaos.ui.classInterface.IBaseUI)) CommandDispatch.removeAllEvents(cast node);
        if (Std.isOfType(node, ChartBase)) { cast(node, ChartBase).destroy(); return; }
        if (Std.isOfType(node, DisplayObjectContainer)) {
            var container:DisplayObjectContainer = cast node;
            for (i in 0...container.numChildren) disposeTree(container.getChildAt(i));
        }
    }
}
