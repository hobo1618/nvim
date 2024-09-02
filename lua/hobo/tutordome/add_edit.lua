local http_request = require("http.request")
local http_cookies = require("http.cookie")
local constants = require("hobo.tutordome.constants")
local cfid = os.getenv("TD_CFID")
local cftoken = os.getenv("TD_CFTOKEN")

local url = "https://td.bespokeeducation.fr/tutordome/billing/add_edit-process.cfm"

DOMAIN = constants.DOMAIN

-- Function to get the text from the current buffer
local function get_buffer_text()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    return table.concat(lines, "\n")
end

local function get_time_date_entry()
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local text = table.concat(lines, "\n")

    -- Initialize variables to store time, date, and entry
    local time_value, date_value, entry_value
    local in_entry = false

    -- Iterate over each line to find time, date, and entry
    for _, line in ipairs(lines) do
        -- Check for the time field
        if line:match("^time:%s*(.*)$") then
            time_value = line:match("^time:%s*(.*)$")
        end

        -- Check for the date field
        if line:match("^date:%s*(.*)$") then
            date_value = line:match("^date:%s*(.*)$")
        end

        -- Check if we are in the entry section
        if line:match("^##%s*Entry") then
            in_entry = true
        elseif line:match("^##%s*") and in_entry then
            in_entry = false -- End of entry section if another heading is found
        end

        -- Collect the entry content
        if in_entry and not line:match("^##%s*Entry") then
            entry_value = (entry_value or "") .. line .. "\n"
        end
    end

    -- Clean up the entry by trimming whitespace
    if entry_value then
        entry_value = entry_value:gsub("^%s+", ""):gsub("%s+$", "")
    end

    return tostring(time_value), tostring(date_value), tostring(entry_value)
end

-- Function to get the multipart form data
local function get_multipart_form_data(content, date, student_id, time)
    local boundary = "----WebKitFormBoundary1KfbYiN3zy8E0Pz0"
    local body = table.concat({
        "--" .. boundary,
        'Content-Disposition: form-data; name="billingPeriod_id"',
        '',
        '798',
        "--" .. boundary,
        'Content-Disposition: form-data; name="billing_action"',
        '',
        'add',
        "--" .. boundary,
        'Content-Disposition: form-data; name="billing_type"',
        '',
        '1',
        "--" .. boundary,
        'Content-Disposition: form-data; name="category"',
        '',
        '1',
        "--" .. boundary,
        'Content-Disposition: form-data; name="student_id"',
        '',
        student_id,
        "--" .. boundary,
        'Content-Disposition: form-data; name="time"',
        '',
        time,
        "--" .. boundary,
        'Content-Disposition: form-data; name="location"',
        '',
        '7',
        "--" .. boundary,
        'Content-Disposition: form-data; name="entryDate"',
        '',
        date,
        "--" .. boundary,
        'Content-Disposition: form-data; name="journal_entry"',
        '',
        content,
        "--" .. boundary,
        'Content-Disposition: form-data; name="office_id"',
        '',
        '0',
        "--" .. boundary,
        'Content-Disposition: form-data; name="skype_session"',
        '',
        '1',
        "--" .. boundary .. "--",
        ''
    }, '\r\n')
    return body, boundary
end

local function get_id_from_frontmatter()
    -- Get the current buffer's path
    local current_file = vim.fn.expand('%:p')

    -- Get the directory of the current buffer
    local current_dir = vim.fn.fnamemodify(current_file, ':h')

    -- Path to the index.md in the same directory
    local index_file = current_dir .. '/index.md'

    -- Open the index.md file
    local file = io.open(index_file, 'r')

    if not file then
        print("index.md file not found")
        return nil
    end

    -- Read the file line by line
    local id_value = nil
    local in_frontmatter = false

    for line in file:lines() do
        if line:match("^%-%-%-") then
            if in_frontmatter then
                break                 -- End of frontmatter
            else
                in_frontmatter = true -- Start of frontmatter
            end
        elseif in_frontmatter then
            -- Look for the id field
            local id_match = line:match("^id:%s*(%d+)")
            if id_match then
                id_value = id_match
                break
            end
        end
    end

    file:close()

    if id_value then
        return tostring(id_value) -- Ensure it's returned as a string
    else
        print("ID not found in frontmatter")
        return nil
    end
end


-- Function to post the text to the specified URL
local function PostLesson()
    local file = io.open("cookies.txt", "r")
    local cookie_store = http_cookies.new_store()
    local student_id = get_id_from_frontmatter()

    -- local text = get_buffer_text()
    local time, date, entry = get_time_date_entry()
    local err = cookie_store:load_from_file(file)
    print(time, date, entry)

    if err then
        print("Error loading cookies from file:", err)
    end

    local jsessionid = cookie_store:get(DOMAIN, "/", "JSESSIONID")
    local cfauth = cookie_store:get(DOMAIN, "/", "CFAUTHORIZATION_tdFranceApp")

    print("JSESSIONID: ", jsessionid)
    print("CFAUTHORIZATION_tdFranceApp: ", cfauth)

    local body, boundary = get_multipart_form_data(entry, date, student_id, time)
    -- local body, boundary = get_multipart_form_data(text, '8/21/24', student_id, '2.0')

    local cookie_header = "CFID=" ..
        cfid .. "; CFTOKEN=" .. cftoken .. "; JSESSIONID=" .. jsessionid .. "; CFAUTHORIZATION_tdFranceApp=" .. cfauth

    -- Create the HTTP request
    local req = http_request.new_from_uri(url)

    local req_headers = {
        ["Content-Type"] = "multipart/form-data; boundary=" .. boundary,
        ["Cookie"] = cookie_header
    }

    req.headers:upsert(":method", "POST")
    req.headers:append("Content-Type", req_headers["Content-Type"])
    req.headers:append("Cookie", req_headers["Cookie"])
    req:set_body(body)
    -- req.follow_redirects = false

    -- Perform the request
    local headers, stream = req:go(10) -- 10 seconds timeout
    if not headers then
        print("Request failed")
        return
    end

    -- Read the response
    local response_body, err2 = stream:get_body_as_string()
    if not response_body then
        print("Failed to get body:", err2)
        return
    end

    print("Response status from td.bespokeeducation.fr:\n", headers:get(":status"))
end

vim.api.nvim_create_user_command('PostLesson', PostLesson, {})
