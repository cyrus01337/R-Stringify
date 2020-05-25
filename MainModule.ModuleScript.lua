script.Name = "Stringify"

local LuaKeywords = { [ "true" ] = true, [ "false" ] = true, [ "if" ] = true, [ "then" ] = true, [ "else" ] = true, [ "elseif" ] = true, [ "and" ] = true, [ "or" ] = true, [ "not" ] = true, [ "function" ] = true, [ "end" ] = true, [ "return"] = true, [ "break" ] = true, [ "nil" ] = true, [ "while" ] = true, [ "for" ] = true, [ "repeat" ] = true, [ "do" ] = true, [ "until" ] = true, [ "in" ] = true, [ "local" ] = true, [ "nil" ] = true }

local DefaultOptions = {
	
	Space = " ",
	
	SecondarySpace = "",
	
	Tab = "	",
	
	NewLine = "\n",
	
	SecondaryNewLine = "\n",
	
	MaxDepth = math.huge
	
}

function Stringify( Obj, Name, Options, Tabs, Cyclic, Key, CyclicObjs, WaitedFor, NumKey )
	
	local First = Cyclic == nil
	
	if not Options then
		
		Options = DefaultOptions
		
	elseif not getmetatable( Options ) then
		
		for a, b in pairs( DefaultOptions ) do
			
			Options[ a ] = Options[ a ] or b
			
		end
		
	end
	
	Tabs = Tabs or 0
	
	local newKey = { }
	
	Key = Key or { }
	
	for a, K in ipairs( Key ) do newKey[ a ] = K end
	
	Key = newKey
	
	if Name then
		
		local Match = First and "^[_%a][%w_%.]*" or "^[_%a][%w_]*"
		
		if type( Name ) == "string" and Name:gsub( Match, "" ) == "" and not LuaKeywords[ Name ] then
			
			Key[ #Key + 1 ] = Name
			
		else
			
			Name = "[" .. Options.SecondarySpace .. Stringify( Name, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.SecondarySpace .. "]"
			
			Key[ #Key + 1 ] = Name
			
			if First then Name = "getfenv(" .. Options.SecondarySpace .. ")" .. Name end
			
		end
		
		Name = Options.Tab:rep( Tabs ) .. Name .. Options.Space .. "=" .. Options.Space
				
	else
		
		if NumKey then
			
			Key[ #Key + 1 ] = "[" .. Options.SecondarySpace .. NumKey .. Options.SecondarySpace .. "]"
			
		end
		
		Name = Options.Tab:rep( Tabs )
		
	end
	
	if Cyclic and type( Obj ) == "table" and Obj ~= { } and Cyclic[ Obj ] then
		
		local Str = Key[ 1 ]
		
		for a = 2, #Key do
			
			Str = Str .. ( Key[ a ]:sub( 1, 1 ) == "[" and "" or "." ) .. Key[ a ]
			
		end
		
		CyclicObjs[ Str ] = Cyclic[ Obj ]
		
		return nil, true
		
	end
	
	if Options.Process then
		
		local Str = Options.Process( Obj, Name, Options, Tabs, Cyclic, Key, CyclicObjs, WaitedFor, NumKey )
		
		if Str then return Str end
		
	end
	
	local Type = typeof( Obj )
	
	if Type == "table" then
		
		if #Key > Options.MaxDepth then
			
			return Options.MaxDepthReplacement or Name .. "{" .. Options.SecondarySpace .. "..." .. Options.SecondarySpace .. "}"
			
		end
		
		Cyclic = Cyclic or { }
		
		WaitedFor = WaitedFor or { }
		
		CyclicObjs = CyclicObjs or { }
		
		local Str = Key[ 1 ]
		
		for a = 2, #Key do
			
			Str = Str .. ( Key[ a ]:sub( 1, 1 ) == "[" and "" or "." ) .. Key[ a ]
			
		end
		
		Cyclic[ Obj ] = Str
		
		Str = "{" .. ( Options.SecondaryNewLine == "" and Options.SecondarySpace or "" )
		
		local Num = 0
		
		for a, b in pairs( Obj ) do
			
			Num = Num + 1
			
			local Val, Cyc = Stringify( b, Num ~= a and a or nil, Options, Tabs + 1, Cyclic, Key, CyclicObjs, WaitedFor, Num == a and a or nil )
			
			if not Cyc then
				
				Str = Str .. Options.SecondaryNewLine .. Options.Tab:rep( Tabs + 1 ) .. Options.NewLine .. Val .. ((next( Obj, a ) ~= nil or Options.SecondaryNewLine ~= "") and "," or "")  .. ( next( Obj, a ) ~= nil and ( Options.SecondaryNewLine == "" and Options.Space or "" ) or "" )
				
			elseif not Name then
				
				Str = Str .. Options.SecondaryNewLine .. Options.Tab:rep( Tabs + 1 ) .. Options.NewLine .. '"error_cycle"' .. ((next( Obj, a ) ~= nil or Options.SecondaryNewLine ~= "") and "," or "") .. ( next( Obj, a ) ~= nil and ( Options.SecondaryNewLine == "" and Options.Space or "" ) or "" )
				
			elseif next( Obj, a ) == nil then
				
				Str = Str:sub( 1, -2 )
				
			end
			
		end
		
		if Num == 0 then
			
			Str = "{" .. Options.SecondarySpace .. "}"
			
		else
			
			Str = Str .. Options.SecondaryNewLine .. Options.Tab:rep( Tabs + 1 ) .. Options.NewLine .. Options.Tab:rep( Tabs ) .. ( Options.Tab == "" and Options.SecondarySpace or "" ) .. "}"
			
		end
		
		if getmetatable( Obj ) then
			
			Str = "setmetatable(" .. Options.SecondarySpace .. Str .. "," .. Options.Space .. Stringify( getmetatable( Obj ), nil, Options, Tabs, Cyclic, Key, CyclicObjs, WaitedFor )
			
		end
		
		if First and Name ~= ( "	" ):rep( Tabs ) then
			
			for a, b in pairs( CyclicObjs ) do
				
				Str = Str .. Options.SecondaryNewLine .. Options.Tab:rep( Tabs ) .. Options.NewLine .. Options.Tab:rep( Tabs ) .. a .. Options.Space .. "=" .. Options.Space .. b
				
			end
			
		end
		
		return Name .. Str
		
	elseif Type == "string" then
		
		Obj = Obj:gsub( "\\", "\\\\" )
		
		Obj = Obj:gsub( "\n", "\\n" )
		
		local Start, End
		
		if Obj:find( '"' ) then
			
			if Obj:find( "'" ) then
				
				if Obj:find( "%[%[" ) or Obj:find( "%]%]" ) then
					
					if Obj:find( "%[%=%=%[" ) or Obj:find( "%]%=%=%]" ) then
						
						Start, End = '"', '"'
						
						Obj = Obj:gsub( '"', '\\"' )
						
					else
						
						Start, End = "[==[", "]==]"
						
					end
					
				else
					
					Start, End = "[[", "]]"
					
				end
				
			else
				
				Start, End = "'", "'"
				
			end
			
		else
			
			Start, End = '"', '"'
			
		end
		
		return Name .. Start .. Obj .. End
		
	elseif Type == "number" then
		
		local Str = tostring( Obj )
		
		if #Str ~= #Str:match( "-?%d*%.?%d*" ) then
			
			if tonumber( Str ) then
				
				return Name .. 'tonumber(' .. Options.SecondarySpace .. '"' .. Str .. '"' .. Options.SecondarySpace .. ')'
				
			elseif Obj == math.huge then
				
				return Name .. "math.huge"
				
			else
				
				return Name .. "0" .. Options.Space .. "/" .. Options.Space .. "0"
				
			end
			
		end
		
		return Name .. Str
		
	elseif Type == "boolean" then
		
		return Name .. tostring( Obj )
		
	elseif Type == "Instance" then
		
		if Obj == game then return "game" end
		
		if not Obj.Parent then return "" end
		
		local Par = Obj
		
		local Str = ""
		
		while Par do
			
			if Par == workspace then
				
				Str = "workspace" .. Str
				
				break
				
			elseif Par == game then
				
				Str = "game" .. Str
				
				break
				
			elseif Par.Parent == game then
				
				Str = "game:GetService(" .. Options.SecondarySpace .. Stringify( Par.ClassName, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.SecondarySpace .. ")" .. Str
				
				break
				
			elseif WaitedFor and WaitedFor[ Par ] then
				
				Str = "[" .. Options.SecondarySpace .. Stringify( Par.Name, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.SecondarySpace .. "]" .. Str
				
			else
				
				if WaitedFor then
					
					WaitedFor[ Par ] = true
					
				end
				 				
				Str = ":WaitForChild(" .. Options.SecondarySpace .. Stringify( Par.Name, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.SecondarySpace .. ")" .. Str
				
			end
			
			Par = Par.Parent
			
		end
		
		return Name .. Str
		
	elseif Type == "nil" then
		
		return Name .. "nil"
		
	elseif Type == "EnumItem" then
		
		return Name .. tostring( Obj )
		
	elseif Type == "function" then
		
		return Name .. [[function ( ) error( "Can't run Stringify functions" ) end]]
		
	elseif Type == "BrickColor" then
		
		return Name .. Type .. ".new(" .. Options.SecondarySpace .. Stringify( tostring( Obj ), nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.SecondarySpace .. ")"
		
	elseif Type == "Color3" then
		
		return Name .. Type .. ".fromRGB(" .. Options.SecondarySpace .. math.floor( Obj.r * 255 + 0.5 ) .. "," .. Options.Space .. math.floor( Obj.g * 255 + 0.5 ) .. "," .. Options.Space .. math.floor( Obj.b * 255 + 0.5 ) .. Options.SecondarySpace .. ")"
		
	elseif Type == "NumberRange" then
		
		return Name .. Type .. ".new(" .. Options.SecondarySpace .. Obj.Min .. "," .. Options.Space .. Obj.Max .. Options.SecondarySpace .. ")"
		
	elseif Type == "ColorSequence" then
		
		local Str = Name .. Type .. ".new(" .. Options.SecondarySpace .. "{"
		
		for a, Point in ipairs( Obj.Keypoints ) do
			
			Str = Str .. Options.Space .. typeof( Point ) .. ".new(" .. Options.SecondarySpace .. Point.Time .. "," .. Options.Space .. Stringify( Point.Value, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.SecondarySpace .. ")" .. ( a ~= #Obj.Keypoints and "," or "" )
			
		end
		
		return Str .. Options.SecondarySpace .. "}" .. Options.SecondarySpace .. ")"
		
	elseif Type == "NumberSequence" then
		
		local Str = Name .. Type .. ".new(" .. Options.SecondarySpace .. "{"
		
		for a, Point in ipairs( Obj.Keypoints ) do
			
			Str = Str .. Options.Space .. typeof( Point ) .. ".new(" .. Options.SecondarySpace .. Point.Time .. "," .. Options.Space .. Point.Value .. Options.Space .. "," .. Options.Space .. Point.Envelope .. Options.SecondarySpace .. ")" .. ( a ~= #Obj.Keypoints and "," or "" )
			
		end
		
		return Str .. Options.SecondarySpace .. "}" .. Options.SecondarySpace .. ")"
		
	elseif Type == "UDim2" then
		
		return Name .. Type .. ".new(" .. Options.SecondarySpace .. Obj.X.Scale .. "," .. Options.Space .. Obj.X.Offset .. "," .. Options.Space .. Obj.Y.Scale .. "," .. Options.Space .. Obj.Y.Offset .. Options.SecondarySpace .. ")"
	
	elseif Type == "Region3" then
		
		local TopLeft, BottomRight = Obj.CFrame.p - Obj.Size / 2, Obj.CFrame.p + Obj.Size / 2
		
		return Name .. Type .. ".new(" .. Options.SecondarySpace .. Stringify( TopLeft, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. "," .. Options.Space .. Stringify( BottomRight, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.SecondarySpace .. ")"
		
	else
		
		return Name .. Type .. ".new(" .. Options.SecondarySpace ..tostring( Obj ) .. Options.SecondarySpace .. ")"
		
	end
	
end

return Stringify