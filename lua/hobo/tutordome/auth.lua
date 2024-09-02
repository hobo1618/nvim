local cfid = os.getenv("TD_CFID")
local cftoken = os.getenv("TD_CFTOKEN")
local jsessionid = os.getenv("TD_JSESSIONID")
local pwd = os.getenv("TD_PASSWORD")
local username = os.getenv("TD_USERNAME")

-- Import the http module
local http_request = require("http.request")
local http_cookies = require("http.cookie")

-- Function to post the text to httpbin
local function TutordomeAuth()
    local cookie_store = http_cookies.new_store()
    local cookie_header = "CFID=" .. cfid .. "; CFTOKEN=" .. cftoken .. "; JSESSIONID=" .. jsessionid
    local boundary = "----WebKitFormBoundarybUic6MdsKulhwUlW"

    local body = table.concat({
        "--" .. boundary,
        'Content-Disposition: form-data; name="user_page"',
        "",
        "/tutordome/index.cfm",
        "--" .. boundary,
        'Content-Disposition: form-data; name="username"',
        "",
        -- "whobden",
        username,
        "--" .. boundary,
        'Content-Disposition: form-data; name="password"',
        "",
        pwd,
        "--" .. boundary .. "--",
        ""
    }, "\r\n")

    -- Create the HTTP request
    local req = http_request.new_from_uri("https://td.bespokeeducation.fr/tutordome/")
    req.headers:upsert(":method", "POST")
    req.headers:append("Content-Type", "multipart/form-data; boundary=" .. boundary)
    req.headers:append("Cookie", cookie_header)
    req:set_body(body)
    req.follow_redirects = false

    -- Send the request and get the response
    local headers = assert(req:go())

    cookie_store:store_from_request(req.headers, headers, nil, "https://td.bespokeeducation.fr")

    local set_cookie = headers:get("set-cookie")
    print(set_cookie)

    local file = io.open("cookies.txt", "w")
    local success, err = cookie_store:save_to_file(file)
    if success then
        print("Cookies successfully saved to file.")
    else
        print("Failed to save cookies: ", err)
    end
    if file then
        file:close()
    end
end

vim.api.nvim_create_user_command('TutordomeAuth', TutordomeAuth, {})
