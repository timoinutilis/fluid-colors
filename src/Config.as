package
{
	public class Config
	{
		private var _columns:int;
		private var _rows:int;
		private var _colorSets:Vector.<Vector.<uint>>;
		private var _mouseEffects:Boolean;
		private var _mouseColors:Vector.<uint>;
		private var _spotMinSeconds:Number;
		private var _spotMaxSeconds:Number;
		private var _setChangeSeconds:Number;
		private var _blur:Number;
		private var _blurQuality:int;
		private var _mask:Boolean;
		private var _maskScale:Number;

		public function Config()
		{
		}
		
		public function parse(object:Object):void
		{
			_columns = object.columns;
			_rows = object.rows;
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
			_setChangeSeconds = object.set_change_seconds;
			_blur = object.blur;
			_blurQuality = object.blur_quality;
			_mask = object.mask;
			_maskScale = object.mask_scale;
		}
		
		private function parseColors(string:String):Vector.<uint>
		{
			var parts:Array = string.split(" ");
			var colors:Vector.<uint> = new Vector.<uint>();
			for each (var part:String in parts)
			{
				var start:int = part.indexOf("#");
				if (start != -1)
				{
					part = part.substr(start + 1, 6);
					var color:int = parseInt("0x" + part);
					colors.push(color);
				}
			}
			return colors;
		}

		public function get columns():int
		{
			return _columns;
		}

		public function get rows():int
		{
			return _rows;
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

		public function get blur():Number
		{
			return _blur;
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
		
	}
}