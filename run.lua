#!/usr/bin/env luajit
local table = require 'ext.table'
local path = require 'ext.path'
local ffi = require 'ffi'
local gl = require 'gl'
local vector = require 'ffi.cpp.vector-lua'
local vec2f = require 'vec-ffi.vec2f'

local App = require 'imgui.appwithorbit'()

-- require'ing this before require'ing imguiapp causes a crash in windows
local ig = require 'imgui'


local function polar(r, theta)
	return r * math.cos(theta), r * math.sin(theta)
end

local function polar1(u)
	return polar(u, u)
end

local _2pi = math.pi * 2

local function I(x) return x end

--local f = polar:o_n(I)
--local f = polar1
--local function f(n) return polar(math.exp(n), n) end
--local function f(n) return polar(n, math.log(n)) end
--local function f(n) return polar(1/n, n) end
--local function f(n) return polar(n, math.pi * math.sin(n)) end

--[[ S_n of u_n for ulam spiral, mapping (r, phi) = (u_n, S_n)
local function ulam_map(u_n)
	local S_n = 2.5714474995 * u_n - _2pi * math.floor(2.5714474995 * u_n / _2pi)
	return polar(u_n, S_n)
end
--]]
local function ulam_map(u)
	-- lhs of the plane
	return polar1(2.5714474995 * u)
	-- 5-point spiral
	--return polar1(2.45509 * u)
end

local generators = table{
	{
		name = 'prime',
		build = function(max)
			local seq = table()
			for n=1,math.huge do
				if n:isprime() then
					seq:insert(n)
					if #seq >= max then break end
				end
			end
			return seq
		end,
		map = polar1,
	},
	{
		name = 'ulam',
		build = function(max)
			local seq = table{1, 2}
			local nways = {0, 0, 1}
			local count = {}
			local u = 3
			repeat
				if nways[u] == 1 then
					for j = 1, #seq do
						local sum = u + seq[j]
						nways[sum] = (nways[sum] or 0) + 1
					end
					seq[#seq+1] = u
				end
				u = u + 1
			until #seq >= max	
			return seq
		end,
		map = ulam_map,
		--map = polar1,
	},
	{
		name = 'pi_in_binary',
		build = function(max)
			local seq = table()
			local digits = path'pi':read()
			for i=1,#digits do
				local byte = digits:byte(i)
				for j=0,7 do
					local k = j + 8 * (i - 1)	-- k = 0-based bit index in string
					if k >= max then break end
					local b = bit.band(1, bit.rshift(byte, j))
					if b == 1 then
						seq:insert(k)
						if #seq >= max then break end
					end
				end
				if #seq >= max then break end
			end
			return seq
		end,
		map = polar1,
	},
}
for _,g in ipairs(generators) do
	generators[g.name] = g
end

--local generator = generators.prime
--local generator = generators.ulam
local generator = ... and generators[...] or generators.pi_in_binary


function App:initGL(...)
	-- on Windows if require 'imgui' is called before require 'imguiapp' then this line dies: 
	App.super.initGL(self, ...)

	self.view.ortho = true
	self.view.orthoSize = 2000

	self:rebuildSequence()
end

App.title = generator.name..' spiral'

local guivars = {
	max = 10000,
	pointsize = 3,
}

function App:update()
	--gl.glClearColor(1,1,1,1)
	gl.glClear(bit.bor(gl.GL_COLOR_BUFFER_BIT, gl.GL_DEPTH_BUFFER_BIT))

	gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)	-- black background
	--gl.glBlendFunc(gl.GL_DST_COLOR, gl.GL_ZERO)	-- white background
	gl.glEnable(gl.GL_BLEND)

	self.sceneobj.uniforms.pointsize = guivars.pointsize;
	self.sceneobj.uniforms.mvProjMat = self.view.mvProjMat.ptr
	self.sceneobj:draw()

	App.super.update(self)
end

function App:rebuildSequence()
	self.sequence = generator.build(guivars.max)
	print('generated sequence of size '..#self.sequence)

	self.vtxCPUBuf = vector'vec2f_t'	-- don't gc

	for _,n in ipairs(self.sequence) do
		local x, y = generator.map(n)
		--local narms = 3.999 
		--local narms = math.pi * math.sqrt(58)
		--local x, y = generator.map(n*2*math.pi/narms)
		self.vtxCPUBuf:emplace_back()[0]:set(x, y)
	end

	-- TODO reuse the buffer upon adjusting the size
	self.sceneobj = require 'gl.sceneobject'{
		program = {
			version = 'latest',
			precision = 'best',
			vertexCode = [[
in vec2 vertex;
uniform mat4 mvProjMat;
uniform float pointsize;
void main() {
	gl_PointSize = pointsize;
	gl_Position = mvProjMat * vec4(vertex, 0., 1.);
}
]],
			fragmentCode = [[
out vec4 fragColor;
void main() {
	fragColor = vec4(1., 1., 1., 1.);
}
]],
		},
		vertexes = {
			data = self.vtxCPUBuf.v,
			size = ffi.sizeof'vec2f_t' * #self.vtxCPUBuf,
			count = #self.vtxCPUBuf,
			dim = 2,
		},
		geometry = {
			mode = gl.GL_POINTS,
		},
	}
end

function App:updateGUI()
	ig.igText('scale: '..tostring(self.view.orthoSize))
	ig.luatableInputFloat('point size', guivars, 'pointsize')
	if ig.luatableInputInt('max', guivars, 'max') then
		self:rebuildSequence()
	end
end

return App():run()
