#lang rosette

(require rosette/lib/synthax
         synthools/lib)

(current-bitwidth #f)

;;Defining struct for state of the inner loop.
(struct $Vii (c sum) #:transparent)
(define ($Vii-eq? s1 s2) (eq? ($Vi_Vi_ii-c s1) ($Vi_Vi_ii-c s2)))



(define-symbolic seq:#L__mtl#6$0-c$0 seq:#L__mtl#6$0-c$1 seq:#L__mtl#6$0-c$2 seq:#L__mtl#6$0-c$3 seq:#L__mtl#6$0-c$4 integer?)
(define seq:#L__mtl#6$0-c
  (list seq:#L__mtl#6$0-c$0 seq:#L__mtl#6$0-c$1 seq:#L__mtl#6$0-c$2 seq:#L__mtl#6$0-c$3 seq:#L__mtl#6$0-c$4))

(define-symbolic seq:#L__mtl#6$0-sum integer?)

(define seq:#L__mtl#6$0
  ($Vii seq:#L__mtl#6$0-c seq:#L__mtl#6$0-sum))

(define-symbolic
  seq:#L__mtl#6$1-c$0 seq:#L__mtl#6$1-c$1 seq:#L__mtl#6$1-c$2 seq:#L__mtl#6$1-c$3 seq:#L__mtl#6$1-c$4 integer?)
(define seq:#L__mtl#6$1-c
  (list seq:#L__mtl#6$1-c$0 seq:#L__mtl#6$1-c$1 seq:#L__mtl#6$1-c$2 seq:#L__mtl#6$1-c$3 seq:#L__mtl#6$1-c$4))

(define-symbolic seq:#L__mtl#6$1-sum integer?)

(define seq:#L__mtl#6$1
  ($Vii seq:#L__mtl#6$1-c seq:#L__mtl#6$1-sum))

(define-symbolic seq:#L__mtl#6$2-c$0 seq:#L__mtl#6$2-c$1 seq:#L__mtl#6$2-c$2 seq:#L__mtl#6$2-c$3 seq:#L__mtl#6$2-c$4 integer?)
(define seq:#L__mtl#6$2-c
  (list seq:#L__mtl#6$2-c$0 seq:#L__mtl#6$2-c$1 seq:#L__mtl#6$2-c$2 seq:#L__mtl#6$2-c$3 seq:#L__mtl#6$2-c$4))

(define-symbolic seq:#L__mtl#6$2-sum integer?)
(define seq:#L__mtl#6$2
  ($Vii seq:#L__mtl#6$2-c seq:#L__mtl#6$2-sum))

(define-symbolic seq:#L__mtl#6$3-c$0 seq:#L__mtl#6$3-c$1 seq:#L__mtl#6$3-c$2 seq:#L__mtl#6$3-c$3 seq:#L__mtl#6$3-c$4 integer?)
(define seq:#L__mtl#6$3-c
  (list seq:#L__mtl#6$3-c$0 seq:#L__mtl#6$3-c$1 seq:#L__mtl#6$3-c$2 seq:#L__mtl#6$3-c$3 seq:#L__mtl#6$3-c$4))

(define-symbolic seq:#L__mtl#6$3-sum integer?)
(define seq:#L__mtl#6$3
  ($Vii seq:#L__mtl#6$3-c seq:#L__mtl#6$3-sum))

(define-symbolic seq:#L__mtl#6$4-c$0 seq:#L__mtl#6$4-c$1 seq:#L__mtl#6$4-c$2 seq:#L__mtl#6$4-c$3 seq:#L__mtl#6$4-c$4 integer?)
(define seq:#L__mtl#6$4-c
  (list seq:#L__mtl#6$4-c$0 seq:#L__mtl#6$4-c$1 seq:#L__mtl#6$4-c$2 seq:#L__mtl#6$4-c$3 seq:#L__mtl#6$4-c$4))

(define-symbolic seq:#L__mtl#6$4-sum integer?)
(define seq:#L__mtl#6$4
  ($Vii seq:#L__mtl#6$4-c seq:#L__mtl#6$4-sum))

(define-symbolic seq:#L__mtl#6$5-c$0 seq:#L__mtl#6$5-c$1 seq:#L__mtl#6$5-c$2 seq:#L__mtl#6$5-c$3 seq:#L__mtl#6$5-c$4 integer?)
(define seq:#L__mtl#6$5-c
  (list seq:#L__mtl#6$5-c$0 seq:#L__mtl#6$5-c$1 seq:#L__mtl#6$5-c$2 seq:#L__mtl#6$5-c$3 seq:#L__mtl#6$5-c$4))

(define-symbolic seq:#L__mtl#6$5-sum integer?)
(define seq:#L__mtl#6$5
  ($Vii seq:#L__mtl#6$5-c seq:#L__mtl#6$5-sum))

(define-symbolic seq:#L__mtl#6$6-c$0 seq:#L__mtl#6$6-c$1 seq:#L__mtl#6$6-c$2 seq:#L__mtl#6$6-c$3 seq:#L__mtl#6$6-c$4 integer?)
(define seq:#L__mtl#6$6-c
  (list seq:#L__mtl#6$6-c$0 seq:#L__mtl#6$6-c$1 seq:#L__mtl#6$6-c$2 seq:#L__mtl#6$6-c$3 seq:#L__mtl#6$6-c$4))

(define-symbolic seq:#L__mtl#6$6-sum integer?)
(define seq:#L__mtl#6$6
  ($Vii seq:#L__mtl#6$6-c seq:#L__mtl#6$6-sum))

(define-symbolic seq:#L__mtl#6$7-c$0 seq:#L__mtl#6$7-c$1 seq:#L__mtl#6$7-c$2 seq:#L__mtl#6$7-c$3 seq:#L__mtl#6$7-c$4 integer?)
(define seq:#L__mtl#6$7-c
  (list seq:#L__mtl#6$7-c$0 seq:#L__mtl#6$7-c$1 seq:#L__mtl#6$7-c$2 seq:#L__mtl#6$7-c$3 seq:#L__mtl#6$7-c$4))

(define-symbolic seq:#L__mtl#6$7-sum integer?)
(define seq:#L__mtl#6$7
  ($Vii seq:#L__mtl#6$7-c seq:#L__mtl#6$7-sum))

(define-symbolic seq:#L__mtl#6$8-c$0 seq:#L__mtl#6$8-c$1 seq:#L__mtl#6$8-c$2 seq:#L__mtl#6$8-c$3 seq:#L__mtl#6$8-c$4 integer?)
(define seq:#L__mtl#6$8-c
  (list seq:#L__mtl#6$8-c$0 seq:#L__mtl#6$8-c$1 seq:#L__mtl#6$8-c$2 seq:#L__mtl#6$8-c$3 seq:#L__mtl#6$8-c$4))

(define-symbolic seq:#L__mtl#6$8-sum integer?)
(define seq:#L__mtl#6$8
  ($Vii seq:#L__mtl#6$8-c seq:#L__mtl#6$8-sum))

(define seq:#L__mtl#6
  (list seq:#L__mtl#6$0 seq:#L__mtl#6$1 seq:#L__mtl#6$2 seq:#L__mtl#6$3 seq:#L__mtl#6$4 seq:#L__mtl#6$5 seq:#L__mtl#6$6 seq:#L__mtl#6$7 seq:#L__mtl#6$8))

(struct $Vii (c colmax mtr mtrl sum) #:transparent)
(define ($Vii-eq? s1 s2) (and (eq? ($Vii-c s1) ($Vii-c s2))
                              (eq? ($Vii-sum s1) ($Vii-sum s2))))

;;Defining inner join function for outer loop.
(define (join#L__mtl#6 $L $R j_start j_end)
  (let ([l.c ($Vi-c $L)]
        [l.sum ($Vi-sum $L)]
        [r.c ($Vi-c $R)]
        [r.sum ($Vi-sum $R)])

    (let ([_fs_0
           (LoopFunc
            0 (lambda (j) (< j 5))
            (lambda (j) (add1 j)) ($Vi l.c l.colmax 0 0)
            (lambda (__s j) (let ([c ($Vii-c __s)]
                                  [colmax ($Vii-colmax __s)]
                                  [mtr ($Vii-mtr __s)]
                                  [sum ($Vii-sum __s)])
                              (let ([c (list-set
                                        c
                                        j
                                        (+ (list-ref r.c j)
                                           (list-ref c j)))])
                                  ($Vii c sum)))))])
      ($Vi ($Vii-c _fs_0)  r.sum))))


;;Functional representation of the loop body.
(define (__loop_body__ s i_begin_ i_end_ )
  (Loop i_begin_ i_end_ 9 s
        (lambda (__s i) (let ([c ($Vii-c __s)]
                              [colmax ($Vii-colmax __s)]
                              [mtr ($Vii-mtr __s)]
                              [mtrl ($Vii-mtrl __s)]
                              [sum ($Vii-sum __s)])
                          (let ([tup$ (join#L__mtl#6 ($Vi c colmax mtr
                                                                sum) (list-ref seq:#L__mtl#6 i) 0 5)])
                            (let ([c ($Vi-c tup$)][colmax ($Vi-colmax tup$)]
                                                        [mtr ($Vi-mtr tup$)][sum ($Vi-sum tup$)])
                              ($Vii c colmax mtr (max mtr mtrl) sum)))))))

;;Wrapping for the sketch of the join.
(define (__join__ $ViiL $ViiR i_start i_end)
  (let ([l.c ($Vii-c $ViiL)]
        [l.colmax ($Vii-colmax $ViiL)]
        [l.mtr ($Vii-mtr $ViiL)]
        [l.mtrl ($Vii-mtrl $ViiL)]
        [l.sum ($Vii-sum $ViiL)] [r.c ($Vii-c $ViiR)]
        [r.colmax ($Vii-colmax $ViiR)]
        [r.mtr ($Vii-mtr $ViiR)]
        [r.mtrl ($Vii-mtrl $ViiR)]
        [r.sum ($Vii-sum $ViiR)])
    (let ([tup$ (LoopFunc
                 0
                 (lambda (j) (< j 5))
                 (lambda (j) (add1 j))
                 ($Vii l.c l.colmax 0 l.mtrl 0)
                 (lambda (__s j)
                   (let ([c ($Vii-c __s)]
                         [colmax ($Vii-colmax __s)]
                         [mtr ($Vii-mtr __s)]
                         [mtrl ($Vii-mtrl __s)]
                         [sum ($Vii-sum __s)])
                     (let ([c (list-set
                               c
                               j
                               (+
                                (NumExprBasic
                                 (list-ref colmax j)
                                 (list-ref r.colmax j)
                                 (list-ref l.colmax j)
                                 (list-ref c j)
                                 (list-ref r.c j)
                                 (list-ref l.c j)
                                 1)
                                (NumExprBasic
                                 (list-ref r.colmax j)
                                 (list-ref r.c j)
                                 1)))])
                       (let ([colmax (list-set
                                      colmax
                                      j
                                      (max
                                       (NumExprBasic
                                        (list-ref colmax j)
                                        (list-ref r.colmax j)
                                        (list-ref l.colmax j)
                                        (list-ref c j)
                                        (list-ref r.c j)
                                        (list-ref l.c j)
                                        1)
                                       (NumExprBasic
                                        (list-ref colmax j)
                                        (list-ref r.colmax j)
                                        (list-ref l.colmax j)
                                        (list-ref c j)
                                        (list-ref r.c j)
                                        (list-ref l.c j)
                                        1)))])
                         ($Vii c colmax
                                     (max
                                      (NumExprBasic
                                       mtr mtrl l.mtr r.mtr l.mtrl r.mtrl
                                       (list-ref colmax j)
                                       (list-ref r.colmax j)
                                       (list-ref l.colmax j)
                                       (list-ref c j)
                                       (list-ref r.c j)
                                       (list-ref l.c j)
                                       1)
                                      (NumExprBasic
                                       mtr mtrl l.mtr r.mtr l.mtrl r.mtrl
                                       (list-ref colmax j)
                                       (list-ref r.colmax j)
                                       (list-ref l.colmax j)
                                       (list-ref c j)
                                       (list-ref r.c j)
                                       (list-ref l.c j)
                                       1))
                                     (max
                                      (NumExprBasic
                                       mtr mtrl l.mtr r.mtr l.mtrl r.mtrl
                                       (list-ref colmax j)
                                       (list-ref r.colmax j)
                                       (list-ref l.colmax j)
                                       (list-ref c j)
                                       (list-ref r.c j)
                                       (list-ref l.c j)
                                       1)
                                      (NumExprBasic
                                       mtr mtrl l.mtr r.mtr l.mtrl r.mtrl
                                       (list-ref colmax j)
                                       (list-ref r.colmax j)
                                       (list-ref l.colmax j)
                                       (list-ref c j)
                                       (list-ref r.c j)
                                       (list-ref l.c j)
                                       1))
                                     r.sum))))))])
      tup$ )))



;;Symbolic input state and synthesized id state
(define $_identity ($Vii (make-list 5 0) (make-list 5 (choose 0 #t #f)) (choose 0 #t #f 0) (choose 0 #t #f 0) (choose 0 #t #f 0)))
(define ($_initial _begin_ end) ($Vii (make-list 5 0) (make-list 5 0) 0 0 0))
;;Actual synthesis work happens here

(define odot (time
              (synthesize
               #:forall (list seq:#L__mtl#6$0-sum seq:#L__mtl#6$0-mtr
                              seq:#L__mtl#6$0-c$0 seq:#L__mtl#6$0-c$1 seq:#L__mtl#6$0-c$2
                              seq:#L__mtl#6$0-c$3 seq:#L__mtl#6$0-c$4 seq:#L__mtl#6$0-colmax$0
                              seq:#L__mtl#6$0-colmax$1 seq:#L__mtl#6$0-colmax$2
                              seq:#L__mtl#6$0-colmax$3 seq:#L__mtl#6$0-colmax$4
                              seq:#L__mtl#6$1-sum seq:#L__mtl#6$1-mtr seq:#L__mtl#6$1-c$0
                              seq:#L__mtl#6$1-c$1 seq:#L__mtl#6$1-c$2 seq:#L__mtl#6$1-c$3
                              seq:#L__mtl#6$1-c$4 seq:#L__mtl#6$1-colmax$0
                              seq:#L__mtl#6$1-colmax$1 seq:#L__mtl#6$1-colmax$2
                              seq:#L__mtl#6$1-colmax$3 seq:#L__mtl#6$1-colmax$4
                              seq:#L__mtl#6$2-sum seq:#L__mtl#6$2-mtr seq:#L__mtl#6$2-c$0
                              seq:#L__mtl#6$2-c$1 seq:#L__mtl#6$2-c$2 seq:#L__mtl#6$2-c$3
                              seq:#L__mtl#6$2-c$4 seq:#L__mtl#6$2-colmax$0
                              seq:#L__mtl#6$2-colmax$1 seq:#L__mtl#6$2-colmax$2
                              seq:#L__mtl#6$2-colmax$3 seq:#L__mtl#6$2-colmax$4
                              seq:#L__mtl#6$3-sum seq:#L__mtl#6$3-mtr seq:#L__mtl#6$3-c$0
                              seq:#L__mtl#6$3-c$1 seq:#L__mtl#6$3-c$2 seq:#L__mtl#6$3-c$3
                              seq:#L__mtl#6$3-c$4 seq:#L__mtl#6$3-colmax$0
                              seq:#L__mtl#6$3-colmax$1 seq:#L__mtl#6$3-colmax$2
                              seq:#L__mtl#6$3-colmax$3 seq:#L__mtl#6$3-colmax$4
                              seq:#L__mtl#6$4-sum seq:#L__mtl#6$4-mtr seq:#L__mtl#6$4-c$0
                              seq:#L__mtl#6$4-c$1 seq:#L__mtl#6$4-c$2 seq:#L__mtl#6$4-c$3
                              seq:#L__mtl#6$4-c$4 seq:#L__mtl#6$4-colmax$0
                              seq:#L__mtl#6$4-colmax$1 seq:#L__mtl#6$4-colmax$2
                              seq:#L__mtl#6$4-colmax$3 seq:#L__mtl#6$4-colmax$4
                              seq:#L__mtl#6$5-sum seq:#L__mtl#6$5-mtr seq:#L__mtl#6$5-c$0
                              seq:#L__mtl#6$5-c$1 seq:#L__mtl#6$5-c$2 seq:#L__mtl#6$5-c$3
                              seq:#L__mtl#6$5-c$4 seq:#L__mtl#6$5-colmax$0
                              seq:#L__mtl#6$5-colmax$1 seq:#L__mtl#6$5-colmax$2
                              seq:#L__mtl#6$5-colmax$3 seq:#L__mtl#6$5-colmax$4
                              seq:#L__mtl#6$6-sum seq:#L__mtl#6$6-mtr seq:#L__mtl#6$6-c$0
                              seq:#L__mtl#6$6-c$1 seq:#L__mtl#6$6-c$2 seq:#L__mtl#6$6-c$3
                              seq:#L__mtl#6$6-c$4 seq:#L__mtl#6$6-colmax$0
                              seq:#L__mtl#6$6-colmax$1 seq:#L__mtl#6$6-colmax$2
                              seq:#L__mtl#6$6-colmax$3 seq:#L__mtl#6$6-colmax$4
                              seq:#L__mtl#6$7-sum seq:#L__mtl#6$7-mtr seq:#L__mtl#6$7-c$0
                              seq:#L__mtl#6$7-c$1 seq:#L__mtl#6$7-c$2 seq:#L__mtl#6$7-c$3
                              seq:#L__mtl#6$7-c$4 seq:#L__mtl#6$7-colmax$0
                              seq:#L__mtl#6$7-colmax$1 seq:#L__mtl#6$7-colmax$2
                              seq:#L__mtl#6$7-colmax$3 seq:#L__mtl#6$7-colmax$4
                              seq:#L__mtl#6$8-sum seq:#L__mtl#6$8-mtr seq:#L__mtl#6$8-c$0
                              seq:#L__mtl#6$8-c$1 seq:#L__mtl#6$8-c$2 seq:#L__mtl#6$8-c$3
                              seq:#L__mtl#6$8-c$4 seq:#L__mtl#6$8-colmax$0
                              seq:#L__mtl#6$8-colmax$1 seq:#L__mtl#6$8-colmax$2
                              seq:#L__mtl#6$8-colmax$3 seq:#L__mtl#6$8-colmax$4)
               #:guarantee (assert (and
                                    ($Vii-eq? (__loop_body__ ($_initial 0 2) 0 2 )
                                                    (__join__ (__loop_body__ ($_initial 0 1) 0 1 )
                                                              (__loop_body__ ($_initial 1 2) 1 2 ) 0 2))
                                    ($Vii-eq? (__loop_body__ ($_initial 0 7) 0 7 )
                                                    (__join__ (__loop_body__ ($_initial 0 1) 0 1 )
                                                              (__loop_body__ ($_initial 1 7) 1 7 ) 0 7))
                                    ($Vii-eq? (__loop_body__ ($_initial 0 5) 0 5 )
                                                    (__join__ (__loop_body__ ($_initial 0 2) 0 2 )
                                                              (__loop_body__ ($_initial 2 5) 2 5 ) 0 5))
                                    ($Vii-eq? (__loop_body__ ($_initial 0 4) 0 4 )
                                                    (__join__ (__loop_body__ ($_initial 0 2) 0 2 )
                                                              (__loop_body__ ($_initial 2 4) 2 4 ) 0 4)))))))

(if (sat? odot) (print-forms odot) (core odot))