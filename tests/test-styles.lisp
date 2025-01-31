(defpackage :cl-styles.tests.styles
  (:use :cl :fiveam :cl-styles)
  (:export :run-tests))
(in-package :cl-styles.tests.styles)

(def-suite :style-tests :description "Tests for the CL-Styles system")
(in-suite :style-tests)

(test ordered-styles-test
      (let ((styles '(a b c d))
            (dependencies '((b a) (c b) (d c))))
        (flet ((mock-apply-after (style styles)
                 (cdr (assoc style dependencies))))
          (is (equal (ordered-styles styles) '(a b c d))))))

(test apply-style-test
      (let ((stylable (make-instance 'stylable)))
        (apply-style stylable (make-instance 'style :property :color :value "red"))
        (is (equal (gethash :color (styles stylable)) "red"))))

(test select-stylables-test
      (let ((s1 (make-instance 'stylable :id "button1"))
            (s2 (make-instance 'stylable :id "button2"))
            (selector (make-instance 'selector :name "button1")))
        (is (equal (select-stylables selector (list s1 s2)) (list s1)))))

(test apply-styles-test
      (let ((s1 (make-instance 'stylable :id "button1"))
            (s2 (make-instance 'stylable :id "button2"))
            (selector (make-instance 'selector :name "button1"))
            (style (make-instance 'style :property :color :value "red")))
        (apply-styles (list style) (list s1 s2) selector)
        (is (equal (gethash :color (styles s1)) "red"))
        (is (equal (gethash :color (styles s2)) nil))))

(test apply-styles-to-stylables-test
      (let ((s1 (make-instance 'stylable :id "button1"))
            (s2 (make-instance 'stylable :id "button2"))
            (selector (make-instance 'selector :name "button1"))
            (style (make-instance 'style :property :color :value "red")))
        (apply-styles-to-stylables (list style) (list s1 s2) selector)
        (is (equal (gethash :color (styles s1)) "red"))
        (is (equal (gethash :color (styles s2)) nil))))

(test select-styles-test
      (let ((s1 (make-instance 'style :name "button1"))
            (s2 (make-instance 'style :name "button2"))
            (selector (make-instance 'selector :name "button1")))
        (is (equal (select-styles selector (list s1 s2)) (list s1)))))

(defun run-tests ()
  (format t "Running Rule tests...~%")
  (run-all-tests))
