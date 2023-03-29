" https://github.com/orgs/community/discussions/12426#discussioncomment-3102062
" accept a word ctrl+L or 40 chars ctrl+left from copilot
function! SuggestChars()
    let suggestion = copilot#Accept("")
    let bar = copilot#TextQueuedForInsertion()
    return bar[0:39]
endfunction

function! SuggestOneWord()
    let suggestion = copilot#Accept("")
    let bar = copilot#TextQueuedForInsertion()
    return split(bar, '[ .]\zs')[0]
endfunction

imap <script><expr> <C-l> SuggestOneWord()
imap <script><expr> <C-left> SuggestChars()
