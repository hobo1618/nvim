function CreateTutorDomeEntry()
    local date = os.date("%Y-%m-%d")
    local filename = date .. ".md"
    local dir = vim.fn.expand('%:p:h')

    local content = string.format([[
---
time: 1.5
date: %s
---

]], os.date("%Y-%m-%d"))

    local file_path = dir .. "/" .. filename
    vim.cmd("edit " .. file_path)
    local lines = {}
    for line in content:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

vim.api.nvim_create_user_command('TDE', CreateTutorDomeEntry, {})


-- Function to load the content of a text file
local function loadFileContent(filePath)
    local file, err = io.open(filePath, "r")
    if not file then
        print("Error: Could not open file " .. filePath .. ". " .. err)
        return nil
    end

    local content = file:read("*a")
    file:close()
    return content
end

-- Function to create the student directory and file
function CreateStudentDirectory(first_name, last_name)
    local dir_name = last_name .. first_name
    local dir_path = vim.fn.getcwd() .. "/" .. dir_name

    -- Create the directory
    vim.fn.mkdir(dir_path, "p")

    -- Paths for files
    local index_file_path = dir_path .. "/index.md"
    local template_file_path = vim.fn.getcwd() .. "/template.md"

    -- Read content from template.md
    local template_content = loadFileContent(template_file_path)
    if not template_content then
        print("Error: Could not read template file " .. template_file_path)
        return
    end

    -- Replace placeholders in the template
    local content = string.gsub(template_content, "{{first_name}}", first_name)
    content = string.gsub(content, "{{last_name}}", last_name)

    -- Write content to index.md
    local file = io.open(index_file_path, "w")
    if not file then
        print("Error: Could not open file " .. index_file_path)
        return
    end

    file:write(content)
    file:close()

    -- Open index.md in the editor
    vim.cmd("edit " .. index_file_path)
end

-- Create the user command
vim.api.nvim_create_user_command('CreateStudentDirectory', function(opts)
    local args = vim.split(opts.args, " ")
    if #args ~= 2 then
        print("Error: Invalid number of arguments. Usage: :CreateStudentDirectory FirstName LastName")
        return
    end
    local first_name = args[1]
    local last_name = args[2]
    CreateStudentDirectory(first_name, last_name)
end, { nargs = "*" })


-- local http = require("http.request")
local cjson = require("cjson")

-- Define the API endpoint
local api_endpoint = "https://httpbin.org/post"

-- Function to get the current buffer content
-- local function get_current_buffer_content()
--     local buffer_number = vim.api.nvim_get_current_buf()
--     local lines = vim.api.nvim_buf_get_lines(buffer_number, 0, -1, true)
--     return table.concat(lines, "\n")
-- end
--
-- -- Function to make a POST request
-- local function PostLesson()
--
--     local content = get_current_buffer_content()
--
--     local headers = {
--         ["Content-Type"] = "application/json"
--     }
--
--     local body = cjson.encode({ text = content }) -- Encode data as JSON
--     local response, err = http.request("POST", api_endpoint, headers, body)
--
--     if not response then
--         print("Error: " .. err)
--         return
--     end
--
--     print("Response status: " .. response.status)
--     print("Response body: " .. response.body)
-- end


-- Import the http module
local http = require("http.request")

-- Function to get the text from the current buffer
local function get_buffer_text()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    return table.concat(lines, "\n")
end

-- Import the http module
local http_request = require("http.request")

-- Function to post the text to httpbin
local function PostLesson()
  local text = get_buffer_text()

  -- Create the HTTP request
  local req = http_request.new_from_uri("https://httpbin.org/post")
  req.headers:upsert(":method", "POST")
  req.headers:upsert("content-type", "text/plain")
  req:set_body(text)

  -- Perform the request
  local headers, stream = req:go(10) -- 10 seconds timeout
  if not headers then
    print("Request failed")
    return
  end

  -- Read the response
  local body, err = stream:get_body_as_string()
  if not body then
    print("Failed to get body:", err)
    return
  end

  print("Response from httpbin:\n", body)
end

-- Map a key to the function
vim.api.nvim_set_keymap("n", "<leader>p", ":lua post_to_httpbin()<CR>", { noremap = true, silent = true })


vim.api.nvim_create_user_command('PostLesson', PostLesson, {})

-- Map a key to the function
-- vim.api.nvim_set_keymap("n", "<leader>p", ":lua post_to_httpbin()<CR>", { noremap = true, silent = true })

-- -- Function to be called from a Neovim command
-- local function post_buffer_content()
--     local content = get_current_buffer_content()
--     post_to_api(content)
-- end

-- Expose the function to Neovim
-- return {
--     post_buffer_content = post_buffer_content
-- }

vim.api.nvim_create_user_command('PostLesson', PostLesson, {})
