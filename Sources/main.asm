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

            ORG    	RAMStart         	; Insert your data definition here
ExampleVar: DS.B   1

;
; code section
;
            ORG    ROMStart
            

_Startup:
			LDHX   #RAMEnd+1        	; initialize the stack pointer
            TXS
            
			LDA	  	#$12				; DATO INMEDIATO PARA DESHABILITAR WATCHDOG	
            STA	  	SOPT1				; DESHABILITAR WATCHDOG
            
            LDA	  #$53    				; Configura IRQMOD=1, IRQPE=1, IRQPDD=1, IRQIE=1
        	STA   IRQSC
            
            CLI							; enable interrupts
            
			LDA		#$FF				; Mover al acumulador el valor inmediato FF hexadecimal
			STA		PTBDD				; Todos los pines del puerto B son salidas
			
			BCLR	PTADD_PTADD3,PTADD	; Pin 3 del puerto A como entrada
			BCLR	PTADD_PTADD2,PTADD	; Pin 2 del puerto A como entrada
			
			MOV		#$00,$60			; Si es 00, la rotacion es hacia la izquierda
										; Si es FF, la rotacion es hacia la derecha
										
			SEC							; Bit de carry encendido
Velocidad: 
			LDA 	PTAD 				; Lee el valor del puerto A por completo
			AND 	#$0C 				; Solo me interesan los pines 3 y 2
			
			CBEQA 	#$0C,Muy_baja	 	; Compara acumulador con valor inmediato "00001100"
										; y si es igual brinca a la etiqueta "Muy_baja"
			
			CBEQA 	#$08,Baja	 		; Compara acumulador con valor inmediato "00001000"
										; y si es igual brinca a la etiqueta "Baja"
			
			CBEQA 	#$04,Media	 		; Compara acumulador con valor inmediato "00000100"
										; y si es igual brinca a la etiqueta "Media"
			
			BEQ 	Alta	 			; Compara acumulador con valor inmediato "00000000"
			
Muy_baja:
			LDX		#$FF				; Registro X se carga con un valor que hara que la velocidad sea muy baja
			BRA		Rotar				; Brincar a rotar
Baja:
			LDX		#$C0				; Registro X se carga con un valor que hara que la velocidad sea baja
			BRA		Rotar				; Brincar a rotar
Media:
			LDX		#$80				; Registro X se carga con un valor que hara que la velocidad sea media
			BRA		Rotar				; Brincar a rotar
Alta:
			LDX		#$40				; Registro X se carga con un valor que hara que la velocidad sea alta
Rotar:	
			LDA		#$FF				; Inicio del retardo
Retardo:
			DBNZA	Retardo				; Decrementa el acumulador y brinca a la etiqueta "Retardo" si no es cero
										; Si el acumulador es cero, realizará la instrucción "DBNZX	Retardo"
									
			DBNZX	Retardo				; Decrementa el registro X y brinca a la etiqueta "Retardo" si no es cero
										; Si el registro X es cero, realizará la instrucción "ROL PTBD"
			
			LDA		$60					; Cargar en el acumulador el valor de la direccion de memoria 60 hexadecimal
			BEQ 	Izquierda			; Si el acumulador es 0, se brinca a la etiqueta "Izquierda"
			BRA		Derecha				; Si el acumulador no es 0, se brinca a la etiqueta "Derecha"
Izquierda:	
			ROR		PTBD				; Rotar a la izquierda el contenido del puerto B con el carry
			BRA		Velocidad			; Brincar a la etiqueta "Velocidad" indefinidamente
Derecha:
			ROL		PTBD				; Rotar a la derecha el contenido del puerto B con el carry
			BRA		Velocidad			; Brincar a la etiqueta "Velocidad" indefinidamente
			
;**************************************************************
;* SubrutinaDireccion - Usando PIN PTA5 como IRQ              *
;*                                                            *
;**************************************************************

SubrutinaDireccion:	
				SEI  					; Quita las IRQ
				
				BSET IRQSC_IRQACK,IRQSC	; Apagar la bandera IRQF
										
				COM $60					; Operacion logica NOT con el valor de la direccion de memoria
				
				CLI   					; Activa las IRQ
				RTI   					; Termina la IRQ

;**************************************************************
;*                 Interrupt Vectors                          *
;**************************************************************

            ORG	$FFFA
			DC.W  SubrutinaDireccion   	; Para el pin IRQ 
			
			ORG	$FFFE
			DC.W  _Startup				; Reset
