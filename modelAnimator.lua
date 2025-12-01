-- Created by @HeavenlyDev
-- Inspired by AnimatedSprite.lua. This script splits spritesheets into pieces and uses those pieces, assigns them to models and animates the models based on what the spritesheet is doing

local RunService = game:GetService("RunService")

local ModelAnimator = {}
ModelAnimator.__index = ModelAnimator

local _aa = {}
local _ca = nil

function ModelAnimator.new(m, sc)
	local s = setmetatable({}, ModelAnimator)

	s._m = m
	s._c = sc
	s._p = true
	s.st = 0
	s._cf = 0
	s._fd = {}
	s._pa = {}
	s._rs = 1
	s._pf = false
	s._el = false

	s:ExtractFrames()
	s:MapPartsToFrames()

	return s
end

function ModelAnimator:ExtractFrames()
	local _cfg = self._c
	local so = 0
	local _frms = {}

	for si, sht in pairs(_cfg.sheets) do
		local _ff = so
		local _tf = sht.rows * _cfg.framesPerRow
		local _ef = _ff + _tf

		for _fi = _ff, math.min(_ef, _cfg.nFrames) - 1 do
			local _ri = _fi - _ff
			local _x = _ri % _cfg.framesPerRow
			local _y = math.floor(_ri / _cfg.framesPerRow)

			_frms[_fi + 1] = {
				sid = sht.id,
				_ofs = Vector2.new(
					_x * (_cfg.fWidth + (_cfg.border or 1)),
					_y * (_cfg.fHeight + (_cfg.border or 1)) + (sht.startPixelY or 0)
				),
				_w = _cfg.fWidth,
				_h = _cfg.fHeight,
				_x = _x,
				_y = _y
			}
		end
		so = _ef
	end

	self._fd = _frms
end

function ModelAnimator:MapPartsToFrames()
	local _pts = {}

	for _, _d in pairs(self._m:GetDescendants()) do
		if _d:IsA("BasePart") then
			table.insert(_pts, _d)
		end
	end

	if #_pts == 0 then return end

	local spf = math.ceil(#_pts)
	local _fw = self._c.fWidth
	local _fh = self._c.fHeight

	local sw = _fw / math.ceil(math.sqrt(spf))
	local sh = _fh / math.ceil(math.sqrt(spf))

	local _cls = math.floor(_fw / sw)
	local _rws = math.floor(_fh / sh)

	for _i, _pt in pairs(_pts) do
		local si = (_i - 1) % (_cls * _rws)
		local _cl = si % _cls
		local _rw = math.floor(si / _cls)

		self._pa[_pt] = {
			sec = {
				_x = _cl * sw,
				_y = _rw * sh,
				_w = sw,
				_h = sh
			},
			_bp = _pt.Position,
			_bc = _pt.CFrame,
			_bs = _pt.Size
		}
	end

	self.sg = {
		_cls = _cls,
		_rws = _rws,
		_w = sw,
		_h = sh
	}
end

function ModelAnimator:AnalyzeFrameSection(_fi, sec)
	local _frm = self._fd[_fi]
	if not _frm then return Vector3.zero end

	local _nx = sec._x / self._c.fWidth
	local _ny = sec._y / self._c.fHeight

	local _prg = (_fi - 1) / (#self._fd - 1)

	local _px = _nx * math.pi * 2
	local _py = _ny * math.pi * 2

	local _oy = math.sin(_prg * math.pi * 4 + _px) * 0.5
	local _ox = math.cos(_prg * math.pi * 2 + _py) * 0.3
	local _oz = math.sin(_prg * math.pi * 3 + _px + _py) * 0.2

	return Vector3.new(_ox, _oy, _oz)
end

function ModelAnimator:AnalyzeFrameRotation(_fi, sec)
	local _frm = self._fd[_fi]
	if not _frm then return CFrame.new() end

	local _nx = sec._x / self._c.fWidth
	local _ny = sec._y / self._c.fHeight

	local _prg = (_fi - 1) / (#self._fd - 1)

	local _px = _nx * math.pi * 2
	local _py = _ny * math.pi * 2

	local _rx = math.sin(_prg * math.pi * 2 + _py) * 0.1
	local _ry = math.sin(_prg * math.pi * 4 + _px) * 0.15
	local _rz = math.cos(_prg * math.pi * 3 + _px + _py) * 0.05

	return CFrame.Angles(_rx, _ry, _rz)
end

function ModelAnimator:UpdateFrame()
	if self._p then return end
	if not self._m.Parent then
		self:Destroy()
		return
	end

	local _cfg = self._c
	local _fi = math.floor((tick() - self.st) / (_cfg.speed or 0.03) * self._rs)

	if self._pf and _cfg.nFrames <= _fi then
		_fi = _cfg.nFrames
		for _i = #_aa, 1, -1 do
			if _aa[_i] == self then
				table.remove(_aa, _i)
			end
		end
		self._el = true
	else
		_fi = (_fi % _cfg.nFrames) + 1
	end

	if _fi == self._cf then return end
	self._cf = _fi

	for _pt, _dt in pairs(self._pa) do
		if _pt.Parent then
			local _ofs = self:AnalyzeFrameSection(_fi, _dt.sec)
			local _rot = self:AnalyzeFrameRotation(_fi, _dt.sec)

			_pt.CFrame = _dt._bc * _rot * CFrame.new(_ofs)
		end
	end

	if self._ucb then
		self._ucb(_fi / _cfg.nFrames, _fi)
	end
end

local function AnimationLoop()
	if #_aa == 0 then
		if _ca then
			_ca:Disconnect()
			_ca = nil
		end
		return
	end

	for _, _an in pairs(_aa) do
		_an:UpdateFrame()
	end
end

function ModelAnimator:Play(_rs)
	if not self._p then return end
	self._rs = _rs or 1
	self._p = false

	if self._po then
		self.st = tick() - self._po
		self._po = nil
	else
		self.st = tick()
	end

	for _, _an in pairs(_aa) do
		if self == _an then return end
	end

	table.insert(_aa, self)
	if not _ca then
		_ca = RunService.Stepped:Connect(AnimationLoop)
	end
end

function ModelAnimator:PlayOnce(_yue)
	self._el = false
	self.st = tick()
	self._pf = true
	self:Play()

	if _yue then
		while not self._el do
			RunService.Stepped:Wait()
		end
	end
end

function ModelAnimator:Pause()
	if self._p then return end
	self._p = true
	self._po = tick() - self.st

	for _i = #_aa, 1, -1 do
		if _aa[_i] == self then
			table.remove(_aa, _i)
		end
	end
end

function ModelAnimator:Reset()
	for _pt, _dt in pairs(self._pa) do
		if _pt.Parent then
			_pt.CFrame = _dt._bc
			_pt.Size = _dt._bs
		end
	end
end

function ModelAnimator:Destroy()
	self:Reset()

	for _i = #_aa, 1, -1 do
		if _aa[_i] == self then
			table.remove(_aa, _i)
		end
	end

	if self._fd then
		for _k in pairs(self._fd) do
			self._fd[_k] = nil
		end
	end

	if self._pa then
		for _k in pairs(self._pa) do
			self._pa[_k] = nil
		end
	end

	for _k in pairs(self) do
		self[_k] = nil
	end
end

return ModelAnimator
