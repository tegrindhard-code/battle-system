
-- Decompiled with the Synapse X Luau decompiler.

local u1 = {
	new = function(p1)
		local v1 = setmetatable({}, u1);
		local v2 = p1 and 0;
		rawset(v1, "_time0", tick());
		rawset(v1, "_position0", v2);
		rawset(v1, "_velocity0", 0 * v2);
		rawset(v1, "_target", v2);
		rawset(v1, "_damper", 1);
		rawset(v1, "_speed", 1);
		return v1;
	end, 
	Impulse = function(p2, p3)
		p2.Velocity = p2.Velocity + p3;
	end, 
	TimeSkip = function(p4, p5)
		local v3 = tick();
		local v4, v5 = p4:_positionVelocity(v3 + p5);
		rawset(p4, "_position0", v4);
		rawset(p4, "_velocity0", v5);
		rawset(p4, "_time0", v3);
	end, 
	__index = function(p6, p7)
		if u1[p7] then
			return u1[p7];
		end;
		if p7 == "Value" or p7 == "Position" or p7 == "p" then
			local v6, v7 = p6:_positionVelocity(tick());
			return v6;
		end;
		if p7 == "Velocity" or p7 == "v" then
			local v8, v9 = p6:_positionVelocity(tick());
			return v9;
		end;
		if p7 == "Target" or p7 == "t" then
			return rawget(p6, "_target");
		end;
		if p7 == "Damper" or p7 == "d" then
			return rawget(p6, "_damper");
		end;
		if p7 == "Speed" or p7 == "s" then
			return rawget(p6, "_speed");
		end;
		error(("%q is not a valid member of Spring"):format(tostring(p7)), 2);
	end, 
	__newindex = function(p8, p9, p10)
		local v10 = tick();
		if p9 == "Value" or p9 == "Position" or p9 == "p" then
			local v11, v12 = p8:_positionVelocity(v10);
			rawset(p8, "_position0", p10);
			rawset(p8, "_velocity0", v12);
		elseif p9 == "Velocity" or p9 == "v" then
			local v13, v14 = p8:_positionVelocity(v10);
			rawset(p8, "_position0", v13);
			rawset(p8, "_velocity0", p10);
		elseif p9 == "Target" or p9 == "t" then
			local v15, v16 = p8:_positionVelocity(v10);
			rawset(p8, "_position0", v15);
			rawset(p8, "_velocity0", v16);
			rawset(p8, "_target", p10);
		elseif p9 == "Damper" or p9 == "d" then
			local v17, v18 = p8:_positionVelocity(v10);
			rawset(p8, "_position0", v17);
			rawset(p8, "_velocity0", v18);
			rawset(p8, "_damper", math.clamp(p10, 0, 1));
		elseif p9 == "Speed" or p9 == "s" then
			local v19, v20 = p8:_positionVelocity(v10);
			rawset(p8, "_position0", v19);
			rawset(p8, "_velocity0", v20);
			if p10 < 0 then
				local v21 = 0;
			else
				v21 = p10;
			end;
			rawset(p8, "_speed", v21);
		else
			error(("%q is not a valid member of Spring").format("%q is not a valid member of Spring", tostring(p9)), 2);
		end;
		rawset(p8, "_time0", v10);
	end, 
	_positionVelocity = function(p11, p12)
		local v22 = nil;
		local v23 = nil;
		local v24 = nil;
		v24 = p12 - rawget(p11, "_time0");
		local v25 = rawget(p11, "_position0");
		v22 = rawget(p11, "_velocity0");
		local v26 = rawget(p11, "_target");
		local v27 = rawget(p11, "_damper");
		local v28 = rawget(p11, "_speed");
		v23 = v25 - v26;
		if v28 == 0 then
			return v25, 0;
		end;
		if not (v27 < 1) then
			local v29 = v22 / v28 + v23;
			local v30 = 2.718281828459045 ^ (v28 * v24);
			return v26 + (v23 + v29 * v28 * v24) / v30, v28 * (v29 - v23 - v29 * v28 * v24) / v30;
		end;
		local v31 = (1 - v27 * v27) ^ 0.5;
		local v32 = (v22 / v28 + v27 * v23) / v31;
		local v33 = math.cos(v31 * v28 * v24);
		local v34 = math.sin(v31 * v28 * v24);
		local v35 = 2.718281828459045 ^ (v27 * v28 * v24);
		return v26 + (v23 * v33 + v32 * v34) / v35, v28 * ((v31 * v32 - v27 * v23) * v33 - (v31 * v23 + v27 * v32) * v34) / v35;
	end
};
return u1;

