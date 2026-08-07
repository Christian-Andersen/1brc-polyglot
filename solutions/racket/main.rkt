#lang racket

(define (update-stats stats temp)
  (match stats
    [(list mn mx tot cnt)
     (list (min mn temp) (max mx temp) (+ tot temp) (add1 cnt))]
    [#f
     (list temp temp temp 1)]))

(define stats
  (for/fold ([acc (hash)])
            ([line (in-lines (open-input-file "../../data/measurements.txt"))])
    (match (string-split line ";")
      [(list city temp-str)
       (define temp (string->number (string-replace temp-str "." "")))
       (hash-set acc city (update-stats (hash-ref acc city #f) temp))])))

(for ([pair (sort (hash->list stats) string<? #:key car)])
  (match (cdr pair)
    [(list mn mx tot cnt)
     (printf "~a\t~a\t~a\t~a\t~a\n" (car pair) mn mx tot cnt)]))
