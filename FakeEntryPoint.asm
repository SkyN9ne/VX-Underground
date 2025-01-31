;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; Fake EP Trick
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; The idea is simple: After loading our program, we change the loaded PE image entry point 
; dynamically to another routine inside our code (In this example is a simple messagebox).
;
; So, when the reverse guy dumps it will get the changed EP and change the PE behaviour 
; when the dumped file run. This is just an educational trick with PE headers for my 
; students understand better the PE Format in a practical way on malware analysis classes.
;
; This trick defeats: 
;       - Process Dump v2.1 (https://github.com/glmcdona/Process-Dump)
;       - OllyDumpEx
;       - Every dumper that grabs info from loaded PE header
; 
; We move the file location to defeat Scylla too.
;
; SWaNk 2020 - VX 
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

format PE GUI 4.0

entry start

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
; includes
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
include '%fasm%\INCLUDE\win32a.inc'

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
section '.text' code readable writeable executable
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        ; if the file was dumped from memory, with one tool that grab the loaded image, 
        ; the EP will chage to this instruction
        push    0
        push    szTitle
        push    szFuckOff
        push    0
        call    [MessageBoxA]

        push    0
        call    [ExitProcess]

start:
        invoke GetModuleHandleA, 0                              ;get imageBase
        mov     [mHandle], eax
        
        mov     ebx, eax                                        ;save into ebx
        add     ebx, 0xa8                                       ;EP 

        invoke VirtualProtect, ebx, 4, PAGE_EXECUTE_READWRITE, Old
        mov     byte[ebx], 0x00                                 ;Change EP to our joke payload
        invoke VirtualProtect, ebx, 4, PAGE_EXECUTE_READ, Old

        ;Now we rename the file so Scylla can't find it on disk (MoveFileA)

        invoke GetModuleFileNameA,0,szfileName, 255             ; return length in eax
        add eax, szfileName                                     ; eax now is in the end of the PE filename

        ;Find for the first '\' from backwards to grab the filename
        @@:
        dec     eax
        cmp     byte[eax],'\'             
        jne     @B
        inc     eax                                             ;skip slash 
        mov     ebx, eax                                        ;save to rename file back

        invoke MoveFileA, eax, tmpName, NULL

        ;normal behaviour, just a messagebox, if the file is dumped here the trap is set
        push    0
        push    szTitle
        push    szExample
        push    0
        call    [MessageBoxA]

        ;rename to the original name

        invoke MoveFileA, tmpName, ebx, NULL

        push    0
        call    [ExitProcess]

error:
        push    0
        call    [ExitProcess]

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
section '.data' data readable writeable
;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

szExample       db      'Original file',0
szFuckOff       db      'Hands off asshole',0
szTitle         db      'Fake EP trick',0
mHandle         dd      ?
szfileName      rb      250
tmpName         db      "1.exe",0
Old             dd      ?

;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
data import
        library kernel,'KERNEL32.DLL',\
                user32,'USER32.DLL'

        import user32,  MessageBoxA,'MessageBoxA'
        import kernel,  ExitProcess,'ExitProcess',\
                        GetModuleHandleA,'GetModuleHandleA',\
                        GetModuleFileNameA,'GetModuleFileNameA',\
                        MoveFileA,'MoveFileA',\
                        VirtualProtect,'VirtualProtect'
 
end data
