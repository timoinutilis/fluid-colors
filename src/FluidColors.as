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
	
	[SWF(width = "640", height = "480", frameRate = "30", backgroundColor="0xFFFFFF")]
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
		private var _rectSize:int;
		private var _examples:Vector.<String>;
		
		private var _textFormat:TextFormat;
		private var _editorContainer:Sprite;
		private var _tf:TextField;
		private var _editor:TextField;
		private var _exampleButtonsContainer:Sprite;
		private var _exampleButtons:Vector.<TextField>;
		private var _okButton:TextField;
		
		public function FluidColors()
		{
			Security.allowDomain("*");
			
			stage.scaleMode = StageScaleMode.EXACT_FIT;
			
			_textFormat = new TextFormat("_sans");

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
		}
		
CONFIG::editor
{
		private function initEditor():void
		{			
			var logo:Bitmap = new Logo() as Bitmap;
			logo.smoothing = true;
			logo.x = 10;
			logo.y = 10;
			
			var version:TextField = new TextField();
			version.defaultTextFormat = _textFormat;
			version.autoSize = TextFieldAutoSize.RIGHT;
			version.alpha = 0.25;
			version.text = "1.0";
			version.x = 632 - version.width;
			version.y = 10 + logo.height - version.height;
			
			_editor = new TextField();
			_editor.defaultTextFormat = _textFormat;
			_editor.multiline = true;
			_editor.border = true;
			_editor.type = TextFieldType.INPUT;
			_editor.x = 10;
			_editor.y = 10 + logo.height;
			_editor.width = 620;
			_editor.height = 400 - logo.height;
			
			var textBytes:ByteArray = new DefaultConfigText() as ByteArray;
			var text:String = textBytes.toString();
			var examplesArray:Array = text.split("----\n");
			_examples = Vector.<String>(examplesArray);
			
			_exampleButtonsContainer = new Sprite();
			_exampleButtons = new Vector.<TextField>();
			for (var i:int = 0; i < _examples.length; i++)
			{
				var button:TextField = createButton("Example " + (i+1), (button != null) ? button.x + button.width + 5 : 0, 0);
				button.addEventListener(MouseEvent.CLICK, onClickExample);
				_exampleButtonsContainer.addChild(button);
				_exampleButtons.push(button);
			}
			_exampleButtonsContainer.x = 640 - _exampleButtonsContainer.width - 10;
			_exampleButtonsContainer.y = 420;
			
			setExample(0);
			
			var testButton:TextField = createButton("Test", 10, 420);
			testButton.addEventListener(MouseEvent.CLICK, onClickTest);
			
			var copyButton:TextField = createButton("Copy", testButton.x + testButton.width + 10, 420);
			copyButton.addEventListener(MouseEvent.CLICK, onClickCopy);
			
			var fullscreenButton:TextField = createButton("Fullscreen", copyButton.x + copyButton.width + 10, 420);
			fullscreenButton.addEventListener(MouseEvent.CLICK, onClickFullscreen);
			
			_okButton = createButton("OK", 10, 40);
			_okButton.addEventListener(MouseEvent.CLICK, onClickOK);
			
			_editorContainer = new Sprite();
			_editorContainer.addChild(logo);
			_editorContainer.addChild(version);
			_editorContainer.addChild(_editor);
			_editorContainer.addChild(testButton);
			_editorContainer.addChild(copyButton);
			_editorContainer.addChild(fullscreenButton);
			_editorContainer.addChild(_exampleButtonsContainer);
			addChild(_editorContainer);
		}
		
		public function setExample(index:int):void
		{
			_editor.text = _examples[Math.min(index, _examples.length - 1)];
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
		
		private function onClickCopy(e:MouseEvent):void
		{
			System.setClipboard(_editor.text);
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
			var request:URLRequest = new URLRequest("colors_config.txt");
			
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
			
			_rectSize = 640 / config.columns;
			
			_colorsBitmap = new Bitmap(new BitmapData(config.columns * _rectSize, config.rows * _rectSize, false), PixelSnapping.ALWAYS, true);
			_colorsBitmap.width = stage.stageWidth;
			_colorsBitmap.height = stage.stageHeight;
			
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
				maskShape.graphics.beginGradientFill(GradientType.RADIAL, [0x000000, 0x000000], [0.0, 1.0], [0, 255], matrix, SpreadMethod.PAD);
				maskShape.graphics.drawRect(0, 0, WIDTH, HEIGHT);
				_container.addChild(maskShape);
			}

			addChild(_container);

			if (config.blur > 0)
			{
				_blur = new BlurFilter(_rectSize * config.blur, _rectSize * config.blur, 3);
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
			var rect:Rectangle = new Rectangle(0, 0, _rectSize, _rectSize);
			
			for (var column:int = 0; column < config.columns; column++)
			{
				for (var row:int = 0; row < config.rows; row++)
				{
					rect.x = column * _rectSize;
					rect.y = row * _rectSize;
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
				var column:int = point.x / _rectSize;
				var row:int = point.y / _rectSize;
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
				
	}
}