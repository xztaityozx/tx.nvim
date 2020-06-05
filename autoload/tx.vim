"{{{
  let s:dictionary = {}
  " build command list for termopen()
  function! s:build_command(cmds, opts) abort
    return [$SHELL] + a:opts + ["-c", join(map(map(copy(a:cmds), {-> map(copy(v:val), {i, item ->item == '[[::tx_arg::]]' ? input('tx >>> ') : item})}), {-> join(v:val, ' ')}), '|')]
  endfunction

  " 
  function! tx#start(cmds, options) abort
    below new 'tx-buffer' | set filetype=Tx | set nonumber | set norelativenumber | let s:tx_bufnr = bufnr()
    
    let l:opts = exists('a:options.shellOptions') ? a:options.shellOptions : []
    let l:cmdList = s:build_command(a:cmds, l:opts)

    echom ' ' | echom 'tx:' l:cmdList[-1]

    " invoke terminal
    call termopen(l:cmdList,
          \{ 
            \"on_exit": {job_id, data ->s:onExit(job_id, data, a:options)}
          \}) | startinsert
  endfunction


  function! s:onExit(id, data, options) abort
    let l:targets=filter(getbufline(s:tx_bufnr, 1, '$'), "v:val != ''")
    sleep 100m
    
    " s:cancelでキャンセルされていたら
    if exists('s:tx_canceled') && s:tx_canceled
      echom 'tx: canceled by user'
      let s:tx_canceled = v:false
      return
    endif
    
    " terminal のバッファを削除
    execute 'bdelete!' s:tx_bufnr

    " コマンドが失敗したらキャンセル
    if a:data != 0 
      echoerr 'tx: Command failed with a non-zero exit code(' . a:data . ')'
      return
    endif

    " 開く対象のファイルが0個ならキャンセル
    if len(l:targets) == 0
      echoerr 'tx: There was no output from the command.'
      return 
    endif

    for item in map(l:targets, {->s:parse(v:val)})

      let l:vimCmd = exists('a:options.vimCmd') ? a:options.vimCmd : "edit"
      let l:cursorOpt = exists('a:options.cursor') ? a:options.cursor : "no"
      call s:split(a:options)

      if l:cursorOpt == "no" 
        execute l:vimCmd l:item.name . ':' . l:item.line
      else
        execute l:vimCmd l:item.name
        call cursor(l:item.line, (a:options.cursor == 'lc' ? l:item.column : 1))
      endif

      echom 'tx: ' . l:vimCmd . ' ' . item.name
    endfor
  endfunction

  function! s:split(options) abort
    if !exists('a:options.split')
      return
    endif

    let l:opt = a:options.split
    if l:opt =~ 'v[ertical]' 
      vertical new
    elseif l:opt =~ 'h[rizontal]'
      split
    endif
  endfunction

  function! s:parse(result) abort
    let l:split = split(a:result, ':')
    return {
          \'name': l:split[0], 
          \'line': len(l:split) >= 2 ? l:split[1] : 1, 
          \'column': len(l:split) >= 3 ? l:split[2] : 1 
          \}
  endfunction

  function! s:cancel() abort
    execute 'bdelete!' s:tx_bufnr
    let s:tx_canceled = v:true
  endfunction

  function! tx#register(name, cmds, opt) abort
    let s:dictionary[a:name]={'cmd': a:cmds, 'opt':a:opt}
  endfunction

  function! tx#call(name) abort
    if !exists('s:dictionary[a:name]')
      echoerr a:name . " is not registered"
      return
    endif

    let l:act = s:dictionary[a:name]
    call tx#start(l:act.cmd, l:act.opt)
  endfunction

  tnoremap <Plug>(tx_cancel) <c-\><c-n>:<c-u>call <SID>cancel()<CR>
"}}}
