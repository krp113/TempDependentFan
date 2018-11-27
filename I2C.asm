#include p18f87k22.inc

global I2C_Config, I2C_Temp_Conversion, I2C_Read_T_Data, I2C_Write_Configure_Thermometer, I2C_Temp_Conversion, I2C_TempH, I2C_TempL, Temperature_Comparison
    
acs0	udata_acs   ; reserve data space in access ram
I2C_TempH	    res 1   ; reserve one byte for high byte of temperature
I2C_TempL	    res 1   ; reserve one byte for low byte of temperature

    
ADC    code		    ;why is 'ADC code' required here?

L equ 0    
H equ 1

;A list of commands
Start_Convert_T		equ 0x51	    ;start temperature conversion 
Stop_Convert_T		equ 0x22	    ;stop temperature conversion 
Read_Temperature	equ 0xAA	    ;read temperautre register
Access_TH		equ 0xA1	    ;access TH register
Access_TL		equ 0xA2	    ;access TL register
Access_Config		equ 0xAC	    ;access config register
Software_POR		equ 0x54	    ;software POR command

;Standard bytes
WRITE			equ b'10010000'	    ;write control byte, <3:0> bits is slave address
READ			equ b'10010001'	    ;read control byte
			
;Digital temperature reading resolution set to 10-bits			
Temp_Resolution		equ b'00001000'	    ;<3:2> = <R1:R0> for resolution

;Temperature thresholds
Temperature_One		equ b'00010100'	    ; 20 degress Celcius
Temperature_Two		equ b'00011000'	    ; 24 degress Celcius
Temperature_Three	equ b'00011100'	    ; 28 degress Celcius
Temperature_Four	equ b'00100000'	    ; 32 degress Celcius
Temperature_Max		equ b'00100011'	    ; 35 degress Celcius


		
;Duty cycles correspondent to Temperature thresholds

Duty_Cycle_Zero		equ b'00000000'	    ; 0% Duty Cycle
Duty_Cycle_One		equ b'00110010'	    ; approx. 20% of Max Duty Cycle
Duty_Cycle_Two		equ b'01100100'	    ; approx. 40% of Max Duty Cycle
Duty_Cycle_Three	equ b'10010110'	    ; approx. 60% of Max Duty Cycle
Duty_Cycle_Four		equ b'11001000'	    ; approx. 80% of Max Duty Cycle
Duty_Cycle_Max		equ b'11110000'	    ; approx. 95% of Max Duty Cycle
Duty_Cycle_Full		equ b'11111111'	    ; 100% Duty Cycle
;*****Setting up the registers for I2C communication*****
I2C_Config_registers
		
    ; PortC pins used to communicate to slave
    bsf	    TRISC, RC3	 
    bsf	    TRISC, RC4	
    
    ; BAUD RATE
    movlw   b'00111111'	;Fosc / (4*(BAUD RATE + 1))  = clock frequency
    movwf   SSP1ADD	
    
    ;Slew Rate control, set to standard of 100kHz
    
    movlw b'00000000'
    movwf SSP1STAT
    
    ; Configuring for using MSSP1 module in Master Mode
    movlw   b'00101000'	
    movwf   SSP1CON1	
    return
    
    ;*****I2C WRITE/READ sequences*****
I2C_Write_Configure_Thermometer
    ; Initiate START condition
    bsf   SSP1CON2, SEN		    ; setting bit for START condition
    call  I2C_Check_If_Done	    ; waiting for I2C operation completion
    
    ; Control byte to be transmitted to slave, with R/W* = 0
    movlw   WRITE	
    movwf   SSP1BUF
    call    I2C_Check_If_Done
    movlw   0x01		    ; error number
    btfsc   SSP1CON2, ACKSTAT	    ; Check status register bit for ACK 
    goto    I2C_Error		    ; if NACK then error, skipping to termination
      
    ; Command byte to access configuration register in the slave
    movlw   Access_Config	    ; access configuration command byte
    movwf   SSP1BUF		    ; reloading SSP1BUF with the command byte
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion	
    movlw   0x02		    ; error number
    btfsc   SSP1CON2, ACKSTAT	    ; Check status register bit for ACK 
    goto    I2C_Error		    ; if NACK then error, skipping to termination  
    
    ; Data byte to set resolution of temperature data
    movlw   Temp_Resolution	    ; configuration byte, setting resolution to 10bytes = PWM duty cycle resolution
    movwf   SSP1BUF
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion	
    movlw   0x04		    ; error number
    btfsc   SSP1CON2, ACKSTAT	    ; Check status register bit for ACK 
    goto    I2C_Error		    ; if NACK then error, skipping to termination   
    bsf	    SSP1CON2, PEN	    ; initiate STOP condition
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion
    return
    
;Initiating Temperature Conversion from Analog to Digital
    I2C_Temp_Conversion
     
    bsf   SSP1CON2, SEN		    ; setting bit for START condition
    call  I2C_Check_If_Done	    ; waiting for I2C operation completion

    movlw   WRITE		    ; Control byte to be sent to the slave, <1:3> bits is the slave address
    movwf   SSP1BUF		    ; <0> = 0 means I want to WRITE to the slave
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion	
    movlw   0x11		    ; error number
    btfsc   SSP1CON2, ACKSTAT	    ; Check status register bit for ACK 
    goto    I2C_Error		    ; if NACK then error, skipping to termination
    
    movlw   Start_Convert_T	    ; initiate temperature conversion
    movwf   SSP1BUF		    ; reloading SSP1BUF with the command byte
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion	
    
    movlw   0x12		    ; error number
    btfsc   SSP1CON2, ACKSTAT	    ; Check status register bit for ACK 
    goto    I2C_Error		    ; if NACK then error, skipping to termination
    
    bsf	    SSP1CON2, PEN	    ; initiate STOP condition
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion
    return
    
; Read data from the Temperature register in the thermometer
I2C_Read_T_Data
    
    bsf	    SSP1CON2, SEN	    ; setting bit for START condition
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion
    
    movlw   WRITE		    ; Control byte to be sent to the slave, <3:1> bits is the slave address
    movwf   SSP1BUF		    ; <0> = 0 means I want to WRITE to the slave first before I READ
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion
    movlw   0x21		    ; error number
    btfsc   SSP1CON2, ACKSTAT	    ; Check status register bit for ACK 
    goto    I2C_Error		    ; if NACK then error, skipping to termination
    
    movlw   Read_Temperature	    ; Read Temperature register command byte
    movwf   SSP1BUF		    ; reloading SSP1BUF with the command byte
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion
    movlw   0x22		    ; error number
    btfsc   SSP1CON2, ACKSTAT	    ; Check status register bit for ACK 
    goto    I2C_Error		    ; if NACK then error, skipping to termination
    
    bsf	    SSP1CON2, RSEN	    ;initiate REPEAT START condition
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion
    
    movlw   READ		    ; Control byte to be sent to the slave, <1:3> bits is the slave address
    movwf   SSP1BUF		    ; <0> = 1 means NOW I want to READ from the slave 
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion
    movlw   0x24		    ; error number
    btfsc   SSP1CON2, ACKSTAT	    ; Check status register bit for ACK 
    goto    I2C_Error		    ; if NACK then error, skipping to termination
    
    ;receving high byte of 16-bit temperature reading
    bsf	    SSP1CON2, RCEN	    ; Enable I2C Receive Mode to receive high byte
    call    I2C_Check_If_Done	    ; receving the data byte here, and waiting for it to complete
    movf    SSP1BUF, W		    ; Get data from SSP1BUF into W register
    movwf   I2C_TempH		    ; move high byte into a reserved file register
    clrf    TRISD	    
    movwf   PORTD		    ; high byte displayed on PORT D
    
    ; Send ACK bit for Acknowledge Sequence for receving first byte
    bcf	    SSP1CON2, ACKDT	    ; ACKDT set to 0 corresponding to ACK
    bsf	    SSP1CON2, ACKEN	    ; sending ACK 'now'
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion
    
    ; receving low byte of 16-bit temperature reading
    bsf	    SSP1CON2, RCEN	    ; Enable I2C Receive Mode to receive 2nd byte
    call    I2C_Check_If_Done	    ; receving anotehr data byte here, and waiting for it to complete
    
    bsf	    SSP1CON2, ACKDT	    ; ACKDT set to 1 corresponding to NACK
    bsf	    SSP1CON2, ACKEN	    ; sending NACK 'now'
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion

    bsf	    SSP1CON2, PEN	    ; initiate STOP condition
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion

    movf    SSP1BUF, W		    ; Transfer data from SSP1BUF into W register
    movwf   I2C_TempL		    ; move low byte into a reserved file register
    
    return
    
;Compare-temperature readings with set thresholds, subroutine
Temperature_Comparison
	
   movlw Temperature_One	    ; First-threshold of 20 degrees celcius
   subwf I2C_TempH		    ; (measured temperature) - (threshold temperature)
   
   btfsc STATUS, N		    ; if subtraction result not negative, skip
   goto	 Less_Than_Temperature_One  ; if subtraction result is negative
   
   btfsc STATUS, Z		    ; if subtraction result not zero, skip
   goto  Equal_to_Temperature_One   ; if subtraction result is zero
   
   btfsc STATUS, C		    ; if subtraction result not postive, skip
   goto  Exceed_Temperature_One	    ; if subtraction result is postive
   
 
   Less_Than_Temperature_One	    
   movlw    Duty_Cycle_Zero	    ; 0% Duty Cycle applied
   movwf    CCPR4L
   goto	    Temp_dependent_fan_control	; repeat procedure
   
   
   
   Equal_to_Temperature_One
   movlw    Duty_Cycle_One	    ; 20% Duty Cycle applied
   movwf    CCPR4L
   goto	    Temp_dependent_fan_control
   
   
   ;end of first comparison
   
   Exceed_Temperature_One
   movlw   Temperature_Two
   subwf   I2C_TempH
   
   btfsc   STATUS, N
   goto	   Less_Than_Temperature_Two
   
   btfsc   STATUS, Z
   goto	   Equal_to_Temperature_Two
   
   btfsc   STATUS, C
   goto	   Exceed_Temperature_Two
   
   Less_Than_Temperature_Two
   movlw   Duty_Cycle_One	    
   movwf   CCPR4L
   goto	   Temp_dependent_fan_control
   
   
   Equal_to_Temperature_Two
   movlw   Duty_Cycle_Two	    
   movwf   CCPR4L
   goto	   Temp_dependent_fan_control
   
   
   ;end of second comparison
   Exceed_Temperature_Two
   movlw   Temperature_Three
   subwf   I2C_TempH
   
   btfsc   STATUS, N
   goto	   Less_Than_Temperature_Three
   
   btfsc   STATUS, Z
   goto	   Equal_to_Temperature_Three
   
   btfsc   STATUS, C
   goto	   Exceed_Temperature_Three
   
   Less_Than_Temperature_Three
   movlw   Duty_Cycle_Two	   
   movwf   CCPR4L
   goto	   Temp_dependent_fan_control
   
   
   Equal_to_Temperature_Three
   movlw   Duty_Cycle_Three	    
   movwf   CCPR4L
   goto	   Temp_dependent_fan_control
   
   ;end of third comparison
   
   Exceed_Temperature_Three
   movlw   Temperature_Four
   subwf   I2C_TempH
   
   btfsc   STATUS, N
   goto	   Less_Than_Temperature_Four
   
   btfsc   STATUS, Z
   goto	   Equal_to_Temperature_Four
   
   btfsc   STATUS, C
   goto	   Exceed_Temperature_Four
   
   Less_Than_Temperature_Four
   movlw   Duty_Cycle_Three	    
   movwf   CCPR4L
   goto	   Temp_dependent_fan_control
   
   
   Equal_to_Temperature_Four
   movlw   Duty_Cycle_Four	   
   movwf   CCPR4L
   goto	   Temp_dependent_fan_control
   
   
   ;end of fourth comparison
   
   Exceed_Temperature_Four
   movlw   Temperature_Five
   subwf   I2C_TempH
   
   btfsc   STATUS, N
   goto	   Less_Than_Temperature_Five
   
   btfsc   STATUS, Z
   goto	   Equal_to_Temperature_Five
   
   btfsc   STATUS, C
   goto	   Exceed_Temperature_Five
   
   Less_Than_Temperature_Five
   movlw   Duty_Cycle_Four	    
   movwf   CCPR4L
   goto	   Temp_dependent_fan_control
   
   
   Equal_to_Temperature_Five
   movlw   Duty_Cycle_Max	    
   movwf   CCPR4L
   goto	   Temp_dependent_fan_control
   
   
   ;end of fifth comparison
   
   Exceed_Temperature_Max
   movlw   Duty_Cycle_Full	    
   movwf   CCPR4L	  
   goto	   Temp_dependent_fan_control
   
   return
   
   ;no comparison needed if T > 35 degrees celcius, Max Duty Cycle applied
    
I2C_Error
    clrf    TRISE
    movwf   PORTE		    ; displaying error on PORTE
 
    bsf	    SSP1CON2, PEN	    ; STOP condition
    call    I2C_Check_If_Done	    ; waiting for I2C operation completion
    
    goto $			    ; stop at this location because the whole code 
				    ; will need to be reinitiated 
				    ; after bug-fixing due to error
    
I2C_Check_If_Done
    
check	btfss PIR1, SSP1IF ; waiting for I2C operation completion
	goto check ; I2C operation incomplete
	bcf PIR1, SSP1IF ; I2C operation complete, clear flag
	return	

;*****big delay subroutouine*****
big_delay
	movlw	0x00		    ; W=0
dloop	decf	0x551,f		    ; no carry when 0x00 -> 0xff
	subwfb	0x550,f		    ; no carry when 0x00 -> 0xff
	bc	dloop		    ; if carry, then loop again
	return			    ; carry not set so return


   
end
