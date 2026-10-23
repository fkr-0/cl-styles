(uiop:define-package :cl-styles.tests/adapters-protocols
  (:use :cl :fiveam)
  (:export))

(in-package :cl-styles.tests/adapters-protocols)

(def-suite cl-styles/adapters-protocols
  :in cl-styles.tests:cl-styles-test)
(in-suite cl-styles/adapters-protocols)

(test adapter-render-projection-honors-canonical-precedence
  (let ((style (cl-styles.adapters:normalize-tui-style-plist
                '(:color :green :fg :red :fg-color :blue
                  :background-color :black :bg :white
                  :attrs (:underline :bold)
                  :bold nil :italic t :blink :t))))
    (is (eq :green (getf style :fg-color)))
    (is (eq :black (getf style :bg-color)))
    (is (not (member :bold (getf style :attrs))))
    (is (member :underline (getf style :attrs)))
    (is (member :italic (getf style :attrs)))
    (is (member :blink (getf style :attrs))))
  (is (equal '(:fg-color nil :bg-color nil :attrs nil)
             (cl-styles.adapters:normalize-tui-style-plist nil))))

(test adapter-render-projection-legacy-aliases-and-removal
  (let* ((source '(:foreground-color :cyan :background :magenta
                   :attributes (:strike :faint)
                   :strike :nil :inverse t :invisible nil))
         (style (cl-styles.adapters:normalize-tui-style-plist source)))
    (is (eq :cyan (getf style :fg-color)))
    (is (eq :magenta (getf style :bg-color)))
    (is (not (member :strike (getf style :attrs))))
    (is (member :faint (getf style :attrs)))
    (is (member :inverse (getf style :attrs)))
    (is (not (member :invisible (getf style :attrs))))
    (is (equal '(:strike :faint) (getf source :attributes))))
  (let ((style (cl-styles.adapters:normalize-tui-style-plist
                '(:fg :red :bg-color :blue :attrs (:bold)))))
    (is (eq :red (getf style :fg-color)))
    (is (eq :blue (getf style :bg-color)))
    (is (member :bold (getf style :attrs)))))

(test adapter-ingress-border-variants-and-attribute-flags
  (let* ((source '(:box :double :border 3 :border-style :dotted
                   :border-top-color (255 0 128)
                   :bold :t :underline :nil :italic t
                   :attributes (:underline :faint)))
         (out (cl-styles.adapters:normalize-tui-declarations source)))
    (is (= 3 (getf out :border)))
    (is (eq :dotted (getf out :border-style)))
    (is (equal '(:rgb 255 0 128) (getf out :border-top-color)))
    (is (member :bold (getf out :attributes)))
    (is (member :italic (getf out :attributes)))
    (is (member :faint (getf out :attributes)))
    (is (not (member :underline (getf out :attributes))))
    (is (null (member :box out)))
    (is (member :box source)))
  (dolist (pair '((:none :none) (:solid :solid) (:double :double)))
    (let ((result (cl-styles.adapters:normalize-tui-declarations
                   (list :box (first pair)))))
      (is (= 1 (getf result :border)))
      (is (eq (second pair) (getf result :border-style))))))

(test adapter-ingress-colors-boundary-and-canonical-spellings
  (let* ((result (cl-styles.adapters:normalize-tui-declarations
                  '(:direction :row :spacing 3 :justify :end
                    :fg-color (2 3 4) :bg-color (255 255 255)
                    :border-left-color (1 2 3)
                    :border-right-color :red
                    :border-bottom-color (:rgb 4 5 6))))
         (canonical (cl-styles.properties:ensure-declarations result)))
    (is (eq :row (getf canonical :flex-direction)))
    (is (eq :flex-end (getf canonical :justify-content)))
    (is (= 3 (getf canonical :gap)))
    (is (equal '(:rgb 2 3 4) (getf canonical :color)))
    (is (equal '(:rgb 255 255 255) (getf canonical :background-color)))
    (is (equal '(:rgb 1 2 3) (getf canonical :border-left-color)))
    (is (eq :red (getf canonical :border-right-color)))
    (is (equal '(:rgb 4 5 6) (getf canonical :border-bottom-color))))
  ;; Malformed color tuples must survive normalization unchanged, so the strict
  ;; property contract (rather than a lossy adapter) can reject them.
  (let ((result (cl-styles.adapters:normalize-tui-declarations
                 '(:color (256 3 4)))))
    (is (equal '(256 3 4) (getf result :color)))
    (signals cl-styles.properties:style-contract-violation
      (cl-styles.properties:ensure-declarations result)))
  (let ((result (cl-styles.adapters:normalize-tui-declarations
                 '(:border :t :box :single))))
    (is (= 1 (getf result :border)))
    (is (eq :solid (getf result :border-style)))))

;; The generic default protocol contract is useful outside ElmTUI's node
;; classes.  Keep the fixture minimal and do not override defaults under test.
(defclass fallback-node ()
  ((id :initarg :id :reader fallback-id :initform nil)
   (kind :initarg :kind :reader fallback-kind :initform :widget)))

(defmethod cl-styles.protocols:stylable-id ((node fallback-node))
  (fallback-id node))
(defmethod cl-styles.protocols:stylable-type ((node fallback-node))
  (fallback-kind node))

(test protocol-defaults-are-safe-for-custom-nodes
  (let ((node (make-instance 'fallback-node :id :entry)))
    (is (null (cl-styles.protocols:stylable-classes node)))
    (is (null (cl-styles.protocols:stylable-inline-style node)))
    (is (null (cl-styles.protocols:stylable-attributes node)))
    (is (null (cl-styles.protocols:stylable-state node)))
    (is (null (cl-styles.protocols:stylable-namespace node)))
    (is (null (cl-styles.protocols:stylable-theme node)))
    (is (eq :entry (cl-styles.protocols:stylable-key node)))))

(test protocol-key-falls-back-to-type-and-attributes
  (let ((node (make-instance 'fallback-node :kind :panel)))
    (is (equal '(:panel) (cl-styles.protocols:stylable-key node)))))

(defclass attributed-fallback-node (fallback-node)
  ((attrs :initarg :attrs :reader fallback-attrs)))
(defmethod cl-styles.protocols:stylable-attributes ((node attributed-fallback-node))
  (fallback-attrs node))

(test protocol-key-includes-attributes-without-an-id
  (let ((node (make-instance 'attributed-fallback-node
                             :kind :panel :attrs '(:role :dialog))))
    (is (equal '(:panel :role :dialog)
               (cl-styles.protocols:stylable-key node)))))

(test api-package-reexports-public-contracts
  "Package definitions execute during load; verify all selected public exports
instead of pretending they are reached by ordinary SB-COVER function calls."
  (dolist (entry '((:cl-styles.protocols "STYLABLE-TYPE")
                   (:cl-styles.protocols "STYLABLE-THEME")
                   (:cl-styles.tokens "RESOLVE-VARIABLES")
                   (:cl-styles.selector "MATCH-SELECTOR-P")
                   (:cl-styles.rule "EXPAND-SHORTHANDS")
                   (:cl-styles.sheet "STYLESHEET-REVISION")
                   (:cl-styles.properties "PROPERTY-DEFAULTS")
                   (:cl-styles.adapters "NORMALIZE-TUI-STYLE-PLIST")
                   (:cl-styles.engine "COMPUTE-STYLE-RESULT")))
    (multiple-value-bind (origin origin-status)
        (find-symbol (second entry) (first entry))
      (multiple-value-bind (public public-status)
          (find-symbol (second entry) :cl-styles.api)
        (is (eq :external origin-status))
        (is (eq :external public-status))
        (is (eq origin public))))))
