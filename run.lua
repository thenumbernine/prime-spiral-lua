#!/usr/bin/env luajit
local gl = require 'ffi.OpenGL'
local ig = require 'ffi.imgui'
local ffi = require 'ffi'
local glCallOrRun = require 'gl.call'
require 'ext'

local App = class(require 'glapp.orbit'(require 'imguiapp'))

App.title = 'prime spiral'

function App:initGL(...)
	App.super.initGL(self, ...)
	self.view.ortho = true
end

local max = ffi.new('int[1]', 100000)
local pointsize = ffi.new('float[1]', 7)

local function polar(r, theta)
	return r * math.cos(theta), r * math.sin(theta)
end

local function I(x) return x end

--local f = polar:o_n(I)
local function f(n) return polar(n, n) end
--local function f(n) return polar(math.exp(n), n) end
--local function f(n) return polar(n, math.log(n)) end
--local function f(n) return polar(1/n, n) end
--local function f(n) return polar(n, math.pi * math.sin(n)) end

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
		for n=1,tonumber(max[0]) do
			local x, y = f(n)
			--local narms = 3.999 
			--local narms = math.pi * math.sqrt(58)
			--local x, y = f(n*2*math.pi/narms)
			if n:isprime() then
				--gl.glColor4f(0,0,0,0)
				gl.glColor4f(1,1,1,1)
			else
				--gl.glColor4f(.9, .9, .9, .9)
				gl.glColor4f(0,0,0,0)
			end
			gl.glVertex2f(x, y)
		end
		gl.glEnd()
	end)

	App.super.update(self)
end

function App:updateGUI()
	ig.igText('scale: '..tostring(self.view.orthoSize))
	if ig.igInputFloat('point size', pointsize) then
		self.call = nil
	end
	if ig.igInputInt('max', max) then
		self.call = nil
	end
end

App():run()
