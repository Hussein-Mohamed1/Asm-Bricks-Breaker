.model small
.stack 100h

.DATA
    AUX_TIME DB 0
.code

INIT_APP PROC NEAR
    ; Set video mode 13h (320x200, 256 colors)
                    mov   ax, 0013h                    ; Set video mode 13h
                    int   10h                          ; Call BIOS interrupt

    ; Clear the screen (fill video memory with 0)
                    mov   ax, 0A000h                   ; Video memory segment address
                    mov   es, ax                       ; ES = video memory
                    xor   di, di                       ; Starting offset in video memory
                    mov   cx, 32000                    ; 320x200 pixels, 1 byte per pixel
                    mov   al, 00h                      ; Black color (0)
                    rep   stosb                        ; Clear the screen
    
                    RET
                    ENDP  INIT_APP

                    EXTRN DRAWBLOCKS:FAR
                    EXTRN DRAW_BALL:FAR
                    EXTRN MOVE_BALL_BY_VELOCITY:FAR
                    EXTRN DELETE_BALL:FAR
                    EXTRN move_paddles:FAR
                    EXTRN draw_paddles:FAR
                    EXTRN CHECK_SCREEN_PIXELS:FAR
                    EXTRN DISPLAY_WIN_MESSAGE:FAR

main PROC
                    MOV   AX, @DATA
                    MOV   DS, AX

                    CALL  INIT_APP
                    CALL  DRAWBLOCKS


    ; GET TIME CH Hours, CL Minutes, DH Seconds, DL Hundreths of a second
    CHECK_TIME:     

    ; PADDLE STUFF
                    call  draw_paddles
                    mov   ah , 01h
                    int   16h
                    jz    NO_INPUT_ACTION

                    CMP   AL, 27                       ; Check if key is ESC
                    JE    exit                         ; If ESC, exit program

                    call  move_paddles

    NO_INPUT_ACTION:
                    MOV   AH, 2CH
                    INT   21H

                    CMP   DL, AUX_TIME
                    JE    CHECK_TIME

                    MOV   AUX_TIME, DL


    ; BALL MOVEMENT
                    CALL  DELETE_BALL
                    CALL  MOVE_BALL_BY_VELOCITY
                    CALL  DRAW_BALL

    ; chexk win condition
                    call  CHECK_SCREEN_PIXELS
                    cmp   al , 1
                    je    GAME_WON
                    JMP   CHECK_TIME
    GAME_WON:       
    call DISPLAY_WIN_MESSAGE
    exit:           
    ; Clear screen
                    MOV   AH, 0
                    MOV   AL, 3
                    INT   10H

    ; Exit program
                    MOV   AH, 4CH
                    INT   21H
main ENDP
END  main