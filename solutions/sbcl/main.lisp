(defpackage :1brc (:use :cl))
(in-package :1brc)

(defun main ()
  (let ((stats (make-hash-table :test #'equal)))
    (with-open-file (in "../../data/measurements.txt")
      (loop for line = (read-line in nil nil)
            while line
            do (let* ((semi (position #\; line))
                      (city (subseq line 0 semi))
                      (temp-str (remove #\. (subseq line (1+ semi))))
                      (temp (parse-integer temp-str)))
                 (let ((entry (gethash city stats)))
                   (if entry
                       (setf (first entry) (min (first entry) temp)
                             (second entry) (max (second entry) temp)
                             (third entry) (+ (third entry) temp)
                             (fourth entry) (1+ (fourth entry)))
                       (setf (gethash city stats) (list temp temp temp 1)))))))
    (let ((cities (sort (loop for city being the hash-keys of stats
                              collect city)
                        #'string<)))
      (dolist (city cities)
        (let ((e (gethash city stats)))
          (format t "~a~c~d~c~d~c~d~c~d~%"
                  city #\Tab (first e) #\Tab (second e)
                  #\Tab (third e) #\Tab (fourth e)))))))

(main)
