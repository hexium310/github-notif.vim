let s:default_interval = 60
let s:texts = []

function! github_notif#get(...) abort
  let options = get(a:, 1, {})
  let poll_interval = get(s:, 'poll_interval', 0)
  let interval_difference = poll_interval - get(g:, 'github_notif_interval', s:default_interval)
  call wait(max([interval_difference, poll_interval]), { -> v:false })

  let modified_since = get(options, 'force', v:false) ? '' : 'If-Modified-Since: ' . get(s:, 'last_getting_time', '')
  let command = s:Curl('notifications', { 'headers': [modified_since] })
  let s:notifications_get_job = jobstart(command, {
    \   'on_stdout': function('s:OnStdout'),
    \   'on_stderr': function('s:OnStderr'),
    \   'stdout_buffered': v:true,
    \ })
endfunction

function! github_notif#run() abort
  if exists('s:timer') && empty(timer_info(s:timer))
    return
  endif

  let poll_interval = get(g:, 'github_notif_interval', s:default_interval)
  if get(g:, 'github_notif_fetch_instantly', 0)
    call github_notif#get()
  endif
  let s:timer_id = timer_start(poll_interval * 1000, { timer -> github_notif#get() }, { 'repeat': -1 })
endfunction

function! github_notif#open() abort
  call s:OpenBuffer()
endfunction

function! github_notif#stop() abort
  if !exists('s:timer_id')
    return
  endif

  call timer_stop(s:timer_id)
  unlet s:timer_id
endfunction

function! s:Curl(endpoint, ...) abort
  let options = get(a:, 1, {})
  if type(options) != v:t_dict
    return
  endif

  let base_url = get(g:, 'github_notif_base_url', 'https://api.github.com/')
  let url = base_url . a:endpoint
  let header = flatten(map(s:BuildHeader(get(options, 'headers', [])), '["-H", v:val]'))

  let command = ['curl', '-s', '-i'] + header + [url]
  return command
endfunction

function! s:BuildHeader(...) abort
  let extended_headers = get(a:, 1, [])
  let token = get(g:, 'github_notif_token', $GITHUB_TOKEN)
  let headers = [
    \   'Authorization: token ' . token,
    \   'Accept: application/vnd.github.v3+json',
    \ ] + extended_headers

  return headers
endfunction

function! s:OnStdout(jobid, data, event) abort
  let response = split(join(a:data), '\r \r')
  let raw_header = response[0]
  let raw_body = response[1:]
  let headers = {}

  for value in split(raw_header, '\r')
    let line = trim(value)
    if line =~# '^HTTP.\+'
      let statuses = split(line)
      let s:status_code = statuses[1]
      continue
    endif

    let header_name_regex = '\(.\{-}\): '
    let header_name = matchlist(line, header_name_regex)[1]
    let headers[header_name] = substitute(line, header_name_regex, '', '')
  endfor

  let s:last_getting_time = get(headers, 'Date', '')
  let poll_interval = str2nr(get(headers, 'X-Poll-Interval', '60'))
  let s:poll_interval = max([get(g:, 'github_notif_interval', s:default_interval), poll_interval])

  if s:status_code == '304'
    return
  endif

  try
    let json = json_decode(join(raw_body))
  catch
    return
  endtry

  if type(json) == v:t_dict && has_key(json, 'message')
    echo json.message
    return
  endif

  let [bufnr, winnr] = s:CreateBuffer()
  call s:SetNotificationsText(bufnr, json)

  if winnr < 0
    let g:github_notif_unread = 1
  endif
endfunction

function! s:OnStderr(job_id, data, event) dict
 return
endfunction

function! s:CreateBuffer() abort
  let buffers = getbufinfo(get(s:, 'notif_buffer', -1))
  if empty(buffers)
    let bufnr = nvim_create_buf(v:false, v:true)
  else
    let buffer = buffers[0]
    let bufnr = buffer.bufnr
    let winnr = get(buffer.windows, 0, -1)
  endif
  call s:SetBufferOption(bufnr)

  let s:notif_buffer = bufnr
  return [bufnr, get(l:, 'winnr', -1)]
endfunction

function s:SetBufferOption(bufnr) abort
  call nvim_buf_set_option(a:bufnr, 'filetype', 'github_notif')
  call nvim_buf_set_option(a:bufnr, 'buftype', 'nowrite')
  call nvim_buf_set_option(a:bufnr, 'bufhidden', 'delete')
  call nvim_buf_set_option(a:bufnr, 'swapfile', v:false)
  call nvim_buf_set_name(a:bufnr, 'github-notif')
endfunction

function! s:OpenBuffer() abort
  let [bufnr, winnr] = s:CreateBuffer()

  call nvim_buf_set_lines(bufnr, 0, -1, v:true, flatten(copy(s:texts)))

  execute('sbuffer ' . bufnr)
  let g:github_notif_unread = 0
endfunction

function! s:SetNotificationsText(bufnr, data) abort
  if type(a:data) != v:t_list
    return
  endif

  let texts = []
  for datum in a:data
    let full_name = datum.repository.full_name
    let reason = datum.reason
    let unread = datum.unread
    let title = datum.subject.title
    let type = datum.subject.type
    let url = datum.subject.url
    let url = substitute(url, '//api.', '//', '')
    let url = substitute(url, '/repos/', '/', '')
    let url = substitute(url, '/pulls/', '/pull/', '')

    let text = [
      \   printf("● %s  %s  %s  %s", full_name, title, reason, type),
      \   printf("    %s", url),
      \ ]
    let texts += [text]
  endfor

  let s:texts = s:Uniq(texts + s:texts)

  call nvim_buf_set_lines(a:bufnr, 0, -1, v:true, flatten(copy(s:texts)))
endfunction

function! s:Uniq(list) abort
  let list = []
  for item in a:list
    if match(list, escape(item[0], '*.^$')) < 0
      call add(list, item)
    endif
  endfor

  return list
endfunction
