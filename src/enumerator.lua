require("lfs")

enumerator = {
	current_dir	= assert(lfs.currentdir()),
	backslash	= string.char(0x5C),
	dollar		= string.char(0x24),
	info		= "enumerator.sty",
	debug		= false,

	-- regexp pattern
	matcher = {}
}

enumerator.matcher.common = function(pattern, str)
	if str:match(pattern) then
		enumerator.debugger("enumerator.matcher.common()", "`"..str.."' match `"..pattern.."'")
		return true
	else
		return false
	end
end

enumerator.matcher.tex = function(str)
	return enumerator.matcher.common(".+[.]tex", str)
end

enumerator.matcher.nosys = function(str)
	return not enumerator.matcher.common("^[.].*", str)
end

enumerator.enable_debug = function() 
	enumerator.debug = true
	
end

enumerator.is_dir = function(path)
	return (lfs.attributes(path, "mode") == "directory")
end

enumerator.is_file = function(path)
	return (lfs.attributes(path, "mode") == "file")
end

enumerator.print_command = function(csname, impl) 
	tex.print(enumerator.backslash..csname.."{"..impl.."}")
end

enumerator.debugger = function(func, str)
	if enumerator.debug then
		local msg = " [debug] "..func..":"..str
		print(msg)
	end
end

enumerator.do_ = function(in_this_dir, attribute_detector, regex_matcher, callback)
	local rpath_to_this_dir = enumerator.current_dir.."/"..in_this_dir
	enumerator.debugger("enumerator.do_()", "rpath_to_this_dir is "..rpath_to_this_dir)
	for name in lfs.dir(rpath_to_this_dir) do
		enumerator.debugger("enumerator.do_()", "name is "..name)
		if (attribute_detector(rpath_to_this_dir.."/"..name) and regex_matcher(name)) then
			callback(in_this_dir.."/"..name)
		end
	end
end

enumerator.do_recursively = function(in_this_dir)
	-- enumerate files...
	enumerator.do_(
		in_this_dir,
		enumerator.is_file, 
		enumerator.matcher.tex, 
		function(objpath) enumerator.print_command("input", objpath) end)

	-- look child-dir...
	enumerator.do_(
		in_this_dir, 
		enumerator.is_dir, 
		enumerator.matcher.nosys, 
		function(objpath) return enumerator.do_recursively(objpath) end)
end
