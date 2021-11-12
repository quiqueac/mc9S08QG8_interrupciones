;*******************************************************************
;* This stationery serves as the framework for a user application. *
;* For a more comprehensive program that demonstrates the more     *
;* advanced functionality of this processor, please see the        *
;* demonstration applications, located in the examples             *
;* subdirectory of the "Freescale CodeWarrior for HC08" program    *
;* directory.                                                      *
;*******************************************************************

; Include derivative-specific definitions
            INCLUDE 'derivative.inc'
            
;
; export symbols
;
            XDEF _Startup
            ABSENTRY _Startup

;
; variable/data section
;
            ORG    $60         		; Insert your data definition here
M60: DS.B   1

;
; code section
;
            ORG    ROMStart
            

_Startup:
			LDA	  	#$12			; WATCHDOG	
            STA	  	SOPT1			; WATCHDOG
            
            LDHX   	#RAMEnd+1		; initialize the stack pointer
            TXS
            
            LDA	  #$53    			; Configura IRQMOD=1, IRQPE=1, IRQPDD=1, IRQIE=1
        	STA   IRQSC
            
            CLI						; enable interrupts
            
Inicio:
			LDA		#$FF			; Mover al acumulador el valor inmediato FF hexadecimal
			STA		PTBDD			; Todos los pines del puerto B son salidas
			
			MOV		#$00,M60			; Si es 00, la rotacion es hacia la izquierda
									; Si es FF, la rotacion es hacia la derecha
			
			SEC						; Bit de carry encendido
Rotar:	
			LDA		#$FF			; Inicio del retardo
			LDX		#$FF
Retardo:
			DBNZA	Retardo			; Decrementa el acumulador y brinca a la etiqueta "Retardo" si no es cero
									; Si el acumulador es cero, realizará la instrucción "DBNZX	Retardo"
									
			DBNZX	Retardo			; Decrementa el registro X y brinca a la etiqueta "Retardo" si no es cero
									; Si el registro X es cero, realizará la instrucción "ROL PTBD"
			
			LDA		M60				; Cargar en el acumulador el valor de la direccion de memoria 60 hexadecimal
			BEQ 	Izquierda		; Si el acumulador es 0, se brinca a la etiqueta "Izquierda"
			BRA		Derecha			; Si el acumulador no es 0, se brinca a la etiqueta "Derecha"
Izquierda:	
			ROL		PTBD			; Rotar a la izquierda el contenido del puerto B con el carry
			BRA		Rotar			; Brincar a la etiqueta rotar
Derecha:
			ROR		PTBD			; Rotar a la derecha el contenido del puerto B con el carry
			BRA		Rotar			; Brincar a la etiqueta rotar
			
			BRA		Rotar			; Brincar a la etiqueta rotar indefinidamente
			
;**************************************************************
;* spurious - Spurious Interrupt Service Routine.             *
;*             (unwanted interrupt)                           *
;**************************************************************

spurious:				; placed here so that security value
			NOP			; does not change all the time.
			RTI

;**************************************************************
;* SubrutinaDireccion - Usando PIN PTA5 como IRQ              *
;*                                                            *
;**************************************************************

SubrutinaDireccion:	
				SEI  						; Quita las IRQ
				
				BSET IRQSC_IRQACK,IRQSC		; Apagar la bandera IRQF
				
				CLC							
				COM M60						; Operacion logica NOT con el valor de la direccion de memoria 60 hexadecimal
				
				CLI   						; Activa las IRQ
				RTI   						; Termina la IRQ

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************

            ORG	$FFFA
			DC.W  SubrutinaDireccion   		; Para el pin IRQ 
			
			ORG	$FFFE
			DC.W  _Startup					; Reset
