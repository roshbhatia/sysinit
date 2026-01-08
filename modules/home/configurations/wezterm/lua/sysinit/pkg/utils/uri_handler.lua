local wezterm = require("wezterm")

local M = {}

-- Determine if a file can be edited based on extension heuristics
local function is_editable(filename)
  -- Extract file extension
  local extension = filename:match("^.+(%..+)$")
  if extension then
    -- Remove the leading dot
    extension = extension:sub(2):lower()

    -- Binary file extensions that shouldn't be opened in editor
    local binary_extensions = {
      -- Images
      jpg = true,
      jpeg = true,
      png = true,
      gif = true,
      bmp = true,
      webp = true,
      svg = true,
      ico = true,
      tiff = true,
      -- Archives
      zip = true,
      tar = true,
      gz = true,
      ["bz2"] = true,
      ["xz"] = true,
      rar = true,
      ["7z"] = true,
      -- Executables
      exe = true,
      bin = true,
      so = true,
      dylib = true,
      -- Video/Audio
      ["mp4"] = true,
      mkv = true,
      mov = true,
      avi = true,
      ["mp3"] = true,
      wav = true,
      aac = true,
      flac = true,
      -- Documents (for preview instead)
      pdf = true,
      doc = true,
      docx = true,
      xls = true,
      xlsx = true,
    }

    if binary_extensions[extension] then
      return false
    end
  end

  return true
end

-- Extract filename from various URI schemes
local function extract_filename(uri)
  -- $EDITOR: scheme
  local start, match_end = uri:find("$EDITOR:")
  if start == 1 then
    return uri:sub(match_end + 1)
  end

  -- file:// scheme
  local start, match_end = uri:find("file:")
  if start == 1 then
    -- Skip "file://" to get `hostname/path/to/file`
    local host_and_path = uri:sub(match_end + 3)
    local slash_pos = host_and_path:find("/")
    if slash_pos then
      -- Return `/path/to/file`
      return host_and_path:sub(slash_pos)
    end
  end

  return nil
end

-- Determine how to handle a file (edit vs preview)
local function get_file_action(filename)
  if is_editable(filename) then
    return "edit"
  end

  -- Check if file exists and is a regular file
  local f = io.open(filename, "r")
  if f then
    f:close()
    return "preview"
  end

  return nil
end

-- Open file in editor
local function open_in_editor(window, pane, filename)
  local editor = os.getenv("VISUAL") or os.getenv("EDITOR") or "nvim"

  local action = wezterm.action.SpawnCommandInNewWindow({
    args = { editor, filename },
  })

  window:perform_action(action, pane)
end

-- Preview file with chafa or appropriate tool
local function preview_file(window, pane, filename)
  local extension = filename:match("^.+(%..+)$")
  if not extension then
    return
  end

  extension = extension:sub(2):lower()

  local image_extensions = {
    jpg = true,
    jpeg = true,
    png = true,
    gif = true,
    bmp = true,
    webp = true,
    ico = true,
  }

  local document_extensions = {
    pdf = true,
  }

  local preview_cmd

  if image_extensions[extension] then
    -- Use chafa for image preview
    preview_cmd = { "chafa", "--size=120x40", filename }
  elseif document_extensions[extension] then
    -- Use pdftotext for PDF preview
    preview_cmd = { "pdftotext", filename, "-" }
  else
    -- Fallback to cat/less for text-like files
    preview_cmd = { "cat", filename }
  end

  if preview_cmd then
    local action = wezterm.action.SpawnCommandInNewWindow({
      args = preview_cmd,
    })
    window:perform_action(action, pane)
  end
end

-- Main open-uri event handler
function M.setup(config)
  wezterm.on("open-uri", function(window, pane, uri)
    local filename = extract_filename(uri)

    if filename then
      local action = get_file_action(filename)

      if action == "edit" then
        open_in_editor(window, pane, filename)
        return false
      elseif action == "preview" then
        preview_file(window, pane, filename)
        return false
      end
    end

    -- Allow default handling for non-file URIs
    return true
  end)
end

return M
