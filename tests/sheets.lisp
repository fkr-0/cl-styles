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

;; Regression boundary: standalone stylesheet mutation, validation, and
;; revision semantics. These cases deliberately use public API only.
(defun test-button-rule (color)
  (cl-styles.rule:make-rule
   :selector (cl-styles.selector:type> :button)
   :declarations (list :color color)))

(test stylesheet-validate-rejects-non-sheets
  (signals error (cl-styles.sheet:validate-stylesheet nil))
  (signals error (cl-styles.sheet:validate-stylesheet '(:rules nil)))
  (is (typep (cl-styles.sheet:validate-stylesheet (make-stylesheet))
             'cl-styles.sheet:stylesheet)))

(test stylesheet-direct-rule-setter-is-revisioned
  (let* ((first (test-button-rule :red))
         (second (test-button-rule :blue))
         (sheet (make-stylesheet :rules (list first))))
    (setf (stylesheet-rules sheet) (list first second))
    (is (= 1 (cl-styles.sheet:stylesheet-revision sheet)))
    (is (equal (list first second) (stylesheet-rules sheet)))
    ;; Equal rule lists are not style-relevant mutations.
    (setf (stylesheet-rules sheet) (copy-list (stylesheet-rules sheet)))
    (is (= 1 (cl-styles.sheet:stylesheet-revision sheet)))
    (setf (stylesheet-rules sheet) nil)
    (is (null (stylesheet-rules sheet)))
    (is (= 2 (cl-styles.sheet:stylesheet-revision sheet)))))

(test stylesheet-variable-setter-validates-before-mutation
  (let* ((rule (cl-styles.rule:make-rule
                :selector (cl-styles.selector:type> :button)
                :declarations (list :font-size (cl-styles.tokens:var "--size"))))
         (sheet (make-stylesheet :rules (list rule)
                                 :variables '(("--size" . 12)))))
    (signals cl-styles.properties:style-contract-violation
      (setf (cl-styles.sheet:stylesheet-variables sheet)
            '(("--size" . :large))))
    (is (equal '(("--size" . 12))
               (cl-styles.sheet:stylesheet-variables sheet)))
    (is (= 0 (cl-styles.sheet:stylesheet-revision sheet)))
    (setf (cl-styles.sheet:stylesheet-variables sheet) '(("--size" . 14)))
    (is (= 1 (cl-styles.sheet:stylesheet-revision sheet)))
    (setf (cl-styles.sheet:stylesheet-variables sheet)
          '(("--size" . 14)))
    (is (= 1 (cl-styles.sheet:stylesheet-revision sheet)))))

(test stylesheet-rules-setter-validates-before-mutation
  (let* ((rule (test-button-rule :red))
         (sheet (make-stylesheet :rules (list rule))))
    (signals cl-styles.rule:invalid-rule
      (setf (stylesheet-rules sheet) (list rule :not-a-rule)))
    (is (equal (list rule) (stylesheet-rules sheet)))
    (is (= 0 (cl-styles.sheet:stylesheet-revision sheet)))
    (signals cl-styles.tokens:missing-style-variable
      (setf (stylesheet-rules sheet)
            (list (cl-styles.rule:make-rule
                   :selector (cl-styles.selector:type> :button)
                   :declarations (list :color (cl-styles.tokens:var "--absent"))))))
    (is (= 0 (cl-styles.sheet:stylesheet-revision sheet)))))

(test stylesheet-variable-setter-rejects-cycles-and-missing
  (let ((sheet (make-stylesheet :variables '(("--ok" . :red)))))
    (signals cl-styles.tokens:style-variable-cycle
      (setf (cl-styles.sheet:stylesheet-variables sheet)
            (list (cons "--a" (cl-styles.tokens:var "--b"))
                  (cons "--b" (cl-styles.tokens:var "--a")))))
    (signals cl-styles.tokens:missing-style-variable
      (setf (cl-styles.sheet:stylesheet-variables sheet)
            (list (cons "--a" (cl-styles.tokens:var "--missing")))))
    (is (equal '(("--ok" . :red))
               (cl-styles.sheet:stylesheet-variables sheet)))
    (is (= 0 (cl-styles.sheet:stylesheet-revision sheet)))))

(test stylesheet-add-rule-rejects-unresolved-variables-atomically
  (let ((sheet (make-stylesheet)))
    (signals cl-styles.tokens:missing-style-variable
      (add-rule sheet (cl-styles.rule:make-rule
                       :selector (cl-styles.selector:type> :button)
                       :declarations (list :color (cl-styles.tokens:var "--missing")))))
    (is (null (stylesheet-rules sheet)))
    (is (= 0 (cl-styles.sheet:stylesheet-revision sheet)))))

(test stylesheet-remove-absent-rule-is-noop
  (let* ((red (test-button-rule :red))
         (blue (test-button-rule :blue))
         (sheet (make-stylesheet :rules (list red))))
    (is (eq sheet (remove-rule sheet blue)))
    (is (equal (list red) (stylesheet-rules sheet)))
    (is (= 0 (cl-styles.sheet:stylesheet-revision sheet)))
    (is (eq sheet (remove-rule sheet red)))
    (is (= 1 (cl-styles.sheet:stylesheet-revision sheet)))
    (remove-rule sheet red)
    (is (= 1 (cl-styles.sheet:stylesheet-revision sheet)))))

(test stylesheet-variable-fallback-allows-valid-rules
  (let* ((rule (cl-styles.rule:make-rule
                :selector (cl-styles.selector:type> :button)
                :declarations (list :color (cl-styles.tokens:var "--missing" :red))))
         (sheet (make-stylesheet :rules (list rule))))
    (is (eq sheet (cl-styles.sheet:validate-stylesheet sheet)))
    (is (equal (list rule) (stylesheet-rules sheet)))
    (is (= 0 (cl-styles.sheet:stylesheet-revision sheet)))))

(test stylesheet-macro-and-stateful-engine-public-contract
  (let* ((rule (test-button-rule :green))
         (sheet (cl-styles.sheet:defstylesheet rule))
         (engine (make-instance 'cl-styles.sheet:style-engine :stylesheet sheet)))
    (is (equal (list rule) (stylesheet-rules sheet)))
    (is (eq sheet (cl-styles.sheet:style-engine-stylesheet engine)))
    (is (cl-styles.sheet:style-engine-dirty engine))
    (is (null (cl-styles.sheet:style-engine-patches engine)))
    (setf (cl-styles.sheet:style-engine-patches engine) (list :patch)
          (cl-styles.sheet:style-engine-dirty engine) nil)
    (is (equal '(:patch) (cl-styles.sheet:style-engine-patches engine)))
    (is (not (cl-styles.sheet:style-engine-dirty engine)))))

(test stylesheet-var-environment-plist-and-hash-table
  (let ((table (make-hash-table :test 'equal))
        (rule (cl-styles.rule:make-rule
               :selector (cl-styles.selector:type> :button)
               :declarations (list :color (cl-styles.tokens:var "--accent")))))
    (setf (gethash "--accent" table) :green)
    (is (typep (make-stylesheet :rules (list rule) :variables table)
               'cl-styles.sheet:stylesheet))
    (is (typep (make-stylesheet :rules (list rule)
                                :variables '("--accent" :blue))
               'cl-styles.sheet:stylesheet))
    (signals cl-styles.tokens:missing-style-variable
      (make-stylesheet :rules (list rule) :variables nil))))
