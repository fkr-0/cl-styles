(uiop:define-package :stylesheet-tests
  (:use :cl :fiveam)
  (:import-from :cl-styles.sheet #:stylesheet-rules #:add-rule #:remove-rule #:make-stylesheet)
  (:export #:stylesheet-suite))
(in-package :stylesheet-tests)

(def-suite stylesheet-suite
  :description "Tests for stylesheet rule management."
  :in cl-styles.tests:cl-styles-test)

(in-suite stylesheet-suite)

(test add-rule
  (let* ((a (cl-styles.rule:defrule (cl-styles.selector:cls> "a") :color :red))
         (b (cl-styles.rule:defrule (cl-styles.selector:cls> "b") :color :blue))
         (ss (make-stylesheet :rules (list a))))
    (add-rule ss b)
    (is (equal (stylesheet-rules ss) (list a b)))))

(test remove-rule
  (let* ((a (cl-styles.rule:defrule (cl-styles.selector:cls> "a") :color :red))
         (b (cl-styles.rule:defrule (cl-styles.selector:cls> "b") :color :blue))
         (ss (make-stylesheet :rules (list a b))))
    (remove-rule ss a)
    (is (equal (stylesheet-rules ss) (list b)))))

(test add-and-remove-rule
  (let* ((a (cl-styles.rule:defrule (cl-styles.selector:cls> "a") :color :red))
         (b (cl-styles.rule:defrule (cl-styles.selector:cls> "b") :color :blue))
         (ss (make-stylesheet :rules (list a))))
    (add-rule ss b)
    (remove-rule ss a)
    (is (equal (stylesheet-rules ss) (list b)))))

(test stylesheet-with-variables
  "Test creating stylesheet with variables"
  (let ((ss (make-stylesheet :variables '(("--primary" . :blue)
                                          ("--size" . 16)))))
    (is (equal (cl-styles.sheet:stylesheet-variables ss)
               '(("--primary" . :blue) ("--size" . 16))))))

(test stylesheet-with-namespace
  "Test creating stylesheet with namespace"
  (let ((ss (make-stylesheet :namespace :my-theme)))
    (is (eql (cl-styles.sheet:stylesheet-namespace ss) :my-theme))))

(test empty-stylesheet
  "Test creating empty stylesheet has proper defaults"
  (let ((ss (make-stylesheet)))
    (is (null (cl-styles.sheet:stylesheet-rules ss)))
    (is (null (cl-styles.sheet:stylesheet-variables ss)))
    (is (null (cl-styles.sheet:stylesheet-namespace ss)))))

(test stylesheet-full-creation
  "Test creating stylesheet with all parameters"
  (let* ((a (cl-styles.rule:defrule (cl-styles.selector:type> :button) :color :red))
         (b (cl-styles.rule:defrule (cl-styles.selector:cls> "primary") :color :blue))
         (ss (make-stylesheet :rules (list a b)
                              :variables '(("--var1" . :val1)) :namespace :test-ns)))
    (is (equal (stylesheet-rules ss) (list a b)))
    (is (equal (cl-styles.sheet:stylesheet-variables ss) '(("--var1" . :val1))))
    (is (eql (cl-styles.sheet:stylesheet-namespace ss) :test-ns))))

(test stylesheet-revision-tracks-style-relevant-mutations
  (let* ((rule (cl-styles.rule:defrule (cl-styles.selector:type> :button) :color :red))
         (ss (make-stylesheet)))
    (is (= 0 (cl-styles.sheet:stylesheet-revision ss)))
    (add-rule ss rule)
    (is (= 1 (cl-styles.sheet:stylesheet-revision ss)))
    (setf (cl-styles.sheet:stylesheet-variables ss) '(("--accent" . :blue)))
    (is (= 2 (cl-styles.sheet:stylesheet-revision ss)))
    (remove-rule ss rule)
    (is (= 3 (cl-styles.sheet:stylesheet-revision ss)))))

(test invalid-property-fails-at-rule-construction
  (signals cl-styles.properties:style-contract-violation
    (cl-styles.rule:defrule (cl-styles.selector:type> :button)
      :not-a-property 1)))

(test variable-resolved-property-type-fails-at-stylesheet-boundary
  (signals cl-styles.properties:style-contract-violation
    (make-stylesheet
     :rules (list (cl-styles.rule:defrule
                   (cl-styles.selector:type> :button)
                   :font-size (cl-styles.tokens:var "--bad-size")))
     :variables '(("--bad-size" . :large)))))

(test add-rule-validates-resolved-property-type
  (let ((sheet (make-stylesheet :variables '(("--bad-size" . :large)))))
    (signals cl-styles.properties:style-contract-violation
      (add-rule sheet
                (cl-styles.rule:defrule
                 (cl-styles.selector:type> :button)
                 :font-size (cl-styles.tokens:var "--bad-size"))))))
