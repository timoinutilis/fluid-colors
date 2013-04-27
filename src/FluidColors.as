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
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFieldType;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	
	[SWF(width = "640", height = "480", frameRate = "30", backgroundColor="0xFFFFFF")]
	public class FluidColors extends Sprite
	{
		[Embed(source="../colors_config.txt", mimeType="application/octet-stream")]
		private const DefaultConfigText:Class;

		public static const EDITOR:Boolean = false;
		
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
		
		private var _tf:TextField;
		private var _editor:TextField;
		private var _testButton:TextField;
		private var _okButton:TextField;
		
		public function FluidColors()
		{
			Security.allowDomain("*");
			
			stage.scaleMode = StageScaleMode.EXACT_FIT;

			if (EDITOR)
			{
				_editor = new TextField();
				_editor.multiline = true;
				_editor.border = true;
				_editor.type = TextFieldType.INPUT;
				_editor.x = 10;
				_editor.y = 10;
				_editor.width = 620;
				_editor.height = 400;
				
				var textBytes:ByteArray = new DefaultConfigText() as ByteArray;
				var text:String = textBytes.toString();
				_editor.text = text;
				
				_testButton = createButton("Test", 10, 420);
				_testButton.addEventListener(MouseEvent.CLICK, onClickTest);
				
				_okButton = createButton("OK", 10, 40);
				_okButton.addEventListener(MouseEvent.CLICK, onClickOK);
				
				addChild(_editor);
				addChild(_testButton);
			}
			else
			{
				var request:URLRequest = new URLRequest("colors_config.txt");
				
				var loader:URLLoader = new URLLoader();
				loader.addEventListener(Event.COMPLETE, onConfigLoaded);
				loader.addEventListener(IOErrorEvent.IO_ERROR, onError);
				loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onError);
				loader.load(request);
			}
			
			if (ExternalInterface.available)
			{
				ExternalInterface.addCallback("Colors_onMouseMove", onMouseMoveJS);
			}
		}
		
		private function createButton(text:String, x:Number, y:Number):TextField
		{
			var button:TextField = new TextField();
			button.autoSize = TextFieldAutoSize.LEFT;
			button.border = true;
			button.text = text;
			button.background = true;
			button.backgroundColor = 0xCCCCCC;
			button.selectable = false;
			button.x = x;
			button.y = y;
			return button;
		}
		
		private function onError(e:ErrorEvent):void
		{
			showError("Could not load configuration file!");
		}
		
		private function showError(text:String):void
		{
			if (_tf == null)
			{
				_tf = new TextField();
				_tf.autoSize = TextFieldAutoSize.LEFT;
				_tf.textColor = 0xFF0000;
				_tf.x = 10;
				_tf.y = 10;
			}
			addChild(_tf);
			_tf.text = text;
			
			if (EDITOR)
			{
				addChild(_okButton);
			}
		}
		
		private function onConfigLoaded(e:Event):void
		{
			var loader:URLLoader = e.currentTarget as URLLoader;
			init(loader.data);
		}
		
		private function init(configText:String):void
		{
			var configObject:Object;
			try
			{
				configObject = com.adobe.serialization.json.JSON.decode(configText, false);
				config.parse(configObject);
			}
			catch (e:Error)
			{
				showError("Configuration file: " + e.toString());
				return;
			}
			
			_rectSize = 120 / config.columns;
			
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

			_blur = new BlurFilter(_rectSize * 1.5, _rectSize * 1.5);
						
			_timer = new Timer(config.setChangeSeconds * 1000);
			_timer.addEventListener(TimerEvent.TIMER, onTimer);
			_timer.start();
			
			addEventListener(Event.ENTER_FRAME, onEnterFrame);
			_container.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			if (EDITOR)
			{
				_container.addEventListener(MouseEvent.CLICK, onClickOK);
			}
		}
		
		private function reset():void
		{
			removeEventListener(Event.ENTER_FRAME, onEnterFrame);
			_container.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			_container.removeEventListener(MouseEvent.CLICK, onClickOK);
			
			_timer.reset();
			_timer.removeEventListener(TimerEvent.TIMER, onTimer);
			_timer = null;
			
			removeChild(_container);
			_colorsBitmap = null;
			_container = null;
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
			_colorsBitmap.bitmapData.applyFilter(_colorsBitmap.bitmapData, rect, new Point(0, 0), _blur);
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
			var rand:int = int(Math.random() * (config.colorSets.length - 1));
			if (rand >= _currentColorSetIndex)
			{
				rand++;
			}
			_currentColorSetIndex = rand;
		}
		
		private function onClickTest(e:MouseEvent):void
		{
			removeChild(_editor);
			removeChild(_testButton);
			
			init(_editor.text);
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
			addChild(_editor);
			addChild(_testButton);
		}
		
	}
}