prog            segment
assume          CS:prog, DS:dane, SS:stosik

naEkran         proc
                MOV     AH,09h
                INT     21h
                RET
endp

start:          MOV     AX,dane
                MOV     DS,AX
                MOV     AX,stosik
                MOV     SS,AX
                MOV     SP,offset szczyt

                MOV     CL,ES:[80h]
                CMP     CL,0
                JE      errorBrakArg
                DEC     CL
                MOV     DI,offset nazwaP
                MOV     SI,82h

                PUSH    DS
                PUSH    ES

                PUSH    DS
                PUSH    ES
                POP     DS
                POP     ES

                REP     MOVSB

                POP     ES
                POP     DS

                MOV     AX,3D00h
                MOV     DX,offset nazwaP
                INT     21h
                CMP     AX,5
                JL      errorPlikNiIst
                MOV     handler,AX
                JMP     terazGramy

errorBrakArg:   MOV     DX,offset errBA
                CALL    naEkran
                JMP     koniec
errorPlikNiIst: MOV     DX,offset errPNI
                CALL    naEkran
                JMP     koniec

terazGramy:     MOV     DX,offset teraGramy
                CALL    naEkran
                MOV     DX,offset nazwaP
                CALL    naEkran

odczyt:         MOV     BX,handler
                MOV     AH,3Fh
                MOV     CX,5
                MOV     DX,offset buffer
                INT     21H

                CMP     AX,CX
                JE      getNuta
                MOV     eof,1

getNuta:        MOV     DX,pauza
                MOV     AL,buffer[0]

                SUB     AL,'A'
                CMP     AX,16
                JL      pelna
                SUB     AL,32
                CMP     AX,7
                JL      plaska
                JMP     errorBledZapNut

pelna:          CMP     AL,15
                JE      returnPauza
                CMP     AL,6
                JG      errorBledZapNut
                MOV     BX,offset nut
                JMP     returnNuta
plaska:         CMP     AL,6
                JG      errorBledZapNut
                MOV     BX,offset flatNut

returnNuta:     XOR     AH,AH
                SAL     AX,1
                MOV     DI,AX
                MOV     DX,[BX][DI]
returnPauza:    MOV     obecNut,DX
                JMP     getOktawa

errorBledZapNut:MOV     DX,offset errBZN
                CALL    naEkran
                JMP     koniec

getOktawa:      MOV     AL,buffer[1]
                SUB     AL,'0'
                CMP     AL,1
                JL      errorBledOkt
                CMP     AL,7
                JG      errorBledOkt
                MOV     obecOkt,AL
                JMP     getDlugosc

errorBledOkt:   MOV     DX,offset errBO
                CALL    naEkran
                JMP     koniec

getDlugosc:     MOV     AL,buffer[2]
                CMP     AL,'9'
                JLE     dlugoscNum
                CMP     AL,'A'
                JGE     dlugoscLit
                JMP     errorNiepopDlu

dlugoscNum:     SUB     AL,'0'
                CMP     AL,1
                JL      errorNiepopDlu
                JMP     returnDlu
dlugoscLit:     SUB     AL,'A'
                CMP     AL,tempo
                JG      errorNiepopDlu

returnDlu:      MOV     obecDlu,AX
                JMP     przygotuj

errorNiepopDlu: MOV     DX,offset errNP
                CALL    naEkran
                JMP     koniec

przygotuj:      MOV     AX,obecNut
                CMP     AX,1
                JE      grajPauze

                XOR     CH,CH
                MOV     CL,8
                SUB     CL,obecOkt
                MOV     AX,obecNut
                SHR     AX,CL
                MOV     BX,AX

                XOR     DX,DX
                MOV     AX,CLK
                DIV     BX
                MOV     BX,100
                MUL     BX
                JMP     skip
grajPauze:      MOV     AX,1
skip:           MOV     obecNut,AX
                XOR     AH,AH
                MOV     AL,tempo
                XOR     DX,DX
                MOV     BX,obecDlu
                DIV     BX
                MOV     obecDlu,AX

                MOV     AX,obecNut
                OUT     42h,AL
                MOV     AL,AH
                OUT     42h,AL

                IN      AL,61h
                OR      AL,00000011b
                OUT     61h,AL

                MOV     CX,obecDlu
                MOV     AH,86h
                MOV     DX,0FFFFh
                INT     15h

                IN      AL,61h
                AND     AL,11111100b
                OUT     61h,AL

                XOR     CX,CX
                MOV     AH,86h
                MOV     DX,0FFFFh
                INT     15h

                XOR     AH,AH
                MOV     AL,eof
                CMP     AL,1
                JE      koniec

                JMP     odczyt

koniec:         MOV     AH,4Ch
                XOR     AL,AL
                INT     21h
prog            ends

dane            segment
CLK             DW      11931 ;1193180 Hz/100
nut             DW      7040,7902,4186,4699,5274,5588,6272 ;A8, B8, C8, D8, E8, F8, G8 Hz
flatNut         DW      6645,7459,3951,4435,4978,5274,5920 ;bA8, bB8, bC8 (B7), bD8, bE8, bF8 (E8), bG8 Hz
pauza           DW      1
nazwaP          DB      127     dup(?)
                DW      0
dolla           DB      10,13,'$'
handler         DW      ?
buffer          DB      5       dup(?)
obecNut         DW      ?
obecOkt         DB      ?
obecDlu         DW      ?
tempo           DB      16 ; ~1 sekunda
eof             DB      0
teraGramy       DB      "Teraz gramy: $"
errBA           DB      "Blad: Nie podano argumentu (nazwy pliku)",10,13,'$'
errPNI          DB      "Blad: Podany plik nie istnieje",10,13,'$'
errBZN          DB      "Blad: Bledny zapis nuty",10,13,'$'
errBO           DB      "Blad: Bleda oktawa",10,13,'$'
errNP           DB      "Blad: Niepoprawna dlugosc trwania nuty",10,13,'$'
dane            ends

stosik          segment
                DW      100h    dup(0)
szczyt          Label   WORD
stosik          ends
end             start