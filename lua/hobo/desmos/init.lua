local http_request = require("http.request")
local http_util = require("http.util")
local cjson = require("cjson")
local os = require("os")
local random = require("math").random
local url = require("socket.url") -- For URL encoding

-- Load cookies from environment variables
local sid = os.getenv("DESMOS_SID")
local awsalb = os.getenv("DESMOS_AWSALB")
local awsalbcors = os.getenv("DESMOS_AWSALBCORS")

-- Function to generate a random 10-character hash
local function generate_random_hash()
    local chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
    local hash = ''
    for i = 1, 10 do
        local rand_index = random(#chars)
        hash = hash .. chars:sub(rand_index, rand_index)
    end
    return hash
end

-- Function to post desmos.json to Desmos
local function PostToDesmos(json_file_path)
    -- Read the JSON file
    local file = io.open(json_file_path, "r")
    if not file then
        print("Error: Could not open file " .. json_file_path)
        return
    end
    local calc_state = file:read("*a")
    file:close()

    -- Generate a new random hash
    local new_hash = generate_random_hash()
    print("New hash: " .. new_hash)

    -- URL-encode the calc_state
    local encoded_calc_state = url.escape(calc_state)



    -- -- Define form data
    -- local form_data = http_util.dict_to_query {
    --     thumb_data = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wcAAgAB/hed4wAAAABJRU5ErkJggg==",
    --     graph_hash = new_hash,
    --     my_graphs = "true",
    --     is_update = "false",
    --     title = new_hash,
    --     calc_state = encoded_calc_state
    -- }


    -- Prepare the HTTP request
    -- local cookie = string.format("sid=%s; AWSALB=%s; AWSALBCORS=%s", sid, awsalb, awsalbcors)
    local body = string.format(
        "thumb_data=data%%3Aimage%%2Fpng%%3Bbase64%%2CiVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/wcAAgAB/hed4wAAAABJRU5ErkJggg%%3D%%3D&graph_hash=%s&my_graphs=true&is_update=false&title=" ..
        new_hash .. "&calc_state=%s&lang=en&product=graphing",
        new_hash,
        encoded_calc_state
    )

    local cookie_header = "sid=" ..
        sid .. "; AWSALB=" .. awsalb .. "; AWSALBCORS=" .. awsalbcors

    local req_headers = {
        ["Content-Type"] = "application/x-www-form-urlencoded; charset=UTF-8",
        ["Cookie"] = cookie_header,
    }

    local req = http_request.new_from_uri("https://www.desmos.com/api/v1/calculator/save")
    req.headers:upsert(":method", "POST")
    -- req.headers:append("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
    req.headers:append("content-type", req_headers["Content-Type"])
    req.headers:append("cookie", req_headers["Cookie"])
    -- req:set_body(form_data)
    req:set_body(body)

    -- Perform the HTTP request with a longer timeout
    local headers, stream = req:go(5) -- Set a timeout of 30 seconds

    print(headers)
    print(stream)

    -- Check for response
    if not headers then
        print("Error: Failed to make request")
        return
    end

    local response_body = stream:get_body_as_string()
    local success, response_data = pcall(cjson.decode, response_body)

    if not success then
        print("Error: Failed to decode response JSON")
        print(response_body) -- Print the raw response for debugging
        return
    end

    -- Print the new hash
    if response_data and response_data.hash then
        print("New Desmos hash: " .. response_data.hash)
    else
        print("Error: Unexpected response from Desmos")
    end
end

-- Register the command in Neovim to accept file arguments only
vim.api.nvim_create_user_command('PostToDesmos', function(args)
    if vim.fn.filereadable(args.args) == 1 then
        PostToDesmos(args.args)
    else
        print("Error: The specified file does not exist or is not readable.")
    end
end, {
    nargs = 1,
    complete = 'file', -- Enables file completion for the command
})
