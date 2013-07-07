package fluidcolors
{
	public class Spot
	{
		private var _lastColor:uint;
		private var _currentColor:uint;
		private var _targetColor:uint;
		private var _time:int;
		private var _currentTime:int;
		private var _main:FluidColors;
		
		public function Spot(main:FluidColors)
		{
			_main = main;
			_lastColor = FluidColors.START_COLOR;
			_currentColor = FluidColors.START_COLOR;
			nextColor();
		}
		
		public function update():void
		{
			_currentTime++;
			if (_currentTime >= _time)
			{
				nextColor();
			}
			if (FluidColors.config.fadeMaxSeconds == 0)
			{
				_currentColor = _targetColor;
			}
			else
			{
				var fadeTime:int = Math.min(_time, FluidColors.config.fadeMaxSeconds * _main.stage.frameRate);
				var factorIn:Number = Math.min(1, _currentTime / fadeTime);
				if (FluidColors.config.smoothFade)
				{
//					factorIn = factorIn * factorIn * (3 - 2 * factorIn);
					factorIn = factorIn * factorIn * factorIn * (factorIn * (factorIn * 6 - 15) + 10);
				}
				var factorOut:Number = 1 - factorIn;
				var currRed:int = red(_lastColor) * factorOut + red(_targetColor) * factorIn;
				var currGreen:int = green(_lastColor) * factorOut + green(_targetColor) * factorIn;
				var currBlue:int = blue(_lastColor) * factorOut + blue(_targetColor) * factorIn;
				_currentColor = color(currRed, currGreen, currBlue);
			}
		}
		
		public function shine():void
		{
			fadeToColor(_main.currentMouseColor, 10);
		}
		
		private function nextColor():void
		{
			var seconds:Number = FluidColors.config.spotMinSeconds + Math.random() * (FluidColors.config.spotMaxSeconds - FluidColors.config.spotMinSeconds);
			fadeToColor(_main.currentColorSet[int(Math.random() * _main.currentColorSet.length)], seconds * _main.stage.frameRate);
		}
		
		private function fadeToColor(color:uint, time:int):void
		{
			_lastColor = _currentColor;
			_targetColor = color;
			_time = time;
			_currentTime = 0;
		}
		
		private function red(color:uint):int
		{
			return (color >> 16) & 0xFF;
		}
		
		private function green(color:uint):int
		{
			return (color >> 8) & 0xFF;
		}
		
		private function blue(color:uint):int
		{
			return color & 0xFF;
		}
		
		private function color(red:int, green:int, blue:int):uint
		{
			return ((red & 0xFF) << 16) | ((green & 0xFF) << 8) | (blue & 0xFF);
		}
		
		public function get currentColor():uint
		{
			return _currentColor;
		}
		
	}
}