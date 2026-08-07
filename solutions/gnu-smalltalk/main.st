Object subclass: #BRC
    instanceVariableNames: ''
    classVariableNames: ''
    poolDictionaries: ''
    category: nil.

!BRC class methodsFor: 'processing'!

parseTemp: line start: start
    | i neg v |
    i := start.
    neg := 0.
    (line at: i) == $- ifTrue: [ neg := 1. i := i + 1 ].
    v := 0.
    [ (line at: i) ~= $. ] whileTrue: [
        v := (v * 10) + ((line at: i) asInteger - 48).
        i := i + 1.
    ].
    i := i + 1.
    v := (v * 10) + ((line at: i) asInteger - 48).
    neg = 1 ifTrue: [ ^ v negated ] ifFalse: [ ^ v ].
!

run
    | map file |
    map := Dictionary new.
    file := FileStream open: '../../data/measurements.txt' mode: FileStream read.
    file linesDo: [ :line |
        line isEmpty ifFalse: [
            | semi city t e |
            semi := line indexOf: $;.
            city := line copyFrom: 1 to: semi - 1.
            t := (BRC parseTemp: line start: semi + 1).
            e := map at: city ifAbsent: [ nil ].
            e ifNil: [ map at: city put: (Array with: t with: t with: t with: 1) ]
              ifNotNil: [
                (t < (e at: 1)) ifTrue: [ e at: 1 put: t ].
                (t > (e at: 2)) ifTrue: [ e at: 2 put: t ].
                e at: 3 put: (e at: 3) + t.
                e at: 4 put: (e at: 4) + 1.
              ].
        ]
    ].
    file close.
    (map keys asSortedCollection) do: [ :city |
        | e |
        e := map at: city.
        Transcript show: city; tab; show: (e at: 1) printString; tab;
            show: (e at: 2) printString; tab; show: (e at: 3) printString; tab;
            show: (e at: 4) printString; cr.
    ].
!
!!

BRC run.
