#!/usr/bin/env luajit
local gl = require 'ffi.OpenGL'
local ffi = require 'ffi'
local glCallOrRun = require 'gl.call'
require 'ext'

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
			local digits = file.pi
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


local App = class(require 'glapp.orbit'(require 'imguiapp'))

-- require'ing this before require'ing imguiapp causes a crash in windows
local ig = require 'imgui'

function App:initGL(...)
	-- on Windows if require 'imgui' is called before require 'imguiapp' then this line dies: 
	App.super.initGL(self, ...)

	self.view.ortho = true
	self:rebuildSequence()
end

App.title = generator.name..' spiral'

local max = ffi.new('int[1]', 10000)
local pointsize = ffi.new('float[1]', 3)

function App:update()
	--gl.glClearColor(1,1,1,1)
	gl.glClear(gl.GL_COLOR_BUFFER_BIT + gl.GL_DEPTH_BUFFER_BIT)

	self.call = self.call or {}
	glCallOrRun(self.call, function()
		gl.glPointSize(pointsize[0])
		gl.glHint(gl.GL_POINT_SMOOTH, gl.GL_NICEST)
		gl.glHint(gl.GL_LINE_SMOOTH, gl.GL_NICEST)
		gl.glHint(gl.GL_POLYGON_SMOOTH, gl.GL_NICEST)
		gl.glEnable(gl.GL_POINT_SMOOTH)
		gl.glEnable(gl.GL_LINE_SMOOTH)
		gl.glEnable(gl.GL_POLYGON_SMOOTH)
		
		gl.glBlendFunc(gl.GL_SRC_ALPHA, gl.GL_ONE_MINUS_SRC_ALPHA)	-- black background
		--gl.glBlendFunc(gl.GL_DST_COLOR, gl.GL_ZERO)	-- white background
		gl.glEnable(gl.GL_BLEND)
	
		gl.glBegin(gl.GL_POINTS)
		for _,n in ipairs(self.sequence) do
			local x, y = generator.map(n)
			--local narms = 3.999 
			--local narms = math.pi * math.sqrt(58)
			--local x, y = generator.map(n*2*math.pi/narms)
			--gl.glColor4f(0,0,0,0)
			gl.glColor4f(1,1,1,1)
			gl.glVertex2f(x, y)
		end
		gl.glEnd()
	end)

	App.super.update(self)
end

function App:rebuildSequence()
	self.call = nil
	self.sequence = generator.build(tonumber(max[0]))
	print('generated sequence of size '..#self.sequence)
end

function App:updateGUI()
	ig.igText('scale: '..tostring(self.view.orthoSize))
	if ig.igInputFloat('point size', pointsize) then
		self.call = nil
	end
	if ig.igInputInt('max', max) then
		self:rebuildSequence()
	end
end

App():run()
