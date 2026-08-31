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
