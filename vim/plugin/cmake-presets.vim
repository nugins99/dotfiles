" ============================================================================
" cmake-presets.vim
" Simple Vim plugin for CMake preset integration with :make
" Joe Davidson + ChatGPT GPT-5
" ============================================================================

if exists('g:loaded_cmake_presets')
  finish
endif
let g:loaded_cmake_presets = 1

let g:cmake_active_preset = ''

function! s:OnStdout(job_id, data) abort
    echom "Stdout: " . a:data
    call add(s:build_output, a:data)
endfunction

function! s:OnStderr(job_id, data) abort
    echom "Stderr: " . a:data
    " Treat stderr the same way
    call add(s:build_output, string(a:data))
endfunction

function! s:OnExit(job_id, exit_status) abort
    " Parse errors using &errorformat
    call setqflist([], 'r', {
        \ 'title': 'CMake Configure',
        \ 'lines': s:build_output,
        \ 'efm': &errorformat
        \ })

    " Open quickfix if any errors/warnings
    if a:exit_status != 0
        copen
    else
        echom "Configured :make for preset " . g:cmake_active_preset
    endif

    " Empty collected output for next run
    let s:build_output = []
endfunction

function! s:StartJob(cmd, root) abort
    let s:build_output = []
    echom "Starting Job: "
    echom a:cmd
    echom "Root: " . a:root
    call job_start(a:cmd, {
        \ 'out_cb': function('s:OnStdout'),
        \ 'err_cb': function('s:OnStderr'),
        \ 'exit_cb':   function('s:OnExit'),
        \ 'cwd': a:root
        \ })
endfunction


" ----------------------------------------------------------------------------
" Utility: run systemlist and trim whitespace
function! s:systemlist_trim(cmd) abort
  return map(systemlist(a:cmd), 'trim(v:val)')
endfunction

" ----------------------------------------------------------------------------
" Find the top-level directory containing CMakeLists.txt
function! s:find_cmake_root(start_dir) abort
  let l:dir = a:start_dir
  while !empty(l:dir)
    if filereadable(l:dir . '/CMakePresets.json') || filereadable(l:dir . '/CMakeUserPresets.json')
      return l:dir
    endif
    let l:parent = fnamemodify(l:dir, ':h')
    if l:parent ==# l:dir
      break
    endif
    let l:dir = l:parent
  endwhile
  return ''
endfunction

" ----------------------------------------------------------------------------
" Save / load preset from .vim/cmake-preselect under project root
function! s:save_preset_to_file(preset) abort
  let l:root = s:find_cmake_root(getcwd())
  if empty(l:root)
    echoerr "Could not find CMakeLists.txt root!"
    return
  endif
  let l:vimdir = l:root . '/.vim'
  if !isdirectory(l:vimdir)
    call mkdir(l:vimdir, 'p')
  endif
  let l:file = l:vimdir . '/cmake-preselect'
  call writefile([a:preset], l:file)
endfunction

function! s:load_preset_from_file() abort
  let l:root = s:find_cmake_root(getcwd())
  if empty(l:root)
    return ''
  endif
  let l:file = l:root . '/.vim/cmake-preselect'
  if filereadable(l:file)
    let l:lines = readfile(l:file)
    if !empty(l:lines)
      return l:lines[0]
    endif
  endif
  return ''
endfunction

" ----------------------------------------------------------------------------
" Get CMake configure presets
function! s:get_presets() abort
  let l:root=s:find_cmake_root(getcwd())
  let l:prevcwd=chdir(l:root)
  if filereadable('CMakePresets.json')
    let l:presets = s:systemlist_trim('cmake --list-presets=configure')
  elseif filereadable('CMakeUserPresets.json')
    let l:presets = s:systemlist_trim('cmake --list-presets=configure')
  else
    echoerr "No CMakePresets.json or CMakeUserPresets.json found!"
    echoerr "Looked in: " . l:root
    call chdir(l:prevcwd)
    return []
  endif

  " Filter only lines starting with a quote (actual preset entries)
  let l:presets = filter(presets, 'v:val =~# "^[[:space:]]*\\\""')
  call chdir(l:prevcwd)
  return l:presets
endfunction

" ----------------------------------------------------------------------------
" Extract buildDir from CMakePresets.json for the given preset
function! s:get_build_dir(preset) abort
  let l:root=s:find_cmake_root(getcwd())
  let l:prevcwd=chdir(l:root)
  if !filereadable('CMakePresets.json') and !filereadable('CMakeUserPresets.txt')
    return ''
  endif
  call chdir(l:prevcwd)
  let lines = readfile('CMakePresets.json')
  let json = join(lines, "\n")
  let pat = '\v"name"\s*:\s*"' . escape(a:preset, '"') . '".{-}"buildDir"\s*:\s*"([^"]+)"'
  return matchstr(json, pat, 1)
endfunction

" ----------------------------------------------------------------------------
" Configure the project for the selected preset and set :make integration
function! s:configure_project() abort
  if empty(g:cmake_active_preset)
    echoerr "No preset selected!"
    return
  endif
  echom "Configuring with preset " . g:cmake_active_preset . "..."
  let l:root=s:find_cmake_root(getcwd())
  let l:cmd = ['cmake', '--preset=' . g:cmake_active_preset]
  call s:StartJob(l:cmd, l:root)
  
  " Integrate with :make
  let &makeprg = 'cd ' . l:root . ';' . 'cmake --build ' . 
        \ ' --preset=' . g:cmake_active_preset . ' --parallel'
endfunction

" ----------------------------------------------------------------------------
" Select preset interactively and persist choice
function! s:select_preset() abort
  let presets = s:get_presets()
  if empty(presets)
    echo "No presets found."
    return
  endif

  let names = filter(map(copy(presets),
        \ {_, v -> matchstr(v, '\v"\s*\zs[^"]+\ze')}), 'v:val !=# ""')

  " Build numbered menu
  let numbered = ['Select a CMake preset:']
  for i in range(len(names))
    call add(numbered, printf('%2d. %s', i + 1, names[i]))
  endfor

  let choice = inputlist(numbered)
  if choice <= 0 || choice > len(names)
    echo "Preset selection cancelled."
    return
  endif

  let g:cmake_active_preset = names[choice - 1]
  call s:save_preset_to_file(g:cmake_active_preset)
  silent call s:configure_project()
endfunction

" ----------------------------------------------------------------------------
" Automatically load saved preset on startup
function! s:auto_load_preset() abort
  let l:preset = s:load_preset_from_file()
  if !empty(l:preset)
    let g:cmake_active_preset = l:preset
    call s:configure_project()
  endif
endfunction

augroup cmake_presets_autoload
  autocmd!
  autocmd VimEnter * call s:auto_load_preset()
augroup END


function s:update_ctags() abort
    let l:root = s:find_cmake_root(getcwd())
    if empty(l:root)
        echoerr "Could not find CMakeLists.txt root!"
        return
    endif
    let l:tagfile = l:root . '/.vim/tags'
    let l:cmd = 'ctags -R -f ' . l:tagfile . ' --languages=C,C++ --exclude=.git --exclude=build ' . l:root
    echom "Updating ctags..."
    echom l:cmd
    call system(l:cmd)

    let l:tagfile = l:root . '/.vim/tags'
    if empty(&tags)
      let &tags = l:tagfile
    else
      let &tags = &tags . ',' . l:tagfile
    endif

    echom "ctags updated."
endfunction


" ----------------------------------------------------------------------------
" User commands
command! CMakeSelectPreset call s:select_preset()
command! CMakeConfigure call s:configure_project()
command! UpdateCtags call s:update_ctags()
" ============================================================================

