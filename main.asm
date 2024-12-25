.model small
.stack 100h

.DATA
    AUX_TIME DB 0
    sender_cursor_row db 0
    sender_cursor_col db 0
    public IS_RECIEVER_FOUND
    IS_RECIEVER_FOUND db 0
    public IS_INGAME
    IS_INGAME db 0
    public CRT_PLAYER
    CRT_PLAYER db 0
.code

;;;;;;;;;		Extrns		;;;;;;;;;

EXTRN DisplayScores:FAR
EXTRN DELETE_SCORE:FAR
EXTRN DRAWBLOCKS:FAR
EXTRN DRAW_BALL:FAR
EXTRN MOVE_BALL_BY_VELOCITY:FAR
EXTRN DELETE_BALL:FAR
EXTRN move_crtPlayer_paddle:FAR
EXTRN draw_paddles:FAR
EXTRN CHECK_FOR_WIN:FAR
EXTRN DISPLAY_WIN_MESSAGE:FAR
EXTRN RESET_PADDLES:FAR
EXTRN DISPLAY_LOOSE_MESSAGE:FAR
EXTRN DISPLAY_HEARTS:FAR
EXTRN DELETE_HEARTS:FAR
EXTRN PLAYER_LIVES:Byte
EXTRN CHECK_SERIAL_MESSAGE:FAR
EXTRN SEND_SERIAL_CHARACTER:FAR
EXTRN ENTER_USERNAME:FAR
EXTRN paddle_one_x:word
EXTRN paddle_one_y:word
EXTRN paddle_two_x:word
EXTRN paddle_two_y:word
EXTRN MOVE_CURSOR:FAR
EXTRN read_otherPlayer_pad_pos:FAR
EXTRN send_crtPlayer_pad_pos:FAR
EXTRN menu:FAR
EXTRN choice:byte
EXTRN INIT_SERIAL:FAR
EXTRN INIT_GAME:FAR
EXTRN SPLIT_SCREEN:FAR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAIN PROC
    MOV AX, @DATA
    MOV DS, AX

    CALL INIT_SERIAL
    ; CALL CLEAR_WINDOW
    ; CALL ENTER_USERNAME
    CALL CLEAR_WINDOW
    call menu
    CALL CLEAR_WINDOW

    CALL SPLIT_SCREEN

    ; Add handshake routine
    ; CALL ESTABLISH_CONNECTION
    
    MAIN_LOOP:
        cmp IS_INGAME,1 ; or choice is 2
        JE PLAY

        CALL CHECK_KEYBOARD ; Check if going to send something
        ; Get current cursor position
        mov ah, 03h
        int 10h
        mov sender_cursor_row, dh
        mov sender_cursor_col, dl
        
        CALL CHECK_SERIAL_MESSAGE ; Check if there is a message to be recieved
        
        mov dh, sender_cursor_row
        mov dl, sender_cursor_col
        mov bh, 0
        mov ah, 2
        int 10h
    JMP MAIN_LOOP
    
    PLAY:
    public START_GAME
    START_GAME PROC FAR
        CALL  INIT_GAME
        CALL  DRAWBLOCKS
        CALL  DISPLAY_HEARTS
        call DisplayScores
        
        ; GET TIME CH Hours, CL Minutes, DH Seconds, DL Hundreths of a second
        CHECK_TIME:     
        ; PADDLE STUFF
            call  draw_paddles

            mov   ah , 01h
            int   16h
            jz    NO_INPUT_ACTION

            CMP   AL, 27                       ; Check if key is ESC
            JE    exit                         ; If ESC, exit program

            call move_crtPlayer_paddle
        NO_INPUT_ACTION:
            call  send_crtPlayer_pad_pos
            call  read_otherPlayer_pad_pos
            MOV   AH, 2CH
            INT   21H

            CMP   DL, AUX_TIME
            JE    CHECK_TIME

            MOV   AUX_TIME, DL


        ; BALL MOVEMENT
            CALL  DELETE_BALL
            CALL  MOVE_BALL_BY_VELOCITY
            CALL  DRAW_BALL

        ; check win condition
            call  CHECK_FOR_WIN
            
            JMP   CHECK_TIME
               
        exit:
        public  EXIT_GAME
        EXIT_GAME PROC FAR           
        ; Clear screen
            MOV   AH, 0
            MOV   AL, 3
            INT   10H

        ; Exit program
            MOV   AH, 4CH
            INT   21H
        EXIT_GAME ENDP
    ENDP START_GAME
main ENDP


CLEAR_WINDOW PROC FAR
	mov al, 03h
	mov ah, 0
	int 10h
	RET
CLEAR_WINDOW ENDP




PUBLIC CHECK_KEYBOARD
CHECK_KEYBOARD PROC FAR
    mov ah, 01h
    INT 16h
    JZ KEYBOARD_CHECK_DONE  ; No key pressed

    mov ah, 0h
    INT 16h

    ; Print Character To Display in blue
    mov ah, 09h
    mov cx, 1
    mov bx, 00001001b
    int 10h
    
    cmp choice, 0
    jne CHECK_FOR_ESC
        
    cmp al, 'p'
    JNE NOT_P
    mov al, 5               ; Signal code for play
    CALL SEND_SERIAL_CHARACTER  ; Send before changing local state
    mov choice, 2
    mov IS_INGAME, 1
    mov CRT_PLAYER, 1
    jmp NOT_ESC
    
NOT_P:
    cmp al, 'c'
    JNE NOT_C
    mov al, 6              ; Signal code for chat
    CALL SEND_SERIAL_CHARACTER  ; Send before changing local state
    mov choice, 1
    CALL CLEAR_WINDOW
    jmp NOT_ESC            
    
NOT_C:
CHECK_FOR_ESC:
    CMP al, 27
    JNZ NOT_ESC 
    jmp exit
        
NOT_ESC:
    CALL SEND_SERIAL_CHARACTER  ; Send before changing local state
    cmp IS_INGAME, 1
    JE KEYBOARD_CHECK_DONE
    CALL MOVE_CURSOR

KEYBOARD_CHECK_DONE:
    RET
CHECK_KEYBOARD ENDP

public TRY_AGAIN
TRY_AGAIN   PROC    FAR
    CALL DELETE_HEARTS
    
    dec PLAYER_LIVES
    JZ DISPLAY_LOOSE_MESSAGE_LABEL

    CALL  DISPLAY_HEARTS
    call RESET_PADDLES
    RET
    
    DISPLAY_LOOSE_MESSAGE_LABEL: 
    call DISPLAY_LOOSE_MESSAGE
    jmp exit
ENDP TRY_AGAIN

END