
-- Decompiled with the Synapse X Luau decompiler.

local v1 = {};
local l__RunService__2 = game:GetService("RunService");
v1.Transitions = {};
v1.Spring = require(script.QSpring);
local v3 = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 0, 0)), ColorSequenceKeypoint.new(0.16666666666666666, Color3.fromRGB(218, 133, 65)), ColorSequenceKeypoint.new(0.3333333333333333, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.6666666666666666, Color3.fromRGB(9, 137, 207)), ColorSequenceKeypoint.new(0.8333333333333334, Color3.fromRGB(61, 21, 133)), (ColorSequenceKeypoint.new(1, Color3.fromRGB(107, 50, 124))) });
function Create(p1)
	return function(p2)
		local v4 = Instance.new(p1);
		local v5, v6, v7 = pairs(p2);
		while true do
			local v8, v9 = v5(v6, v7);
			if v8 then

			else
				break;
			end;
			v7 = v8;
			local v10, v11 = pcall(function()
				if type(v8) == "number" then
					v9.Parent = v4;
					return;
				end;
				if type(v9) == "function" then

				else
					v4[v8] = v9;
					return;
				end;
				v4[v8]:connect(v9);
			end);
			if not v10 then
				error("Create: could not set property " .. v8 .. " of " .. p1 .. " (" .. v11 .. ")", 2);
			end;		
		end;
		return v4;
	end;
end;
local l__TweenService__1 = game:GetService("TweenService");
function v1.Tween(p3, p4, p5)
	local v12 = nil;
	local v13 = Instance.new("NumberValue");
	v13.Value = 0;
	local v14 = l__TweenService__1:Create(v13, p3, {
		Value = 1
	});
	v12 = v14.TweenInfo.Time;
	local v15 = v13:GetPropertyChangedSignal("Value");
	local u2 = tick() + v14.TweenInfo.DelayTime;
	local u3 = v13;
	v15:connect(function()
		if p5(u3.Value, tick() - u2) ~= false then
			return;
		end;
		u3:Destroy();
		v14:Cancel();
	end);
	v14:Play();
	if not p4 then
		v14.Completed:Connect(function()
			p5(1, v12);
			u3:Destroy();
			u3 = nil;
		end);
		return v14;
	end;
	v14.Completed:Wait();
	p5(1, v12);
	u3:Destroy();
	u3 = nil;
end;
local l__Particles__4 = game.ReplicatedStorage.Models.Misc.Particles;
function v1.HitRing(p6, p7, p8, p9, p10, p11)
	local v16 = Instance.new("Attachment", workspace.Terrain);
	v16.CFrame = p6;
	local v17 = l__Particles__4.HitParticleBlue:Clone();
	v17.Color = ColorSequence.new(p7);
	v17.Size = NumberSequence.new(p8, p9);
	v17.Transparency = p10;
	v17.Lifetime = p11 or NumberRange.new(0.25, 0.5);
	v17.Enabled = false;
	v17.Parent = v16;
	game.Debris:AddItem(v16, v17.Lifetime.Max * 2);
	return v17, v16;
end;
function v1.GetCenter(p12)
	local l__CoordinateFrame1__18 = p12.CoordinateFrame1;
	return l__CoordinateFrame1__18 + (p12.CoordinateFrame2.p - l__CoordinateFrame1__18.p) / 2;
end;
function v1.SquishModel(p13, p14, p15, p16)
	local v19 = Vector3.new(1, 0, 1);
	local v20 = {};
	for v21, v22 in pairs(p13:GetDescendants()) do
		if v22:IsA("BasePart") and v22.Name ~= "Base" then
			v22.Anchored = true;
			table.insert(v20, {
				part = v22, 
				ds = v22.Size, 
				pcf = v22.CFrame
			});
		end;
	end;
	p13:BreakJoints();
	local u5 = p14 and 0.1;
	local u6 = p15 and 1.15;
	local l__CFrame__7 = p13.Base.CFrame;
	v1.Tween(TweenInfo.new(p16), true, function(p17)
		for v23, v24 in pairs(v20) do
			v24.part.Size = v24.ds + Vector3.new((v24.ds.X * u6 - v24.ds.X) * p17, (v24.ds.Y * u5 - v24.ds.Y) * p17, (v24.ds.Z * u6 - v24.ds.Z) * p17);
			v24.part.CFrame = v24.pcf - v24.pcf.p + (l__CFrame__7.p + (v24.pcf.p * v19 - l__CFrame__7.p * v19) + Vector3.new(0, u5 * p17 * (v24.pcf.Y - l__CFrame__7.Y), 0));
		end;
	end);
	spawn(function()
		wait(1);
		u5 = 1;
		u6 = 1;
		v1.Tween(TweenInfo.new(1, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), true, function(p18)
			for v25, v26 in pairs(v20) do
				v26.part.Size = v26.ds + Vector3.new((v26.ds.X * u6 - v26.ds.X) * p18, (v26.ds.Y * u5 - v26.ds.Y) * p18, (v26.ds.Z * u6 - v26.ds.Z) * p18);
				v26.part.CFrame = v26.pcf - v26.pcf.p + (l__CFrame__7.p + (v26.pcf.p * v19 - l__CFrame__7.p * v19) + Vector3.new(0, u5 * p18 * (v26.pcf.Y - l__CFrame__7.Y), 0));
			end;
		end);
	end);
end;
function v1.MakeShape2D(p19, p20, p21, p22, p23, p24, p25)
	assert(p20 >= 3);
	if not p22 then
		p22 = 0.1;
	end;
	local v27 = {
		parts = {}, 
		center = p19, 
		radius = p21
	};
	local v28 = math.pi - 2 * math.pi / p20;
	local v29 = 2 * math.pi / p20;
	local v30 = {};
	for v31 = v29, 2 * math.pi, v29 do
		v30[#v30 + 1] = p19 * CFrame.new(math.cos(v31) * p21, math.sin(v31) * p21, 0);
	end;
	for v32 = 1, #v30 do
		local v33 = v30[v32];
		if v32 == #v30 then
			local v34 = 1;
		else
			v34 = v32 + 1;
		end;
		local v35 = v30[v34];
		local v36 = Instance.new("Part");
		v36.Anchored = true;
		v36.CanCollide = false;
		local v37 = v35.p - v33.p;
		v36.Size = Vector3.new(p22, p22, v37.magnitude + p22 * math.tan((math.pi - v28) / 2) / 2 * 2);
		v36.Color = p23 or Color3.fromRGB(255, 255, 255);
		v36.Material = p24 and "SmoothPlastic";
		v36.Transparency = p25 and 1;
		v36.CFrame = CFrame.new(v33.p + v37 / 2, v35.p);
		v36.Parent = workspace;
		table.insert(v27.parts, v36);
	end;
	return v27;
end;
function v1.lerp(p26, p27, p28)
	return p26 + (p27 - p26) * p28;
end;
function v1.bezierCurve(p29, p30, p31, p32, p33)
	return p29 * (1 - p33) ^ 3 + p30 * 3 * p33 * (1 - p33) ^ 2 + 3 * p31 * p33 * p33 * (1 - p33) + p32 * p33 ^ 3;
end;
function v1.MapNumbers(p34, p35, p36, p37, p38)
	if p36 == p35 then
		error("Range of zero");
	end;
	return (p34 - p35) * (p38 - p37) / (p36 - p35) + p37;
end;
function v1.makeSpiral(p39, p40, p41, p42, p43, p44, p45, p46, p47)
	local v38 = {};
	for v39 = 1, p39 do
		local v40 = Create("Part")({
			Anchored = true, 
			CanCollide = false, 
			Transparency = 1, 
			Name = "node" .. v39, 
			Size = Vector3.new(1, 1, 1), 
			CFrame = p40,
			Create("Attachment")({
				Name = "a0", 
				Position = Vector3.new(p44 / 2, 0, 0)
			}), Create("Attachment")({
				Name = "a1", 
				Position = Vector3.new(-p44 / 2, 0, 0)
			}), Create("Trail")({
				Name = "Trail", 
				Lifetime = 1, 
				Transparency = NumberSequence.new(0, 1), 
				LightEmission = 0.75, 
				LightInfluence = 0, 
				Color = ColorSequence.new(Color3.fromRGB(255, 255, 255)), 
				WidthScale = NumberSequence.new(0.1, 1)
			})
		});
		for v41, v42 in pairs(p47) do
			v40.Trail[v41] = v42;
		end;
		v40.Parent = workspace;
		v40.Trail.Attachment0 = v40.a0;
		v40.Trail.Attachment1 = v40.a1;
		table.insert(v38, v40);
	end;
	local u8 = 2 * math.pi / p39;
	v1.Tween(p45, true, function(p48)
		for v43 = 1, #v38 do
			local v44 = nil;
			v44 = p41 * p48 + (v43 - 1) * u8;
			if p46 == "Shrink" then
				local v45 = p43 - p43 * p48;
				v38[v43].CFrame = p40 * CFrame.new(v45 * math.cos(v44), p42 * p48, v45 * math.sin(v44));
			elseif p46 == "Grow" then
				local v46 = p43 * p48;
				v38[v43].CFrame = p40 * CFrame.new(v46 * math.cos(v44), p42 * p48, v46 * math.sin(v44));
			elseif p46 == "Sphere" then
				local v47 = p43 * math.sin(p48 * math.pi);
				v38[v43].CFrame = p40 * CFrame.new(v47 * math.cos(v44), p42 * p48, v47 * math.sin(v44));
			elseif p46 == "SphereInverted" then
				local v48 = p43 - p43 * math.sin(p48 * math.pi);
				v38[v43].CFrame = p40 * CFrame.new(v48 * math.cos(v44), p42 * p48, v48 * math.sin(v44));
			elseif p46 == "Infinity" then
				local v49 = p41 * p48 + (v43 - 1) * u8;
				v38[v43].CFrame = p40 * CFrame.new(p43 * math.cos(v49) / (1 + math.sin(v49) ^ 2), p43 * (math.sin(v49) * math.cos(v49)) / (1 + math.sin(v49) ^ 2), 0);
			elseif p46 == "SemicircleRight" then
				v38[v43].CFrame = p40 * CFrame.new(p43 * math.cos(v44) + p42 / 3 * math.sin(math.pi * p48), p42 * p48, p43 * math.sin(v44));
			elseif p46 == "SemicircleLeft" then
				v38[v43].CFrame = p40 * CFrame.new(p43 * math.cos(v44) + -p42 / 3 * math.sin(math.pi * p48), p42 * p48, p43 * math.sin(v44));
			else
				v38[v43].CFrame = p40 * CFrame.new(p43 * math.cos(v44), p42 * p48, p43 * math.sin(v44));
			end;
		end;
	end);
	wait(p45.Time);
	for v50 = 1, #v38 do
		v38[v50]:Destroy();
		v38[v50] = nil;
	end;
end;
local l__Misc__9 = game.ReplicatedStorage.Models.Misc;
function v1.ballExplosion(p49, p50, p51, p52, p53, p54, p55)
	local v51 = Create("Part")({
		Size = Vector3.new(p51 * 0.1, p51 * 0.1, p51 * 0.1), 
		Color = p53, 
		Anchored = true, 
		CanCollide = false, 
		Shape = "Ball", 
		Material = p55, 
		CFrame = p50
	});
	local v52 = v51:Clone();
	v52.Size = v51.Size * 0.75;
	v52.Color = p52;
	v52.Material = p54;
	local v53 = l__Misc__9.ThinRing:Clone();
	v53.Color = Color3.fromRGB(255, 255, 255);
	v53.Material = "SmoothPlastic";
	v53.CFrame = p50;
	v53.Size = Vector3.new(1, 0.1, 1);
	v51.Parent = workspace;
	v52.Parent = workspace;
	v53.Parent = workspace;
	v1.Tween(p49, false, function(p56)
		local v54 = 0.1 * p51 + 0.9 * p51 * p56;
		v51.Size = Vector3.new(v54, v54, v54);
		v52.Size = v51.Size * 0.75;
		v53.Size = Vector3.new(v54 * 2, 0.1, v54 * 2);
		v51.Transparency = p56;
		v52.Transparency = p56;
		v53.Transparency = p56;
	end);
	game.Debris:AddItem(v51, p49.Time);
	game.Debris:AddItem(v52, p49.Time);
	game.Debris:AddItem(v53, p49.Time);
end;
function v1.blast(p57, p58, p59, p60, p61, p62, p63, p64, p65)
	local v55 = l__Misc__9.HitEffect1:Clone();
	v55.Transparency = 0.1;
	v55.Color = p61;
	v55.Size = Vector3.new(p58, 0.8 * p58, p58);
	if not p64 then
		local v56 = "Neon";
	else
		v56 = "SmoothPlastic";
	end;
	v55.Material = v56;
	local v57 = v55:Clone();
	v57.Size = Vector3.new(p58 / 2, p59, p58 / 2);
	v57.Color = p62;
	local v58 = p57 * CFrame.Angles(0, -math.pi / 2, -math.pi / 2) * CFrame.new(0, v55.Size.Y / 2, 0);
	local v59 = p57 * CFrame.Angles(0, -math.pi / 2, -math.pi / 2) * CFrame.new(0, v57.Size.Y / 2, 0);
	v55.CFrame = v58;
	v57.CFrame = v59;
	local v60 = l__Misc__9.ThinRing:Clone();
	v60.Color = p63;
	if not p64 then
		local v61 = "Neon";
	else
		v61 = "SmoothPlastic";
	end;
	v60.Material = v61;
	v60.CFrame = p57 * CFrame.Angles(math.pi / 2, 0, 0);
	v60.Size = Vector3.new(3, 0.1, 3);
	local v62 = l__Particles__4.HitParticleRed:Clone();
	v62.Color = ColorSequence.new(p61, p62);
	if not p64 then
		local v63 = 1;
	else
		v63 = 0;
	end;
	v62.LightEmission = v63;
	v62.Enabled = false;
	v62.Parent = Instance.new("Attachment", v60);
	v62:Emit(20);
	v60.Parent = workspace;
	v55.Parent = workspace;
	v57.Parent = workspace;
	local l__Size__10 = v55.Size;
	local l__Size__11 = v57.Size;
	local l__Size__12 = v60.Size;
	v1.Tween(TweenInfo.new(p65 and 0.5, Enum.EasingStyle.Cubic), true, function(p66)
		v55.Size = l__Size__10 + Vector3.new(p58 * p66 / 3, -p58 * 0.8 * p66 * 0.66, p58 * p66 / 3);
		v55.CFrame = v58 * CFrame.new(0, -p58 * 0.8 * p66 * 0.33, 0);
		v57.Size = l__Size__11 - Vector3.new(1, p59 * p66, 1);
		v57.CFrame = v59 * CFrame.new(0, -p59 / 2 * p66, 0);
		v60.Size = l__Size__12 + Vector3.new(p60 * p66, 0, p60 * p66);
		v60.Transparency = 0.1 + 0.9 * p66;
		v57.Transparency = 0.1 + 0.9 * p66;
		v55.Transparency = 0.1 + 0.9 * p66;
	end);
	v55:Destroy();
	v57:Destroy();
	v60:Destroy();
end;
local u13 = Random.new();
function v1.trailSwirl(p67, p68, p69, p70, p71, p72, p73, p74, p75)
	local v64 = Instance.new("Trail");
	for v65, v66 in pairs(p72) do
		if v64[v65] then
			v64[v65] = v66;
		end;
	end;
	local u14 = nil;
	local u15 = (function()
		local v67 = Instance.new("Attachment", workspace.Terrain);
		local v68 = Instance.new("Attachment", workspace.Terrain);
		local v69 = v64:Clone();
		v69.Parent = workspace.Terrain;
		v69.Attachment0 = v67;
		v69.Attachment1 = v68;
		if p75 then
			v69.Texture = p75;
		end;
		v67.CFrame = p67;
		v68.CFrame = p67;
		return {
			trail = v69, 
			at0 = v67, 
			at1 = v68, 
			scf = p67 * CFrame.Angles(u13:NextNumber() * 2 * math.pi, u13:NextNumber() * 2 * math.pi, u13:NextNumber() * 2 * math.pi)
		};
	end)();
	v1.Tween(TweenInfo.new(p68, p74 and Enum.EasingStyle.Cubic or Enum.EasingStyle.Linear), false, function(p76)
		if p73 then
			u14 = u15.scf * CFrame.Angles(0, 0.2 * p71 + 0.8 * p71 * p76, 0) * CFrame.new(0, 0, -p69 * p76);
		else
			u14 = u15.scf * CFrame.Angles(0, 0.2 * p71 + 0.8 * p71 * p76, 0) * CFrame.new(0, 0, -p69 + p69 * p76 * 0.9);
		end;
		u15.at0.WorldCFrame = u14 * CFrame.new(p70 - p70 * p76 * 0.5, 0, 0);
		u15.at1.WorldCFrame = u14 * CFrame.new(-p70 + p70 * p76 * 0.5, 0, 0);
	end).Completed:Connect(function()
		wait(u15.trail.Lifetime - p68);
		u15.trail:Destroy();
		u15.at0:Destroy();
		u15.at1:Destroy();
		u15 = nil;
	end);
end;
function v1.CurveSlash(p77, p78, p79, p80)
	local v70 = Instance.new("Attachment", workspace.Terrain);
	local v71 = Instance.new("Attachment", workspace.Terrain);
	local v72 = 2 * p78 * 0.707;
	v70.CFrame = p77 * CFrame.new(p78, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0);
	v71.CFrame = p77 * CFrame.new(-p78, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0);
	local v73 = Create("Beam")({
		LightEmission = 1, 
		LightInfluence = 0, 
		Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.1, 0), NumberSequenceKeypoint.new(0.9, 0), NumberSequenceKeypoint.new(1, 1) }), 
		Color = ColorSequence.new(p79, p80), 
		Texture = "rbxassetid://6352522269", 
		TextureSpeed = 2.5, 
		TextureLength = 0.2, 
		CurveSize0 = -v72, 
		CurveSize1 = v72, 
		Width0 = 20, 
		Width1 = 15, 
		Segments = 15, 
		Attachment0 = v70, 
		Attachment1 = v71
	});
	local v74 = 1 / v73.TextureSpeed;
	delay(v74 / 2, function()
		v1.slashEffect(p77 * CFrame.new(0, 0, -p78) * CFrame.Angles(0, 0, math.pi / 2), p79, p80, 2 * p78, 1, 0.1);
	end);
	v73.Parent = workspace.Terrain;
	game.Debris:AddItem(v73, v74);
	game.Debris:AddItem(v70, v74);
	game.Debris:AddItem(v71, v74);
end;
function v1.SwirlShader(p81, p82, p83, p84)

end;
function v1.trailSlash(p85, p86, p87, p88, p89, p90, p91)
	local v75 = Instance.new("Attachment", workspace.Terrain);
	local v76 = Instance.new("Attachment", workspace.Terrain);
	local v77 = Instance.new("Trail", workspace.Terrain);
	v77.LightEmission = 1;
	v77.LightInfluence = 0;
	v77.Texture = "http://www.roblox.com/asset/?id=5823056107";
	v77.Transparency = NumberSequence.new(0, 1);
	v77.Color = ColorSequence.new(p89);
	v77.Attachment0 = v75;
	v77.Attachment1 = v76;
	v77.Lifetime = p86 * 2;
	if p91 then
		local v78 = true;
	else
		v78 = false;
	end;
	v77.FaceCamera = v78;
	local u16 = p90 or math.pi * 2;
	v1.Tween(TweenInfo.new(p86, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), true, function(p92)
		v75.WorldCFrame = p85 * CFrame.new(p87 * math.cos(u16 * p92), 0, -p87 * math.sin(u16 * p92));
		v76.WorldCFrame = p85 * CFrame.new(p88 * math.cos(u16 * p92), 0, -p88 * math.sin(u16 * p92));
	end);
	v77.Enabled = false;
	delay(v77.Lifetime / 2, function()
		v77:Destroy();
		v75:Destroy();
	end);
end;
function v1.ClawSlash(p93, p94, p95, p96, p97)
	local v79 = Vector3.new(p93.x, p94.y, p93.z);
	local v80 = CFrame.new(v79, p94);
	local v81 = l__Misc__9.ClawMesh:Clone();
	v81:ClearAllChildren();
	v81.Color = p96;
	v81.Transparency = 0;
	v81.Size = Vector3.new(5.097, 3.91, 9.9);
	for v82 = -1, 1 do
		local v83 = Instance.new("Attachment", v81);
		local v84 = Instance.new("Attachment", v81);
		local v85 = Instance.new("Trail", v81);
		v83.Position = Vector3.new(2.5 * v82, 0.5, -v81.Size.Y / 2);
		v84.Position = Vector3.new(2.5 * v82, -1, -4);
		v85.Color = ColorSequence.new(p96);
		v85.Lifetime = 0.5;
		v85.Transparency = NumberSequence.new(0, 1);
		v85.LightEmission = 1;
		v85.LightInfluence = 0;
		v85.Attachment0 = v83;
		v85.Attachment1 = v84;
	end;
	local v86 = v81:Clone();
	local v87 = CFrame.new((v80 * CFrame.new(v81.Size.Z, 3, 0)).p, p94);
	local v88 = (v87 - v87.p) * CFrame.Angles(-math.pi / 6, -math.pi / 2 - math.pi / 6, -math.pi / 2);
	local v89 = CFrame.Angles(0, math.pi / 6, -math.pi / 2);
	local v90 = CFrame.new((v80 * CFrame.new(-v81.Size.Z, 3, 0)).p, p94);
	local v91 = (v90 - v90.p) * CFrame.Angles(-math.pi / 6, math.pi / 2 + math.pi / 6, math.pi / 2);
	local v92 = CFrame.Angles(0, -math.pi / 6, math.pi / 2);
	v81.CFrame = v88 + v87.p;
	v86.CFrame = v91 + v90.p;
	v81.Parent = p95.scene;
	v86.Parent = p95.scene;
	local v93 = TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.In);
	local u17 = p94 - v79;
	local u18 = (v87 - v87.p) * v89;
	local u19 = (v90 - v90.p) * v92;
	local v94 = v1.Tween(v93, true, function(p98)
		v81.CFrame = v88:Lerp(u18, p98) + (v87 * CFrame.new(u17.magnitude * math.sin(math.pi * p98), 0, -u17.magnitude * p98)).p;
		v86.CFrame = v91:Lerp(u19, p98) + (v90 * CFrame.new(-u17.magnitude * math.sin(math.pi * p98), 0, -u17.magnitude * p98)).p;
	end);
	coroutine.wrap(function()
		local v95 = v80 + u17;
		v1.HitRing(v95, p96, 2, 11, NumberSequence.new(0, 1)):Emit(3);
		v1.slashEffect(v95 * CFrame.Angles(0, 0, math.pi / 6), p96, p97, 25, 4, 0.1);
		v1.slashEffect(v95 * CFrame.Angles(0, 0, -math.pi / 6), p96, p97, 25, 4, 0.1);
		local l__CFrame__20 = v81.CFrame;
		local l__CFrame__21 = v86.CFrame;
		v1.Tween(TweenInfo.new(0.2), true, function(p99)
			v81.CFrame = l__CFrame__20 * CFrame.new(0, -7 * p99, -7 * p99);
			v86.CFrame = l__CFrame__21 * CFrame.new(0, -7 * p99, -7 * p99);
			v81.Transparency = p99;
			v86.Transparency = p99;
		end);
		wait(0.5);
		v81:Destroy();
		v86:Destroy();
	end)();
end;
function v1.slashEffect(p100, p101, p102, p103, p104, p105)
	local v96 = p103 and 10;
	local v97 = p104 and 2;
	local v98 = l__Particles__4.SlashBrick:Clone();
	v98.Trail.Color = ColorSequence.new(p101, p102);
	v98.Trail2.Color = ColorSequence.new(p102);
	v98.Trail3.Color = ColorSequence.new(p101);
	v98.Attachment.Position = Vector3.new(v97, 0, 0);
	v98.Attachment0.Position = Vector3.new(-v97, 0, 0);
	v98.CFrame = p100 * CFrame.new(-v96, 0, 0);
	v98.Parent = workspace;
	l__TweenService__1:Create(v98, TweenInfo.new(p105 and 0.5), {
		CFrame = p100 * CFrame.new(v96, 0, 0)
	}):Play();
	game.Debris:AddItem(v98, 0.55);
end;
function v1.MaxYFOV(p106, p107)
	return math.tan(math.rad(workspace.CurrentCamera.FieldOfView) / 2) * (p106 - p107).magnitude * 2;
end;
function v1.BeamLightning(p108, p109, p110, p111, p112, p113, p114)
	local l__magnitude__99 = (p108 - p109).magnitude;
	p114 = p114 and 0.3;
	local v100 = {};
	local v101 = TweenInfo.new(p114, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0);
	for v102 = 0, p110 do
		local v103 = v1.lerp(p108, p109, v102 / p110);
		local v104 = p111 * math.clamp(1 - v102 / p110, 0, 0.6);
		local v105 = u13:NextInteger(-v104, v104);
		local v106 = u13:NextInteger(-v104, v104);
		local v107 = Instance.new("Attachment");
		local v108 = Vector3.new(v105, u13:NextInteger(-v104, v104), v106);
		if v102 == 0 then
			v108 = Vector3.new();
		elseif v102 == p110 then
			v108 = Vector3.new(v105, 0, v106);
		end;
		v107.Position = v103 + v108;
		v107.Parent = workspace.Terrain;
		table.insert(v100, v107);
		if v100[#v100 - 1] then
			local v109 = Instance.new("Beam");
			v109.Attachment0 = v100[#v100 - 1];
			v109.Attachment1 = v107;
			v109.LightEmission = 1;
			v109.LightInfluence = 0;
			v109.Transparency = NumberSequence.new(0);
			v109.Color = ColorSequence.new(p112);
			v109.Parent = workspace.Terrain;
			v109.Width0 = p113;
			v109.Width1 = p113;
			v1.Tween(v101, false, function(p115, p116)
				v109.Transparency = NumberSequence.new(p115);
				v109.Width0 = p113 - 0.99 * p113 * p115;
				v109.Width1 = p113 - 0.99 * p113 * p115;
			end);
			delay(p114, function()
				v109:Destroy();
			end);
		end;
	end;
	delay(p114 * p110, function()
		for v110, v111 in pairs(v100) do
			v111:Destroy();
		end;
	end);
end;
function v1.BranchLightning(p117, p118, p119, p120, p121, p122, p123, p124)
	local u22 = {};
	local function v112(p125, p126, p127)
		table.insert(u22, {
			isBranch = p127, 
			branchCount = 2,
			p125, p126
		});
	end;
	v112(p117, p118);
	local v113 = 0;
		for v115 = 1, #u22 do
			if u22[v115].isBranch and u22[v115].branchCount > 0 then
				local v116 = u22[v115];
				v116.branchCount = v116.branchCount - 1;
				local v117 = u22[v115][1];
				local v118 = u22[v115][2];
				local v119 = CFrame.new(v117 + (v118 - v117) / 2, v118) * CFrame.Angles(0, 0, u13:NextNumber() * 2 * math.pi) * CFrame.new(u13:NextNumber(-p119, p119), 0, 0);
				if v113 < p120 and u13:NextNumber() > 0.2 then
					v112(v119.p, (v119 * CFrame.Angles(u13:NextNumber(-math.pi / 12, math.pi / 12), 0, 0) * CFrame.new(0, 0, -0.7 * (v119.p - v117).magnitude)).p, true);
				end;
				table.remove(u22, v115);
				v112(v117, v119.p);
				v112(v119.p, v118);
			else
				local v120 = u22[v115][1];
				local v121 = u22[v115][2];
				local v122 = CFrame.new(v120 + (v121 - v120) / 2, v121) * CFrame.Angles(0, 0, u13:NextNumber() * 2 * math.pi) * CFrame.new(u13:NextNumber(-p119, p119), 0, 0);
				if v113 < p120 and u13:NextNumber() > 0.2 then
					local v123 = v122 * CFrame.Angles(u13:NextNumber(-math.pi / 9, math.pi / 9), 0, 0) * CFrame.new(0, 0, -0.7 * (v122.p - v120).magnitude);
					v113 = v113 + 1;
					v112(v122.p, v123.p, true);
				end;
				table.remove(u22, v115);
				v112(v120, v122.p);
				v112(v122.p, v121);
			
			
		end;
		p119 = p119 / 2;
	end;
	for v124, v125 in pairs(u22) do
		if v124 ~= 0 then
			local v126 = v125[1];
			local v127 = v125[2];
			if v125.isBranch then
				v1.BeamLightning(v126, v127, 1, 0, p122, p121 / 2, p123);
			else
				v1.BeamLightning(v126, v127, 1, 0, p122, p121, p123);
			end;
		end;
	end;
end;
function v1.BlackBox(p128, p129)
	local v128 = Instance.new("Model");
	local v129 = Instance.new("Part");
	v129.Anchored = true;
	v129.CanCollide = false;
	v129.Size = Vector3.new(p129, 2, p129);
	v129.Transparency = 1;
	v129.Name = "Top";
	v129.Material = "Neon";
	v129.CFrame = p128 * CFrame.new(0, p129 / 2, 0);
	v129.Color = Color3.fromRGB(0, 0, 0);
	local v130 = v129:Clone();
	v130.CFrame = p128 * CFrame.new(0, -p129 / 2, 0);
	v130.Name = "Bottom";
	local v131 = v129:Clone();
	v131.Size = Vector3.new(2, p129, p129);
	v131.CFrame = p128 * CFrame.new(p129 / 2, 0, 0);
	local v132 = v131:Clone();
	v132.CFrame = p128 * CFrame.new(-p129 / 2, 0, 0);
	local v133 = v129:Clone();
	v133.Size = Vector3.new(p129, p129, 2);
	v133.CFrame = p128 * CFrame.new(0, 0, p129 / 2);
	v133.Name = "Front";
	local v134 = v133:Clone();
	v134.CFrame = p128 * CFrame.new(0, 0, -p129 / 2);
	v134.Name = "Back";
	v129.Parent = v128;
	v130.Parent = v128;
	v131.Parent = v128;
	v132.Parent = v128;
	v133.Parent = v128;
	v134.Parent = v128;
	v128.Parent = workspace;
	return v128;
end;
function v1.NewTransition(p130)
	local v135 = Instance.new("ScreenGui", game.Players.LocalPlayer.PlayerGui);
	v135.DisplayOrder = 10;
	v135.IgnoreGuiInset = true;
	local v136 = Instance.new("Frame");
	v136.BackgroundColor3 = p130 or Color3.fromRGB(0, 0, 0);
	v136.BorderSizePixel = 0;
	v136.Position = UDim2.fromScale(-1, 0);
	v136.Size = UDim2.fromScale(1, 1);
	v136.Parent = v135;
	local v137 = {
		screengui = v135, 
		frame = v136
	};
	function v137.SlideIn()
		v1.Tween(TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), true, function(p131)
			v136.Position = UDim2.fromScale(-1 + 1 * p131, 0);
		end);
	end;
	function v137.SlideOut()
		v1.Tween(TweenInfo.new(0.2, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), true, function(p132)
			v136.Position = UDim2.fromScale(-p132, 0);
		end);
	end;
	function v137.FadeIn(p133)
		v136.Transparency = 1;
		v136.Position = UDim2.fromScale(0, 0);
		v1.Tween(TweenInfo.new(p133, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), true, function(p134)
			v136.Transparency = 1 - p134;
		end);
	end;
	function v137.FadeOut(p135)
		v1.Tween(TweenInfo.new(p135 and 0.2, Enum.EasingStyle.Linear), true, function(p136)
			v136.Transparency = p136;
		end);
	end;
	return v137;
end;
return v1;

