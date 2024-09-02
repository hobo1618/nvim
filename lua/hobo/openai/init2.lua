-- ConvertQuestion.lua
local http = require("http.request")
local cjson = require("cjson.safe")
local api_key = os.getenv("OPENAI_API_KEY")

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

-- Function to create messages for OpenAI API
local function create_messages(file_content, system_prompt, attachments)
    local messages = {}

    -- Include system prompt if available
    if system_prompt then
        table.insert(messages, { role = "system", content = system_prompt })
    end

    -- Add user message
    table.insert(messages, { role = "user", content = file_content })

    -- Add attachments as additional user messages (if any)
    if attachments then
        for _, attachment in ipairs(attachments) do
            table.insert(messages, { role = "user", content = attachment })
        end
    end

    return messages
end

-- Function to send a message to ChatGPT with optional system prompt
local function MessageChatGPT(args)
    -- Attempt to read the system prompt from 'system.md' at the root of the current directory
    local system_prompt_path = "system.md"
    local system_prompt = read_file(system_prompt_path)

    -- Read the content from the provided file path (user input)
    local file_path = args.args
    local file_content = read_file(file_path)
    if not file_content then
        print("Error: Unable to read file content.")
        return
    end

    -- Prepare the messages array for the API request
    local messages = create_messages(file_content, system_prompt, nil)

    -- Prepare the request body with the messages
    local body = cjson.encode({
        model = "gpt-4o",
        messages = messages
    })

    -- Send the request
    local request = http.new_from_uri(url)
    request.headers:upsert(":method", "POST")
    for k, v in pairs(headers) do
        request.headers:upsert(k, v)
    end
    request:set_body(body)

    -- Receive the response
    local response_headers, stream = request:go()

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

-- Function to send a message to ChatGPT with optional attachments
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

    -- Read the content of each attachment file
    local attachments = {}
    for _, attachment_path in ipairs(attachment_paths) do
        local attachment_content = read_file(attachment_path)
        if attachment_content then
            table.insert(attachments, attachment_content)
        else
            print("Warning: Unable to read attachment at path:", attachment_path)
        end
    end

    -- Prepare the messages array for the API request
    local messages = create_messages(file_content, system_prompt, attachments)

    -- Prepare the request body with the messages
    local body = cjson.encode({
        model = "gpt-4o",
        messages = messages
    })

    -- Send the request
    local request = http.new_from_uri(url)
    request.headers:upsert(":method", "POST")
    for k, v in pairs(headers) do
        request.headers:upsert(k, v)
    end
    request:set_body(body)

    -- Receive the response
    local response_headers, stream = request:go()

    if not response_headers then
        print("Error sending request:", stream)
        return
    end

    local response_body, err = stream:get_body_as_string()
    if not response_body then
        print("Error receiving response:", err)
        return
    end

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

-- Create the Vim command to call the MessageChatGPT function with a file path and enable file path completion
vim.api.nvim_create_user_command('MessageChatGPT', MessageChatGPT, {
    nargs = 1,            -- Requires exactly one argument (the file path)
    complete = 'file'     -- Enable file path completion
})

-- Create the Vim command to call the MessageChatGPTWithAttachments function with multiple file paths and enable file path completion
vim.api.nvim_create_user_command('MessageChatGPTWithAttachments', MessageChatGPTWithAttachments, {
    nargs = '+',            -- Requires at least one argument (the main file path), with optional additional attachment paths
    complete = 'file'       -- Enable file path completion
})

