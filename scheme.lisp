(DEFVAR *ALARMCLOCK-RUNTIME-ALARMTIME* 0)
(DEFVAR *ALARMCLOCK-RUNTIME-ENABLED* NIL)

(DEFUN ALARMCLOCK (TIMERNAME Q)
       (COND ((EQ TIMERNAME 'RUNTIME)
              (COND ((AND (NUMBERP Q)
                          (PLUSP Q))
                     (SETQ *ALARMCLOCK-RUNTIME-ALARMTIME* (+ (GET-INTERNAL-RUN-TIME)
                                                             (FLOOR (* Q INTERNAL-TIME-UNITS-PER-SECOND)
                                                                    1000000))
                           *ALARMCLOCK-RUNTIME-ENABLED* T))
                    (T (SETQ *ALARMCLOCK-RUNTIME-ENABLED* NIL))))
             (T (ERROR "UNSUPPORTED TIMERNAME - ALARMCLOCK ~S" TIMERNAME))))

(DEFUN ALARMCLOCKPOLL ()
       (COND ((BOUNDP 'ALARMCLOCK)
              (COND ((AND *ALARMCLOCK-RUNTIME-ENABLED*
                         (>= (GET-INTERNAL-RUN-TIME) *ALARMCLOCK-RUNTIME-ALARMTIME*))
                     (SETQ *ALARMCLOCK-RUNTIME-ENABLED* NIL)
                     (FUNCALL (SYMBOL-VALUE 'ALARMCLOCK) '(RUNTIME)))))
             (T (ERROR "ALARMCLOCK NOT BOUND TO ANY HANDLER - ALARMCLOCKPOLL"))))

(DEFMACRO DEFPROP (SYM VAL IND)
  `(SETF (GET ',SYM ',IND) ',VAL))

(DEFUN PUTPROP (SYM VAL IND)
  (SETF (GET SYM IND) VAL))

(DEFUN ASSQ (ITEM ALIST)
  (ASSOC ITEM ALIST :TEST #'EQ))

(DEFUN MEMQ (ITEM LIST)
  (MEMBER ITEM LIST :TEST #'EQ))

(DEFUN DELQ (ITEM LIST)
  (DELETE ITEM LIST :TEST #'EQ))

(DEFUN SYMEVAL (X)
       (SYMBOL-VALUE X))

(SETQ *PRINT-CIRCLE* T)




(DECLAIM (SPECIAL **EXP** **UNEVLIS** **ENV** **EVLIS** **PC** **CLINK** **VAL** **TEM**
                     **TOP** **QUEUE** **TICK** **PROCESS** **QUANTUM**
                     VERSION LISPVERSION))

(DEFUN SCHEME ()
       (SETQ VERSION '|AI Memo 349 SCHEME|  LISPVERSION (LISP-IMPLEMENTATION-VERSION))
       (TERPRI)
       (PRINC '|This is SCHEME |)
       (PRINC VERSION)
       (PRINC '| running in LISP |)
       (PRINC (LISP-IMPLEMENTATION-TYPE)) (PRINC '| |) (PRINC LISPVERSION)
       (SETQ **ENV** NIL  **QUEUE** NIL
             **PROCESS** (CREATE!PROCESS '(**TOP** '|SCHEME -- Toplevel|)))
       (SWAPINPROCESS)
       (ALARMCLOCK 'RUNTIME **QUANTUM**)
       (MLOOP))

(SETQ **TOP**
      '(BETA (LAMBDA (**MESSAGE**)
                (LABELS ((**TOP1**
                          (LAMBDA (**IGNORE1** **IGNORE2** **IGNORE3**)
                             (**TOP1** (TERPRI) (PRINC '|==> |)
                                       (PRINT (SET '* (EVALUATE (READ))))))))
                    (**TOP1** (TERPRI) (PRINC **MESSAGE**) NIL)))
             NIL))

(DEFUN SETTICK (X) (SETQ **TICK** T))

(SETQ **QUANTUM** 10000 ALARMCLOCK 'SETTICK)

(DEFUN MLOOP ()
       (DO ((**TICK** NIL)) (NIL)       ;DO forever
           (ALARMCLOCKPOLL)     ;Simulate MacLisp ALARMCLOCK func
           (AND **TICK** (ALLOW) (SCHEDULE))
           (FUNCALL **PC**)))

(DEFUN ALLOW ()
       ((LAMBDA (VCELL)
                (COND (VCELL (CDR VCELL))
                      (T T)))
        (ASSQ '*ALLOW* **ENV**)))

(DEFUN SCHEDULE ()
       (COND (**QUEUE**
              (SWAPOUTPROCESS)
              (NCONC **QUEUE** (LIST **PROCESS**))
              (SETQ **PROCESS** (CAR **QUEUE**)
                    **QUEUE** (CDR **QUEUE**))
              (SWAPINPROCESS)))
       (SETQ **TICK** NIL)
       (ALARMCLOCK 'RUNTIME **QUANTUM**))

(DEFUN SWAPOUTPROCESS ()
       ((LAMBDA (**CLINK**)
                (PUTPROP **PROCESS** (SAVEUP **PC**) 'CLINK)
                (PUTPROP **PROCESS** **VAL** 'VAL))
         **CLINK**))

(DEFUN SWAPINPROCESS ()
       (SETQ **CLINK** (GET **PROCESS** 'CLINK)
             **VAL** (GET **PROCESS** 'VAL))
       (RESTORE))

(DEFUN PRIMOP (X)
       (AND (SYMBOLP X) (FBOUNDP X) (NOT (MACRO-FUNCTION X)) (NOT (SPECIAL-OPERATOR-P X))))

(DEFUN SAVEUP (RETAG)
       (SETQ **CLINK** (LIST **EXP** **UNEVLIS** **ENV** **EVLIS** RETAG **CLINK**)))

(DEFUN RESTORE ()
  (PROG (TEMP)
       (SETQ TEMP (OR **CLINK**
                     (ERROR "PROCESS RAN OUT - RESTORE ~S" **EXP**))
             **EXP** (CAR TEMP)
              TEMP (CDR TEMP)
             **UNEVLIS** (CAR TEMP)
              TEMP (CDR TEMP)
             **ENV** (CAR TEMP)
              TEMP (CDR TEMP)
             **EVLIS** (CAR TEMP)
              TEMP (CDR TEMP)
             **PC** (CAR TEMP)
              TEMP (CDR TEMP)
             **CLINK** (CAR TEMP))))

(DEFUN AEVAL ()
       (COND ((ATOM **EXP**)
              (COND ((NUMBERP **EXP**)
                     (SETQ **VAL** **EXP**)
                     (RESTORE))
                    ((STRINGP **EXP**)      ;Note: added strings
                     (SETQ **VAL** **EXP**)
                     (RESTORE))
                    ((PRIMOP **EXP**)
                     (SETQ **VAL** **EXP**)
                     (RESTORE))
                    ((SETQ **TEM** (ASSQ **EXP** **ENV**))
                     (SETQ **VAL** (CDR **TEM**))
                     (RESTORE))
                    (T (SETQ **VAL** (SYMEVAL **EXP**))
                       (RESTORE))))
             ((ATOM (CAR **EXP**))
              (COND ((SETQ **TEM** (GET (CAR **EXP**) 'AINT))
                     (SETQ **PC** **TEM**))
                    ((EQ (CAR **EXP**) 'LAMBDA)
                     (SETQ **VAL** (LIST 'BETA **EXP** **ENV**))
                     (RESTORE))
                    ((SETQ **TEM** (GET (CAR **EXP**) 'AMACRO))
                     (SETQ **EXP** (FUNCALL **TEM** **EXP**)))
                    (T (SETQ **EVLIS** NIL
                             **UNEVLIS** **EXP**
                             **PC** 'EVLIS))))
             ((EQ (CAAR **EXP**) 'LAMBDA)
              (SETQ **EVLIS** (LIST (CAR **EXP**))
                    **UNEVLIS** (CDR **EXP**)
                    **PC** 'EVLIS))
             (T (SETQ **EVLIS** NIL
                      **UNEVLIS** **EXP**
                      **PC** 'EVLIS))))

(DEFUN EVLIS ()
       (COND ((NULL **UNEVLIS**)
              (SETQ **EVLIS** (REVERSE **EVLIS**))
              (COND ((ATOM (CAR **EVLIS**))
                     (SETQ **VAL** (APPLY (CAR **EVLIS**) (CDR **EVLIS**)))
                     (RESTORE))
                    ((EQ (CAAR **EVLIS**) 'LAMBDA)
                     (SETQ **ENV** (PAIRLIS (CADAR **EVLIS**) (CDR **EVLIS**) **ENV**)
                           **EXP** (CADDAR **EVLIS**)
                           **PC** 'AEVAL))
                    ((EQ (CAAR **EVLIS**) 'BETA)
                     (SETQ **ENV** (PAIRLIS (CADR (CADAR **EVLIS**))
                                            (CDR **EVLIS**)
                                            (CADDAR **EVLIS**))
                           **EXP** (CADDR (CADAR **EVLIS**))
                           **PC** 'AEVAL))
                    ((EQ (CAAR **EVLIS**) 'DELTA)
                     (SETQ **CLINK** (CADAR **EVLIS**))
                     (RESTORE))
                    (T (ERROR "BAD FUNCTION - EVARGLIST ~S" **EXP**))))
             (T (SAVEUP 'EVLIS1)
                (SETQ **EXP** (CAR **UNEVLIS**)
                      **PC** 'AEVAL))))

(DEFUN EVLIS1 ()
       (SETQ **EVLIS** (CONS **VAL** **EVLIS**)
             **UNEVLIS** (CDR **UNEVLIS**)
             **PC** 'EVLIS))

(DEFPROP EVALUATE EVALUATE AINT)

(DEFUN EVALUATE ()
       (SAVEUP 'EVALUATE1)
       (SETQ **EXP** (CADR **EXP**)
             **PC** 'AEVAL))

(DEFUN EVALUATE1 ()
       (SETQ **EXP** **VAL**
             **PC** 'AEVAL))

(DEFPROP IF AIF AINT)

(DEFUN AIF ()
       (SAVEUP 'AIF1)
       (SETQ **EXP** (CADR **EXP**)
             **PC** 'AEVAL))

(DEFUN AIF1 ()
       (COND (**VAL** (SETQ **EXP** (CADDR **EXP**)))
             (T (SETQ **EXP** (CADDDR **EXP**))))
       (SETQ **PC** 'AEVAL))

(DEFPROP QUOTE AQUOTE AINT)

(DEFUN AQUOTE ()
       (SETQ **VAL** (CADR **EXP**))
       (RESTORE))

(DEFPROP LABELS ALABELS AINT)

(DEFUN ALABELS ()
       (SETQ **TEM** (MAPCAR #'(LAMBDA (DEF)
                                  (CONS (CAR DEF)
                                        (LIST 'BETA (CADR DEF) NIL)))
                         (CADR **EXP**)))
       (MAPC #'(LAMBDA (VC) (RPLACA (CDDDR VC) **TEM**)) **TEM**)
       (SETQ **ENV** (NCONC **TEM** **ENV**)
             **EXP** (CADDR **EXP**)
             **PC** 'AEVAL))

(DEFUN CREATE!PROCESS (EXP)
       ((LAMBDA (**PROCESS** **EXP** **ENV** **UNEVLIS** **EVLIS** **PC** **CLINK** **VAL**)
                (SWAPOUTPROCESS)
                **PROCESS**)
        (GENSYM)
        EXP
        **ENV**
        NIL
        NIL
        'AEVAL
        (LIST NIL NIL NIL NIL 'TERMINATE NIL)
        NIL))

(DEFUN START!PROCESS (P)
       (COND ((OR (NOT (ATOM P)) (NOT (GET P 'CLINK)))
              (ERROR "BAD PROCESS -- START!PROCESS ~S" **EXP**)))
       (OR (EQ P **PROCESS**) (MEMQ P **QUEUE**)
           (SETQ **QUEUE** (NCONC **QUEUE** (LIST P))))
       P)

(DEFUN STOP!PROCESS (P)
       (COND ((MEMQ P **QUEUE**)
              (SETQ **QUEUE** (DELQ P **QUEUE**)))
             ((EQ P **PROCESS**) (TERMINATE)))
       P)

(DEFUN TERMINATE ()
       (COND ((NULL **QUEUE**)
              (SETQ **PROCESS**
                    (CREATE!PROCESS '(**TOP** '|SCHEME -- QUEUEOUT|))))
             (T (SETQ **PROCESS** (CAR **QUEUE**)
                      **QUEUE** (CDR **QUEUE**))))
       (SETQ **CLINK** (GET **PROCESS** 'CLINK))
       (SETQ **VAL** (GET **PROCESS** 'VAL))
       'TERMINATE-VALUE)

(DEFPROP EVALUATE!UNINTERRUPTIBLY EVALUATE!UNINTERRUPTIBLY AINT)

(DEFUN EVALUATE!UNINTERRUPTIBLY ()
       (SETQ **ENV** (ACONS '*ALLOW* NIL **ENV**)
             **EXP** (CADR **EXP**)
             **PC** 'AEVAL))

(DEFPROP DEFINE DEFINE AINT)

(DEFUN DEFINE ()
       (SET (CADR **EXP**) (LIST 'BETA (CADDR **EXP**) NIL))
       (SETQ **VAL** (CADR **EXP**))
       (RESTORE))

(DEFUN ASET (VAR VALU)
       (SETQ **TEM** (ASSQ VAR **ENV**))
       (COND (**TEM** (RPLACD **TEM** VALU))
             (T (SET VAR VALU)))
       VALU)

(DEFPROP CATCH ACATCH AINT)

(DEFUN ACATCH ()
       (SETQ **ENV** (ACONS (CADR **EXP**) (LIST 'DELTA **CLINK**) **ENV**)
             **EXP** (CADDR **EXP**)
             **PC** 'AEVAL))




(DEFPROP AND AAND AMACRO)

(DEFUN AAND (EXP)
       (AAND-EXPAND (CDR EXP)))

(DEFUN AAND-EXPAND (ARGS)
       (COND ((NULL ARGS) T)
             ((NULL (CDR ARGS)) (CAR ARGS))
             (T (LIST 'IF (CAR ARGS) (AAND-EXPAND (CDR ARGS)) NIL))))

(DEFPROP OR AOR AMACRO)

(DEFUN AOR (EXP)
       (AOR-EXPAND (CDR EXP)))

(DEFUN AOR-EXPAND (ARGS)
       (COND ((NULL ARGS) NIL)
             ((NULL (CDR ARGS)) (CAR ARGS))
             (T ((LAMBDA (TEMP)
                     (LIST (LIST 'LAMBDA
                                 (LIST TEMP)
                                 (LIST 'IF TEMP TEMP (AOR-EXPAND (CDR ARGS))))
                           (CAR ARGS)))
                 (GENSYM)))))

(DEFPROP BLOCK ABLOCK AMACRO)

(DEFUN ABLOCK (EXP)
       (ABLOCK-EXPAND (CDR EXP)))

(DEFUN ABLOCK-EXPAND (ARGS)
       (COND ((NULL ARGS) NIL)
             ((NULL (CDR ARGS)) (CAR ARGS))
             (T (LIST (LIST 'LAMBDA
                            (LIST (GENSYM))
                            (ABLOCK-EXPAND (CDR ARGS)))
                      (CAR ARGS)))))

(DEFPROP COND ACOND AMACRO)

(DEFUN ACOND (EXP)
       (ACOND-EXPAND (CDR EXP)))

(DEFUN ACOND-EXPAND (CLAUSES)
       (COND ((NULL CLAUSES) NIL)
             ((EQ (CAAR CLAUSES) 'T) (CONS 'BLOCK (CDAR CLAUSES)))
             (T (LIST 'IF
                      (CAAR CLAUSES)
                      (CONS 'BLOCK (CDAR CLAUSES))
                      (ACOND-EXPAND (CDR CLAUSES))))))

(DEFPROP DO ADO AMACRO)

(DEFUN ADO (EXP)
       ((LAMBDA (DOLOOP)
            (LIST 'LABELS
                  (LIST (LIST DOLOOP
                              (LIST 'LAMBDA
                                    (CONS (GENSYM) (MAPCAR #'CAR (CADR EXP)))
                                    (LIST 'IF
                                          (CAADDR EXP)
                                          (CONS 'BLOCK (CDADDR EXP))
                                          (CONS DOLOOP (CONS (CONS 'BLOCK (CDDDR EXP))
                                                             (MAPCAR #'(LAMBDA (SPEC)
                                                                           (COND ((CDDR SPEC) (CADDR SPEC))
                                                                                 (T (CAR SPEC))))
                                                                     (CADR EXP))))))))
                  (CONS DOLOOP (CONS NIL (MAPCAR #'CADR (CADR EXP))))))
        (GENSYM)))


