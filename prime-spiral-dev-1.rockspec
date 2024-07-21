package = "prime-spiral"
version = "dev-1"
source = {
	url = "git+https://github.com/thenumbernine/prime-spiral-lua"
}
description = {
	summary = "prime spiral distribution visualizer",
	detailed = "prime spiral distribution visualizer",
	homepage = "https://github.com/thenumbernine/prime-spiral-lua",
	license = "MIT"
}
dependencies = {
	"lua >= 5.1"
}
build = {
	type = "builtin",
	modules = {
		["prime-spiral.run"] = "run.lua"
	}
}
