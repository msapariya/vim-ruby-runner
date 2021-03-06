if exists('g:loaded_RubyRunner')
  finish
endif
let g:loaded_RubyRunner = 1

if has('gui_running')
  if has("unix")
    let s:uname = system("uname")
    if s:uname == "Darwin"
      " Mac key short cuts
      let g:RubyRunner_key = '<D-r>'
      let g:RubyRunner_keep_focus_key = '<D-R>'
    else "Linux key shortcuts
      exec 'set winaltkeys=no'
      let g:RubyRunner_key = '<M-r>'
      let g:RubyRunner_keep_focus_key = '<M-R>'
    endif
  else "Windows key shortcuts
    exec 'set winaltkeys=no'
    let g:RubyRunner_key = '<M-r>'
    let g:RubyRunner_keep_focus_key = '<M-R>'
  endif
else
  let g:RubyRunner_key = '<Leader>r'
  let g:RubyRunner_keep_focus_key = '<Leader>R'
end

if (!exists("g:RubyRunner_open_below"))
  let g:RubyRunner_open_below = 0
endif

if has("unix")
  let s:output_file = "/tmp/ruby_runner_output.txt"
else
  let s:output_file = "c:\\temp" . "\\ruby_runner_output.txt"
endif

function! s:RunRuby()

  cd %:p:h  " Use file dir as pwd

  " Prepend 'STDOUT.sync=true' to the script so STDOUT and STDERR appear in the correct order.
  " Also fix load path for require/require_relative.
  exec 'silent w ! ruby -pe ''p "STDOUT.sync=true; $:.unshift Dir.pwd; Kernel.class_eval { alias_method :require_relative, :require };" if $.==1 '' | ruby >' s:output_file '2>&1'

  cd -  " Back to old dir

  " Reuse or create new buffer. Based on code in Decho
  " http://www.vim.org/scripts/script.php?script_id=120
  if exists('t:rrbufnr') && bufwinnr(t:rrbufnr) > 0
    exec 'keepjumps' bufwinnr(t:rrbufnr) 'wincmd W'
    exec 'normal ggdG'
  else
    exec 'keepjumps silent!' (g:RubyRunner_open_below == 1 ? 'below' : '') 'new'
    if (exists("g:RubyRunner_window_size"))
      exec 'resize' g:RubyRunner_window_size
    endif
    let t:rrbufnr=bufnr('%')
  end

  exec 'read' s:output_file
  " Fix extraneous leading blank line.
  1d
  " Close on q.
  map <buffer> q ZZ
  " Set a filetype so we can define more mappings elsewhere.
  set ft=ruby-runner
  " Make it a scratch (temporary) buffer.
  setlocal buftype=nofile bufhidden=wipe noswapfile

endfunction


command! RunRuby call <SID>RunRuby()

if !hasmapto('RunRuby') && has('autocmd')

  exec 'au FileType ruby map  <buffer>' g:RubyRunner_key ':RunRuby<CR>'
  exec 'au FileType ruby map  <buffer>' g:RubyRunner_keep_focus_key ':RunRuby<CR> <C-w>w'

  " Since the GUI Vim mapping uses <D>, it makes sense to be able to run it
  " even in insert mode. Not so with <leader> mappings.
  if has('gui_running')
    exec 'au FileType ruby imap <buffer>' g:RubyRunner_key '<Esc>:RunRuby<CR>'
    exec 'au FileType ruby imap <buffer>' g:RubyRunner_keep_focus_key '<Esc>:RunRuby<CR> <C-w>wa'
  endif

  " Close output buffer
  exec 'au FileType ruby-runner map <buffer>' g:RubyRunner_key 'ZZ'

  "Map RunRuby globally
  if exists("g:RunRuby_map_globally")
    exec 'map' g:RubyRunner_key ':RunRuby<CR>'
    exec 'map' g:RubyRunner_keep_focus_key ':RunRuby<CR> <C-w>w'
  endif
endif
