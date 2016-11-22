;   FUNDACAO UNIVERSITARIA REGIONAL DE BLUMENAU - FURB
;     DISCIPLINA: ARQUITETURA DE COMPUTADORES II
;               SEMESTRE: 2016/2
; ACADEMICOS: DIOVANI BERNARDI DA MOTTA, FELIPE CORSO E 
;            GABRIEL DOS SANTOS RAITHZ   


.MODEL	SMALL
; INICIO DO MAPEAMENTO DAS REGIOES DE MEMORIAS USADAS COMO I/O (INPUT/OUTPUT) DE DADOS PARA OS PERIFERICOS
IO0  EQU  0000H
IO1  EQU  0200H
IO2  EQU  0400H
IO3  EQU  0600H
IO4  EQU  0800H
IO5  EQU  0A00H
IO6  EQU  0C00H
IO7  EQU  0E00H
IO8  EQU  1000H
IO9  EQU  1200H
IO10 EQU  1400H
IO11 EQU  1600H
IO12 EQU  1800H
IO13 EQU  1A00H
IO14 EQU  1C00H
IO15 EQU  1E00H

; MAPEAMENTO DAS REGIOES DE MEMORIAS USADAS PARA O CONTROLE DA COMUNICA��O USART/SERIAL
ADR_TIMER_DATA0   EQU  (IO3 + 00H)
ADR_TIMER_DATA1   EQU  (IO3 + 02H)
ADR_TIMER_DATA2   EQU  (IO3 + 04H)
ADR_TIMER_CONTROL EQU  (IO3 + 06H)

TIMER_COUNTER0	EQU 00H
TIMER_COUNTER1	EQU 40H
TIMER_COUNTER2	EQU 80H

TIMER_LATCH	  EQU 00H
TIMER_LSB	  EQU 10H
TIMER_MSB	  EQU 20H
TIMER_LSB_MSB 	  EQU 30H

TIMER_MODE0	EQU 00H
TIMER_MODE1	EQU 02H
TIMER_MODE2	EQU 04H
TIMER_MODE3	EQU 06H
TIMER_MODE4	EQU 08H
TIMER_MODE5	EQU 09H
TIMER_BCD	EQU 01H

; MACRO QUE TEM COMO RESPONSABILIDADE INICIALIZAR O BEEP USADO PELO DESPERTADOR
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

; 8251A USART RESOURCES

ADR_USART_DATA EQU  (IO6 + 00H) ;ONDE VOCE VAI MANDAR E RECEBER DADOS DO 8251
ADR_USART_CMD  EQU  (IO6 + 02H) ;� O LOCAL ONDE VOCE VAI ESCREVER PARA PROGRAMAR O 8251
ADR_USART_STAT EQU  (IO6 + 02H)  ;RETORNA O STATUS SE UM CARACTER FOI DIGITADO

;CODIFICACAO NECESSARIAS PARA EXIBI��O DOS VALORES CONTABILIZADOS NO RELOGIO E QUE SER�O ENVIADOS PARA O TERMINAL
ZERO = 10111111B 
ONE = 10000110B 
TWO = 11011011B 
THREE = 11001111B 
FOUR = 11100110B 
FIVE = 11101101B 
SIX = 11111101B 
SEVEN = 10000111B 
EIGHT = 11111111B 
NINE = 11101111B 


.8086
.CODE
   ORG 0008H
   PONTEIRO_TRATADOR_INTERRUPCAO DB 4 DUP(?) ; PONTEIRO PARA INTERRUPCAO
   ;APONTA PARA UMA ROTINA CHAMADA A CADA 1 SEGUNDO VIA HARDWARE INTERRUPT
   ;OBSERVE NO 8086 O PINO NMI, ELE ESTA RECEBENDO UM PULSO A CADA UM SEGUNDO, FOR�ANDO A INTERRUP��O

   ORG 0400H ;RESERVADO PARA VETOR DE INTERRUPCOES

.STARTUP
	MOV AX,0000
	MOV DS,AX
	
	; TRIGGER DE DISPARO PARA A INTERRUPCAO QUE OCORRERA A CADA 1 SEGUNDO
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

; ROTINA QUE SER� EXECUTADA A CADA UM SEGUNDO  E � INVOCADA AUTOMATICAMENTE PELO 8086 QUANDO HOUVER UMA INTERRUPCAO
INTERRUPT_ONE_SECOND:
	PUSHF 
	PUSH AX ; EMPILHA OS REGISTRADORES
	PUSH DX
	CMP LEU_SEGUNDOS, 01H ; VERIFICA SE ELE LEU UM SEGUNDO
	JNE REST
	CALL ATUALIZAR_RELOGIO ; INVOCA A ROTINA DE ATUALIZA��O DO VALOR CONTIDO NO RELOGIO
	CALL VERIFICA_DESPERTADOR ; VERIFICAR SE O HORARIO CORRENTE � O MESMO ARMAZENADO PELA ALARME
	REST:
	POP DX
	POP AX
	POPF
	IRET

; ROTINA QUE IRA INICIALIZAR TODOS OS DISPLAYS COM  VALOR ZERO	
ZERA:
    ; ESCREVE O VALOR ZERO PARA O DISPLAY CONECTADO NA PORTA IO0 
    MOV DX, IO0
    MOV AL, ZERO
    OUT DX, AL
    ; ESCREVE O VALOR ZERO PARA O DISPLAY CONECTADO NA PORTA IO1
    MOV DX, IO1
    MOV AL, ZERO
    OUT DX, AL
    ; ESCREVE O VALOR ZERO PARA O DISPLAY CONECTADO NA PORTA IO2
    MOV DX, IO2
    MOV AL, ZERO
    OUT DX, AL
    ; ESCREVE O VALOR ZERO PARA O DISPLAY CONECTADO NA PORTA IO3
    MOV DX, IO3
    MOV AL, ZERO
    OUT DX, AL
    ; ESCREVE O VALOR ZERO PARA O DISPLAY CONECTADO NA PORTA IO4
    MOV DX, IO4
    MOV AL, ZERO
    OUT DX, AL
    ; ESCREVE O VALOR ZERO PARA O DISPLAY CONECTADO NA PORTA IO5
    MOV DX, IO5
    MOV AL, ZERO
    OUT DX, AL
    
    RET

; ROTINA QUE SER� USADA PARA EFETUAR A ATUALIZACAO DO RELOGIO    
ATUALIZAR_RELOGIO:
    CMP HOR_DEZ,32H
    JNE CONTINUA
    CMP HOR_UNI,34H
    JE ZERA_HOR_DEZ

; ROTINA QUE EFETUA O PROCESSO DE CONTROLE PARA VERIFICAR OS LIMITES HORARIOS (23:59:59)    
CONTINUA:
    CMP HOR_UNI,39H  
    JE ZERA_HOR_UNI
    CMP MIN_DEZ,36H ; VERIFICAR SE FOI ATINGIDO O VALOR MAXIMO PERMITIDO PARA A DEZENA DE MINUTO (6)
    JE ZERA_MIN_DEZ
    CMP MIN_UNI,39H ; VERIFICAR SE FOI ATINGIDO O VALOR MAXIMO PERMITIDO PARA A UNIDADE DE MINUTO (9)
    JE ZERA_MIN_UNI
    CMP SEG_DEZ,36H ; VERIFICAR SE FOI ATINGIDO O VALOR MAXIMO PERMITIDO PARA A DEZENA DE SEGUNDO (6)
    JE ZERA_SEG_DEZ
    CMP SEG_UNI,39H ; VERIFICAR SE FOI ATINGIDO O VALOR MAXIMO PERMITIDO PARA A UNIDADE DE MINUTO (9)
    JE ZERA_SEG_UNI
    INC SEG_UNI ; INCREMENTA O VALOR DOS SEGUNDO
    JMP SEG_UNI_SHOW ; EXIBE O VALOR NO DISPLAY DO RELOGIO

; ROTINAS RESPONSAVEIS POR ZERAR O VALOR CONTIDO NOS DISPLAYS    
ZERA_SEG_UNI:
    MOV SEG_UNI,30H
    INC SEG_DEZ ; ESTOURA A UNIDADE DE SEGUNDO E INCREMENTA A DEZENA DE SEGUNDO
    JMP SEG_DEZ_SHOW
ZERA_SEG_DEZ:
    MOV SEG_DEZ,30H
    INC MIN_UNI ; ESTOURA A DEZENA DE SEGUNDO E INCREMENTA A UNIDADE DE SEGUNDO
    JMP MIN_UNI_SHOW
ZERA_MIN_UNI:
    MOV MIN_UNI,30H
    INC MIN_DEZ 
    JMP MIN_DEZ_SHOW
ZERA_MIN_DEZ:
    MOV MIN_DEZ,30H
    INC HOR_UNI
    JMP HOR_UNI_SHOW
ZERA_HOR_UNI:
    MOV HOR_UNI,30H
    INC HOR_DEZ
    JMP HOR_DEZ_SHOW 
ZERA_HOR_DEZ:
    MOV HOR_DEZ,30H ; ZERA O VALOR DE TODOS OS DISPLAYS
    MOV HOR_UNI,30H
    MOV MIN_DEZ,30H
    MOV MIN_UNI,30H
    MOV SEG_DEZ,30H
    MOV SEG_UNI,30H
    JMP ZERA

;ROTINA VERIFICANDO QUE N�MERO DA UNIDADE DOS SEGUNDOS DEVE SER EXIBIDA
SEG_UNI_SHOW:
    CMP SEG_UNI, 30H
    JE SEG_UNI_0
    CMP SEG_UNI, 31H 
    JE SEG_UNI_1
    CMP SEG_UNI, 32H 
    JE SEG_UNI_2
    CMP SEG_UNI, 33H 
    JE SEG_UNI_3
    CMP SEG_UNI, 34H
    JE SEG_UNI_4
    CMP SEG_UNI, 35H 
    JE SEG_UNI_5
    CMP SEG_UNI, 36H 
    JE SEG_UNI_6
    CMP SEG_UNI, 37H 
    JE SEG_UNI_7
    CMP SEG_UNI, 38H 
    JE SEG_UNI_8
    CMP SEG_UNI, 39H
    JE SEG_UNI_9

;ROTINA VERIFICANDO QUE N�MERO DA DEZENA DOS SEGUNDOS DEVE SER EXIBIDA	
SEG_DEZ_SHOW:
    CMP SEG_DEZ, 30H
    JE SEG_DEZ_0
    CMP SEG_DEZ, 31H 
    JE SEG_DEZ_1
    CMP SEG_DEZ, 32H 
    JE SEG_DEZ_2
    CMP SEG_DEZ, 33H 
    JE SEG_DEZ_3
    CMP SEG_DEZ, 34H
    JE SEG_DEZ_4
    CMP SEG_DEZ, 35H 
    JE SEG_DEZ_5

;ROTINA VERIFICANDO QUE N�MERO DA UNIDADE DOS MINUTOS DEVE SER EXIBIDA
MIN_UNI_SHOW:
    CMP MIN_UNI, 30H
    JE MIN_UNI_0
    CMP MIN_UNI, 31H 
    JE MIN_UNI_1
    CMP MIN_UNI, 32H 
    JE MIN_UNI_2
    CMP MIN_UNI, 33H 
    JE MIN_UNI_3
    CMP MIN_UNI, 34H
    JE MIN_UNI_4
    CMP MIN_UNI, 35H 
    JE MIN_UNI_5
    CMP MIN_UNI, 36H 
    JE MIN_UNI_6
    CMP MIN_UNI, 37H 
    JE MIN_UNI_7
    CMP MIN_UNI, 38H 
    JE MIN_UNI_8
    CMP MIN_UNI, 39H
    JE MIN_UNI_9

;ROTINA VERIFICANDO QUE N�MERO DA DEZENA DOS MINUTOS DEVE SER EXIBIDA	
MIN_DEZ_SHOW:
    CMP MIN_DEZ, 30H
    JE MIN_DEZ_0
    CMP MIN_DEZ, 31H 
    JE MIN_DEZ_1
    CMP MIN_DEZ, 32H 
    JE MIN_DEZ_2
    CMP MIN_DEZ, 33H 
    JE MIN_DEZ_3
    CMP MIN_DEZ, 34H
    JE MIN_DEZ_4
    CMP MIN_DEZ, 35H 
    JE MIN_DEZ_5

;ROTINA VERIFICANDO QUE N�MERO DA UNIDADE DAS HORAS DEVE SER EXIBIDA
HOR_UNI_SHOW:
    CMP HOR_UNI, 30H
    JE HOR_UNI_0
    CMP HOR_UNI, 31H 
    JE HOR_UNI_1
    CMP HOR_UNI, 32H 
    JE HOR_UNI_2
    CMP HOR_UNI, 33H 
    JE HOR_UNI_3
    CMP HOR_UNI, 34H
    JE HOR_UNI_4
    CMP HOR_UNI, 35H 
    JE HOR_UNI_5
    CMP HOR_UNI, 36H 
    JE HOR_UNI_6
    CMP HOR_UNI, 37H 
    JE HOR_UNI_7
    CMP HOR_UNI, 38H 
    JE HOR_UNI_8
    CMP HOR_UNI, 39H
    JE HOR_UNI_9

;ROTINA VERIFICANDO QUE N�MERO DA DEZENA DAS HORAS DEVE SER EXIBIDA
HOR_DEZ_SHOW:
    CMP HOR_DEZ, 30H
    JE HOR_DEZ_0
    CMP HOR_DEZ, 31H 
    JE HOR_DEZ_1
    CMP HOR_DEZ, 32H 
    JE HOR_DEZ_2
    
;ROTINA MOSTRANDO D�GITOS DA UNIDADE DOS SEGUNDOS 0-9 
SEG_UNI_0:
    MOV DX, IO0
    MOV AL, ZERO
    OUT DX, AL
    RET
SEG_UNI_1:
    MOV DX, IO0
    MOV AL, ONE
    OUT DX, AL
    RET
SEG_UNI_2:
    MOV DX, IO0
    MOV AL, TWO
    OUT DX, AL
    RET
SEG_UNI_3:
    MOV DX, IO0
    MOV AL, THREE
    OUT DX, AL
    RET
SEG_UNI_4:
    MOV DX, IO0
    MOV AL, FOUR
    OUT DX, AL
    RET
SEG_UNI_5:
    MOV DX, IO0
    MOV AL, FIVE
    OUT DX, AL
    RET
SEG_UNI_6:
    MOV DX, IO0
    MOV AL, SIX
    OUT DX, AL
    RET
SEG_UNI_7:
    MOV DX, IO0
    MOV AL, SEVEN
    OUT DX, AL
    RET
SEG_UNI_8:
    MOV DX, IO0
    MOV AL, EIGHT
    OUT DX, AL
    RET
SEG_UNI_9:
    MOV DX, IO0
    MOV AL, NINE
    OUT DX, AL
    RET

;ROTINA QUE MOSTRANDO D�GITOS DA DEZENA DOS SEGUNDOS 0-6
SEG_DEZ_0:
    MOV DX, IO1
    MOV AL, ZERO
    OUT DX, AL
    JMP SEG_UNI_SHOW
SEG_DEZ_1:
    MOV DX, IO1
    MOV AL, ONE
    OUT DX, AL
    JMP SEG_UNI_SHOW
SEG_DEZ_2:
    MOV DX, IO1
    MOV AL, TWO
    OUT DX, AL
    JMP SEG_UNI_SHOW
SEG_DEZ_3:
    MOV DX, IO1
    MOV AL, THREE
    OUT DX, AL
    JMP SEG_UNI_SHOW
SEG_DEZ_4:
    MOV DX, IO1
    MOV AL, FOUR
    OUT DX, AL
    JMP SEG_UNI_SHOW
SEG_DEZ_5:
    MOV DX, IO1
    MOV AL, FIVE
    OUT DX, AL
    JMP SEG_UNI_SHOW
SEG_DEZ_6:
    MOV DX, IO1
    MOV AL, SIX
    OUT DX, AL
    JMP SEG_UNI_SHOW

;ROTINA QUE MOSTRANDO D�GITOS DA UNIDADE DOS MINUTOS 0-9 
MIN_UNI_0:
    MOV DX, IO2
    MOV AL, ZERO
    OUT DX, AL
    JMP SEG_DEZ_SHOW
MIN_UNI_1:
    MOV DX, IO2
    MOV AL, ONE
    OUT DX, AL
    JMP SEG_DEZ_SHOW
MIN_UNI_2:
    MOV DX, IO2
    MOV AL, TWO
    OUT DX, AL
    JMP SEG_DEZ_SHOW
MIN_UNI_3:
    MOV DX, IO2
    MOV AL, THREE
    OUT DX, AL
    JMP SEG_DEZ_SHOW
MIN_UNI_4:
    MOV DX, IO2
    MOV AL, FOUR
    OUT DX, AL
    JMP SEG_DEZ_SHOW
MIN_UNI_5:
    MOV DX, IO2
    MOV AL, FIVE
    OUT DX, AL
    JMP SEG_DEZ_SHOW
MIN_UNI_6:
    MOV DX, IO2
    MOV AL, SIX
    OUT DX, AL
    JMP SEG_DEZ_SHOW
MIN_UNI_7:
    MOV DX, IO2
    MOV AL, SEVEN
    OUT DX, AL
    JMP SEG_DEZ_SHOW
MIN_UNI_8:
    MOV DX, IO2
    MOV AL, EIGHT
    OUT DX, AL
    JMP SEG_DEZ_SHOW
MIN_UNI_9:
    MOV DX, IO2
    MOV AL, NINE
    OUT DX, AL
    JMP SEG_DEZ_SHOW

;ROTINA QUE MOSTRANDO D�GITOS DA DEZENA DOS MINUTOS 0-6
MIN_DEZ_0:
    MOV DX, IO3
    MOV AL, ZERO
    OUT DX, AL
    JMP MIN_UNI_SHOW
MIN_DEZ_1:
    MOV DX, IO3
    MOV AL, ONE
    OUT DX, AL
    JMP MIN_UNI_SHOW
MIN_DEZ_2:
    MOV DX, IO3
    MOV AL, TWO
    OUT DX, AL
    JMP MIN_UNI_SHOW
MIN_DEZ_3:
    MOV DX, IO3
    MOV AL, THREE
    OUT DX, AL
    JMP MIN_UNI_SHOW
MIN_DEZ_4:
    MOV DX, IO3
    MOV AL, FOUR
    OUT DX, AL
    JMP MIN_UNI_SHOW
MIN_DEZ_5:
    MOV DX, IO3
    MOV AL, FIVE
    OUT DX, AL
    JMP MIN_UNI_SHOW
MIN_DEZ_6:
    MOV DX, IO3
    MOV AL, SIX
    OUT DX, AL
    JMP MIN_UNI_SHOW

;ROTINA QUE MOSTRANDO D�GITOS DA UNIDADE DAS HORAS 0-9 
HOR_UNI_0:
    MOV DX, IO4
    MOV AL, ZERO
    OUT DX, AL
    JMP MIN_DEZ_SHOW
HOR_UNI_1:
    MOV DX, IO4
    MOV AL, ONE
    OUT DX, AL
    JMP MIN_DEZ_SHOW
HOR_UNI_2:
    MOV DX, IO4
    MOV AL, TWO
    OUT DX, AL
    JMP MIN_DEZ_SHOW
HOR_UNI_3:
    MOV DX, IO4
    MOV AL, THREE
    OUT DX, AL
    JMP MIN_DEZ_SHOW
HOR_UNI_4:
    MOV DX, IO4
    MOV AL, FOUR
    OUT DX, AL
    JMP MIN_DEZ_SHOW
HOR_UNI_5:
    MOV DX, IO4
    MOV AL, FIVE
    OUT DX, AL
    JMP MIN_DEZ_SHOW
HOR_UNI_6:
    MOV DX, IO4
    MOV AL, SIX
    OUT DX, AL
    JMP MIN_DEZ_SHOW
HOR_UNI_7:
    MOV DX, IO4
    MOV AL, SEVEN
    OUT DX, AL
    JMP MIN_DEZ_SHOW
HOR_UNI_8:
    MOV DX, IO4
    MOV AL, EIGHT
    OUT DX, AL
    JMP MIN_DEZ_SHOW
HOR_UNI_9:
    MOV DX, IO4
    MOV AL, NINE
    OUT DX, AL
    JMP MIN_DEZ_SHOW   

;ROTINA QUE MOSTRANDO D�GITOS DA DEZENA DAS HORAS 0-6
HOR_DEZ_0:
    MOV DX, IO5
    MOV AL, ZERO
    OUT DX, AL
    JMP HOR_UNI_SHOW
HOR_DEZ_1:
    MOV DX, IO5
    MOV AL, ONE
    OUT DX, AL
    JMP HOR_UNI_SHOW
HOR_DEZ_2:
    MOV DX, IO5
    MOV AL, TWO
    OUT DX, AL
    JMP HOR_UNI_SHOW
HOR_DEZ_3:
    MOV DX, IO5
    MOV AL, THREE
    OUT DX, AL
    JMP HOR_UNI_SHOW
HOR_DEZ_4:
    MOV DX, IO5
    MOV AL, FOUR
    OUT DX, AL
    JMP HOR_UNI_SHOW
HOR_DEZ_5:
    MOV DX, IO5
    MOV AL, FIVE
    OUT DX, AL
    JMP HOR_UNI_SHOW
HOR_DEZ_6:
    MOV DX, IO5
    MOV AL, SIX
    OUT DX, AL
    JMP HOR_UNI_SHOW  
    
JMP ZERA

; ROTINA RESPONSAVEL POR CONFIGURAR A INICIALIZACAO DO TERMINAL
INICIALIZA_8251:                                     
   MOV AL,0
   MOV DX, ADR_USART_CMD ;INFORMA QUE SER� ENVIAO UM COMANDOPARA O TERMINAL
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
   CMP LEU_HORAS, 00H
   JE LER_HORA_DESPERTADOR
   CMP LEU_MINUTOS, 00H
   JE LER_MINUTO_DESPERTADOR
   CMP LEU_SEGUNDOS, 00H
   JE LER_SEGUNDO_DESPERTADOR
   CALL MANDA_CARACTER	

LER_HORA_DESPERTADOR:
   CALL MOSTRAR_MSG_HORAS
   CMP DIGITOU_DEZENA, 00H
   JE LER_DEZ_H
   JMP LER_UNI_H

LER_MINUTO_DESPERTADOR:
   CALL MOSTRAR_MSG_MINUTOS
   CMP DIGITOU_DEZENA, 00H
   JE LER_DEZ_M
   JMP LER_UNI_M
   
LER_SEGUNDO_DESPERTADOR:
   CALL MOSTRAR_MSG_SEGUNDOS
   CMP DIGITOU_DEZENA, 00H
   JE LER_DEZ_S
   JMP LER_UNI_S
   
 ; LE OS VALORES
LER_UNI_H:
   MOV HOR_UNI_DES, AL
   MOV DIGITOU_DEZENA, 00H
   CALL MANDA_CARACTER
   MOV AX, 13
   CALL MANDA_CARACTER
   INC LEU_HORAS
   JMP DESPERTADOR

LER_DEZ_H: 
   MOV HOR_DEZ_DES, AL
   INC DIGITOU_DEZENA
   CALL MANDA_CARACTER
   JMP ECOAR_LEITURA_DESPERTADOR
   
   
LER_UNI_M:
   MOV MIN_UNI_DES, AL
   MOV DIGITOU_DEZENA, 00H
   CALL MANDA_CARACTER
   MOV AX, 13
   CALL MANDA_CARACTER
   INC LEU_MINUTOS
   JMP DESPERTADOR

LER_DEZ_M: 
   MOV MIN_DEZ_DES, AL
   INC DIGITOU_DEZENA
   CALL MANDA_CARACTER
   JMP ECOAR_LEITURA_DESPERTADOR
   
   
LER_UNI_S:
   MOV SEG_UNI_DES, AL
   MOV DIGITOU_DEZENA, 00H
   CALL MANDA_CARACTER
   MOV AX, 13
   CALL MANDA_CARACTER
   INC LEU_SEGUNDOS
   JMP MOSTRAR_DESPERTADOR

LER_DEZ_S: 
   MOV SEG_DEZ_DES, AL
   INC DIGITOU_DEZENA
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
   CMP MOSTROU_MSG_H, 00H
   JNE RETORNO
   LEA BX, MSG_DESP_H
   CALL MOSTRAR_BX
   INC MOSTROU_MSG_H
   JMP ECOAR_LEITURA_DESPERTADOR
MOSTRAR_MSG_MINUTOS:
   CMP MOSTROU_MSG_M, 00H
   JNE RETORNO
   LEA BX, MSG_DESP_M
   CALL MOSTRAR_BX
   INC MOSTROU_MSG_M
   JMP ECOAR_LEITURA_DESPERTADOR

MOSTRAR_MSG_SEGUNDOS:
   CMP MOSTROU_MSG_S, 00H
   JNE RETORNO
   LEA BX, MSG_DESP_S
   CALL MOSTRAR_BX
   INC MOSTROU_MSG_S
   JMP ECOAR_LEITURA_DESPERTADOR
RETORNO:
   RET
   
MOSTRAR_DESPERTADOR:
   LEA BX, MSG_DESPERTADOR
   CALL MOSTRAR_BX
   
   MOV AL, HOR_DEZ_DES
   CALL MANDA_CARACTER
   MOV AL, HOR_UNI_DES
   CALL MANDA_CARACTER
   
   LEA BX, DOIS_PONTOS
   CALL MOSTRAR_BX
   
   MOV AL, MIN_DEZ_DES
   CALL MANDA_CARACTER
   MOV AL, MIN_UNI_DES
   CALL MANDA_CARACTER
   
   LEA BX, DOIS_PONTOS
   CALL MOSTRAR_BX
   
   MOV AL, SEG_DEZ_DES
   CALL MANDA_CARACTER
   MOV AL, SEG_UNI_DES
   CALL MANDA_CARACTER
   
   JMP LOOP_INI
   
VERIFICA_DESPERTADOR:
   MOV AL, HOR_DEZ
   CMP AL, HOR_DEZ_DES
   JE COMP_HOR_UNI
   RET
COMP_HOR_UNI:
   MOV AL, HOR_UNI
   CMP AL, HOR_UNI_DES
   JE COMP_MIN_DEZ
   RET
COMP_MIN_DEZ:
   MOV AL, MIN_DEZ
   CMP AL, MIN_DEZ_DES
   JE COMP_MIN_UNI
   RET
COMP_MIN_UNI:
   MOV AL, MIN_UNI
   CMP AL, MIN_UNI_DES
   JE COMP_SEG_DEZ
   RET
COMP_SEG_DEZ:
   MOV AL, SEG_DEZ
   CMP AL, SEG_DEZ_DES
   JE COMP_SEG_UNI
   RET
COMP_SEG_UNI:
   MOV AL, SEG_UNI
   CMP AL, SEG_UNI_DES
   JE DESPERTAR
   RET
DESPERTAR:
   LEA BX, MSG_DESPERTADOR
   CALL MOSTRAR_BX
   MACRO_INICIALIZA_8253_TIMER0 00H,0BFH 
   RET

;MEUS DADOS
.DATA
    SEG_UNI DB 30H
    SEG_DEZ DB 30H
    MIN_UNI DB 30H
    MIN_DEZ DB 30H
    HOR_UNI DB 30H
    HOR_DEZ DB 30H
    
    MSG_INI_H  DB "DIGITE AS HORAS INICIAIS",13,10,0
    MSG_INI_M  DB "DIGITE OS MINUTOS INICIAIS",13,10,0
    MSG_INI_S  DB "DIGITE OS SEGUNDOS INICIAIS",13,10,0
    MSG_DESP_H DB "DIGITE AS HORAS PARA O DESPERTADOR",13,10,0
    MSG_DESP_M DB "DIGITE OS MINUTOS PARA O DESPERTADOR",13,10,0
    MSG_DESP_S DB "DIGITE OS SEGUNDOS PARA O DESPERTADOR",13,10,0
    MSG_DESPERTADOR DB "O DESPERTADOR IRA TOCAR AS ",0
    DOIS_PONTOS DB ":",0
    
    SEG_UNI_DES DB 00H
    SEG_DEZ_DES DB 00H
    MIN_UNI_DES DB 00H
    MIN_DEZ_DES DB 00H
    HOR_UNI_DES DB 00H
    HOR_DEZ_DES DB 00H
    
    DIGITOU_DEZENA DB 00H
    LEU_HORAS DB 00H
    LEU_MINUTOS DB 00H
    LEU_SEGUNDOS DB 00H
    MOSTROU_MSG_H DB 00H
    MOSTROU_MSG_M DB 00H
    MOSTROU_MSG_S DB 00H
    
    
    CONTADOR_SEGUNDOS DB 0
    NOTA DB 0
    TEMPO_NOTA DB 0
    
;MILHA PILHA
.STACK
MINHA_PILHA DW 128 DUP(0) 

END