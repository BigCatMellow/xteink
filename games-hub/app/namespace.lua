-- Flat, stable per-game storage names inside the hub's firmware-owned sandbox.
local Namespace={}
local function valid(name)
  return type(name)=='string' and #name>0 and name:match('^[%w._-]+$') and not name:find('..',1,true)
end
function Namespace.new(id)
  assert(type(id)=='string' and id:match('^[a-z]+$'),'Invalid game ID')
  local scope={prefix=id..'--',error=nil,root=nil}
  local storage={}
  function scope:key(name)
    assert(valid(name) and #self.prefix+#name<=64,'Invalid save filename')
    return self.prefix..name
  end
  function scope:begin() self.error=nil end
  local function invoke(method,name,...)
    local root=scope.root and scope.root.storage
    if method=='write' or method=='remove' then
      assert(not scope.read_error,'Save disabled after a read error')
    end
    assert(root and type(root[method])=='function','Save storage unavailable')
    local key=scope:key(name)
    local ok,value,err=pcall(root[method],root,key,...)
    if not ok then
      scope.error=tostring(value);if method=='read' then scope.read_error=scope.error end
      error(value,0)
    end
    if (value==false and (method=='write' or method=='remove')) or (value==nil and err and err~='not_found') then
      scope.error=tostring(err or 'Save failed')
      if method=='read' then scope.read_error=scope.error;error(scope.error,0) end
    end
    return value,err
  end
  for _,method in ipairs({'read','write','remove','exists','size'}) do
    storage[method]=function(_,name,...) return invoke(method,name,...) end
  end
  function storage:list()
    local names,err=scope.root.storage:list()
    if not names then return nil,err end
    local result={}
    for _,name in ipairs(names) do
      if type(name)=='string' and name:sub(1,#scope.prefix)==scope.prefix then result[#result+1]=name:sub(#scope.prefix+1) end
    end
    return result
  end
  function storage:usage() return scope.root.storage:usage() end
  local proxy=setmetatable({storage=storage,files=storage},{__index=function(_,key)
    local value=scope.root[key]
    if type(value)=='function' then return function(_,...) return value(scope.root,...) end end
    return value
  end})
  function scope:context(root) self.root=root;return proxy end
  return scope
end
return Namespace
