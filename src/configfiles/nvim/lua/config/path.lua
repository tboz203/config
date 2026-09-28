---@class Path
local Path = require("plenary.path")

Path._new = Path.new
function Path:new(...)
  local args = { ... }

  if type(self) == "string" then
    table.insert(args, 1, self)
  end

  local path_input
  if #args == 1 then
    path_input = args[1]
  else
    path_input = args
  end

  -- If we already have a Path, it's fine.
  --   Just return it
  if Path.is_path(path_input) then
    return path_input
  end

  -- TODO: Should probably remove and dumb stuff like double seps, periods in the middle, etc.
  local sep = Path.path.sep
  if type(path_input) == "table" then
    sep = path_input.sep or Path.path.sep
    path_input.sep = nil
  end

  local path_string
  if type(path_input) == "table" then
    -- TODO: It's possible this could be done more elegantly with __concat
    --       But I'm unsure of what we'd do to make that happen
    local path_objs = {}
    for _, v in ipairs(path_input) do
      if Path.is_path(v) then
        table.insert(path_objs, v.filename)
      else
        assert(type(v) == "string")
        table.insert(path_objs, v)
      end
    end

    path_string = table.concat(path_objs, sep)
  else
    assert(type(path_input) == "string", vim.inspect(path_input))
    path_string = path_input
  end

  local obj = {
    filename = path_string,

    _sep = sep,
  }

  setmetatable(obj, Path)

  return obj
end

-- overriding Path:find_upwards because as of 2023-09-29 if a matching file is
-- not found, it enters an infinite loop and hangs the whole editor
---@diagnostic disable-next-line
function Path:find_upwards(filename)
  local folder = self:normalized()
  local root = Path.path.root()
  while folder:absolute() ~= root do
    local p = folder / filename
    if p:exists() then
      return p
    end
    folder = folder:parent()
  end
  return nil
end

-- corrected & extended version of `Path:find_upwards`
---@param ... string
---@return string?
function Path:find_any_upwards(...)
  local folder = self
  local root = Path.path.root()
  while folder:absolute() ~= root do
    for _, filename in pairs({ ... }) do
      local p = folder / filename
      if p:exists() then
        return p
      end
    end
    folder = folder:parent()
  end
  return nil
end

function Path:normalized()
  return Path(self:normalize())
end

function Path:absoluted()
  return Path(self:absolute())
end

---@return string
function Path:basename()
  return vim.fs.basename(self.filename)
end

-- allow calling `Path` as a constructor
setmetatable(Path, {
  __call = Path.new,
})

return Path
