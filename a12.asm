; ***************************************************************

section	.data

; -----
;  Define standard constants.

LF			equ	10			; line feed
NULL		equ	0			; end of string
ESC			equ	27			; escape key

TRUE		equ	1
FALSE		equ	0

SUCCESS		equ	0			; Successful operation
NOSUCCESS	equ	1			; Unsuccessful operation

STDIN		equ	0			; standard input
STDOUT		equ	1			; standard output
STDERR		equ	2			; standard error

SYS_read	equ	0			; call code for read
SYS_write	equ	1			; call code for write
SYS_open	equ	2			; call code for file open
SYS_close	equ	3			; call code for file close
SYS_fork	equ	57			; call code for fork
SYS_exit	equ	60			; call code for terminate
SYS_creat	equ	85			; call code for file open/create
SYS_time	equ	201			; call code for get time

; -----
;  Message strings

header		db	"**********************************************", LF
		db	ESC, "[1m", "Harshad Numbers Program"
		db	ESC, "[0m", LF, LF, NULL
msgStart	db	"--------------------------------------", LF	
		db	"Start Counting", LF, NULL
harMsgMain	db	"Harshad Numbers: ", NULL
msgProgDone	db	LF, LF, "Completed.", LF, NULL

numberLimit	dq	0			; limit (quad)
thdCount	dd	0			; thread Count
prtFlg		db	FALSE		; print harshad numbers?

; -----
;  Globals (used by threads)

STEP		equ	10000
idxCounter	dq	1
hCount		dq	0

myLock1		dq	0
myLock2		dq	0

; -----
;  Thread data structures

pthreadID0	dq	0, 0, 0, 0, 0
pthreadID1	dq	0, 0, 0, 0, 0
pthreadID2	dq	0, 0, 0, 0, 0
pthreadID3	dq	0, 0, 0, 0, 0

; -----
;  Variables for thread function.

msgThread1	db	" ...Thread starting...", LF, NULL

; -----
;  Variables for printMessageValue

newLine		db	LF, NULL
comma		db	", ", NULL

; -----
;  Variables for getArguments function

THREAD_MIN	equ	1
THREAD_MAX	equ	4

LIMIT_MIN	equ	10
LIMIT_MAX	equ	5000000000

PRT_LIMIT	equ	10000
NUMS_PER_LINE	equ	10

errUsage	db	"Usage: ./harshadNums -th <1|2|3|4> ",
		db	"-lm <base14Number> <-pr|-np>", LF, NULL
errOptions	db	"Error, invalid command line options."
		db	LF, NULL
errTHSpec	db	"Error, invalid thread count specifier."
		db	LF, NULL
errTHValue	db	"Error, thread count invalid."
		db	LF, NULL
errLMSpec	db	"Error, invalid limit specifier."
		db	LF, NULL
errLMValue	db	"Error, limit invalid."
		db	LF, NULL
errPSpec	db	"Error, invalid print specifier."
		db	LF, NULL

; -----
;  For dividing quad by 10

qTen	dq	10

; -----
;  Uninitialized data

section	.bss

tmpString	resb	20
hNums		resd	1000


; ***************************************************************

section	.text

; -----
;  External statements for thread functions.

extern	pthread_create, pthread_join

; ================================================================
;  Harshad numbers program.

global main
main:
	push	rbp
	mov	rbp, rsp

; -----
;  Get/check command line arguments

	mov		rdi, rdi			; argc
	mov		rsi, rsi			; argv
	mov		rdx, thdCount
	mov		rcx, numberLimit
	mov		r8, prtFlg
	call	getArguments

	cmp		rax, TRUE
	jne		progDone

	cmp		qword [numberLimit], PRT_LIMIT
	jbe		doHeaders
	mov		byte [prtFlg], FALSE
doHeaders:

; -----
;  Initial actions:
;	Display initial messages

	mov		rdi, header
	call	printString

	mov		rdi, msgStart
	call	printString

	; debug:
	; call 	findHarshadNums

	; mov		r12, qword[idxCounter]
	; cmp		r12, qword[numberLimit]
	; ja		debug_done
	; debug_done:


; -----
;  Create new thread(s)
;	pthread_create(&pthreadID0, NULL, &threadFunction0, NULL);

	; How many threads to create
	mov		r12d, dword[thdCount]
	cmp		r12d, 1
	je		thread1
	cmp		r12d, 2
	je		thread2
	cmp		r12d, 3
	je		thread3

	thread4:
	mov		rdi, pthreadID3
	mov		rsi, NULL
	mov		rdx, findHarshadNums
	mov		rcx, NULL
	call	pthread_create

	thread3:
	mov		rdi, pthreadID2
	mov		rsi, NULL
	mov		rdx, findHarshadNums
	mov		rcx, NULL
	call	pthread_create

	thread2:
	mov		rdi, pthreadID1
	mov		rsi, NULL
	mov		rdx, findHarshadNums
	mov		rcx, NULL
	call	pthread_create

	thread1:
	mov		rdi, pthreadID0
	mov		rsi, NULL
	mov		rdx, findHarshadNums
	mov		rcx, NULL
	call	pthread_create

; -----
;  Wait for thread(s) to complete.
;	pthread_join (pthreadID0, NULL);

	; mov		qword[idxCounter], 1
	; mov		qword[hCount], 0

WaitForThreadCompletion:
	mov		r12, qword[idxCounter]
	cmp		r12, qword[numberLimit]
	ja		WaitForThreadCompletion_done

	; How many threads to attempt to join
	mov		r12d, dword[thdCount]
	cmp		r12d, 1
	je		thread1j
	cmp		r12d, 2
	je		thread2j
	cmp		r12d, 3
	je		thread3j

	thread4j:
	mov		rdi, qword [pthreadID3]
	mov		rsi, NULL
	call	pthread_join

	thread3j:
	mov		rdi, qword [pthreadID2]
	mov		rsi, NULL
	call	pthread_join

	thread2j:
	mov		rdi, qword [pthreadID1]
	mov		rsi, NULL
	call	pthread_join

	thread1j:
	mov		rdi, qword [pthreadID0]
	mov		rsi, NULL
	call	pthread_join

	WaitForThreadCompletion_done:

; -----
;  Display final count

showFinalResults:
	mov		rdi, newLine
	call	printString

	mov		rdi, harMsgMain
	call	printString
	mov		rdi, qword [hCount]
	mov		rsi, tmpString
	call	int2b14
	mov		rdi, tmpString
	call	printString
	mov		rdi, newLine
	call	printString

	cmp		byte [prtFlg], TRUE
	jne		doMsg

	mov		rbx, 0
	mov		r14, 0
prtNumsLoop:
	mov		edi, dword [hNums+rbx*4]
	mov		rsi, tmpString
	call	int2b14
	mov		rdi, tmpString
	call	printString

	inc		r14
	cmp		r14, NUMS_PER_LINE
	jne		skpNewLine
	mov		r14, 0
	mov		rdi, newLine
	call	printString
	jmp		skpComma
skpNewLine:

	mov		r10, qword [hCount]
	dec		r10
	cmp		rbx, r10
	je		skpComma
	mov		rdi, comma
	call	printString
skpComma:

	inc		rbx
	cmp		rbx, qword [hCount]
	jb		prtNumsLoop

; **********
;  Program done, display final message
;	and terminate.

doMsg:
	mov		rdi, msgProgDone
	call	printString

progDone:
	pop		rbp
	mov		rax, SYS_exit			; system call for exit
	mov		rdi, SUCCESS			; return code SUCCESS
	syscall

; ******************************************************************
;  Function getArguments()
;	Get, check, convert, verify range, and return the
;	sequential/parallel option, the limit, and the print flag.

;  Example HLL call:
;	stat = getArguments(argc, argv, &thdConut, &numberLimit, &prtFlg)

;  This routine performs all error checking, conversion of
;  ASCII/base14 to integer, verifies legal range.
;  For errors, applicable message is displayed and FALSE is returned.
;  For good data, all values are returned via addresses with TRUE returned.

;  Command line format (fixed order):
;	-th <1|2|3|4> -lm <base14Number> -pr|-np

; -----
;  Arguments:
;	- rdi: ARGC, value
;	- rsi: ARGV, address
;	- rdx: thread count (dword), address
;	- rcx: limit (qword), address
;	- r8:  print / no print flag (byte), address

global getArguments
getArguments:
	push	r12
	push	r13

	mov		r12, rdi ; rdi used for print now

;----------------------------------------------
; Check for correct argc

	; Usage error
	cmp		r12, 1				
	ja		checkArgc

	mov		rdi, errUsage
	jmp		printErr

	; If correct amnt of args
	checkArgc:
	cmp		r12, 6
	je		checkArgv

	mov		rdi, errOptions
	jmp		printErr

;----------------------------------------------
; Check arguments
; Note: r12 free again

	;----------
	; Check 1st arg (-th)
	checkArgv:
		; Arg = '-th'
		mov		r12, qword[rsi + 8]
		mov		r12d, dword[r12]
		cmp		r12d, 0x0068742d ; -th
		je		check2ndArg

		errArg1:
		mov		rdi, errTHSpec
		jmp		printErr

	;----------
	; Check 2nd arg (1,2,3,4)
	check2ndArg:
		mov		r12, qword[rsi + 16]

		; Cnvt chr to int
		movzx	r12d, word[r12] ; word[] to look for byte + null
		sub		r12d, '0'

		; 1 <= arg2 <= 4
		cmp		r12d, THREAD_MIN
		jl		errArg2			 
		cmp		r12d, THREAD_MAX
		ja		errArg2

		; Pass thd cnt by ref
		mov		dword[rdx], r12d
		jmp		check3rdArg

		errArg2:
		mov		rdi, errTHValue
		jmp		printErr

	;----------
	; Check 3rd arg (-lm)
	check3rdArg:
		mov		r12, qword[rsi + 24]
		mov		r12d, dword[r12]
		cmp		r12d, 0x006d6c2d ; -lm
		je		check5thArg

		errArg3:
		mov		rdi, errLMSpec
		jmp		printErr

	;----------
	; Check 5th arg (-pr|-np)
	; 5th before 4th due to limit 1000 changing -pr to -np
	check5thArg:
		mov		r12, qword[rsi + 40]
		mov		r12d, dword[r12]
		cmp		r12d, 0x0072702d ; -pr
		je		isPR
		cmp		r12d, 0x00706e2d ; -np
		jne		errArg5

		; ret r8
		mov		byte[r8], FALSE
		jmp 	check4thArg
		isPR:
		mov		byte[r8], TRUE
		jmp 	check4thArg

		errArg5:
		mov		rdi, errPSpec
		jmp		printErr

	;----------
	; Check 4th arg 
	; 4th last as b142int uses mul. rdx had an arg in it
	check4thArg:
		mov		r12, qword[rsi + 32]

		; Note: rsi free to use now

		; Cnvt b14 to dec
		mov		rdi, r12
		xor		rsi, rsi ; Empty rsi, returns # from call
		call	b142int

		; When value isn't base-14
		cmp		rax, FALSE
		je		errArg4

		; LIMIT_MIN <= arg4 <= LIMIT_MAX
		mov		rdx, LIMIT_MIN
		cmp		rsi, rdx
		jb		errArg4
		mov		rdx, LIMIT_MAX
		cmp		rsi, rdx
		ja		errArg4

		; Pass lm cnt by ref
		mov		qword[rcx], rsi
		jmp		chkArg_Done

		errArg4:
		mov		rdi, errLMValue
		jmp		printErr

;----------------------------------------------
; Return True
; Function done

	chkArg_Done:
	mov		rax, TRUE
	jmp		getArguments_done

;----------------------------------------------
; Error

	printErr:
	call	printString
	mov		rax, FALSE

	getArguments_done:
	pop		r13
	pop		r12
ret

; ******************************************************************
;  Thread function, findHarshadNums()
;	Find harshad numbers.

; -----
;  Arguments:
;	N/A (global variable accessed)
;  Returns:
;	N/A (global variable accessed)

global findHarshadNums
findHarshadNums:
	push	r12
	push	r13
	push	r14

	mov		r14, STEP

	; Get idxCounter, inc it
	; Note: Don't use rax. Lock uses rax
	call 	spinLock1
		mov		r12, qword[idxCounter]
		add		qword[idxCounter], r14
	call	spinUnlock1

	hNumLP:
	; If all nums checked, immediately exit
	cmp		r12, qword[numberLimit]
	ja		findHarshadNums_done

	; Divide number by 10 to get individual digits
	; Loops until can't divide anymore
	mov		rax, r12
	xor		rdx, rdx
	xor		r13, r13
	addDigits:
		div		qword[qTen]
		add		r13, rdx
		xor		rdx, rdx

		cmp		rax, 0
		jne		addDigits

	; Check if Harshad Number
	mov		rax, r12
	div		r13
	cmp		rdx, 0
	jne		notHNum

	; If hNum, update count
	; If < 1000 or no print, add to array
	; Note: Again, don't use rax
	call	spinLock2
		inc		qword[hCount]
		cmp		byte[prtFlg], FALSE
		je		noPrint

		mov		r13, qword[hCount]
		mov		dword[hNums + r13 * 4], r12d
		noPrint:
	call	spinUnlock2

	notHNum:

	; Loop
	inc		r12
	dec		r14
	cmp		r14, 0
	jae		hNumLP

	findHarshadNums_done:
	pop		r14
	pop 	r13
	pop		r12
ret

; ******************************************************************
;  Mutex lock
;	checks lock (shared gloabl variable)
;		if unlocked, sets lock
;		if locked, loops to recheck until lock is free

global	spinLock1
spinLock1:
	mov	rax, 1			; Set the RAX register to 1.

lock	xchg	rax, qword [myLock1]	; Atomically swap the RAX register with
					;  the lock variable.
					; This will always store 1 to the lock, leaving
					;  the previous value in the RAX register.

	test	rax, rax	        ; Test RAX with itself. Among other things, this will
					;  set the processor's Zero Flag if RAX is 0.
					; If RAX is 0, then the lock was unlocked and
					;  we just locked it.
					; Otherwise, RAX is 1 and we didn't acquire the lock.

	jnz	spinLock1		; Jump back to the MOV instruction if the Zero Flag is
					;  not set; the lock was previously locked, and so
					; we need to spin until it becomes unlocked.
	ret

; -----

global	spinLock2
spinLock2:
	mov	rax, 1			; Set the RAX register to 1.

lock	xchg	rax, qword [myLock2]	; Atomically swap the RAX register with
					;  the lock variable.
					; This will always store 1 to the lock, leaving
					;  the previous value in the RAX register.

	test	rax, rax	        ; Test RAX with itself. Among other things, this will
					;  set the processor's Zero Flag if RAX is 0.
					; If RAX is 0, then the lock was unlocked and
					;  we just locked it.
					; Otherwise, RAX is 1 and we didn't acquire the lock.

	jnz	spinLock2		; Jump back to the MOV instruction if the Zero Flag is
					;  not set; the lock was previously locked, and so
					; we need to spin until it becomes unlocked.
	ret

; ******************************************************************
;  Mutex unlock
;	unlock the lock (shared global variable)

global	spinUnlock1
spinUnlock1:
	mov	rax, 0			; Set the RAX register to 0.

	xchg	rax, qword [myLock1]	; Atomically swap the RAX register with
					;  the lock variable.
	ret

global	spinUnlock2
spinUnlock2:
	mov	rax, 0			; Set the RAX register to 0.

	xchg	rax, qword [myLock2]	; Atomically swap the RAX register with
					;  the lock variable.
	ret

; ******************************************************************
;  Function: Check and convert ASCII/base-14 string to integer.

; Arguments
; rdi: String Address (base-14)
; rsi: Int Value (conversion)

; Returns
; TRUE/FALSE if converted or not
; Int value of b14 string
global b142int
b142int:
	push	r12
	push	r13
	push 	r14

	mov		r12, 0   ; Count of chr
	mov		r13, 0 	 ; Count of spaces
	mov		r14d, 14 ; For 14^x

	; Get count of total chr in str
	; Also finds count of spaces at beg
	b14ChrCnt:
		cmp 	byte[rdi + r12], NULL	; NULL terminated
		je		b14ChrCnt_done

		cmp		byte[rdi + r12], ' '	; Find spaces, inc space count
		jne		notSpace
		inc		r13
		notSpace:

		inc		r12
		jmp		b14ChrCnt	
	b14ChrCnt_done:
	dec		r12			; Str starts at 0

	sub		r12, r13	; total - spaces = chr count
	

	; Start at LSD, read chr until spaces (r12 < r13)
	cvt2int:
		cmp		byte[rdi + r13], NULL
		je		cvt2int_done

		push	r12

        ;------------------------------
        ; Check bad input
        ; Convert to int

        ; a-d
        cmp     byte[rdi + r13], 'a'
        jb      notLowercase
        cmp     byte[rdi + r13], 'd'
        ja      notB14

        sub     byte[rdi + r13], 'W'
        jmp     toInt_done

        ; A-D
        notLowercase:
        cmp     byte[rdi + r13], 'A'
        jb      notChr
        cmp     byte[rdi + r13], 'D'
        ja      notB14
        
        sub     byte[rdi + r13], '7'
        jmp     toInt_done

        ; 0-9
        notChr:
        cmp     byte[rdi + r13], '0'
        jb      notB14
        cmp     byte[rdi + r13], '9'
        ja      notB14

        sub     byte[rdi + r13], '0'

		toInt_done:

		;------------------------------
		; Get dec value
		
		mov		rax, 1 ; 14^0 = 1
		pow14:
			cmp		r12, 0
			je		pow14_done

			mul 	r14d

			dec		r12
			jmp		pow14
		pow14_done:

		movzx	r12, byte[rdi + r13]
		mul		r12
		add		rsi, rax

		pop		r12

		dec		r12
		inc		r13
		jmp 	cvt2int
	cvt2int_done:

	; Succesful conversion
	mov		rax, TRUE
	jmp		b142int_done

	; Failed conversion
	notB14:
		pop 	r12
		mov		rax, FALSE
		jmp		b142int_done

	b142int_done:
	pop		r14
	pop		r13
	pop		r12
ret

; ******************************************************************
;  Convert integer to ASCII/base-14 string.
;	Note, no error checking done on integer.
;	No leadings paces placed in string.

; -----
;  HLL Call:
;	int2b14(integer, strAddr)

; -----
;  Arguments:
;	- rdi: integer, value
;	- rsi: string, address

; -----
;  Returns:
;	ASCII/base-14 string (NULL terminated)

global  int2b14
int2b14:
	push	r12
	push	r13
	push	r14

	mov		rax, rdi	; Integer to div/cnvt
	mov		rdi, 14 	; For div
	mov		r13, 0		; Cnt of chr

	; Get values and cnvt values to chr
	toB14:
		xor		rdx, rdx
		inc		r13
		idiv 	rdi
		add		rdx, '0'
		cmp		rdx, '9'
		jle 	isNumb
		add		rdx, 7 ; A,B,C,D
		
		isNumb:
		push	rdx 		; Storing all in stack
		xor		rdx, rdx 	; For div

		cmp		rax, 0 ; Done when no more divs
		jg		toB14

	; Create the string
	mov		r12, 0 ; Indx in str
	makeString: 
		cmp		r12, r13
		je		makeString_done

		pop		rax
		mov		byte[rsi + r12], al

		inc		r12
		jmp		makeString
	makeString_done:

	mov		byte[rsi + r12], NULL

	pop		r14
	pop		r13
	pop		r13
ret

; ******************************************************************
;  Generic procedure to display a string to the screen.
;  String must be NULL terminated.
;  Algorithm:
;	Count characters in string (excluding NULL)
;	Use syscall to output characters

;  Arguments:
;	- address, string
;  Returns:
;	nothing

global	printString
printString:

; -----
;  Count characters to write.

	mov	rdx, 0
strCountLoop:
	cmp	byte [rdi+rdx], NULL
	je	strCountLoopDone
	inc	rdx
	jmp	strCountLoop
strCountLoopDone:
	cmp	rdx, 0
	je	printStringDone

; -----
;  Call OS to output string.

	mov	rax, SYS_write			; system code for write()
	mov	rsi, rdi			; address of characters to write
	mov	rdi, STDOUT			; file descriptor for standard in
						; rdx=count to write, set above
	syscall					; system call

; -----
;  String printed, return to calling routine.

printStringDone:
	ret

; ******************************************************************

