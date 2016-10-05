
let s:porNumber = 19191

fun! s:SendClojureCode(namespace, code)
    let command = json_encode({'namespace': a:namespace, 'code': a:code})
    return system("echo '" . command . "' | nc localhost " . s:porNumber)
endf

fun! s:ReadRange() range
    let code = join(getline(a:firstline, a:lastline))
    echo s:SendClojureCode('user', code)
endf

command! -range ClojureCode <line1>,<line2>call s:ReadRange()
