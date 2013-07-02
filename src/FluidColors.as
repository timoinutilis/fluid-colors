package
{
	import com.adobe.serialization.json.JSON;
	
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.GradientType;
	import flash.display.InteractiveObject;
	import flash.display.PixelSnapping;
	import flash.display.Shape;
	import flash.display.SpreadMethod;
	import flash.display.Sprite;
	import flash.display.StageAlign;
	import flash.display.StageDisplayState;
	import flash.display.StageScaleMode;
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.events.TimerEvent;
	import flash.external.ExternalInterface;
	import flash.filters.BlurFilter;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.system.Security;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.text.TextFormat;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	[SWF(width = "640", height = "480", frameRate = "20", backgroundColor="0xFFFFFF")]
	public class FluidColors extends Sprite
	{
CONFIG::editor
{
		[Embed(source="editor_colors_config.txt", mimeType="application/octet-stream")]
		private const DefaultConfigText:Class;
		
		[Embed(source="logo.png", mimeType="image/png")]
		private const Logo:Class;
}

		public static const START_COLOR:uint = 0xFFFFFF;
		public static const WIDTH:Number = 640;
		public static const HEIGHT:Number = 480;
		
		public static const config:Config = new Config();

		private var _container:Sprite;
		private var _colorsBitmap:Bitmap;
		private var _spots:Vector.<Vector.<Spot>>;
		private var _blur:BlurFilter;
		private var _currentColorSetIndex:int;
		private var _timer:Timer;
		private var _rectWidth:int;
		private var _rectHeight:int;
		private var _examples:Vector.<String>;
		
		private var _textFormat:TextFormat;
		private var _editorContainer:Sprite;
		private var _tf:TextField;
		private var _editor:TextField;
		private var _version:TextField
		private var _scrollBar:ScrollBar;
		private var _controlButtonsContainer:Sprite;
		private var _exampleButtonsContainer:Sprite;
		private var _exampleButtons:Vector.<TextField>;
		private var _okButton:TextField;
		private var _loaderFileRef:FileReference;
		
		public function FluidColors()
		{
			Security.allowDomain("*");
			
			stage.scaleMode = StageScaleMode.NO_SCALE;
			stage.align = StageAlign.TOP_LEFT;
			
			_textFormat = new TextFormat("_sans", 18);

			CONFIG::editor
			{
				initEditor();
			}
			CONFIG::player
			{
				initPlayer();
			}
			
			if (ExternalInterface.available)
			{
				try
				{
					ExternalInterface.addCallback("Colors_onMouseMove", onMouseMoveJS);
				}
				catch (e:Error)
				{
					// ignore
				}
			}
			
			stage.addEventListener(Event.RESIZE, onResizePlayer);
		}
		
		private function resizeEditor():void
		{
			
		}
		
CONFIG::editor
{
		private function initEditor():void
		{			
			var logo:Bitmap = new Logo() as Bitmap;
			logo.smoothing = true;
			logo.x = 10;
			logo.y = 10;
			
			_version = new TextField();
			_version.defaultTextFormat = _textFormat;
			_version.autoSize = TextFieldAutoSize.RIGHT;
			_version.alpha = 0.25;
			_version.text = "1.0";
			_version.y = 10 + logo.height - _version.height;
			
			_editor = new TextField();
			_editor.defaultTextFormat = _textFormat;
			_editor.multiline = true;
			_editor.border = true;
			_editor.type = TextFieldType.INPUT;
			_editor.x = 10;
			_editor.y = 10 + logo.height;
			_editor.addEventListener(Event.SCROLL, onScroll);
			_editor.addEventListener(Event.CHANGE, refreshScrollBar);
			
			_scrollBar = new ScrollBar();
			
			var textBytes:ByteArray = new DefaultConfigText() as ByteArray;
			var text:String = textBytes.toString();
			var examplesArray:Array = text.split("----\n");
			_examples = Vector.<String>(examplesArray);
			
			_exampleButtonsContainer = new Sprite();
			
			var examplesText:TextField = new TextField();
			examplesText.defaultTextFormat = _textFormat;
			examplesText.autoSize = TextFieldAutoSize.LEFT;
			examplesText.text = "Examples: ";
			examplesText.x = 0;
			_exampleButtonsContainer.addChild(examplesText);

			_exampleButtons = new Vector.<TextField>();
			for (var i:int = 0; i < _examples.length; i++)
			{
				var button:TextField = createButton(String(i+1), (button != null) ? button.x + button.width + 5 : examplesText.width, 0);
				button.addEventListener(MouseEvent.CLICK, onClickExample);
				_exampleButtonsContainer.addChild(button);
				_exampleButtons.push(button);
			}
			
			setExample(0);
			refreshScrollBar();
			
			_controlButtonsContainer = new Sprite();
			
			var testButton:TextField = createButton("Test it!", 0, 0);
			testButton.addEventListener(MouseEvent.CLICK, onClickTest);
			
			var saveButton:TextField = createButton("Save", testButton.x + testButton.width + 10, 0);
			saveButton.addEventListener(MouseEvent.CLICK, onClickSave);
			
			var loadButton:TextField = createButton("Load", saveButton.x + saveButton.width + 10, 0);
			loadButton.addEventListener(MouseEvent.CLICK, onClickLoad);
			
			var fullscreenButton:TextField = createButton("Fullscreen", loadButton.x + loadButton.width + 10, 0);
			fullscreenButton.addEventListener(MouseEvent.CLICK, onClickFullscreen);

			_controlButtonsContainer.addChild(testButton);
			_controlButtonsContainer.addChild(saveButton);
			_controlButtonsContainer.addChild(loadButton);
			_controlButtonsContainer.addChild(fullscreenButton);
			
			_okButton = createButton("OK", 10, 40);
			_okButton.addEventListener(MouseEvent.CLICK, onClickOK);
			
			_editorContainer = new Sprite();
			_editorContainer.addChild(logo);
			_editorContainer.addChild(_version);
			_editorContainer.addChild(_editor);
			_editorContainer.addChild(_scrollBar);
			_editorContainer.addChild(_controlButtonsContainer);
			_editorContainer.addChild(_exampleButtonsContainer);
			addChild(_editorContainer);
			
			stage.addEventListener(Event.RESIZE, onResizeEditor);
			onResizeEditor();
			
			_loaderFileRef = new FileReference();
			_loaderFileRef.addEventListener(Event.SELECT, onLoadSelect);
			_loaderFileRef.addEventListener(Event.COMPLETE, onLoadComplete);
		}
		
		private function onResizeEditor(e:Event = null):void
		{
			_editor.width = stage.stageWidth - 30;
			_editor.height = stage.stageHeight - _editor.y - 60;
			
			_scrollBar.x = _editor.x + _editor.width + 3;
			_scrollBar.y = _editor.y;
			_scrollBar.width = 8;
			_scrollBar.height = _editor.height + 1;
			
			_version.x = stage.stageWidth - 16 - _version.width;
			
			_controlButtonsContainer.x = 10;
			_controlButtonsContainer.y = stage.stageHeight - 45;
			_exampleButtonsContainer.x = _editor.x + _editor.width - _exampleButtonsContainer.width;
			_exampleButtonsContainer.y = stage.stageHeight - 45;

			refreshScrollBar();
		}
		
		private function onScroll(e:Event):void
		{
			_scrollBar.position = _editor.scrollV - 1;
		}
		
		private function refreshScrollBar(e:Event = null):void
		{
			_scrollBar.max = _editor.numLines;
			_scrollBar.numVisible = Math.floor((_editor.height) / (Number(_textFormat.size) + 4));
		}
		
		public function setExample(index:int):void
		{
			_editor.text = _examples[Math.min(index, _examples.length - 1)];
			refreshScrollBar();
		}
		
		private function createButton(text:String, x:Number, y:Number):TextField
		{
			var button:TextField = new TextField();
			button.defaultTextFormat = _textFormat;
			button.autoSize = TextFieldAutoSize.LEFT;
			button.border = true;
			button.text = " " + text + " ";
			button.background = true;
			button.backgroundColor = 0xCCCCCC;
			button.selectable = false;
			button.x = x;
			button.y = y;
			button.addEventListener(MouseEvent.ROLL_OVER, onOverButton);
			button.addEventListener(MouseEvent.ROLL_OUT, onOutButton);
			button.addEventListener(MouseEvent.MOUSE_DOWN, onDownButton);
			button.addEventListener(MouseEvent.MOUSE_UP, onOverButton);
			return button;
		}
		
		private function onOverButton(e:MouseEvent):void
		{
			var textField:TextField = e.currentTarget as TextField;
			textField.backgroundColor = 0xEEEEEE;
		}
		
		private function onOutButton(e:MouseEvent):void
		{
			var textField:TextField = e.currentTarget as TextField;
			textField.backgroundColor = 0xCCCCCC;
		}
		
		private function onDownButton(e:MouseEvent):void
		{
			var textField:TextField = e.currentTarget as TextField;
			textField.backgroundColor = 0xCCDDEE;
		}
		
		private function onClickTest(e:MouseEvent):void
		{
			removeChild(_editorContainer);
			initConfig(_editor.text);
		}
		
		private function onClickSave(e:MouseEvent):void
		{
			var fileRef:FileReference = new FileReference();
			fileRef.save(_editor.text, "colors_config.json");
		}
		
		private function onClickLoad(e:MouseEvent):void
		{
			_loaderFileRef.browse([new FileFilter("Configuration (*.json)", "*.json")]);
		}
		
		private function onLoadSelect(e:Event):void
		{
			_loaderFileRef.load();
		}
		
		private function onLoadComplete(e:Event):void
		{
			var text:String = _loaderFileRef.data.toString();
			_editor.text = text;
		}
		
		private function onClickFullscreen(e:MouseEvent):void
		{
			if (stage.displayState == StageDisplayState.NORMAL)
			{	
				stage.displayState = StageDisplayState.FULL_SCREEN;
			}
			else
			{
				stage.displayState = StageDisplayState.NORMAL;
			}
		}
		
		private function onClickExample(e:MouseEvent):void
		{
			var button:TextField = e.currentTarget as TextField;
			var index:int = _exampleButtons.indexOf(button);
			setExample(index);
		}
		
		private function onClickOK(e:MouseEvent):void
		{
			removeEventListener(MouseEvent.CLICK, onClickOK);
			if (_container != null)
			{
				reset();
			}
			if (_tf != null && _tf.parent != null)
			{
				removeChild(_tf);
			}
			if (_okButton != null && _okButton.parent != null)
			{
				removeChild(_okButton);
			}
			addChild(_editorContainer);
		}
		
		private function reset():void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			_container.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			CONFIG::editor
			{
				_container.removeEventListener(MouseEvent.CLICK, onClickOK);
			}
			
			_blur = null;
			
			_timer.reset();
			_timer.removeEventListener(TimerEvent.TIMER, onTimer);
			_timer = null;
			
			removeChild(_container);
			_colorsBitmap = null;
			_container = null;
		}

}
		
CONFIG::player
{
		private function initPlayer():void
		{
			var request:URLRequest = new URLRequest("colors_config.json");
			
			var loader:URLLoader = new URLLoader();
			loader.addEventListener(Event.COMPLETE, onConfigLoaded);
			loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
			loader.load(request);
		}

		private function onError(e:ErrorEvent):void
		{
			showError("Could not load configuration file!");
		}
		
		private function onConfigLoaded(e:Event):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			initConfig(loader.data);
		}
}
		
		private function showError(text:String):void
		{
			if (_tf == null)
			{
				_tf = new TextField();
				_tf.defaultTextFormat = _textFormat;
				_tf.autoSize = TextFieldAutoSize.LEFT;
				_tf.textColor = 0xFF0000;
				_tf.x = 10;
				_tf.y = 10;
			}
			addChild(_tf);
			_tf.text = text;
			
			CONFIG::editor
			{
				addChild(_okButton);
			}
		}
		
		private function initConfig(configText:String):void
		{
			var configObject:Object;
			try
			{
				configObject = com.adobe.serialization.json.JSON.decode(configText);
				config.parse(configObject);
			}
			catch (e:Error)
			{
				showError("Configuration file: " + e.toString());
				return;
			}
			
			_rectWidth = 640 / config.columns;
			_rectHeight = 480 / config.rows;
			
			_colorsBitmap = new Bitmap(new BitmapData(config.columns * _rectWidth, config.rows * _rectHeight, false, config.backgroundColor), PixelSnapping.ALWAYS, true);
			_colorsBitmap.width = WIDTH;
			_colorsBitmap.height = HEIGHT;
			
			_currentColorSetIndex = Math.random() * config.colorSets.length;
			
			_spots = new Vector.<Vector.<Spot>>();
			for (var row:int = 0; row < config.rows; row++)
			{
				_spots[row] = new Vector.<Spot>();
				for (var column:int = 0; column < config.columns; column++)
				{
					_spots[row][column] = new Spot(this);
				}
			}
			
			_container = new Sprite();
			_container.addChild(_colorsBitmap);
			
			if (config.mask)
			{
				var maskShape:Shape = new Shape();
				var matrix:Matrix = new Matrix();
				var gradientWidth:Number = WIDTH * config.maskScale;
				var gradientHeight:Number = HEIGHT * config.maskScale;
				matrix.createGradientBox(gradientWidth, gradientHeight, 0, 0.5 * (WIDTH - gradientWidth), 0.5 * (HEIGHT - gradientHeight));
				maskShape.graphics.beginGradientFill(GradientType.RADIAL, [config.maskColor, config.maskColor], [0.0, 1.0], [0, 255], matrix, SpreadMethod.PAD);
				maskShape.graphics.drawRect(0, 0, WIDTH, HEIGHT);
				_container.addChild(maskShape);
			}

			addChild(_container);

			if (config.blurX > 0 || config.blurY > 0)
			{
				_blur = new BlurFilter(_rectWidth * config.blurX, _rectHeight * config.blurY, 3);
			}
						
			_timer = new Timer(config.setChangeSeconds * 1000);
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
			_timer.start();
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			_container.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			CONFIG::editor
			{
				_container.addEventListener(MouseEvent.CLICK, onClickOK);
			}
			
			onResizePlayer();
		}
		
		public function getColor(column:int, row:int):Spot
		{
			if (column >= 0 && row >= 0 && column < config.columns && row < config.rows)
			{
				return _spots[row][column];
			}
			return null;
		}
		
		public function get currentColorSet():Vector.<uint>
		{
			return config.colorSets[_currentColorSetIndex];
		}
		
		public function get currentMouseColor():uint
		{
			var index:int = Math.min(_currentColorSetIndex, config.mouseColors.length - 1);
			return config.mouseColors[index];
		}
		
		private function onEnterFrame(e:Event):void
		{
			var border:Number;
			if (_rectWidth > _rectHeight)
			{
				border = _rectHeight - (_rectHeight * config.spotScale);
			}
			else
			{
				border = _rectWidth - (_rectWidth * config.spotScale);
			}
			var rect:Rectangle = new Rectangle(0, 0, _rectWidth - border, _rectHeight - border);
			
			if ((config.blurX != 0 || config.blurY != 0) && config.spotScale < 1)
			{
				_colorsBitmap.bitmapData.fillRect(_colorsBitmap.bitmapData.rect, config.backgroundColor);
			}
			
			for (var column:int = 0; column < config.columns; column++)
			{
				for (var row:int = 0; row < config.rows; row++)
				{
					rect.x = column * _rectWidth + border * 0.5;
					rect.y = row * _rectHeight + border * 0.5;
					_spots[row][column].update();
					_colorsBitmap.bitmapData.fillRect(rect, _spots[row][column].currentColor);
				}
			}
			
			rect.x = 0;
			rect.y = 0;
			rect.width = _colorsBitmap.bitmapData.width;
			rect.height = _colorsBitmap.bitmapData.height;
			if (_blur != null)
			{
				_colorsBitmap.bitmapData.applyFilter(_colorsBitmap.bitmapData, rect, new Point(0, 0), _blur);
			}
		}
		
		private function onMouseMove(e:MouseEvent):void
		{
			var stagePos:Point = new Point(e.stageX, e.stageY);
			if (stagePos.x != 0 && stagePos.y != 0)
			{
				var pos:Point = _colorsBitmap.globalToLocal(stagePos);
				onMouseMovePoint(pos);
			}
		}
		
		private function onMouseMoveJS(posX:Number, posY:Number):void
		{
			if (_container != null)
			{
				// stop listening to Flash mouse events if there are JavaScript events.
				_container.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
				
				var pos:Point = new Point(posX * _colorsBitmap.bitmapData.width, posY * _colorsBitmap.bitmapData.height);
				onMouseMovePoint(pos);
			}
		}
		
		private function onMouseMovePoint(point:Point):void
		{
			if (config.mouseEffects)
			{
				var column:int = point.x / _rectWidth;
				var row:int = point.y / _rectHeight;
				var color:Spot = getColor(column, row);
				if (color != null)
				{
					color.shine();
				}
			}
		}
		
		private function onTimer(e:TimerEvent):void
		{
			if (config.colorSets.length > 1)
			{
				var rand:int = int(Math.random() * (config.colorSets.length - 1));
				if (rand >= _currentColorSetIndex)
				{
					rand++;
				}
				_currentColorSetIndex = rand;
			}
		}
		
		private function onResizePlayer(e:Event = null):void
		{
			if (_container != null)
			{
				if (config.keepAspectRatio)
				{
					_container.width = stage.stageWidth;
					_container.scaleY = _container.scaleX;
					if (_container.height < stage.stageHeight)
					{
						_container.height = stage.stageHeight;
						_container.scaleX = _container.scaleY;
					}
				}
				else
				{
					_container.width = stage.stageWidth;
					_container.height = stage.stageHeight;
				}
			}
		}
		
	}
}