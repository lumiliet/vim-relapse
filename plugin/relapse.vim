
let s:relapsePort = 19191
command! -range Relapse <line1>,<line2>call s:ReadRange()


fun! s:SendClojureCode(namespace, code, nreplPort)
    let json = json_encode({'namespace': a:namespace, 'code': a:code, 'port': a:nreplPort})
    let command = "echo " . shellescape(json) . " | nc localhost " . s:relapsePort . "\n"
    let result = system(command)

    if result =~ "java.net.ConnectException"
        return s:SendClojureCode(a:namespace, a:code, s:ResetPortNumber())
    elseif len(result)
        return result
    else
        return "No response"
    endif
endf


fun! s:GetCode(firstLine, lastLine)
    if a:firstLine == a:lastLine
        let form = s:FindParentForm()
        if len(form)
            return form
        endif
    endif

    return join(getline(a:firstLine, a:lastLine), "\n")
endf


fun! s:ReadRange() range
    call s:CorrectCursorPosition()
    
    let code = s:GetCode(a:firstline, a:lastline)

    let portNumber = s:GetPortNumber()
    if portNumber
        echo s:SendClojureCode(s:ReadNamespace(), code, portNumber)
    else
        echo "No running repl for project"
    endif

endf


fun! s:CorrectCursorPosition()
    let pos = getcurpos()
    call cursor(pos[1], pos[4])
endf


fun! s:ReadNamespace()
    for lineNumber in range(0, line('$'))
        let match = matchlist(getline(lineNumber), '\_s*(ns\_s\_s*\(\_S\_S*\)')
        if len(match)
            return match[1]
        endif
    endfor

    return 'user'
endf


fun! s:GetPortNumber()
    if !exists('b:nreplPort')
        let b:nreplPort = s:ReadPortNumber()
    endif

    return b:nreplPort
endf


fun! s:ResetPortNumber()
    let b:nreplPort = s:ReadPortNumber()
    return b:nreplPort
endf


fun! s:ReadPortNumber()
    let nreplFilename = findfile('.nrepl-port', expand('%:p') . ';~/')
    if len(nreplFilename)
        return join(readfile(nreplFilename))
    else
        return 0
    endif
endf


fun! s:Backwards(pos)
    let code = getline(0, line('.') - 1) + [getline('.')[:a:pos - 1]]

    return s:TraverseCode(code, -1)
endf


fun! s:Forwards(pos)
    let code = [getline('.')[a:pos:]] + getline(line('.') + 1, '$')

    return s:TraverseCode(code, 1)
endf


fun! s:TraverseCode(code, increment)

    let code = split(join(a:code, "\n"), '\zs')

    if a:increment < 0
        let code = reverse(code)
    endif

    let parenCount = 0
    let maxCount = 0
    let position = 0
    for index in range(0, len(code) -1)
        let char = code[index]
        if char == ')'
            let parenCount = parenCount + a:increment
        elseif char == '('
            let parenCount = parenCount - a:increment
        endif

        if parenCount > maxCount
            let maxCount = parenCount
            let position = index
        endif
    endfor

    if maxCount == 0
        return ""
    elseif a:increment < 0
        return join(reverse(code[:position]), '')
    else
        return join(code[:position], '')
    endif
endf


fun! s:Walk(pos)
    if a:pos < 1
        return ""
    else
        return s:Backwards(a:pos) . s:Forwards(a:pos)
    endif
endf


fun! s:FindParentForm()
    let pos = getpos('.')[2]
    return s:FindFirstForm([pos, s:GetPosOf('(') + 1, s:GetPosOf(')')])
endf

fun! s:GetPosOf(char)
    return match(getline('.'), a:char)
endf

fun! s:FindFirstForm(positions)
    if len(a:positions) == 0
        return ""
    endif

    let firstPass = s:Walk(a:positions[0])
    if len(firstPass)
        return firstPass
    else
        return s:FindFirstForm(a:positions[1:])
    endif

endf
