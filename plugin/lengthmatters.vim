if exists('g:loaded_lengthmatters') || v:version < 700
    finish
endif
let g:loaded_lengthmatters=1

" Another helper function that creates a default highlighting command based on
" the current colorscheme (it's always updated to the *current* colorscheme).
" By default, it creates a command that highlights the overlength match with the
" same bg as Comment's fg and the same fg as Normal's bg. It should look good on
" every colorscheme.
function! s:DefaultHighlighting()
    let cmd = 'highlight ' . g:lengthmatters_match_name

    for md in ['cterm', 'term', 'gui']
        let bg = synIDattr(hlID('Comment'), 'fg', md)
        let fg = synIDattr(hlID('Normal'), 'bg', md)

        " Break out if we're in GUI vim and the mode isn't 'gui' since GUI tries to
        " parse cterm values too, and it can screw up in some cases.
        if has('gui_running') && md !=# 'gui'
            continue
        endif

        if !empty(bg) | let cmd .= ' ' . md . 'bg=' . bg | endif
        if !empty(fg) | let cmd .= ' ' . md . 'fg=' . fg | endif
    endfor

    return cmd
endfunction


let g:lengthmatters_on_by_default = get ( g:,'lengthmatters_on_by_default', 1)
let g:lengthmatters_use_textwidth = get ( g:,'lengthmatters_use_textwidth', 1)
let g:lengthmatters_start_at_column = get ( g:,'lengthmatters_start_at_column', 81)
let g:lengthmatters_match_name = get ( g:,'lengthmatters_match_name', 'OverLength')
let g:lengthmatters_highlight_command = get ( g:,'lengthmatters_highlight_command', s:DefaultHighlighting())
let g:lengthmatters_excluded = get ( g:,'lengthmatters_excluded', [])
let g:lengthmatters_exclude_readonly = get ( g:,'exclude_readonly', 1)


function! s:Enable()
    let b:lengthmatters_active = 1
    " Create a new match if it doesn't exist already (in order to avoid creating
    " multiple matches for the same buffer).
    if !exists('b:lengthmatters_match')
        let l:column = ( g:lengthmatters_use_textwidth && &tw > 0 ) ? &tw + 1 : g:lengthmatters_start_at_column
        let l:regex = '\%' . l:column . 'v.\+'
        call s:Highlight()
        let b:lengthmatters_match = matchadd(g:lengthmatters_match_name, l:regex)
    endif
endfunction


function! s:Disable()
    let b:lengthmatters_active = 0
    call s:Highlight()
    if exists('b:lengthmatters_match')
        call matchdelete(b:lengthmatters_match)
        unlet b:lengthmatters_match
    endif
endfunction

function! s:Init()
    let b:lengthmatters_tw = &tw
    let b:lengthmatters_buffer_inited = 1
    let b:lengthmatters_active = g:lengthmatters_on_by_default

    " if the file is read-only it will not be highlighted by default
    if &readonly && g:lengthmatters_exclude_readonly
        let b:lengthmatters_active = 0
    endif

    " buftype is 'terminal' in :terminal buffers in NeoVim
    " if filetype is in lengthmatters_excluded list it will
    " not be highlighted by default
    if index(g:lengthmatters_excluded, &ft) >= 0 || &buftype == 'terminal'
        let b:lengthmatters_active = 0
    endif

    " Create a new match if it doesn't exist already (in order to avoid creating
    " multiple matches for the same buffer).
    if ( !exists('b:lengthmatters_match') && b:lengthmatters_active )
        let l:column = ( g:lengthmatters_use_textwidth && &tw > 0 ) ? &tw + 1 : g:lengthmatters_start_at_column
        let l:regex = '\%' . l:column . 'v.\+'
        call s:Highlight()
        let b:lengthmatters_match = matchadd(g:lengthmatters_match_name, l:regex)
    endif
endfunction

function! s:Update()
    call s:Highlight()
    if ( g:lengthmatters_use_textwidth && &tw > 0 ) && ( &tw != b:lengthmatters_tw )
        let b:lengthmatters_tw = &tw
        call s:Disable()
        call s:Enable()
    endif
endfunction

" Toggle between active and inactive states.
function! s:Toggle()
    if !exists('b:lengthmatters_active') || !b:lengthmatters_active
        call s:Enable()
    else
        call s:Disable()
    endif
endfunction


" Execute the highlight command.
function! s:Highlight()
    " Clear every previous highlight.
    exec 'hi clear ' . g:lengthmatters_match_name
    exec 'hi link ' . g:lengthmatters_match_name . ' NONE'

    if( b:lengthmatters_active )
        " The user forced something, so use that something. See the functions defined
        " in autoload/lengthmatters.vim.
        if exists('g:lengthmatters_linked_to')
            exe 'hi link ' . g:lengthmatters_match_name . ' ' . g:lengthmatters_linked_to
        elseif exists('g:lengthmatters_highlight_colors')
            exe 'hi ' . g:lengthmatters_match_name . ' ' . g:lengthmatters_highlight_colors
        else
            exec s:DefaultHighlighting()
        endif
    endif
endfunction


" The AutocmdTrigger call different functions if the file is opened first time
" it call Init() otherwise Update()
function! s:AutocmdTrigger()
    if !exists('b:lengthmatters_buffer_inited')
        call s:Init()
    else
        call s:Update()
    endif
endfunction



augroup lengthmatters
    autocmd!
    " trigger when enter/swtich different files(buffer)
    autocmd BufEnter * call s:AutocmdTrigger()
    " Re-highlight the match on every colorscheme change (includes bg changes).
    autocmd ColorScheme * call s:Highlight()
augroup END

" Define commands
command! LengthmattersInit call s:Init()
command! LengthmattersEnable call s:Enable()
command! LengthmattersDisable call s:Disable()
command! LengthmattersToggle call s:Toggle()
command! LengthmattersReload call s:Disable() | call s:Enable()
command! LengthmattersEnableAll bufdo call s:Enable()
command! LengthmattersDisableAll bufdo call s:Disable()
