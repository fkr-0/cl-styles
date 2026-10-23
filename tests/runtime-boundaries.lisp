(uiop:define-package :cl-styles.tests/runtime-boundaries
  (:use :cl :fiveam)
  (:export))
(in-package :cl-styles.tests/runtime-boundaries)

(def-suite cl-styles/runtime-boundaries
  :in cl-styles.tests:cl-styles-test)
(in-suite cl-styles/runtime-boundaries)

(test color-parser-validates-hex-channel-ranges-and-shapes
  (dolist (valid '(0 255 "#0aF9eD" (1 2 3) (:rgb 0 127 255)
                   (:rgba 0 1 2 0.5) (:hsl 50 0 100) (:256 255)))
    (is (cl-styles.tokens:color-p valid)))
  (dolist (invalid '(-1 256 "#00000" "#GGGGGG" (0 1 256)
                     (:rgb 1 2) (:rgba 1 2 3 -0.1)
                     (:hsl 1 101 50) (:256 256) (:unknown 1) :blue))
    (is (not (cl-styles.tokens:color-p invalid))))
  (is (equal '(:rem 2) (cl-styles.tokens:root-em 2)))
  (is (equal '(:ch 3) (cl-styles.tokens:ch 3)))
  (is (equal '(:px 4) (cl-styles.tokens:len 4 :px)))
  (is (cl-styles.tokens:length-p (cl-styles.tokens:ch 4)))
  (is (null (cl-styles.tokens:length-p '(:bogus 2)))))

(test variable-resolution-recovers-from-nested-cycle-using-fallback
  (let ((vars (list (cons "--a" (cl-styles.tokens:var "--b"))
                    (cons "--b" (cl-styles.tokens:var "--a")))))
    (multiple-value-bind (value expansions)
        (cl-styles.tokens:resolve-variable-value
         (cl-styles.tokens:var "--a" :green) vars :property :color)
      (is (eq :green value))
      (is (some #'cl-styles.tokens:variable-expansion-fallback-used-p
                expansions))))
  (multiple-value-bind (value expansions)
      (cl-styles.tokens:resolve-variable-value
       (cl-styles.tokens:var "--a" (cl-styles.tokens:var "--fallback" 4))
       nil :property :font-size)
    (is (= 4 value))
    (is (= 2 (length expansions))))
  (multiple-value-bind (value expansions)
      (cl-styles.tokens:resolve-variable-value
       (cl-styles.tokens:var :accent) '("accent" :magenta))
    (is (eq :magenta value))
    (is (= 1 (length expansions))))
  (signals error (cl-styles.tokens:validate-variable-environment 12)))

(test shorthand-three-and-four-value-box-and-flex-paths
  (let ((out (cl-styles.rule:expand-shorthands
              '(:padding (1 2 3) :margin (4 5 6 7) :gap 2
                :flex 5 :flex-flow (:column :wrap)))))
    (is (= 1 (getf out :padding-top)))
    (is (= 2 (getf out :padding-left)))
    (is (= 3 (getf out :padding-bottom)))
    (is (= 4 (getf out :margin-top)))
    (is (= 5 (getf out :margin-right)))
    (is (= 6 (getf out :margin-bottom)))
    (is (= 7 (getf out :margin-left)))
    (is (= 2 (getf out :row-gap)))
    (is (= 2 (getf out :column-gap)))
    (is (= 5 (getf out :flex-grow)))
    (is (= 1 (getf out :flex-shrink)))
    (is (= 0 (getf out :flex-basis)))
    (is (eq :column (getf out :flex-direction)))
    (is (eq :wrap (getf out :flex-wrap))))
  ;; An explicit longhand always beats the shorthand.
  (let ((out (cl-styles.rule:expand-shorthands
              '(:padding (1 2 3 4) :padding-left 99
                :flex (2 3) :flex-grow 88))))
    (is (= 99 (getf out :padding-left)))
    (is (= 88 (getf out :flex-grow)))
    (is (= 3 (getf out :flex-shrink)))
    (is (= 0 (getf out :flex-basis)))))

(test selector-value-equality-covers-mixed-representations
  (flet ((same (a b) (cl-styles.selector::selector-value-eql a b)))
    (is (same nil nil))
    (is (not (same nil :x)))
    (is (not (same :x nil)))
    (is (same :button 'button))
    (is (same "button" "button"))
    (is (same "button" :button))
    (is (same :button "button"))
    (is (same 3 3))
    (is (not (same 3 4)))
    (is (same '(1 :a) '(1 "a")))
    (is (not (same '(1 :a) '(1 :a :b))))
    (is (not (same :button 42)))))

(test invalid-selector-reports-path-and-reason
  (handler-case
      (progn
        (cl-styles.selector:validate-selector '(:and (:type :button) (:bogus :x)))
        (is nil))
    (cl-styles.selector:invalid-selector (condition)
      (is (equal '(1) (cl-styles.selector:invalid-selector-path condition)))
      (is (eq :unknown-selector-operator
              (cl-styles.selector:invalid-selector-reason condition)))
      (is (search "Invalid selector" (princ-to-string condition)))))
  (dolist (invalid '((:type) (:id nil) (:class) (:state)
                     (:attr) (:first-child 1) (:last-child 2)
                     (:nth-child -1) (:nth-child 1.2)
                     (:and) (:or) (:not) (:has)
                     (:child (:type :root)) (:desc (:type :root))))
    (signals cl-styles.selector:invalid-selector
      (cl-styles.selector:compile-selector invalid))))

(defclass runtime-node ()
  ((parent :initarg :parent :initform nil :reader runtime-parent)
   (kind :initarg :kind :initform :child :reader runtime-kind)))
(defmethod cl-styles.protocols:stylable-parent ((node runtime-node))
  (runtime-parent node))
(defmethod cl-styles.protocols:stylable-type ((node runtime-node))
  (runtime-kind node))

(test orphan-child-selector-is-no-match-not-protocol-error
  (let ((node (make-instance 'runtime-node)))
    (is (null (cl-styles.selector:match-selector-p
               (cl-styles.selector:child>
                (cl-styles.selector:type> :root)
                (cl-styles.selector:type> :child)) node)))))

(test internal-plist-merge-preserves-caller-owned-input
  (let* ((left (list :color :red :width 3))
         (right (list :width 4 :height 5))
         (merged (cl-styles.engine::%plist-merge left right)))
    (is (equal '(:color :red :width 3) left))
    (is (equal '(:width 4 :height 5) right))
    (is (eq :red (getf merged :color)))
    (is (= 4 (getf merged :width)))
    (is (= 5 (getf merged :height)))
    (is (not (eq merged left)))))
