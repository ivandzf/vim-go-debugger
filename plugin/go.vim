if !exists('g:vim_go_debugger_enabled')
    let g:vim_go_debugger_enabled = 1
endif

if g:vim_go_debugger_enabled
    nnoremap <leader>r :call <sid>GoRunDebug()<CR>
endif

command! -nargs=1 GoRunDebug call GoRunDebug(<q-args>)

" source
let s:realize = 'realize'

let g:envarFileName = '.env_tmp'
let g:deleteTemporartyEnvar = 0

" list of sources
let s:sourceAvailables = [s:realize]

" check plugin when source has plugin
function! s:checkPlugin(source) 
   let err = 0
   " realize
   if a:source == s:realize 
      let err = s:checkRealizePlugin()
   endif 

   return err
endfunction

" check realize plugin
function! s:checkRealizePlugin()
   " yq
   if !executable('yq')
      call s:echoError('yq is not installed')
      return -1
   endif
endfunction

" set envar by source
function! s:setEnvar(source) 
   let s:singleLineEnvar = ''
   " realize
   if a:source == s:realize  
      let l:results = s:executeAndFetchList('!yq r .realize.yaml "schema[*].env" | sed "s/\: /=/g; s/\:\$/=/g;"')
      for s in l:results
         let s:singleLineEnvar .= s.' '
      endfor
   endif

   return s:singleLineEnvar
endfunction

function! s:executeAndFetchList(command) 
   silent! exe a:command.' > '.g:envarFileName

   let l:results = []
   let s:lines = readfile(g:envarFileName)
   for s:line in s:lines
      call add(l:results, s:line)
   endfor

   if g:deleteTemporartyEnvar == 1 | call delete(g:envarFileName) | endif

   return l:results
endfunction
   
function! g:GoRunDebug(source) 
   let l:isSourceValid = 0
   for s in s:sourceAvailables
      if s == a:source 
         let l:isSourceValid = 1
         break
      endif
   endfor

   if l:isSourceValid == 0
      call s:echoError('source is not valid')
      return -1
   endif

   let l:err = s:checkPlugin(a:source)
   if l:err != 0 
      return -1
   endif

   let l:env = s:setEnvar(a:source)
   exe 'GoDebugStart . '.l:env

endfunction

" just echo the error
function s:echoError(message)
   echohl ErrorMsg
   echomsg 'vim-go-debug.error: '.a:message
   echohl None
endfunction
