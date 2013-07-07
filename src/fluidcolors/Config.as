package fluidcolors
{
	public class Config
	{
		private var _columns:int;
		private var _rows:int;
		private var _keepAspectRatio:Boolean;
		private var _colorSets:Vector.<Vector.<uint>>;
		private var _mouseEffects:Boolean;
		private var _mouseColors:Vector.<uint>;
		private var _spotMinSeconds:Number;
		private var _spotMaxSeconds:Number;
		private var _fadeMaxSeconds:Number;
		private var _smoothFade:Boolean;
		private var _setChangeSeconds:Number;
		private var _blurX:Number;
		private var _blurY:Number;
		private var _blurQuality:int;
		private var _mask:Boolean;
		private var _maskScale:Number;
		private var _maskColor:uint;
		private var _spotScale:Number;
		private var _backgroundColor:uint;

		public function Config()
		{
		}
		
		public function parse(object:Object):void
		{
			_columns = object.columns;
			_rows = object.rows;
			_keepAspectRatio = object.keep_aspect_ratio;
			_colorSets = new Vector.<Vector.<uint>>();
			var colorSetsArray:Array = object.color_sets;
			for each (var colorSet:String in colorSetsArray)
			{
				_colorSets.push(parseColors(colorSet));
			}
			_mouseEffects = object.mouse_effects;
			_mouseColors = parseColors(object.mouse_colors);
			_spotMinSeconds = object.spot_min_seconds;
			_spotMaxSeconds = object.spot_max_seconds;
			_fadeMaxSeconds = object.fade_max_seconds;
			_smoothFade = object.smooth_fade;
			_setChangeSeconds = object.set_change_seconds;
			_blurX = object.blur_x;
			_blurY = object.blur_y;
			_blurQuality = object.blur_quality;
			_mask = object.mask;
			_maskScale = object.mask_scale;
			_maskColor = parseColor(object.mask_color, 0x000000);
			_spotScale = object.spot_scale;
			_backgroundColor = parseColor(object.background_color, 0xFFFFFF);
		}
		
		private function parseColors(string:String):Vector.<uint>
		{
			var parts:Array = string.split(" ");
			var colors:Vector.<uint> = new Vector.<uint>();
			for each (var part:String in parts)
			{
				var color:int = parseColor(part);
				if (color != -1)
				{
					colors.push(color);
				}
			}
			return colors;
		}
		
		private function parseColor(string:String, defaultColor:int = -1):int
		{
			if (string != null)
			{
				var start:int = string.indexOf("#");
				if (start != -1)
				{
					string = string.substr(start + 1, 6);
					var color:int = parseInt("0x" + string);
					return color;
				}
			}
			return defaultColor;
		}

		public function get columns():int
		{
			return _columns;
		}

		public function get rows():int
		{
			return _rows;
		}
		
		public function get keepAspectRatio():Boolean
		{
			return _keepAspectRatio;
		}
		
		public function get colorSets():Vector.<Vector.<uint>>
		{
			return _colorSets;
		}

		public function get mouseEffects():Boolean
		{
			return _mouseEffects;
		}

		public function get mouseColors():Vector.<uint>
		{
			return _mouseColors;
		}

		public function get spotMinSeconds():Number
		{
			return _spotMinSeconds;
		}

		public function get spotMaxSeconds():Number
		{
			return _spotMaxSeconds;
		}

		public function get setChangeSeconds():Number
		{
			return _setChangeSeconds;
		}

		public function get fadeMaxSeconds():Number
		{
			return _fadeMaxSeconds;
		}
		
		public function get smoothFade():Boolean
		{
			return _smoothFade;
		}
		
		public function get blurX():Number
		{
			return _blurX;
		}
		
		public function get blurY():Number
		{
			return _blurY;
		}
		
		public function get blurQuality():int
		{
			return _blurQuality;
		}
		
		public function get mask():Boolean
		{
			return _mask;
		}

		public function get maskScale():Number
		{
			return _maskScale;
		}

		public function get maskColor():uint
		{
			return _maskColor;
		}

		public function get spotScale():Number
		{
			return _spotScale;
		}

		public function get backgroundColor():uint
		{
			return _backgroundColor;
		}
		
	}
}