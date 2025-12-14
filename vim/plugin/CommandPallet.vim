" show_run_commands.vim
" Vim 8.2 plugin: Show and Run Commands (VS Code–like Command Palette)
" Popup-based UI with fuzzy matching
"
" Requirements:
" - Vim 8.2 with popup support (+popupwin, Vim 8.1.1517+)
"
" =============================
" User configuration
" =============================
" let g:show_run_commands_list = [
"   {'name': 'Build project', 'cmd': 'make'},
"   {'name': 'Run tests',     'cmd': 'make test'},
"   {'name': 'Open TODO',     'cmd': 'edit TODO.md'},
" ]
"
" let g:show_run_commands_width  = 40
" let g:show_run_commands_height = 20
" let g:show_run_commands_keymap = '<Leader>p'
"
"
let g:show_run_commands_list = [
   \{'name': 'CMake: Preset', 'cmd': 'CMakeSelectPreset'},
   \{'name': 'CMake: Configure', 'cmd': 'silent CMakeConfigure'},
   \{'name': 'CMake: Build', 'cmd': 'CMakeBuild'},
   \{'name': 'CMake: Test', 'cmd': 'CMakeTest'},
   \{'name': 'Make', 'cmd': 'make'},
   \{'name': 'Run tests',     'cmd': 'make test'},
   \{'name': 'Open TODO',     'cmd': 'edit ~/TODO.md'} ]


if exists('g:loaded_show_run_commands')
  finish
endif
let g:loaded_show_run_commands = 1

if !exists('g:show_run_commands_list')
  let g:show_run_commands_list = []
endif
if !exists('g:show_run_commands_width')
  let g:show_run_commands_width = 40
endif
if !exists('g:show_run_commands_height')
  let g:show_run_commands_height = 20
endif
if !exists('g:show_run_commands_keymap')
  let g:show_run_commands_keymap = '<Leader>p'
endif

" =============================
" Internal state
" =============================
let s:popup_id = -1
let s:filter   = ''
let s:matches  = []
let s:cursor   = 0

" =============================
" Fuzzy match + score
" =============================
function! s:fuzzy_score(text, pattern) abort
  if empty(a:pattern)
    return 0
  endif
  let l:t = tolower(a:text)
  let l:p = tolower(a:pattern)
  let l:score = 0
  let l:ti = 0
  for c in split(l:p, '\zs')
    let l:pos = stridx(l:t, c, l:ti)
    if l:pos < 0
      return -1
    endif
    let l:score += 10 - (l:pos - l:ti)
    let l:ti = l:pos + 1
  endfor
  return l:score
endfunction

function! s:compute_matches() abort
  let l:out = []
  for item in g:show_run_commands_list
    let l:name = get(item, 'name', '')
    let l:cmd  = get(item, 'cmd', '')
    let l:s1 = s:fuzzy_score(l:name, s:filter)
    let l:s2 = s:fuzzy_score(l:cmd,  s:filter)
    let l:score = max([l:s1, l:s2])
    if l:score >= 0
      call add(l:out, {'item': item, 'score': l:score})
    endif
  endfor
  call sort(l:out, {a,b -> b.score - a.score})
  let s:matches = map(l:out, 'v:val.item')
endfunction

" =============================
" Rendering
" =============================
function! s:render() abort
  call s:compute_matches()
  let l:lines = []
  call add(l:lines, '▶ ' . s:filter)
  call add(l:lines, repeat('─', g:show_run_commands_width - 2))

  if empty(s:matches)
    call add(l:lines, '  (no matches)')
  else
    for i in range(0, min([len(s:matches)-1, g:show_run_commands_height-4]))
      let l:prefix = (i == s:cursor ? '❯ ' : '  ')
      let l:name = get(s:matches[i], 'name', '')
      call add(l:lines, l:prefix . l:name)
    endfor
  endif

  call popup_settext(s:popup_id, l:lines)
endfunction

" =============================
" Input handling
" =============================
function! s:on_key(id, key) abort
  if a:key == "\<Esc>" || a:key == 'q'
    call popup_close(s:popup_id)
    let s:popup_id = -1
    return 1
  elseif a:key == "\<CR>"
    if s:cursor < len(s:matches)
      let l:cmd = get(s:matches[s:cursor], 'cmd', '')
      call popup_close(s:popup_id)
      let s:popup_id = -1
      execute l:cmd
    endif
    return 1
  elseif a:key == "\<Down>" || a:key == "\<C-n>"
    let s:cursor = min([s:cursor + 1, len(s:matches)-1])
  elseif a:key == "\<Up>" || a:key == "\<C-p>"
    let s:cursor = max([s:cursor - 1, 0])
  elseif a:key == "\<BS>"
    let s:filter = s:filter[:-2]
    let s:cursor = 0
  elseif strlen(a:key) == 1
    let s:filter .= a:key
    let s:cursor = 0
  endif

  call s:render()
  return 1
endfunction

" =============================
" Open palette
" =============================
function! s:open_palette() abort
  if s:popup_id != -1
    return
  endif

  let s:filter = ''
  let s:cursor = 0

  let s:popup_id = popup_create([], {
        \ 'line': 'cursor+1',
        \ 'col': 'cursor',
        \ 'minwidth': g:show_run_commands_width,
        \ 'minheight': g:show_run_commands_height,
        \ 'border': ['-'],
        \ 'padding': [0,1,0,1],
        \ 'mapping': 0,
        \ 'filter': function('s:on_key'),
        \ 'zindex': 200,
        \ })

  call s:render()
endfunction

command! ShowRunCommands call s:open_palette()

if !empty(g:show_run_commands_keymap)
  execute 'nnoremap <silent> ' . g:show_run_commands_keymap . ' :ShowRunCommands<CR>'
endif

highlight Pmenu ctermbg=darkblue ctermfg=yellow guibg=#2E3440
highlight PmenuSel ctermfg=yellow ctermbg=darkred guifg=yellow guibg=#BF616A
