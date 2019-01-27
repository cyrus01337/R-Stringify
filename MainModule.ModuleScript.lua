function Stringify( Obj, Name, Options, Tabs, Cyclic, Key, CyclicObjs, WaitedFor, NumKey )
	
	local First = Cyclic == nil
	
	Options = Options or { }
	
	Options.Space = Options.Space or " "
	
	Options.Tab = Options.Tab or "	"
	
	Options.NewLine = Options.NewLine or "\n"
	
	Options.SecondaryNewLine = Options.SecondaryNewLine or "\n"
	
	Options.MaxDepth = Options.MaxDepth or math.huge
	
	Tabs = Tabs or 0
	
	local newKey = { }
	
	Key = Key or { }
	
	for a = 1, #Key do newKey[ a ] = Key[ a ] end
	
	Key = newKey
	
	if Name then
		
		local Match = First and "^[_%a][%w_%.]*" or "^[_%a][%w_]*"
		
		if type( Name ) == "string" and Name:gsub( Match, "" ) == "" then
			
			Key[ #Key + 1 ] = Name
			
		else
			
			Name = "[" .. Options.Space .. Stringify( Name, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.Space .. "]"
			
			Key[ #Key + 1 ] = Name
			
			if First then Name = "getfenv(" .. Options.Space .. ")" .. Name end
			
		end
		
		Name = Options.Tab:rep( Tabs ) .. Name .. Options.Space .. "=" .. Options.Space
				
	else
		
		if NumKey then
			
			Key[ #Key + 1 ] = "[" .. Options.Space .. NumKey .. Options.Space .. "]"
			
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
			
			return Options.MaxDepthReplacement or Name .. "{" .. Options.Space .. "..." .. Options.Space .. "}"
			
		end
		
		Cyclic = Cyclic or { }
		
		WaitedFor = WaitedFor or { }
		
		CyclicObjs = CyclicObjs or { }
		
		local Str = Key[ 1 ]
		
		for a = 2, #Key do
			
			Str = Str .. ( Key[ a ]:sub( 1, 1 ) == "[" and "" or "." ) .. Key[ a ]
			
		end
		
		Cyclic[ Obj ] = Str
		
		Str = "{" .. Options.Space
		
		local Num = 0
		
		for a, b in pairs( Obj ) do
			
			Num = Num + 1
			
			local Val, Cyc = Stringify( b, Num ~= a and a or nil, Options, Tabs + 1, Cyclic, Key, CyclicObjs, WaitedFor, Num == a and a or nil )
			
			if not Cyc then
				
				Str = Str .. Options.SecondaryNewLine .. Options.Tab:rep( Tabs + 1 ) .. Options.SecondaryNewLine .. Val .. ( next( Obj, a ) ~= nil and ( "," .. Options.Space ) or "" )
				
			end
			
		end
		
		if Num == 0 then
			
			Str = "{" .. Options.Space .. "}"
			
		else
			
			Str = Str .. Options.SecondaryNewLine .. Options.Tab:rep( Tabs + 1 ) .. Options.SecondaryNewLine .. Options.Tab:rep( Tabs ) .. ( Options.Tab == "" and Options.Space or "" ) .. "}"
			
		end
		
		if getmetatable( Obj ) then
			
			Str = "setmetatable(" .. Options.Space .. Str .. "," .. Options.Space .. Stringify( getmetatable( Obj ), nil, Options, Tabs, Cyclic, Key, CyclicObjs, WaitedFor )
			
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
				
				return Name .. 'tonumber(' .. Options.Space .. '"' .. Str .. '"' .. Options.Space .. ')'
				
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
				
				Str = "game:GetService(" .. Options.Space .. Stringify( Par.ClassName, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.Space .. ")" .. Str
				
				break
				
			elseif WaitedFor[ Par ] then
				
				Str = "[" .. Options.Space .. Stringify( Par.Name, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.Space .. "]" .. Str
				
			else
				
				WaitedFor[ Par ] = true
				
				Str = ":WaitForChild(" .. Options.Space .. Stringify( Par.Name, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.Space .. ")" .. Str
				
			end
			
			Par = Par.Parent
			
		end
		
		return Name .. Str
		
	elseif Type == "nil" then
		
		return Name .. "nil"
		
	elseif Type == "EnumItem" then
		
		return Name .. tostring( Obj )
		
	elseif Type == "function" then
		
		return Name .. [[function ( ) error( "Can't run ToString functions" ) end]]
		
	elseif Type == "BrickColor" then
		
		return Name .. Type .. ".new(" .. Options.Space .. Stringify( tostring( Obj ), nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.Space .. ")"
		
	elseif Type == "Color3" then
		
		return Name .. Type .. ".fromRGB(" .. Options.Space .. math.floor( Obj.r * 255 + 0.5 ) .. "," .. Options.Space .. math.floor( Obj.g * 255 + 0.5 ) .. "," .. Options.Space .. math.floor( Obj.b * 255 + 0.5 ) .. Options.Space .. ")"
		
	elseif Type == "NumberRange" then
		
		return Name .. Type .. ".new(" .. Options.Space .. Obj.Min .. "," .. Options.Space .. Obj.Max .. Options.Space .. ")"
		
	elseif Type == "ColorSequence" then
		
		local Str = Name .. Type .. ".new(" .. Options.Space .. "{"
		
		for a = 1, #Obj.Keypoints do
			
			Str = Str .. Options.Space .. typeof( Obj.Keypoints[ a ] ) .. ".new(" .. Options.Space .. Obj.Keypoints[ a ].Time .. "," .. Options.Space .. Stringify( Obj.Keypoints[ a ].Value, nil, Options, 0, Cyclic, Key, CyclicObjs, WaitedFor ) .. Options.Space .. ")" .. ( a ~= #Obj.Keypoints and "," or "" )
			
		end
		
		return Str .. Options.Space .. "}" .. Options.Space .. ")"
		
	elseif Type == "NumberSequence" then
		
		local Str = Name .. Type .. ".new(" .. Options.Space .. "{"
		
		for a = 1, #Obj.Keypoints do
			
			Str = Str .. Options.Space .. typeof( Obj.Keypoints[ a ] ) .. ".new(" .. Options.Space .. Obj.Keypoints[ a ].Time .. "," .. Options.Space .. Obj.Keypoints[ a ].Value .. Options.Space .. "," .. Options.Space .. Obj.Keypoints[ a ].Envelope .. Options.Space .. ")" .. ( a ~= #Obj.Keypoints and "," or "" )
			
		end
		
		return Str .. Options.Space .. "}" .. Options.Space .. ")"
		
	elseif Type == "UDim2" then
		
		return Name .. Type .. ".new(" .. Options.Space .. Obj.X.Scale .. "," .. Options.Space .. Obj.X.Offset .. "," .. Options.Space .. Obj.Y.Scale .. "," .. Options.Space .. Obj.Y.Offset .. Options.Space .. ")"
		
	else
		
		return Name .. Type .. ".new(" .. Options.Space ..tostring( Obj ) .. Options.Space .. ")"
		
	end
	
end

return Stringify