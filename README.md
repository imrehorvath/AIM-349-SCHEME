# AIM-349-SCHEME
Revive the original Scheme interpreter that was published in the AIM-349 by Sussman and Steele in 1975

## About

The Scheme interpreter that was published in the [AIM-349 by Gerald Jay Sussman and Guy Lewis Steele Jr. back in December 1975](https://research.scheme.org/lambda-papers/lambda-papers-scheme-report.html) was wrintten in [MacLisp](https://en.wikipedia.org/wiki/Maclisp) an old LISP dialect that had some versions created for ITS, Multics, etc.
The intention of this project is to revive that original Scheme interpreter so it can be tinkered with, by "porting" it to a modern and standard [Common Lisp](https://en.wikipedia.org/wiki/Common_Lisp), so it can run anywhere where Common Lisp is available.

## Implementation Notes

1. Keep the original Scheme interpreter that was published, and apply changes only when necessary and keep them minimal.
2. Interactive, REPL-based usage in mind for tinkering.
3. The A-list representation has been changed, so it uses the usual dotted-pair, insted of the two element proper-list for the key-value association. (Environment-structure)
4. Syntax changes like `DECLAIM` insted of `DECLARE` for the special variables followed-up.
5. Shims for the timer-based alarmclock functionality has been added. (These were available in the ITS and Multics MacLisp versions but are absent in modern Common Lisp)
6. Last but not least, the "missing" AMACROs have been re-created, based on the hints in the AI Memo. (This makes it possible to run all the Scheme examples directly, those which were publised in the AI Memo)

## Run the Scheme Interpreter in Common Lisp

The [GNU CLISP](https://www.gnu.org/software/clisp/) interpreter has been used for this demo as it has nice, redline-based REPL. The Scheme code used below in the demo run, are either directly taken from the AI Memo or is a slightly modified version of the original.

As usual first we load the interpreter by `LOAD`, then run the Toplevel calling `(SCHEME)`. When we are done, we can simply exit to the shell by calling `(QUIT)`.

**Note:** Some of the example outputs have been abbreviated for improved readability, like those with closures and continuations.

```
[1]> (LOAD "scheme.lisp")
;; Loading file scheme.lisp ...
;; Loaded file scheme.lisp
#P"/Users/<user>/AIM-349-SCHEME/scheme.lisp"
[2]> (SCHEME)

This is SCHEME AI Memo 349 SCHEME running in LISP CLISP 2.49.92 (2018-02-18) (built on tahoe-arm64.local [127.0.0.1])
SCHEME -- Toplevel
==> (DEFINE COUNT-ATOM
    (LAMBDA (L)
        (LABELS ((COUNTCAR
                  (LAMBDA (L)
                      (IF (ATOM L) 1
                          (+ (COUNTCAR (CAR L))
                             (COUNTCDR (CDR L))))))
                 (COUNTCDR
                  (LAMBDA (L)
                      (IF (ATOM L)
                          (IF (NULL L) 0 1)
                          (+ (COUNTCAR (CAR L))
                             (COUNTCDR (CDR L)))))))
           (COUNTCDR L))))

COUNT-ATOM 
==> (COUNT-ATOM '(1 2 (3 NIL (5))))

5 
==> (DEFINE FACT
    (LAMBDA (N) (IF (= N 0) 1
                    (* N (FACT (- N 1))))))

FACT 
==> (FACT 7)

5040 
==> (DEFINE FACT
    (LAMBDA (N)
        (LABELS ((FACT1 (LAMBDA (M ANS)
                            (IF (= M 0) ANS
                                (FACT1 (- M 1)
                                       (* M ANS))))))
                 (FACT1 N 1))))

FACT 
==> (FACT 7)

5040 
==> (DEFINE FACT
    (LAMBDA (N C)
        (IF (= N 0) (C 1)
            (FACT (- N 1)
                  (LAMBDA (A) (C (* N A)))))))

FACT 
==> (FACT 7 (LAMBDA (X) X))

5040 
==> (DEFINE CONS-CELL
    (LAMBDA (CONTENTS)
        (LABELS ((THE-CELL
                  (LAMBDA (MSG)
                      (IF (EQ MSG 'CONTENTS?) CONTENTS
                          (IF (EQ MSG 'CELL?) 'YES
                              (IF (EQ (CAR MSG) '<-)
                                  (BLOCK (ASET 'CONTENTS (CADR MSG))
                                         THE-CELL)
                                  (ERROR "UNRECOGNIZED MESSAGE ~S - CONS-CELL" MSG)))))))
                THE-CELL)))

CONS-CELL 
==> (ASET 'ACELL (CONS-CELL 'FOO))

<closure1>
==> (ACELL 'CELL?)

YES 
==> (ACELL 'CONTENTS?)

FOO 
==> (ACELL '(<- BAR))

<closure1>
==> (ACELL 'CONTENTS?)

BAR 
==> (DEFINE FAV-SQRT
    (LAMBDA (X EPSILON)
        ((LAMBDA (ANS LOOPTAG)
             (CATCH RETURNTAG
                    (BLOCK
                        (ASET 'LOOPTAG (CATCH M M))
                        (IF (< (ABS (- (* ANS ANS) X)) EPSILON)
                            (RETURNTAG ANS)
                            NIL)
                        (ASET 'ANS (/ (+ (/ X ANS) ANS) 2.0))
                        (LOOPTAG LOOPTAG))))
         1.0
         NIL)))

FAV-SQRT 
==> (FAV-SQRT 81 0.01)

9.000011 
==> (DEFINE REV
    (LAMBDA (L)
        (DO ((L1 L (CDR L1))
             (ANS NIL (CONS (CAR L1) ANS)))
            ((NULL L1) ANS))))

REV 
==> (REV '(5 4 3 2 1))

(1 2 3 4 5) 
==> (DEFINE FRINGE
    (LAMBDA (TREE)
        (LABELS ((FRINGE1
                  (LAMBDA (NODE ALT)
                      (IF (ATOM NODE)
                          (LAMBDA (MSG)
                              (IF (EQ MSG 'FIRST) NODE
                                  (IF (EQ MSG 'NEXT) (ALT)
                                      (ERROR "UNRECOGNIZED MESSAGE ~S - FRINGE" MSG))))
                          (FRINGE1 (CAR NODE)
                                   (LAMBDA () (FRINGE1 (CDR NODE) ALT)))))))
                (FRINGE1 TREE
                         (LAMBDA ()
                             (LAMBDA (MSG) (IF (EQ MSG 'FIRST) '*EOF*
                                               (ERROR "MESSAGE ~S ON EMPTY/EXHAUSTED TREE - FRINGE" MSG))))))))

FRINGE 
==> (DEFINE SAMEFRINGE
    (LAMBDA (T1 T2)
        (DO ((C1 (FRINGE T1) (C1 'NEXT))
             (C2 (FRINGE T2) (C2 'NEXT)))
            ((OR (NOT (EQ (C1 'FIRST) (C2 'FIRST)))
                 (EQ (C1 'FIRST) '*EOF*)
                 (EQ (C2 'FIRST) '*EOF*))
             (EQ (C1 'FIRST) (C2 'FIRST))))))

SAMEFRINGE 
==> (SAMEFRINGE '(1 2 (4 3)) '(1 2 (3 4)))

NIL 
==> (SAMEFRINGE '(1 2 3 (4)) '(1 2 (3 4)))

T 
==> (DEFINE NFIRST
    (LAMBDA (E N)
        (IF (= N 0) NIL
            (CONS (CAR E) (NFIRST (CDR E) (- N 1))))))

NFIRST 
==> (DEFINE NREST
    (LAMBDA (E N)
        (IF (= N 0) E
            (NREST (CDR E) (- N 1)))))

NREST 
==> (DEFINE MATCH
    (LAMBDA (PATTERN EXPRESSION)
        (LABELS ((MATCH1
            (LAMBDA (P E ALIST LOSE)
                (IF (NULL P) (IF (NULL E) (LIST ALIST LOSE) (LOSE))
                    (IF (ATOM (CAR P))
                        (IF (NULL E) (LOSE)
                            (IF (EQ (CAR E) (CAR P))
                                (MATCH1 (CDR P) (CDR E) ALIST LOSE)
                                (LOSE)))
                        (IF (EQ (CAAR P) 'THV)
                            (IF (NULL E) (LOSE)
                                ((LAMBDA (V)
                                     (IF V (IF (EQ (CAR E) (CADR V))
                                               (MATCH1 (CDR P) (CDR E) ALIST LOSE)
                                               (LOSE))
                                         (MATCH1 (CDR P) (CDR E)
                                                 (CONS (LIST (CADAR P) (CAR E)) ALIST)
                                                 LOSE)))
                                 (ASSQ (CADAR P) ALIST)))
                            (IF (EQ (CAAR P) 'THV*)
                                ((LAMBDA (V)
                                     (IF V
                                         (IF (< (LENGTH E) (LENGTH (CADR V))) (LOSE)
                                             (IF (EQUAL (NFIRST E (LENGTH (CADR V)))
                                                        (CADR V))
                                                 (MATCH1 (CDR P)
                                                         (NREST E (LENGTH (CADR V)))
                                                         ALIST
                                                         LOSE)
                                                 (LOSE)))
                                         (LABELS ((MATCH*
                                             (LAMBDA (N)
                                                 (IF (> N (LENGTH E)) (LOSE)
                                                     (MATCH1 (CDR P) (NREST E N)
                                                             (CONS (LIST (CADAR P)
                                                                         (NFIRST E N))
                                                                   ALIST)
                                                             (LAMBDA ()
                                                                 (MATCH* (+ N 1))))))))
                                                 (MATCH* 0))))
                                 (ASSQ (CADAR P) ALIST))
                                (LOSE))))))))
                (MATCH1 PATTERN
                        EXPRESSION
                        NIL
                        (LAMBDA () NIL)))))

MATCH 
==> (MATCH '(A (THV* B) (THV C) (THV C) (THV* B) (THV* E)) 
           '(A X Y Q Q X Y Z Z X Y Q Q X Y R))

(((E (Z Z X Y Q Q X Y R)) (C Q) (B (X Y)))
 <continuation1>)
==> ((CADR (SYMEVAL '*)))

(((E (R)) (C Z) (B (X Y Q Q X Y)))
 <continuation2>)
==> ((CADR (SYMEVAL '*)))

NIL 
==> (DEFINE TRY!TWO!THINGS!IN!PARALLEL
    (LAMBDA (F1 F2)
        (CATCH C
           ((LAMBDA (P1 P2)
               ((LAMBDA (F1 F2)
                    (EVALUATE!UNINTERRUPTIBLY
                     (BLOCK (ASET 'P1 (CREATE!PROCESS '(F1)))
                            (ASET 'P2 (CREATE!PROCESS '(F2)))
                            (START!PROCESS P1)
                            (START!PROCESS P2)
                            (STOP!PROCESS **PROCESS**))))
                (LAMBDA ()
                   ((LAMBDA (VALUE)
                       (EVALUATE!UNINTERRUPTIBLY
                        (BLOCK (STOP!PROCESS P2) (C VALUE))))
                    (F1)))
                (LAMBDA ()
                   ((LAMBDA (VALUE)
                       (EVALUATE!UNINTERRUPTIBLY
                        (BLOCK (STOP!PROCESS P1) (C VALUE))))
                    (F2)))))
            NIL NIL))))

TRY!TWO!THINGS!IN!PARALLEL 
==> (DEFINE SIGN
    (LAMBDA (N)
        (IF (EQUAL N 0) 'ZERO
            (TRY!TWO!THINGS!IN!PARALLEL
                (LAMBDA ()
                    (DO ((I 0 (1+ I)))
                        ((EQUAL I N) 'POSITIVE)))
                (LAMBDA ()
                    (DO ((I 0 (1- I)))
                        ((EQUAL I N) 'NEGATIVE)))))))

SIGN 
==> (SIGN 0)

ZERO 
==> (SIGN -120)

NEGATIVE 
==> (SIGN 120)

POSITIVE 
==> (QUIT)
Bye.
```

## License

MIT License

Copyright (c) 2026 Imre Horvath
