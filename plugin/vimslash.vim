" The MIT License (MIT)
"
" Copyright (c) 2016 Junegunn Choi
" Modified by Qeuroal
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.

" options
let g:vimslashAutoMiddle=get(g:,'vimslashAutoMiddle',1)
let g:vimslashAutoStarMiddle=get(g:,'vimslashAutoStarMiddle',0)

function! s:wrap(seq)
	if mode() == 'c' && stridx('/?', getcmdtype()) < 0
		return a:seq
	endif
	silent! autocmd! vimslash
	let seq=a:seq
	set hlsearch
	if g:vimslashAutoMiddle==1&&(a:seq=='n'||a:seq=='N')
		return seq."\<plug>(vimslash-trailer)" . "zz"
	else
		return seq."\<plug>(vimslash-trailer)"
	endif
endfunction

function! s:immobile(seq)
	let s:winline = winline()
	let s:pos = getpos('.')
	return a:seq."\<plug>(vimslash-prev)"
endfunction

function! s:vsearch(cmdtype)
	set hlsearch
	let temp = @s
	norm! gv"sy
	let @/ = '\V' . substitute(escape(@s, a:cmdtype.'\'), '\n', '\\n', 'g')
	let @s = temp
endfunction

function! s:trailer()
	augroup vimslash
		autocmd!
		autocmd CursorMoved,CursorMovedI * set nohlsearch | autocmd! vimslash
	augroup END

	let seq = foldclosed('.') != -1 ? 'zv' : ''
	if exists('s:winline')
		let sdiff = winline() - s:winline
		unlet s:winline
		if sdiff > 0
			let seq .= sdiff."\<c-e>"
		elseif sdiff < 0
			let seq .= -sdiff."\<c-y>"
		endif
	endif
	let after = len(maparg("<plug>(vimslash-after)", mode())) ? "\<plug>(vimslash-after)" : ''
	return seq . after
endfunction

function! s:trailerOnLeave()
	augroup vimslash
		autocmd!
		autocmd InsertLeave * call <sid>trailer()
	augroup END
	return ''
endfunction

function! s:prev()
	return getpos('.') == s:pos ? '' : '``'
endfunction

function! s:escape(backward)
	return '\V'.substitute(escape(@", '\' . (a:backward ? '?' : '/')), "\n", '\\n', 'g')
endfunction

function! s:starFind(seq,hlcmd)
	if a:seq=='*'
		let @/="\\<".expand("<cword>")."\\>"
	endif
	set hlsearch
	if a:hlcmd
		augroup vimslash
			autocmd!
			autocmd CursorMoved,CursorMovedI * set nohlsearch | autocmd! vimslash
		augroup END
	endif
	if g:vimslashAutoStarMiddle
		let end="zz"
	else
		let end=""
	endif
	redraw!
	return end
endfunction

function! s:starFindForward(seq,hlcmd)
	if a:seq=='#'
		let @/="\\<".expand("<cword>")."\\>"
	endif
	set hlsearch
	if a:hlcmd
		augroup vimslash
			autocmd!
			autocmd CursorMoved,CursorMovedI * set nohlsearch | autocmd! vimslash
		augroup END
	endif
	redraw!
	if g:vimslashAutoStarMiddle
		execute "normal! zz"
	endif
endfunction

function! vimslash#blink(times, delay)
	let s:blink = { 'ticks': 2 * a:times, 'delay': a:delay }

	function! s:blink.tick(_)
		let self.ticks -= 1
		let active = self == s:blink && self.ticks > 0

		if !self.clear() && active && &hlsearch
			let [line, col] = [line('.'), col('.')]
			let w:blinkId = matchadd('IncSearch',
						\ printf('\%%%dl\%%>%dc\%%<%dc', line, max([0, col-2]), col+2))
		endif
		if active
			call timer_start(self.delay, self.tick)
			if has('nvim')
				call feedkeys("\<plug>(vimslash-nop)")
			endif
		endif
	endfunction

	function! s:blink.clear()
		if exists('w:blinkId')
			call matchdelete(w:blinkId)
			unlet w:blinkId
			return 1
		endif
	endfunction

	call s:blink.clear()
	call s:blink.tick(0)
	return ''
endfunction

map      <expr> <plug>(vimslash-trailer) <sid>trailer()
imap     <expr> <plug>(vimslash-trailer) <sid>trailerOnLeave()
noremap  <expr> <plug>(vimslash-prev)    <sid>prev()
inoremap        <plug>(vimslash-prev)    <nop>
noremap!        <plug>(vimslash-nop)     <nop>

map   <silent><expr>n    <sid>wrap('n')
map   <silent><expr>N    <sid>wrap('N')
nnoremap  <silent><expr>*    <sid>starFind('*',1)
nnoremap  <silent><expr>g*   <sid>starFind('*',0)
nnoremap  <silent><expr>g8   <sid>starFind('*',0)
nnoremap  <silent>#  :call <sid>starFindForward('#',1)<cr>:let v:searchforward=0<cr>
nnoremap  <silent>g# :call <sid>starFindForward('#',0)<cr>:let v:searchforward=0<cr>
" nmap  <expr>*    <sid>wrap(<sid>immobile('*'))
" nmap  <expr>#    <sid>wrap(<sid>immobile('#'))
xnoremap <silent>*  :<C-u>call <SID>vsearch('/')<cr>:call <sid>starFind('',1)<cr>
xnoremap <silent>#  :<C-u>call <SID>vsearch('?')<cr>:call <sid>starFind('',1):let v:searchforward=0<cr>
xnoremap <silent>g* :<C-u>call <SID>vsearch('/')<cr>:call <sid>starFind('',0)<cr>
xnoremap <silent>g8 :<C-u>call <SID>vsearch('/')<cr>:call <sid>starFind('',0)<cr>
xnoremap <silent>g# :<C-u>call <SID>vsearch('?')<cr>:call <sid>starFind('',0):let v:searchforward=0<cr>
xnoremap <silent>g8 :<C-u>call <SID>vsearch('/')<cr>:call <sid>starFind('',0)<cr>
