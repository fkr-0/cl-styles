(uiop:define-package :cl-styles.util
  (:use :common-lisp)
  (:export :hash-table-keys))

(in-package :cl-styles.util)

(defun hash-table-keys (table)
  "Return a list of all keys in the hash table."
  (let (keys)
    (maphash (lambda (key value)
               (declare (ignore value))
               (push key keys))
             table)
    keys))
