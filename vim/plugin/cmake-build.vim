" ========== CMake async build for Vim 8.0 ==========
let s:build_output = []

function! s:OnBuildStdout(job_id, data) abort
    echom "Stdout: " . a:data
    call add(s:build_output, a:data)
endfunction

function! s:OnBuildStderr(job_id, data) abort
        
    echom "Stderr: " . a:data
    " Treat stderr the same way
    call add(s:build_output, string(a:data))
endfunction

function! s:OnBuildExit(job_id, exit_status) abort
    " Parse errors using &errorformat
    call setqflist([], 'r', {
        \ 'title': 'CMake Build',
        \ 'lines': s:build_output,
        \ 'efm': &errorformat
        \ })

    " Empty collected output for next run
    let s:build_output = []

    " Open quickfix if any errors/warnings
    copen
endfunction


function! s:CMakeStartBuild() abort
    let cmd = ['cmake', '--build', '--preset', g:cmake_active_preset,  '-j12']

    let s:build_output = []

    call job_start(cmd, {
        \ 'out_cb': function('s:OnBuildStdout'),
        \ 'err_cb': function('s:OnBuildStderr'),
        \ 'exit_cb':   function('s:OnBuildExit'),
        \ })
endfunction

function! s:CMakeStartTest() abort
    let cmd = ['cmake', '--build', '--preset', g:cmake_active_preset,  '-j12', '--target', 'test']

    let s:build_output = []

    call job_start(cmd, {
        \ 'out_cb': function('s:OnBuildStdout'),
        \ 'err_cb': function('s:OnBuildStderr'),
        \ 'exit_cb':   function('s:OnBuildExit'),
        \ })
endfunction


command! CMakeBuild call s:CMakeStartBuild()
command! CMakeTest call s:CMakeStartTest()
