.MODEL	SMALL
; I/O Address Bus decode - every device gets 0x200 addresses */
IO0  EQU  0000h
IO1  EQU  0200h
IO2  EQU  0400h
IO3  EQU  0600h
IO4  EQU  0800h
IO5  EQU  0A00h
IO6  EQU  0C00h
IO7  EQU  0E00h
IO8  EQU  1000h
IO9  EQU  1200h
IO10 EQU  1400h
IO11 EQU  1600h
IO12 EQU  1800h
IO13 EQU  1A00h
IO14 EQU  1C00h
IO15 EQU  1E00h

ADR_TIMER_DATA0   EQU  (IO3 + 00h)
ADR_TIMER_DATA1   EQU  (IO3 + 02h)
ADR_TIMER_DATA2   EQU  (IO3 + 04h)
ADR_TIMER_CONTROL EQU  (IO3 + 06h)

TIMER_COUNTER0	EQU 00h
TIMER_COUNTER1	EQU 40h
TIMER_COUNTER2	EQU 80h

TIMER_LATCH	  EQU 00h
TIMER_LSB	  EQU 10h
TIMER_MSB	  EQU 20h
TIMER_LSB_MSB 	  EQU 30h

TIMER_MODE0	EQU 00h
TIMER_MODE1	EQU 02h
TIMER_MODE2	EQU 04h
TIMER_MODE3	EQU 06h
TIMER_MODE4	EQU 08h
TIMER_MODE5	EQU 09h
TIMER_BCD	EQU 01h

MACRO_INICIALIZA_8253_TIMER0 MACRO HIGH,LOW
   PUSHF
   PUSH AX
   PUSH DX
   
   MOV AL,36H
   MOV DX, ADR_TIMER_CONTROL
   OUT DX,AL

   MOV AL,LOW
   MOV DX, ADR_TIMER_DATA0
   OUT DX,AL

   MOV AL,HIGH
   MOV DX, ADR_TIMER_DATA0
   OUT DX,AL
   
   POP DX
   POP AX
   POPF
ENDM

; 8251A USART 
ADR_USART_DATA EQU  (IO6 + 00h)
;ONDE VOCE VAI MANDAR E RECEBER DADOS DO 8251

ADR_USART_CMD  EQU  (IO6 + 02h)
;É O LOCAL ONDE VOCE VAI ESCREVER PARA PROGRAMAR O 8251

ADR_USART_STAT EQU  (IO6 + 02h)
;RETORNA O STATUS SE UM CARACTER FOI DIGITADO
;RETORNA O STATUS SE POSSO TRANSMITIR CARACTER PARA O TERMINAL

;Numeros
DIG0 = 10111111B ;DEC = 191
DIG1 = 10000110B ;DEC = 134
DIG2 = 11011011B ;DEC = 219
DIG3 = 11001111B ;DEC = 207
DIG4 = 11100110B ;DEC = 230
DIG5 = 11101101B ;DEC = 237
DIG6 = 11111101B ;DEC = 253
DIG7 = 10000111B ;DEC = 135
DIG8 = 11111111B ;DEC = 255
DIG9 = 11101111B ;DEC = 239


.8086
.CODE
   ;assume    CS:code,DS:data
   org 0008h
   PONTEIRO_TRATADOR_INTERRUPCAO DB 4 DUP(?) ; PONTEIRO PARA INTERRUPCAO
   ;APONTA PARA UMA ROTINA CHAMADA A CADA 1 SEGUNDO VIA HARDWARE INTERRUPT
   ;OBSERVE NO 8086 O PINO NMI, ELE ESTA RECEBENDO UM PULSO A CADA UM SEGUNDO, FORÇANDO A INTERRUPÇÃO

   ;RESERVADO PARA VETOR DE INTERRUPCOES
   org 0400h

.startup
	MOV AX,0000
	MOV DS,AX
	
	MOV WORD PTR PONTEIRO_TRATADOR_INTERRUPCAO, OFFSET INTERRUPT_ONE_SECOND
	MOV WORD PTR PONTEIRO_TRATADOR_INTERRUPCAO + 2, SEG INTERRUPT_ONE_SECOND 

	MOV AX,@DATA
	MOV DS,AX
	MOV AX,@STACK
	MOV SS,AX

	CALL INICIALIZA_8251 

	CALL ZERA
	
	JMP DESPERTADOR

LOOP_INI: JMP LOOP_INI	

INTERRUPT_ONE_SECOND:
	PUSHF 
	PUSH AX
	PUSH DX
	CMP leu_segundos, 01h
	JNE rest
	CALL ATUALIZAR_RELOGIO
	CALL VERIFICA_DESPERTADOR
	rest:
	POP DX
	POP AX
	POPF
	IRET

ZERA:
    MOV DX, IO0
    MOV AL, DIG0
    OUT DX, AL
    
    MOV DX, IO1
    MOV AL, DIG0
    OUT DX, AL
    
    MOV DX, IO2
    MOV AL, DIG0
    OUT DX, AL
    
    MOV DX, IO3
    MOV AL, DIG0
    OUT DX, AL
    
    MOV DX, IO4
    MOV AL, DIG0
    OUT DX, AL
    
    MOV DX, IO5
    MOV AL, DIG0
    OUT DX, AL
    
    RET

ATUALIZAR_RELOGIO:
    cmp hor_dez,32h
    jne continua
    cmp hor_uni,34h
    je zera_hor_dez
    continua:
    cmp hor_uni,39h
    je zera_hor_uni
    cmp min_dez,36h
    je zera_min_dez
    cmp min_uni,39h
    je zera_min_uni
    cmp seg_dez,36h
    je zera_seg_dez
    cmp seg_uni,39h
    je zera_seg_uni
    inc seg_uni
    jmp seg_uni_show

zera_seg_uni:
    mov seg_uni,30h
    inc seg_dez
    jmp seg_dez_show
zera_seg_dez:
    mov seg_dez,30h
    inc min_uni
    jmp min_uni_show
zera_min_uni:
    mov min_uni,30h
    inc min_dez
    jmp min_dez_show
zera_min_dez:
    mov min_dez,30h
    inc hor_uni
    jmp hor_uni_show
zera_hor_uni:
    mov hor_uni,30h
    inc hor_dez
    jmp hor_dez_show 
zera_hor_dez:
    mov hor_dez,30h
    mov hor_uni,30h
    mov min_dez,30h
    mov min_uni,30h
    mov seg_dez,30h
    mov seg_uni,30h
    jmp ZERA

;Verificando que número da unidade dos segundos deve ser exibida
seg_uni_show:
    cmp seg_uni, 30h
    je seg_uni_0
    cmp seg_uni, 31h 
    je seg_uni_1
    cmp seg_uni, 32h 
    je seg_uni_2
    cmp seg_uni, 33h 
    je seg_uni_3
    cmp seg_uni, 34h
    je seg_uni_4
    cmp seg_uni, 35h 
    je seg_uni_5
    cmp seg_uni, 36h 
    je seg_uni_6
    cmp seg_uni, 37h 
    je seg_uni_7
    cmp seg_uni, 38h 
    je seg_uni_8
    cmp seg_uni, 39h
    je seg_uni_9

;Verificando que número da dezena dos segundos deve ser exibida	
seg_dez_show:
    cmp seg_dez, 30h
    je seg_dez_0
    cmp seg_dez, 31h 
    je seg_dez_1
    cmp seg_dez, 32h 
    je seg_dez_2
    cmp seg_dez, 33h 
    je seg_dez_3
    cmp seg_dez, 34h
    je seg_dez_4
    cmp seg_dez, 35h 
    je seg_dez_5

;Verificando que número da unidade dos minutos deve ser exibida
min_uni_show:
    cmp min_uni, 30h
    je min_uni_0
    cmp min_uni, 31h 
    je min_uni_1
    cmp min_uni, 32h 
    je min_uni_2
    cmp min_uni, 33h 
    je min_uni_3
    cmp min_uni, 34h
    je min_uni_4
    cmp min_uni, 35h 
    je min_uni_5
    cmp min_uni, 36h 
    je min_uni_6
    cmp min_uni, 37h 
    je min_uni_7
    cmp min_uni, 38h 
    je min_uni_8
    cmp min_uni, 39h
    je min_uni_9

;Verificando que número da dezena dos minutos deve ser exibida	
min_dez_show:
    cmp min_dez, 30h
    je min_dez_0
    cmp min_dez, 31h 
    je min_dez_1
    cmp min_dez, 32h 
    je min_dez_2
    cmp min_dez, 33h 
    je min_dez_3
    cmp min_dez, 34h
    je min_dez_4
    cmp min_dez, 35h 
    je min_dez_5

;Verificando que número da unidade das horas deve ser exibida
hor_uni_show:
    cmp hor_uni, 30h
    je hor_uni_0
    cmp hor_uni, 31h 
    je hor_uni_1
    cmp hor_uni, 32h 
    je hor_uni_2
    cmp hor_uni, 33h 
    je hor_uni_3
    cmp hor_uni, 34h
    je hor_uni_4
    cmp hor_uni, 35h 
    je hor_uni_5
    cmp hor_uni, 36h 
    je hor_uni_6
    cmp hor_uni, 37h 
    je hor_uni_7
    cmp hor_uni, 38h 
    je hor_uni_8
    cmp hor_uni, 39h
    je hor_uni_9

;Verificando que número da dezena das horas deve ser exibida
hor_dez_show:
    cmp hor_dez, 30h
    je hor_dez_0
    cmp hor_dez, 31h 
    je hor_dez_1
    cmp hor_dez, 32h 
    je hor_dez_2
    
;Mostrando dígitos da unidade dos segundos 0-9 
seg_uni_0:
    MOV DX, IO0
    MOV AL, DIG0
    OUT DX, AL
    ret
seg_uni_1:
    MOV DX, IO0
    MOV AL, DIG1
    OUT DX, AL
    RET
seg_uni_2:
    MOV DX, IO0
    MOV AL, DIG2
    OUT DX, AL
    RET
seg_uni_3:
    MOV DX, IO0
    MOV AL, DIG3
    OUT DX, AL
    RET
seg_uni_4:
    MOV DX, IO0
    MOV AL, DIG4
    OUT DX, AL
    RET
seg_uni_5:
    MOV DX, IO0
    MOV AL, DIG5
    OUT DX, AL
    RET
seg_uni_6:
    MOV DX, IO0
    MOV AL, DIG6
    OUT DX, AL
    RET
seg_uni_7:
    MOV DX, IO0
    MOV AL, DIG7
    OUT DX, AL
    RET
seg_uni_8:
    MOV DX, IO0
    MOV AL, DIG8
    OUT DX, AL
    RET
seg_uni_9:
    MOV DX, IO0
    MOV AL, DIG9
    OUT DX, AL
    RET

;Mostrando dígitos da dezena dos segundos 0-6
seg_dez_0:
    MOV DX, IO1
    MOV AL, DIG0
    OUT DX, AL
    jmp seg_uni_show
seg_dez_1:
    MOV DX, IO1
    MOV AL, DIG1
    OUT DX, AL
    jmp seg_uni_show
seg_dez_2:
    MOV DX, IO1
    MOV AL, DIG2
    OUT DX, AL
    jmp seg_uni_show
seg_dez_3:
    MOV DX, IO1
    MOV AL, DIG3
    OUT DX, AL
    jmp seg_uni_show
seg_dez_4:
    MOV DX, IO1
    MOV AL, DIG4
    OUT DX, AL
    jmp seg_uni_show
seg_dez_5:
    MOV DX, IO1
    MOV AL, DIG5
    OUT DX, AL
    jmp seg_uni_show
seg_dez_6:
    MOV DX, IO1
    MOV AL, DIG6
    OUT DX, AL
    jmp seg_uni_show

;Mostrando dígitos da unidade dos minutos 0-9 
min_uni_0:
    MOV DX, IO2
    MOV AL, DIG0
    OUT DX, AL
    jmp seg_dez_show
min_uni_1:
    MOV DX, IO2
    MOV AL, DIG1
    OUT DX, AL
    jmp seg_dez_show
min_uni_2:
    MOV DX, IO2
    MOV AL, DIG2
    OUT DX, AL
    jmp seg_dez_show
min_uni_3:
    MOV DX, IO2
    MOV AL, DIG3
    OUT DX, AL
    jmp seg_dez_show
min_uni_4:
    MOV DX, IO2
    MOV AL, DIG4
    OUT DX, AL
    jmp seg_dez_show
min_uni_5:
    MOV DX, IO2
    MOV AL, DIG5
    OUT DX, AL
    jmp seg_dez_show
min_uni_6:
    MOV DX, IO2
    MOV AL, DIG6
    OUT DX, AL
    jmp seg_dez_show
min_uni_7:
    MOV DX, IO2
    MOV AL, DIG7
    OUT DX, AL
    jmp seg_dez_show
min_uni_8:
    MOV DX, IO2
    MOV AL, DIG8
    OUT DX, AL
    jmp seg_dez_show
min_uni_9:
    MOV DX, IO2
    MOV AL, DIG9
    OUT DX, AL
    jmp seg_dez_show

;Mostrando dígitos da dezena dos minutos 0-6
min_dez_0:
    MOV DX, IO3
    MOV AL, DIG0
    OUT DX, AL
    jmp min_uni_show
min_dez_1:
    MOV DX, IO3
    MOV AL, DIG1
    OUT DX, AL
    jmp min_uni_show
min_dez_2:
    MOV DX, IO3
    MOV AL, DIG2
    OUT DX, AL
    jmp min_uni_show
min_dez_3:
    MOV DX, IO3
    MOV AL, DIG3
    OUT DX, AL
    jmp min_uni_show
min_dez_4:
    MOV DX, IO3
    MOV AL, DIG4
    OUT DX, AL
    jmp min_uni_show
min_dez_5:
    MOV DX, IO3
    MOV AL, DIG5
    OUT DX, AL
    jmp min_uni_show
min_dez_6:
    MOV DX, IO3
    MOV AL, DIG6
    OUT DX, AL
    jmp min_uni_show

;Mostrando dígitos da unidade das horas 0-9 
hor_uni_0:
    MOV DX, IO4
    MOV AL, DIG0
    OUT DX, AL
    jmp min_dez_show
hor_uni_1:
    MOV DX, IO4
    MOV AL, DIG1
    OUT DX, AL
    jmp min_dez_show
hor_uni_2:
    MOV DX, IO4
    MOV AL, DIG2
    OUT DX, AL
    jmp min_dez_show
hor_uni_3:
    MOV DX, IO4
    MOV AL, DIG3
    OUT DX, AL
    jmp min_dez_show
hor_uni_4:
    MOV DX, IO4
    MOV AL, DIG4
    OUT DX, AL
    jmp min_dez_show
hor_uni_5:
    MOV DX, IO4
    MOV AL, DIG5
    OUT DX, AL
    jmp min_dez_show
hor_uni_6:
    MOV DX, IO4
    MOV AL, DIG6
    OUT DX, AL
    jmp min_dez_show
hor_uni_7:
    MOV DX, IO4
    MOV AL, DIG7
    OUT DX, AL
    jmp min_dez_show
hor_uni_8:
    MOV DX, IO4
    MOV AL, DIG8
    OUT DX, AL
    jmp min_dez_show
hor_uni_9:
    MOV DX, IO4
    MOV AL, DIG9
    OUT DX, AL
    jmp min_dez_show   

;Mostrando dígitos da dezena das horas 0-6
hor_dez_0:
    MOV DX, IO5
    MOV AL, DIG0
    OUT DX, AL
    jmp hor_uni_show
hor_dez_1:
    MOV DX, IO5
    MOV AL, DIG1
    OUT DX, AL
    jmp hor_uni_show
hor_dez_2:
    MOV DX, IO5
    MOV AL, DIG2
    OUT DX, AL
    jmp hor_uni_show
hor_dez_3:
    MOV DX, IO5
    MOV AL, DIG3
    OUT DX, AL
    jmp hor_uni_show
hor_dez_4:
    MOV DX, IO5
    MOV AL, DIG4
    OUT DX, AL
    jmp hor_uni_show
hor_dez_5:
    MOV DX, IO5
    MOV AL, DIG5
    OUT DX, AL
    jmp hor_uni_show
hor_dez_6:
    MOV DX, IO5
    MOV AL, DIG6
    OUT DX, AL
    jmp hor_uni_show  
    
JMP ZERA

INICIALIZA_8251:                                     
   MOV AL,0
   MOV DX, ADR_USART_CMD
   OUT DX,AL
   OUT DX,AL
   OUT DX,AL
   MOV AL,40H
   OUT DX,AL
   MOV AL,4DH
   OUT DX,AL
   MOV AL,37H
   OUT DX,AL
   RET

RECEBE_CARACTER:
   PUSHF
   PUSH DX
AGUARDA_CARACTER:
   MOV DX, ADR_USART_STAT
   IN  AL,DX
   TEST AL,2
   JZ AGUARDA_CARACTER
   MOV DX, ADR_USART_DATA
   IN AL,DX
   SHR AL,1
NAO_RECEBIDO:
   POP DX
   POPF
   RET
   
MANDA_CARACTER:
   PUSHF
   PUSH DX
   PUSH AX  ; SALVA AL   
BUSY:
   MOV DX, ADR_USART_STAT
   IN  AL,DX
   TEST AL,1
   JZ BUSY
   MOV DX, ADR_USART_DATA
   POP AX  ; RESTAURA AL
   OUT DX,AL
   POP DX
   POPF
   RET

ECOAR_LEITURA_DESPERTADOR:
	CALL RECEBE_CARACTER
	DESPERTADOR:
	CMP leu_horas, 00h
	JE LER_HORA_DESPERTADOR
	CMP leu_minutos, 00h
	JE LER_MINUTO_DESPERTADOR
	CMP leu_segundos, 00h
	JE LER_SEGUNDO_DESPERTADOR
	CALL MANDA_CARACTER	

LER_HORA_DESPERTADOR:
   CALL MOSTRAR_MSG_HORAS
   CMP digitou_dezena, 00h
   JE LER_DEZ_H
   JMP LER_UNI_H

LER_MINUTO_DESPERTADOR:
   CALL MOSTRAR_MSG_MINUTOS
   CMP digitou_dezena, 00h
   JE LER_DEZ_M
   JMP LER_UNI_M
   
LER_SEGUNDO_DESPERTADOR:
   CALL MOSTRAR_MSG_SEGUNDOS
   CMP digitou_dezena, 00h
   JE LER_DEZ_S
   JMP LER_UNI_S
   
 ; LE OS VALORES
LER_UNI_H:
   MOV hor_uni_des, AL
   MOV digitou_dezena, 00H
   CALL MANDA_CARACTER
   MOV AX, 13
   CALL MANDA_CARACTER
   INC leu_horas
   JMP DESPERTADOR

LER_DEZ_H: 
   MOV hor_dez_des, AL
   INC digitou_dezena
   CALL MANDA_CARACTER
   JMP ECOAR_LEITURA_DESPERTADOR
   
   
LER_UNI_M:
   MOV min_uni_des, AL
   MOV digitou_dezena, 00H
   CALL MANDA_CARACTER
   MOV AX, 13
   CALL MANDA_CARACTER
   INC leu_minutos
   JMP DESPERTADOR

LER_DEZ_M: 
   MOV min_dez_des, AL
   INC digitou_dezena
   CALL MANDA_CARACTER
   JMP ECOAR_LEITURA_DESPERTADOR
   
   
LER_UNI_S:
   MOV seg_uni_des, AL
   MOV digitou_dezena, 00H
   CALL MANDA_CARACTER
   MOV AX, 13
   CALL MANDA_CARACTER
   INC leu_segundos
   JMP MOSTRAR_DESPERTADOR

LER_DEZ_S: 
   MOV seg_dez_des, AL
   INC digitou_dezena
   CALL MANDA_CARACTER
   JMP ECOAR_LEITURA_DESPERTADOR
   
MOSTRAR_BX:
   MOV AL, [BX]
   CMP AL, 0
   JE FIM_MOSTRAR_BX
   CALL MANDA_CARACTER
   INC BX
   JMP MOSTRAR_BX    
FIM_MOSTRAR_BX:
   RET
   
MOSTRAR_MSG_HORAS:
   CMP mostrou_msg_h, 00h
   JNE RETORNO
   LEA BX, MSG_DESP_H
   CALL MOSTRAR_BX
   INC mostrou_msg_h
   JMP ECOAR_LEITURA_DESPERTADOR
MOSTRAR_MSG_MINUTOS:
   CMP mostrou_msg_m, 00h
   JNE RETORNO
   LEA BX, MSG_DESP_M
   CALL MOSTRAR_BX
   INC mostrou_msg_m
   JMP ECOAR_LEITURA_DESPERTADOR

MOSTRAR_MSG_SEGUNDOS:
   CMP mostrou_msg_s, 00h
   JNE RETORNO
   LEA BX, MSG_DESP_S
   CALL MOSTRAR_BX
   INC mostrou_msg_s
   JMP ECOAR_LEITURA_DESPERTADOR
RETORNO:
   ret
   
MOSTRAR_DESPERTADOR:
   LEA BX, MSG_DESPERTADOR
   CALL MOSTRAR_BX
   
   MOV AL, hor_dez_des
   CALL MANDA_CARACTER
   MOV AL, hor_uni_des
   CALL MANDA_CARACTER
   
   LEA BX, DOIS_PONTOS
   CALL MOSTRAR_BX
   
   MOV AL, min_dez_des
   CALL MANDA_CARACTER
   MOV AL, min_uni_des
   CALL MANDA_CARACTER
   
   LEA BX, DOIS_PONTOS
   CALL MOSTRAR_BX
   
   MOV AL, seg_dez_des
   CALL MANDA_CARACTER
   MOV AL, seg_uni_des
   CALL MANDA_CARACTER
   
   JMP LOOP_INI
   
VERIFICA_DESPERTADOR:
   MOV AL, hor_dez
   CMP AL, hor_dez_des
   JE comp_hor_uni
   RET
comp_hor_uni:
   MOV AL, hor_uni
   CMP AL, hor_uni_des
   JE comp_min_dez
   RET
comp_min_dez:
   MOV AL, min_dez
   CMP AL, min_dez_des
   JE comp_min_uni
   RET
comp_min_uni:
   MOV AL, min_uni
   CMP AL, min_uni_des
   JE comp_seg_dez
   RET
comp_seg_dez:
   MOV AL, seg_dez
   CMP AL, seg_dez_des
   JE comp_seg_uni
   RET
comp_seg_uni:
   MOV AL, seg_uni
   CMP AL, seg_uni_des
   JE DESPERTAR
   RET
DESPERTAR:
   LEA BX, MSG_DESPERTADOR
   CALL MOSTRAR_BX
   MACRO_INICIALIZA_8253_TIMER0 00H,0BFH 
   RET

;MEUS DADOS
.DATA
    seg_uni db 30h
    seg_dez db 30h
    min_uni db 30h
    min_dez db 30h
    hor_uni db 30h
    hor_dez db 30h
    
    MSG_INI_H  DB "DIGITE AS HORAS INICIAIS",13,10,0
    MSG_INI_M  DB "DIGITE OS MINUTOS INICIAIS",13,10,0
    MSG_INI_S  DB "DIGITE OS SEGUNDOS INICIAIS",13,10,0
    MSG_DESP_H DB "DIGITE AS HORAS PARA O DESPERTADOR",13,10,0
    MSG_DESP_M DB "DIGITE OS MINUTOS PARA O DESPERTADOR",13,10,0
    MSG_DESP_S DB "DIGITE OS SEGUNDOS PARA O DESPERTADOR",13,10,0
    MSG_DESPERTADOR DB "O DESPERTADOR IRA TOCAR AS ",0
    DOIS_PONTOS DB ":",0
    
    seg_uni_des db 00h
    seg_dez_des db 00h
    min_uni_des db 00h
    min_dez_des db 00h
    hor_uni_des db 00h
    hor_dez_des db 00h
    
    digitou_dezena db 00h
    leu_horas db 00h
    leu_minutos db 00h
    leu_segundos db 00h
    mostrou_msg_h db 00h
    mostrou_msg_m db 00h
    mostrou_msg_s db 00h
    
    
    CONTADOR_SEGUNDOS DB 0
    NOTA DB 0
    TEMPO_NOTA DB 0
    
;MILHA PILHA
.STACK
MINHA_PILHA DW 128 DUP(0) 

END