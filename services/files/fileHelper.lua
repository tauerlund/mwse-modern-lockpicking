--- Helper class containing file-related utility functions
---@class fileHelper
local this = {}

---@private
---@type mwseLogger
this.logger = mwse.Logger.new()

--- Gets all files of the specified type in the given directory
---@public
---@param dir string The directory to search in
---@param fileType fileType The file type/extension to filter by
---@return string[]|nil files An array of file names matching the specified type, or nil if the directory is invalid
function this.getAllFilesInDirectory(dir, fileType)
    if not this.isDirectory(dir) then
        this.logger:error("%s is not a valid directory", dir)
        return nil
    end

    local files = {}

    for file in lfs.dir(dir) do
        ---@cast fileType +string
        if file:lower():endswith(fileType:lower()) then
            table.insert(files, file)
        end
    end

    if table.empty(files) then
        this.logger:debug("Found no files at %s", dir)
    end

    return files
end

---@private
---@param path string
---@return boolean
function this.isDirectory(path)
    return lfs.attributes(path, "mode") == "directory"
end

return this
