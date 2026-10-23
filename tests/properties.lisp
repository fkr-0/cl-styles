(uiop:define-package :cl-styles.tests/properties
  (:use :cl :fiveam)
  (:import-from :cl-styles.api)
  (:export))

(in-package :cl-styles.tests/properties)

(def-suite cl-styles/properties
  :in cl-styles.tests:cl-styles-test)

(in-suite cl-styles/properties)

(test groups-and-layouts
  (let* ((pad (cl-styles.properties:properties-for-group :padding))
         (mg  (cl-styles.properties:properties-for-group :margin))
         (box (cl-styles.properties:properties-for-group :box))
         (flex (cl-styles.properties:properties-for-layout :flex))
         (grid (cl-styles.properties:properties-for-layout :grid)))
    (is (member :padding-left pad))
    (is (member :margin-right mg))
    (is (member :border-top-width box))
    (is (member :flex-direction flex))
    (is (member :grid-template-columns grid))))

(test property-normalization-and-validation
  (let* ((decls
           '(:align-items :start
             :flex-direction "row"
             :grid-auto-flow
             :row-dense
             :width 10))
         (ens
           (cl-styles.properties:ensure-declarations decls)))
    (is (eql :flex-start (getf ens :align-items)))
    (is (eql :row (getf ens :flex-direction)))
    (is (eql :row-dense (getf ens :grid-auto-flow)))
    (is (= 10 (getf ens :width))))
  ;; invalid enum should signal
  (signals cl-styles.properties:style-contract-violation
    (cl-styles.properties:ensure-declarations '(:display :weird))))

(test terminal-geometry-declarations-are-valid
  "Maintained viewport/container geometry hints belong to the shared style contract."
  (let ((ens (cl-styles.properties:ensure-declarations
               '(:offset-x 2 :offset-y 3 :scroll-x 4 :scroll-y 5))))
    (is (= 2 (getf ens :offset-x)))
    (is (= 3 (getf ens :offset-y)))
    (is (= 4 (getf ens :scroll-x)))
    (is (= 5 (getf ens :scroll-y)))))

(test tui-256-color-palette-contract
  "Valid 0..255 palette colors flow through canonical color aliases."
  (let ((styles (cl-styles.properties:ensure-declarations
                  '(:fg-color (:rgb 12 34 56) :bg-color (:256 77)))))
    (is (equal (getf styles :color) '(:rgb 12 34 56)))
    (is (equal (getf styles :background-color) '(:256 77))))
  (dolist (invalid '((:256 -1) (:256 256) (:256 :bad) (:256)))
    (signals cl-styles.properties:style-contract-violation
      (cl-styles.properties:ensure-declarations
        (list :background-color invalid)))))

(test tui-color-aliases-normalize-to-canonical-properties
  "ElmTUI color spellings normalize without weakening the style contract."
  (let ((ens (cl-styles.properties:ensure-declarations
               '(:fg-color :white :bg-color :black))))
    (is (eq :white (getf ens :color)))
    (is (eq :black (getf ens :background-color)))
    (is (null (getf ens :fg-color)))
    (is (null (getf ens :bg-color)))))

(test tui-declaration-adapter-normalizes-legacy-border-forms
  "ElmTUI compatibility spellings become strict declarations at the adapter boundary."
  (let ((boxed (cl-styles.adapters:normalize-tui-declarations
                 '(:box :single :width 10 :fg-color :white)))
        (ascii (cl-styles.adapters:normalize-tui-declarations
                '(:box :ascii :height 4)))
        (boolean-border (cl-styles.adapters:normalize-tui-declarations
                         '(:border t :border-style :single))))
    (is (= 1 (getf boxed :border)))
    (is (eq :solid (getf boxed :border-style)))
    (is (= 10 (getf boxed :width)))
    (is (eq :white (getf boxed :color)))
    (is (null (member :box boxed :test #'eql)))
    (is (eq :ascii (getf ascii :border-style)))
    (is (= 1 (getf boolean-border :border)))
    (is (eq :solid (getf boolean-border :border-style)))
    (is-true (cl-styles.properties:ensure-declarations boxed))
    (is-true (cl-styles.properties:ensure-declarations ascii))
    (is-true (cl-styles.properties:ensure-declarations boolean-border))))

(test tui-declaration-adapter-normalizes-legacy-layout-and-color-forms
  (let ((normalized
          (cl-styles.adapters:normalize-tui-declarations
           '(:direction :row :spacing 2 :justify :center
             :fg-color (12 34 56) :bg-color (65 43 21)
             :bold t :underline nil))))
    (is (eq :row (getf normalized :flex-direction)))
    (is (= 2 (getf normalized :gap)))
    (is (eq :center (getf normalized :justify-content)))
    (is (equal '(:rgb 12 34 56) (getf normalized :color)))
    (is (equal '(:rgb 65 43 21) (getf normalized :background-color)))
    (is (member :bold (getf normalized :attributes)))
    (is (not (member :underline (getf normalized :attributes))))
    (is (null (member :direction normalized :test #'eql)))
    (is (null (member :spacing normalized :test #'eql)))
    (is (null (member :bold normalized :test #'eql)))
    (is-true (cl-styles.properties:ensure-declarations normalized))))

(test shorthands-flex-and-gap
  (let* ((decl '(:flex (2 3 4) :gap (1 2)))
         (exp  (cl-styles.rule:expand-shorthands decl)))
    (is (= 2 (getf exp :flex-grow)))
    (is (= 3 (getf exp :flex-shrink)))
    (is (= 4 (getf exp :flex-basis)))
    (is (= 1 (getf exp :row-gap)))
    (is (= 2 (getf exp :column-gap)))))

(test border-shorthand
  (let* ((decl `(:border (2 :solid ,(cl-styles.tokens:rgb 255 0 0))))
         (exp  (cl-styles.rule:expand-shorthands decl)))
    (is (= 2 (getf exp :border-top-width)))
    (is (eql :solid (getf exp :border-left-style)))
    (is (equal (cl-styles.tokens:rgb 255 0 0) (getf exp :border-right-color)))))

(test flex-shorthand-properties-are-registered
  "Existing flex and flex-flow shorthands are valid static declarations before expansion."
  (is-true (cl-styles.properties:ensure-declarations
            (list :flex (list 1 1 0) :flex-flow (list :row :wrap))))
  (signals cl-styles.properties:style-contract-violation
    (cl-styles.properties:ensure-declarations
     (list :flex (list 1 :bad 0)))))

(test terminal-attributes-are-validated
  (is-true (cl-styles.properties:ensure-declarations
            (list :attributes '(:bold :underline) :attrs '(:italic))))
  (signals cl-styles.properties:style-contract-violation
    (cl-styles.properties:ensure-declarations
     (list :attributes '(:bogus)))))

(test tui-dimension-values-match-layout-contract
  (is-true (cl-styles.properties:ensure-declarations (list :width :fill)))
  (is-true (cl-styles.properties:ensure-declarations (list :height :auto)))
  (signals cl-styles.properties:style-contract-violation
    (cl-styles.properties:ensure-declarations (list :height :bogus))))

(test property-contract-diagnostics-and-pair-shape
  (let ((condition (make-condition 'cl-styles.properties:style-contract-violation
                                   :where :height :expected :number :got :bad)))
    (is (eq :height (cl-styles.properties:where condition)))
    (is (eq :number (cl-styles.properties:expected condition)))
    (is (eq :bad (cl-styles.properties:got condition)))
    (is (search "height" (string-downcase (princ-to-string condition)))))
  (dolist (plist '((:width) (:width 2 :color)))
    (signals cl-styles.properties:style-contract-violation
      (cl-styles.properties:normalize-declarations plist))
    (signals cl-styles.properties:style-contract-violation
      (cl-styles.properties:ensure-static-declarations plist)))
  (signals cl-styles.properties:style-contract-violation
    (cl-styles.properties:ensure-declarations '(:unregistered 3)))
  (signals cl-styles.properties:style-contract-violation
    (cl-styles.properties:ensure-static-declarations '(:unregistered 3))))

(test property-normalization-preserves-data-and-canonical-aliases
  (let ((result (cl-styles.properties:ensure-declarations
                 '("font-family" "Liberation Mono" :fg :red
                   :color :blue :height "50%" :bold :t
                   :underline :nil :grid-template-columns nil))))
    (is (string= "Liberation Mono" (getf result :font-family)))
    (is (eq :blue (getf result :color)))
    (is (not (member :fg result)))
    (is (string= "50%" (getf result :height)))
    (is (eq t (getf result :bold)))
    (is (null (getf result :underline)))
    (is (member :grid-template-columns result)))
  ;; Normalization is pure: changing the result cannot modify the input.
  (let* ((source '(:fg :red :width 5))
         (result (cl-styles.properties:normalize-declarations source)))
    (setf (getf result :width) 9)
    (is (= 5 (getf source :width))))
  (dolist (invalid '(:nope "x%" "100%%" "-1%"))
    (signals cl-styles.properties:style-contract-violation
      (cl-styles.properties:ensure-declarations (list :width invalid)))))

(test property-types-and-range-boundaries
  (dolist (pair '((:opacity 0) (:opacity 1) (:opacity 0.5)
                  (:aspect-ratio 1/2) (:aspect-ratio 2)
                  (:position :absolute) (:visibility :hidden)
                  (:z-index -2) (:font-family "monospace")
                  (:bold t) (:bold nil)))
    (is (equal (second pair)
               (getf (cl-styles.properties:ensure-declarations pair) (first pair)))))
  (dolist (pair '((:opacity -0.1) (:opacity 1.1) (:opacity :bad)
                  (:aspect-ratio 0) (:aspect-ratio -1)
                  (:position :floating) (:visibility 12)
                  (:font-family :monospace) (:z-index :center)
                  (:bold 2)))
    (signals cl-styles.properties:style-contract-violation
      (cl-styles.properties:ensure-declarations pair))))

(test property-defaults-and-registry-are-observable
  (multiple-value-bind (value found)
      (cl-styles.properties:property-default :unregistered)
    (is (null value))
    (is (null found)))
  (let* ((key :cl-styles-test-explicit-default)
         (registry cl-styles.properties::*property-registry*)
         (prior (multiple-value-list (gethash key registry))))
    (unwind-protect
         (progn
           (cl-styles.properties:register-property
            key '(:type :number :default 0 :default-supplied-p t))
           (multiple-value-bind (value present)
               (cl-styles.properties:property-default key)
             (is (= 0 value))
             (is (not (null present))))
           (is (= 0 (getf (cl-styles.properties:property-defaults) key)))
           (is (equal (cl-styles.properties:property-defaults)
                      (cl-styles.properties:property-defaults))))
      (if (second prior)
          (setf (gethash key registry) (first prior))
          (remhash key registry)))))

(test property-static-variable-fallback-contract
  (let ((variable (cl-styles.tokens:var "--unknown")))
    (is (equal (list :font-size variable)
               (cl-styles.properties:ensure-static-declarations
                (list :font-size variable))))
    (is (equal (list :font-size (cl-styles.tokens:var "--unknown" 12))
               (cl-styles.properties:ensure-static-declarations
                (list :font-size (cl-styles.tokens:var "--unknown" 12)))))
    (signals cl-styles.properties:style-contract-violation
      (cl-styles.properties:ensure-static-declarations
       (list :font-size (cl-styles.tokens:var "--unknown" :large))))
    ;; Nested variables defer validation until the complete environment is known.
    (is (equal (list :font-size
                     (cl-styles.tokens:var "--unknown"
                                           (cl-styles.tokens:var "--fallback")))
               (cl-styles.properties:ensure-static-declarations
                (list :font-size
                      (cl-styles.tokens:var "--unknown"
                                            (cl-styles.tokens:var "--fallback"))))))))

(test property-group-queries-do-not-leak-registry-lists
  (let ((copied (cl-styles.properties:properties-for-group :padding)))
    (setf (first copied) :corrupted)
    (is (not (member :corrupted
                     (cl-styles.properties:properties-for-group :padding)))))
  (is (null (cl-styles.properties:properties-for-group :no-such-group)))
  (is (null (cl-styles.properties:properties-for-layout :no-such-layout)))
  (is (member :gap (cl-styles.properties:properties-for-layout :flex)))
  (is (= 1 (count :display (cl-styles.properties:properties-for-layout :flex)))))

(test registered-extension-types-remain-strict
  "Extenders can register length-typed declarations without weakening validation."
  (let* ((key :cl-styles-test-length)
         (registry cl-styles.properties::*property-registry*)
         (previous (multiple-value-list (gethash key registry))))
    (unwind-protect
         (progn
           (cl-styles.properties:register-property key '(:type :length))
           (is (equal '(:px 4)
                      (getf (cl-styles.properties:ensure-declarations
                             (list key (cl-styles.tokens:px 4))) key)))
           (signals cl-styles.properties:style-contract-violation
             (cl-styles.properties:ensure-declarations (list key 4)))
           (cl-styles.properties:register-property key '(:type :unsupported))
           (signals error
             (cl-styles.properties:ensure-declarations (list key :anything)))
           (cl-styles.properties:register-property key '(:type 42))
           (signals error
             (cl-styles.properties:ensure-declarations (list key 42))))
      (if (second previous)
          (setf (gethash key registry) (first previous))
          (remhash key registry)))))
