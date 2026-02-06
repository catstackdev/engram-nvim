-- Async job control using vim.loop (libuv)
local M = {}

-- Execute async job with callback
-- @param cmd string: command to execute
-- @param args table: command arguments
-- @param opts table: options { on_stdout, on_stderr, on_exit, cwd }
function M.run(cmd, args, opts)
  opts = opts or {}

  local stdout = vim.loop.new_pipe(false)
  local stderr = vim.loop.new_pipe(false)
  local handle, pid

  local stdout_data = ''
  local stderr_data = ''

  handle, pid = vim.loop.spawn(
    cmd,
    {
      args = args,
      stdio = { nil, stdout, stderr },
      cwd = opts.cwd,
    },
    vim.schedule_wrap(function(code, signal)
      stdout:close()
      stderr:close()
      if handle and not handle:is_closing() then
        handle:close()
      end

      if opts.on_exit then
        opts.on_exit(code, signal, stdout_data, stderr_data)
      end
    end)
  )

  if not handle then
    vim.notify('engram.nvim: Failed to spawn process: ' .. cmd, vim.log.levels.ERROR)
    return nil
  end

  vim.loop.read_start(
    stdout,
    vim.schedule_wrap(function(err, data)
      if err then
        vim.notify('engram.nvim: stdout error: ' .. err, vim.log.levels.ERROR)
      end
      if data then
        stdout_data = stdout_data .. data
        if opts.on_stdout then
          opts.on_stdout(data)
        end
      end
    end)
  )

  vim.loop.read_start(
    stderr,
    vim.schedule_wrap(function(err, data)
      if err then
        vim.notify('engram.nvim: stderr error: ' .. err, vim.log.levels.ERROR)
      end
      if data then
        stderr_data = stderr_data .. data
        if opts.on_stderr then
          opts.on_stderr(data)
        end
      end
    end)
  )

  return handle, pid
end

-- Execute command and return output (synchronous wrapper)
function M.run_sync(cmd, args, timeout)
  timeout = timeout or 5000
  local done = false
  local result = { code = -1, stdout = '', stderr = '' }

  M.run(cmd, args, {
    on_exit = function(code, signal, stdout, stderr)
      result = { code = code, signal = signal, stdout = stdout, stderr = stderr }
      done = true
    end,
  })

  -- Wait for completion with timeout
  local start = vim.loop.now()
  while not done and (vim.loop.now() - start) < timeout do
    vim.wait(10)
  end

  if not done then
    return nil, 'timeout'
  end

  return result
end

-- HTTP request using curl (async)
function M.http_request(method, url, opts, callback)
  opts = opts or {}
  local args = {
    '-s', -- silent
    '-X',
    method,
    url,
  }

  -- Add headers
  if opts.headers then
    for key, value in pairs(opts.headers) do
      table.insert(args, '-H')
      table.insert(args, key .. ': ' .. value)
    end
  end

  -- Add body
  if opts.body then
    table.insert(args, '-H')
    table.insert(args, 'Content-Type: application/json')
    table.insert(args, '-d')
    table.insert(args, opts.body)
  end

  -- Add timeout
  if opts.timeout then
    table.insert(args, '--max-time')
    table.insert(args, tostring(math.floor(opts.timeout / 1000)))
  end

  M.run('curl', args, {
    on_exit = function(code, signal, stdout, stderr)
      if code ~= 0 then
        callback(stderr or 'HTTP request failed', nil)
        return
      end

      -- Try to parse JSON
      local ok, json = pcall(vim.json.decode, stdout)
      if not ok then
        callback('Failed to parse JSON: ' .. stdout, nil)
        return
      end

      callback(nil, json)
    end,
  })
end

return M
