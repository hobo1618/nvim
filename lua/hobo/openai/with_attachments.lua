local http = require("http.request")
local cjson = require("cjson.safe")
local api_key = os.getenv("OPENAI_API_KEY")
local mime = require("mime") -- LuaSocket library to handle base64 encoding

-- Check if the API key is available
if not api_key then
    print("Error: OPENAI_API_KEY environment variable is not set.")
    return
end

-- Create a request object
local url = "https://api.openai.com/v1/chat/completions"
local headers = {
    ["content-type"] = "application/json",
    ["authorization"] = "Bearer " .. api_key
}

-- Function to encode content to base64
local function encode_base64(content)
    return mime.b64(content)
end

-- Function to read the content of a file
local function read_file(file_path)
    local file = io.open(file_path, "r")
    if not file then
        return nil
    end
    local content = file:read("*a")
    file:close()
    return content
end

-- Function to write the content to a file
local function write_to_file(file_path, content)
    local file = io.open(file_path, "w")
    if not file then
        print("Error: Unable to open file for writing at path:", file_path)
        return false
    end
    file:write(content)
    file:close()
    return true
end

-- Function to send a message to ChatGPT with optional attachments (including images)
local function MessageChatGPTWithAttachments(args)
    -- Attempt to read the system prompt from 'system.md' at the root of the current directory
    local system_prompt_path = "system.md"
    local system_prompt = read_file(system_prompt_path)

    -- Split arguments into main file path and attachment paths
    local file_path = args.fargs[1]
    local attachment_paths = { unpack(args.fargs, 2) } -- Remaining arguments are attachment paths

    -- Read the content from the provided file path (user input)
    local file_content = read_file(file_path)
    if not file_content then
        print("Error: Unable to read main file content.")
        return
    end

    local debug_url =
    "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"

    -- Read and encode each attachment file
    local attachments = {}
    for _, attachment_path in ipairs(attachment_paths) do
        local attachment_content = read_file(attachment_path)
        if attachment_content then
            -- Encode attachment as base64 and format as data URL
            local base64_content = encode_base64(attachment_content)
            local data_url = "data:image/jpeg;base64," .. base64_content -- assuming image/jpeg; adjust as needed
            write_to_file("data_url", data_url)
            table.insert(attachments, {
                type = "image_url",
                -- image_url = { url = data_url }
                image_url = { url = debug_url }
            })
        else
            print("Warning: Unable to read attachment at path:", attachment_path)
        end
    end

    -- Prepare the messages array for the API request
    local messages = {}

    -- Include system prompt if available
    if system_prompt then
        table.insert(messages, { role = "system", content = system_prompt })
    end

    -- Add user message with possible text and attachments
    local user_message = {
        role = "user",
        content = {
            {
                type = "text",
                text = file_content
            }
        }
    }

    -- Include attachments as part of the user message content
    for _, attachment in ipairs(attachments) do
        table.insert(user_message.content, attachment)
    end

    table.insert(messages, user_message)

    -- Prepare the request body with the messages
    local body = cjson.encode({
        model = "gpt-4o-mini",
        messages = messages
    })

    -- Send the request
    local request = http.new_from_uri(url)
    request.headers:upsert(":method", "POST")
    for k, v in pairs(headers) do
        request.headers:upsert(k, v)
    end
    write_to_file("body.json", body)

    request:set_body(body)


    -- Receive the response
    local response_headers, stream = request:go(30)

    if not response_headers then
        print("Error sending request:", stream)
        return
    end

    local response_body, err = stream:get_body_as_string()
    if not response_body then
        print("Error receiving response:", err)
        return
    end

    -- Print raw response body for debugging
    print("Raw response body:", response_body)

    -- Decode the response
    local response, decode_err = cjson.decode(response_body)
    if not response then
        print("Error decoding JSON:", decode_err)
        return
    end

    -- Check for the expected response structure
    if response and response.choices then
        local chatgpt_response = response.choices[1].message.content
        print("ChatGPT's Response: " .. chatgpt_response)

        -- Write the response to output.md
        if write_to_file("output.md", chatgpt_response) then
            print("Response written to output.md")
        else
            print("Error writing response to output.md")
        end

        return chatgpt_response
    else
        print("Unexpected response format:", cjson.encode(response))
        return "Error in response"
    end
end

-- Create the Vim command to call the MessageChatGPTWithAttachments function with multiple file paths and enable file path completion
vim.api.nvim_create_user_command('MessageChatGPTWithAttachments', MessageChatGPTWithAttachments, {
    nargs = '+',      -- Requires at least one argument (the main file path), with optional additional attachment paths
    complete = 'file' -- Enable file path completion
})
