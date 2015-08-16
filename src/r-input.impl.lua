require("lfs")
module("enumerator", package.seeall)

info = "enumerator.sty"
debug = false
root = ""
symbol = { backslash = string.char(0x5c), dollar = string.char(0x24) }

action = { continue_ = false, break_ = true }

action_map = {
  file = {}, 
  directory = {}, 
  -- link = {},
  user = { file = {}, directory = {}, }
}

-- todo: improvement this function...
function dprint (str) 
  if debug then print(str) end
end

function command (str, ...)
  return symbol.backslash..str.."{"..table.concat(({...}), ",").."}"
end

default_action_and_pattern =  {"", function (path) return action.continue_ end}

function init ()
  -- user's action map.
  table.insert(action_map.user.file, default_action_and_pattern)
  table.insert(action_map.user.directory, default_action_and_pattern)

  -- system's action map.
  table.insert(action_map.file, {"^[.].*", function (path) return action.break_ end})
  table.insert(action_map.file, {".+[.]tex$",
    function (path)
      tex.print(command("input", path)) 
      return action.break_
    end
  })

  table.insert(action_map.directory, {"^[.].*", function (path) return action.break_ end})
  table.insert(action_map.directory, {".+", 
  function (path) do_(path) return action.break_ end})
end

function do_ (path)
  local function match_and_action (file, pattern, action_)
    if file:match(pattern) then 
      dprint("MATCH : file = "..path.."/"..file.." | pattern = "..pattern)
      return action_(path.."/"..file)
    end
    return action.continue_
  end

  local function attribute(file, path) return lfs.attributes(path.."/"..file, "mode") end 
  local function user_map (file, path) return action_map.user[attribute(file, path)] end
  local function sys_map  (file, path) return action_map[attribute(file, path)] end

  local function rounds (file, path, map)
    for k, v in ipairs(map(file, path)) do
      -- このネストイミフでしょ？でも意味あるんだよ（意図を書くのがめんどくさい）
      if match_and_action(file, unpack(v)) == action.break_ then 
        return action.break_ 
      end
    end
    return action.continue_
  end

  for file in lfs.dir(path) do
    if not rounds(file, path, user_map) then rounds(file, path, sys_map) end
  end
end

function start (...)
  if #{...} ~= 0 then
    root = unpack({...})
  end
  do_(root)
end

init()
