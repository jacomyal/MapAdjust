/*
# Copyright (c) 2010 Alexis Jacomy <alexis.jacomy@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
*/

package com.carte_du_tendre.y2010.display{
	
	import com.carte_du_tendre.y2010.data.Graph;
	import com.carte_du_tendre.y2010.data.Node;
	import com.dncompute.graphics.ArrowStyle;
	import com.dncompute.graphics.GraphicsUtil;
	import com.zavoo.svg.SvgPaths;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.display.Stage;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	
	import flashx.textLayout.formats.Float;
	
	public class MainDisplayElement extends Sprite{
		
		public static const NODE_SELECTED:String= "New node selected";
		public static const GRAPH_VIEW:String = "Graph view";
		public static const MAX_SCALE:Number = 50;
		public static const STEPS:Number = 12;
		
		private var _currentSelectionDisplayAttributes:DisplayAttributes;
		private var _currentDisplayedNodes:Vector.<DisplayNode>;
		private var _constantDisplayNodes:Vector.<DisplayNode>;
		private var _currentDisplayedMainNode:DisplayNode;
		private var _nextNodesToDisplay:Vector.<Node>;
		private var _isGraphView:Boolean; //true: Graph view, false: Local view
		private var _selectedNode:Node;
		private var _graph:Graph;
		
		private var _initialGraphSpatialState:Array; //[top_left_x,top_left_y,bottom_right_x,bottom_right_y,scale]
		private var _localView_edgesToDraw:Array;
		private var _attributesAreaWidth:Number;
		private var _sceneXCenter:Number;
		private var _sceneYCenter:Number;
		private var _svgPaths:SvgPaths;
		private var _edgesScale:Number;
		private var _historic:Array;
	
		private var _svgInfoField:TextField;
		private var _axeSprite:Sprite;
		private var _mobileSprite:Sprite;
		private var _initXScale:Number;
		private var _initYScale:Number;
		
		private var _moveStep:Array;
		private var _isReady:Boolean;
		private var _framesNumber:int;
		private var _style:ArrowStyle;
		private var _angleDelay:Number;
		private var _edgesContainer:Sprite;
		private var _nodesContainer:Sprite;
		private var _labelsContainer:Sprite;
		private var _attributesContainer:Sprite;
		private var _backgroundContainer:Sprite;
		private var _nodesHitAreaContainer:Sprite;
		
		public function MainDisplayElement(new_parent:DisplayObjectContainer,newGraph:Graph,newSvgPath:String){
			new_parent.addChild(this);
			_graph = newGraph;
			
			_moveStep = new Array();
			_angleDelay = 1/8.5;
			
			_backgroundContainer = new Sprite();
			_attributesContainer = new Sprite();
			_edgesContainer = new Sprite();
			_nodesContainer = new Sprite();
			_labelsContainer = new Sprite();
			_nodesHitAreaContainer = new Sprite();
			_attributesAreaWidth = DisplayAttributes.TEXTFIELD_WIDTH;
			
			_isReady = false;
			_currentDisplayedMainNode = null;
			_currentSelectionDisplayAttributes = null;
			_initialGraphSpatialState = [-500,-500,500,500,1];
			_edgesScale = Math.min(stage.stageWidth/3-20,stage.stageHeight/3-20);
			
			_sceneXCenter = stage.stageWidth/2;
			_sceneYCenter = stage.stageHeight/2;
			
			addChild(_backgroundContainer);
			addChild(_edgesContainer);
			addChild(_nodesContainer);
			addChild(_labelsContainer);
			addChild(_nodesHitAreaContainer);
			parent.addChild(_attributesContainer);
			
			_style = new ArrowStyle();
			_style.headLength = 10;
			_style.headWidth = 10;
			_style.shaftPosition = 0;
			_style.shaftThickness = 4;
			_style.edgeControlPosition = 0.5;
			_style.edgeControlSize = 0.5;
			
			trace("MainDisplayElement.MainDisplayElement: GUI initiated.");
			
			// Display the background:
			var backgroundPath:String = newSvgPath;
			graphView_backgroundInit(backgroundPath);
			_backgroundContainer.x = 0;
			_backgroundContainer.y = 0;
			_backgroundContainer.scaleX = 1;
			_backgroundContainer.scaleY = 1;
			
			// Display the informations:
			_svgInfoField = new TextField();
			refreshSVGInfo();
			_svgInfoField.x = 10;
			_svgInfoField.y = 10;
			this.stage.addChild(_svgInfoField);
			
			addEventListener(Event.ENTER_FRAME,refreshHandler);
			
			// Axe sprite and mobile sprite:
			_axeSprite = new Sprite();
			_axeSprite.graphics.lineStyle(1.5,0x000000);
			_axeSprite.graphics.moveTo(0,5);
			_axeSprite.graphics.lineTo(0,100);
			_axeSprite.graphics.drawCircle(0,0,5);
			_axeSprite.x = stage.stageWidth-30;
			_axeSprite.y = 30;
			stage.addChild(_axeSprite);
			
			_mobileSprite = new Sprite();
			_mobileSprite.graphics.lineStyle(0,0x000000,0);
			_mobileSprite.graphics.beginFill(0x339933);
			_mobileSprite.graphics.drawCircle(0,0,4.5);
			_mobileSprite.x = stage.stageWidth-30;
			_mobileSprite.y = 80;
			stage.addChild(_mobileSprite);
			
			processScaling();
			
			drawGraph();
		}
		
		private function whileDragMobile(e:Event):void{
			_backgroundContainer.scaleX = _initXScale*(_mobileSprite.y/80);
			_backgroundContainer.scaleY = _initYScale*(_mobileSprite.y/80);
		}
		
		private function refreshHandler(e:Event):void{
			refreshSVGInfo();
		}
		
		private function refreshSVGInfo():void{
			_svgInfoField.htmlText = '<font face="Verdana" size="12" color="#996633">SVG paths information:' +
				'\n\t- Background X = '+_backgroundContainer.x+',' +
				'\n\t- Background Y = '+-_backgroundContainer.y+',' +
				'\n\t- Background X scale = '+_backgroundContainer.scaleX+',' +
				'\n\t- Background Y scale = '+_backgroundContainer.scaleY+',' +
				'\n\t- Background width = '+_backgroundContainer.width+',' +
				'\n\t- Background height = '+_backgroundContainer.height+',' +
				'</font>';
			_svgInfoField.autoSize = TextFieldAutoSize.LEFT;
		}

		public function drawGraph():void{
			var node:Node;
			var displayNode:DisplayNode;
			
			_historic = null;
			_isReady = false;
			_isGraphView = true;
			_currentSelectionDisplayAttributes = null;
			_edgesContainer.graphics.clear();
			removeDisplayedNodes();
			
			addChildAt(_backgroundContainer,0);
			
			if(_currentDisplayedMainNode!=null){
				_currentDisplayedMainNode = null;
			}
			
			_currentDisplayedNodes = new Vector.<DisplayNode>();
			
			for each(node in _graph.nodes){
				displayNode = new DisplayNode(node,stage.stageWidth/2,stage.stageHeight/2);
				_currentDisplayedNodes.push(displayNode);
				
				addNodeAsChild(displayNode);
				displayNode.setStep(node.x,node.y,2*STEPS);
			}
			
			graphView_processDisplayNodesScaling();
			graphView_addEventListeners();
			graphView_transitionLauncher();
			processScaling();
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL,graphView_zoomScene);
			stage.addEventListener(MouseEvent.MOUSE_DOWN,graphView_drag);
			stage.addEventListener(MouseEvent.MOUSE_UP,graphView_drop);
		}
		
		private function processScaling():void{
			var xMin:Number = _graph.nodes[0].x;
			var xMax:Number = _graph.nodes[0].x;
			var yMin:Number = _graph.nodes[0].y;
			var yMax:Number = _graph.nodes[0].y;
			var ratio:Number;
			
			for (var i:Number = 1;i<_graph.nodes.length;i++){
				if(_graph.nodes[i].x < xMin)
					xMin = _graph.nodes[i].x;
				if(_graph.nodes[i].x > xMax)
					xMax = _graph.nodes[i].x;
				if(_graph.nodes[i].y < yMin)
					yMin = _graph.nodes[i].y;
				if(_graph.nodes[i].y > yMax)
					yMax = _graph.nodes[i].y;
			}
			
			var xCenter:Number = (xMax + xMin)/2;
			var yCenter:Number = (yMax + yMin)/2;
			
			var xSize:Number = xMax - xMin;
			var ySize:Number = yMax - yMin;
			
			ratio = Math.min(stage.stageWidth/(xSize),stage.stageHeight/(ySize))*0.6;
			
			_initialGraphSpatialState = [stage.stageWidth/2-xCenter*ratio,stage.stageHeight/2-yCenter*ratio,
										 stage.stageWidth/2-xCenter*ratio+stage.stageWidth/ratio,
										 stage.stageHeight/2-yCenter*ratio+stage.stageHeight/ratio,ratio];
			
			moveGraphScene(stage.stageWidth/2-xCenter*ratio,stage.stageHeight/2-yCenter*ratio,ratio);
		}
		
		private function processFirstSVGScale():void{
			_backgroundContainer.x = (_initialGraphSpatialState[0]+_initialGraphSpatialState[2])/2 - _backgroundContainer.width/2;
			_backgroundContainer.y = (_initialGraphSpatialState[1]+_initialGraphSpatialState[3])/2 - _backgroundContainer.height/2;
		}
		
		private function moveGraphScene(new_x:Number,new_y:Number,new_ratio:Number):void{
			this.x = new_x;
			this.y = new_y;
			this.scaleX = new_ratio;
			this.scaleY = new_ratio;
		}
		
		private function addNodeAsChild(displayNode:DisplayNode):void{
			_nodesContainer.addChild(displayNode);
			_labelsContainer.addChild(displayNode.labelField);
			_nodesHitAreaContainer.addChild(displayNode.upperCircle);
		}
		
		private function removeNodeAsChild(displayNode:DisplayNode):void{
			_nodesContainer.removeChild(displayNode);
			_labelsContainer.removeChild(displayNode.labelField);
			_nodesHitAreaContainer.removeChild(displayNode.upperCircle);
		}
		
		private function addNodeAsTopChild(displayNode:DisplayNode):void{
			this.addChild(displayNode);
			this.addChild(displayNode.labelField);
			this.addChild(displayNode.upperCircle);
		}
		
		private function removeNodeAsTopChild(displayNode:DisplayNode):void{
			this.removeChild(displayNode);
			this.removeChild(displayNode.labelField);
			this.removeChild(displayNode.upperCircle);
		}
		
		private function removeDisplayedNodes():void{
			var l:int;
			var i:int;
			
			//Remove first the nodes themselves:
			l = _nodesContainer.numChildren;
			for(i=0;i<l;i++){
				_nodesContainer.removeChildAt(l-1-i);
			}
			
			//Remove secondly the edges:
			l = _edgesContainer.numChildren;
			for(i=0;i<l;i++){
				_edgesContainer.removeChildAt(l-1-i);
			}
			
			//Remove next the labels:
			l = _labelsContainer.numChildren;
			for(i=0;i<l;i++){
				_labelsContainer.removeChildAt(l-1-i);
			}
			
			//Remove the attributes:
			l = _attributesContainer.numChildren;
			for(i=0;i<l;i++){
				_attributesContainer.removeChildAt(l-1-i);
			}
			
			//Remove finally the hit areas:
			l = _nodesHitAreaContainer.numChildren;
			for(i=0;i<l;i++){
				_nodesHitAreaContainer.removeChildAt(l-1-i);
			}
		}
		
		private function removeLabelFieldFromStage():void{
			var l:int = this.numChildren;
			var i:int;
			
			for(i=0;i<l;i++){
				if(this.getChildAt(l-1-i) is TextField){
					this.removeChildAt(l-1-i);
				}
			}
		}
		
		private function graphView_addEventListeners():void{
			var l:int = _currentDisplayedNodes.length;
			
			stage.addEventListener(MouseEvent.MOUSE_WHEEL,graphView_zoomScene);
			stage.addEventListener(MouseEvent.MOUSE_DOWN,graphView_drag);
			stage.addEventListener(MouseEvent.MOUSE_UP,graphView_drop);
		}
		
		private function graphView_removeEventListeners():void{
			var l:int = _currentDisplayedNodes.length;
			
			stage.removeEventListener(MouseEvent.MOUSE_WHEEL,graphView_zoomScene);
			stage.removeEventListener(MouseEvent.MOUSE_DOWN,graphView_drag);
			stage.removeEventListener(MouseEvent.MOUSE_UP,graphView_drop);
		}
		
		private function graphView_transitionLauncher():void{
			_framesNumber = 0;
			addEventListener(Event.ENTER_FRAME,graphView_transition);
		}
		
		private function graphView_transition(e:Event):void{
			if(_framesNumber>=2*STEPS){
				removeEventListener(Event.ENTER_FRAME,graphView_transition);
				_isReady = true;
				dispatchEvent(new Event(GRAPH_VIEW));
			}else{
				// All nodes:
				var displayNode:DisplayNode;
				
				for each(displayNode in _currentDisplayedNodes){
					displayNode.moveTo(displayNode.x+displayNode.step[0],displayNode.y+displayNode.step[1]);
				}
				
				_framesNumber++;
			}
		}
		
		private function graphView_processDisplayNodesScaling():void{
			var displayNode:DisplayNode;
			
			for each(displayNode in _currentDisplayedNodes){
				displayNode.size = DisplayNode.NODES_SCALE*displayNode.node.size;
				displayNode.draw();
			}
		}
		
		public function graphView_zoomScene(evt:MouseEvent):void{
			var new_scale:Number;
			var new_x:Number;
			var new_y:Number;
			var a:Array = _initialGraphSpatialState;
			
			if (evt.delta>=0){
				//new_scale = Math.min(a[4]*MAX_SCALE,this.scaleX*1.5);
				new_scale = this.scaleX*1.5;
				new_x = evt.stageX+(this.x-evt.stageX)*new_scale/this.scaleX;
				new_y = evt.stageY+(this.y-evt.stageY)*new_scale/this.scaleY;
			}else{
				//new_scale = Math.max(a[4]/2,this.scaleX*2/3);
				new_scale = this.scaleX*2/3;
				new_x = evt.stageX+(this.x-evt.stageX)*new_scale/this.scaleX;
				new_y = evt.stageY+(this.y-evt.stageY)*new_scale/this.scaleY;
			}
			
			//new_x = Math.min(a[2]-stage.stageWidth/new_scale,new_x);
			//new_x = Math.max(a[0],new_x);
			//new_y = Math.min(a[3]-stage.stageHeight/new_scale,new_y);
			//new_y = Math.max(a[1],new_y);
			
			moveGraphSceneSlowly(new_x,new_y,new_scale);
		}
		
		private function moveGraphSceneSlowly(new_x:Number,new_y:Number,new_ratio:Number):void{
			_moveStep[0] = new_x;
			_moveStep[1] = new_y;
			_moveStep[2] = new_ratio;
			
			stage.removeEventListener(MouseEvent.MOUSE_DOWN,graphView_drag);
			stage.removeEventListener(MouseEvent.MOUSE_UP,graphView_drop);
			addEventListener(Event.ENTER_FRAME,slowDisplacementHandler);
		}
		
		private function slowDisplacementHandler(e:Event):void{
			var d2:Number = Math.pow(this.x-_moveStep[0],2)+Math.pow(this.y-_moveStep[1],2)+Math.pow(this.scaleX-_moveStep[2],2);
			
			if(d2<1){
				moveGraphScene(_moveStep[0], _moveStep[1], _moveStep[2]);
				removeEventListener(Event.ENTER_FRAME,slowDisplacementHandler);
				if(_isGraphView==true){
					stage.addEventListener(MouseEvent.MOUSE_DOWN,graphView_drag);
					stage.addEventListener(MouseEvent.MOUSE_UP,graphView_drop);
				}
			}else{
				moveGraphScene(this.x/2 + _moveStep[0]/2, this.y/2 + _moveStep[1]/2, this.scaleX/2 + _moveStep[2]/2);
			}
		}
		
		private function graphView_drag(evt:MouseEvent):void{
			var a:Array = _initialGraphSpatialState;
			var rect:Rectangle = new Rectangle(a[0]/a[4]*this.scaleX,
											   a[1]/a[4]*this.scaleY,
											   10000,10000);
											   //a[2]-stage.stageWidth/a[4]-a[0],
											   //a[3]-stage.stageHeight/a[4]-a[1]);
			//this.startDrag(false,rect);
			
			if(evt.target == _backgroundContainer){
				_backgroundContainer.startDrag();
			}else if(evt.target == _mobileSprite){
				_initXScale = _backgroundContainer.scaleX;
				_initYScale = _backgroundContainer.scaleY;
				
				var rect2:Rectangle = new Rectangle(stage.stageWidth-30,30,0,100);
				_mobileSprite.startDrag(true,rect2);
				stage.addEventListener(Event.ENTER_FRAME,whileDragMobile);
				stage.addEventListener(MouseEvent.MOUSE_UP,dropMobile);
			}else{
				this.startDrag();
			}
		}
		
		private function dropMobile(e:MouseEvent):void{
			stage.removeEventListener(Event.ENTER_FRAME,whileDragMobile);
			stage.removeEventListener(MouseEvent.MOUSE_UP,dropMobile);
			_mobileSprite.x = stage.stageWidth-30;
			_mobileSprite.y = 80;
		}
		
		private function graphView_drop(evt:MouseEvent):void{
			_backgroundContainer.stopDrag();
			this.stopDrag();
		}
		
		public function graphView_backgroundInit(path:String):void{
			var loader:URLLoader = new URLLoader();
			var request:URLRequest = new URLRequest(path);
			loader.load(request);
			loader.addEventListener(Event.COMPLETE, graphView_onSvgLoadComplete);	
		}
		
		private function graphView_onSvgLoadComplete(event:Event):void {
			var loader:URLLoader = URLLoader(event.target);
			_svgPaths = new SvgPaths(loader.data);		    
			
			_svgPaths.drawToGraphics(_backgroundContainer.graphics, 1, 10, 10);
		}
		
		public function get graph():Graph{
			return _graph;
		}

		public function set graph(value:Graph):void{
			_graph = value;
		}

		public function get nodesHitAreaContainer():Sprite{
			return _nodesHitAreaContainer;
		}
		
		public function set nodesHitAreaContainer(value:Sprite):void{
			_nodesHitAreaContainer = value;
		}
		
		public function get attributesContainer():Sprite{
			return _attributesContainer;
		}
		
		public function set attributesContainer(value:Sprite):void{
			_attributesContainer = value;
		}
		
		public function get labelsContainer():Sprite{
			return _labelsContainer;
		}
		
		public function set labelsContainer(value:Sprite):void{
			_labelsContainer = value;
		}
		
		public function get nodesContainer():Sprite{
			return _nodesContainer;
		}
		
		public function set nodesContainer(value:Sprite):void{
			_nodesContainer = value;
		}
		
		public function get edgesContainer():Sprite{
			return _edgesContainer;
		}
		
		public function set edgesContainer(value:Sprite):void{
			_edgesContainer = value;
		}
		
		public function get angleDelay():Number{
			return _angleDelay;
		}
		
		public function set angleDelay(value:Number):void{
			_angleDelay = value;
		}
		
		public function get isReady():Boolean{
			return _isReady;
		}
		
		public function set isReady(value:Boolean):void{
			_isReady = value;
		}
		
		public function get selectedNode():Node{
			return _selectedNode;
		}
		
		public function set selectedNode(value:Node):void{
			_selectedNode = value;
		}
		
		public function get nextNodesToDisplay():Vector.<Node>{
			return _nextNodesToDisplay;
		}
		
		public function set nextNodesToDisplay(value:Vector.<Node>):void{
			_nextNodesToDisplay = value;
		}
		
		public function get currentDisplayedMainNode():DisplayNode{
			return _currentDisplayedMainNode;
		}
		
		public function set currentDisplayedMainNode(value:DisplayNode):void{
			_currentDisplayedMainNode = value;
		}
		
		public function get currentDisplayedNodes():Vector.<DisplayNode>{
			return _currentDisplayedNodes;
		}
		
		public function set currentDisplayedNodes(value:Vector.<DisplayNode>):void{
			_currentDisplayedNodes = value;
		}
		
		public function get currentSelectionDisplayAttributes():DisplayAttributes{
			return _currentSelectionDisplayAttributes;
		}
		
		public function set currentSelectionDisplayAttributes(value:DisplayAttributes):void{
			_currentSelectionDisplayAttributes = value;
		}
		
		public function get constantDisplayNodes():Vector.<DisplayNode>{
			return _constantDisplayNodes;
		}
		
		public function set constantDisplayNodes(value:Vector.<DisplayNode>):void{
			_constantDisplayNodes = value;
		}
		
		public function get moveStep():Array{
			return _moveStep;
		}
		
		public function set moveStep(value:Array):void{
			_moveStep = value;
		}
		
		public function get isGraphView():Boolean{
			return _isGraphView;
		}
		
		public function set isGraphView(value:Boolean):void{
			_isGraphView = value;
		}
		
		public function get style():ArrowStyle{
			return _style;
		}
		
		public function set style(value:ArrowStyle):void{
			_style = value;
		}
		
		public function get framesNumber():int{
			return _framesNumber;
		}
		
		public function set framesNumber(value:int):void{
			_framesNumber = value;
		}
		
		public function get localView_edgesToDraw():Array{
			return _localView_edgesToDraw;
		}
		
		public function set localView_edgesToDraw(value:Array):void{
			_localView_edgesToDraw = value;
		}
		
		public function get attributesAreaWidth():Number{
			return _attributesAreaWidth;
		}
		
		public function set attributesAreaWidth(value:Number):void{
			_attributesAreaWidth = value;
		}
		
		public function get sceneYCenter():Number{
			return _sceneYCenter;
		}
		
		public function set sceneYCenter(value:Number):void{
			_sceneYCenter = value;
		}
		
		public function get sceneXCenter():Number{
			return _sceneXCenter;
		}
		
		public function set sceneXCenter(value:Number):void{
			_sceneXCenter = value;
		}
		
		public function get initialGraphSpatialState():Array{
			return _initialGraphSpatialState;
		}
		
		public function set initialGraphSpatialState(value:Array):void{
			_initialGraphSpatialState = value;
		}
		
		public function get historic():Array{
			return _historic;
		}
		
		public function set historic(value:Array):void{
			_historic = value;
		}
		
		public function get svgPaths():SvgPaths{
			return _svgPaths;
		}
		
		public function set svgPaths(value:SvgPaths):void{
			_svgPaths = value;
		}
		
		public function get backgroundContainer():Sprite{
			return _backgroundContainer;
		}
		
		public function set backgroundContainer(value:Sprite):void{
			_backgroundContainer = value;
		}
		
		public function get edgesScale():Number{
			return _edgesScale;
		}
		
		public function set edgesScale(value:Number):void{
			_edgesScale = value;
		}
	}
}