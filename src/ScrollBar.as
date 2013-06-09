package
{
	import flash.display.Shape;
	import flash.display.Sprite;
	
	public class ScrollBar extends Sprite
	{
		private var _position:int = 0;
		private var _max:int = 1;
		private var _numVisible:int = 1;
		private var _width:Number = 1;
		private var _height:Number = 1;
		private var _bar:Shape;
		
		public function ScrollBar()
		{
			super();
			_bar = new Shape();
			addChild(_bar);
		}
		
		public function get numVisible():int
		{
			return _numVisible;
		}

		public function set numVisible(value:int):void
		{
			if (value != _numVisible)
			{
				_numVisible = value;
				redrawBar();
			}
			trace("vis " + value);
		}

		public function get max():int
		{
			return _max;
		}

		public function set max(value:int):void
		{
			if (_max != value)
			{
				_max = value;
				redrawBar();
			}
		}

		public function get position():int
		{
			return _position;
		}

		public function set position(value:int):void
		{
			_position = value;
			placeBar();
		}
		
		override public function set width(value:Number):void
		{
			_width = value;
			redraw();
		}

		override public function set height(value:Number):void
		{
			_height = value;
			redraw();
		}
		
		private function redraw():void
		{
			graphics.clear();
			graphics.beginFill(0xEEEEEE);
			graphics.drawRect(0, 0, _width, _height);
			redrawBar();
		}
		
		private function redrawBar():void
		{
			_bar.graphics.clear();
			_bar.graphics.beginFill(0xCCCCCC);
			_bar.graphics.drawRect(0, 0, _width, _height * fill);
			placeBar();
		}
		
		private function get fill():Number
		{
			return Math.min(1, _numVisible / _max);
		}
		
		private function placeBar():void
		{
			_bar.y = _height * _position / _max;
		}

	}
}