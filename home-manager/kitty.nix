{ my-config, ... }:
{
	programs.kitty = {
		enable = true;
		settings = {
			background_opacity = 0;
			font_family = my-config.fonts.monospace;
			font_size = 12;
			cursor_shape = "beam";
		};
	};
}
