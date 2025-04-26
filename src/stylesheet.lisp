;;; ─── cl-styles/stylesheet.lisp ─────────────────────────────────────────
(uiop:define-package :cl-styles.stylesheet
  (:nicknames :styles.stylesheet)
  (:use :common-lisp)
  (:import-from :log4cl :log-info)
  (:import-from :cl-styles.api :stylesheet :make-style
    :stylesheet-rules :style-set :rule-styles
    :value-value :style-val
    :style-property :style)
  (:import-from :cl-styles.util :=?)
  (:import-from :cl-styles.util :hash-table-keys)
  (:import-from :cl-styles.styles :tuple-prop :stylegroup-p
    :styles :style-group :style-sub-styles :tuple-value)
  (:import-from :cl-styles.style-set :new :copy
    :*default-styles* :style-of :merge-styles!
    :style-set-styles)
  (:import-from :cl-styles.rule :defrule :style-rule
    :rule-selector )
  (:import-from :cl-styles.selector :selects :cls>
    :selection-specificity :cl-cls)
  (:export  :add-rule :query-style-sheet :merge-rule!
    :defstylesheet :my-stylesheet ))
(in-package :cl-styles.stylesheet)

(defmethod merge-rule! ((sheet stylesheet) (rule style-rule))
  "Add or merge a style rule RULE into the stylesheet SHEET."
  (let ((existing-rule
          (find (rule-selector rule) (stylesheet-rules sheet)
            :test #'=?
            :key #'rule-selector)))
    (if existing-rule
      (merge-styles! (rule-styles existing-rule) (rule-styles rule))
      (push rule (stylesheet-rules sheet))))
  sheet)

(defmethod query-style-sheet ((sheet stylesheet) target)
  "Query the stylesheet for styles that apply to the target stylable object.
Returns a style set containing the styles that apply to the target."
  (let ((styles (copy (styles target)))
         (specificity-table (make-hash-table :test #'eql)))
    (maphash
      (lambda (key value)
        (setf (gethash key specificity-table)
          (cons (value-value (style-val value)) 0)))
      (style-set-styles styles))
    (dolist (rule (stylesheet-rules sheet))
      (when (selects (rule-selector rule) target)
        (let ((spec (selection-specificity (rule-selector rule))))
          (maphash
            (lambda (key value)
              (let* ((current (gethash key specificity-table))
                      (current-spec (or (and (listp current) (cdr current)) -1)))
                (when (> spec current-spec)
                  (setf (gethash key specificity-table)
                    (cons (value-value (style-val value)) spec)))))
            (style-set-styles (rule-styles rule))))))
    (maphash
      (lambda (key value)
        (setf (style-of styles key) (make-style key (car value))))
      specificity-table)
    styles))

(defmacro defstylesheet (&body rules)
  "Macro to define a stylesheet with the given style rules."
  `(let ((sheet (make-instance 'stylesheet :rules nil)))
     (dolist (rule (list ,@rules))
       (merge-rule! sheet rule))
     sheet))

(defvar item
  (defrule (cls> "item")
    (:box :single))
  "Style rule for items.")

(defvar focus
  (defrule (cls> "focus")
    (:bg-color 102)
    (:fg-color 46))
  "Style rule for focus.")

(defvar unfocus
  (defrule (cls> "unfocus")
    (:bg-color 26)
    (:fg-color 122))
  "Style rule for unfocus.")

(defvar label
  (defrule (cls> "label")
    (:box :none)
    (:underline t)
    (:align :center))
  "Style rule for label.")

(defvar scroll
  (defrule (cls> "scroll")
    (:scrollbar-v t)
    (:width 12) (:height 19))
  "Style rule for scroll.")

(defvar my-stylesheet
  (defstylesheet
    (defrule (cls> "button")
      (:box :ascii))
    label
    (defrule (cls> "container")
      (:box :single :bg-color 33 :fg-color 12))
    focus
    unfocus
    scroll)
  "A sample stylesheet.")
;; End of stylesheet.lisp

;; (uiop:define-package :cl-styles.stylesheet
;;   (:nicknames :styles.stylesheet)
;;   (:use :common-lisp)
;;   (:import-from :log4cl :log-info)
;;   (:import-from :cl-styles.api :stylesheet :make-style
;;    :stylesheet-rules :style-set :rule-styles
;;                 :value-value :style-val
;;                 :style-property :style)
;;   (:import-from :cl-styles.util :=?)
;;   (:import-from :cl-styles.util :hash-table-keys)
;;   (:import-from :cl-styles.styles :tuple-prop :stylegroup-p
;;    :styles :style-group :style-sub-styles :tuple-value)
;;   (:import-from :cl-styles.style-set :new :copy
;;    :*default-styles* :style-of :merge-styles!
;;                 :style-set-styles)
;;   (:import-from :cl-styles.rule :defrule :style-rule
;;    :rule-selector )
;;   (:import-from :cl-styles.selector :selects :cls>
;;    :selection-specificity :cl-cls>)
;;   (:export  :add-rule :query-style-sheet
;;             :defstylesheet :my-stylesheet ))

;; (in-package :cl-styles.stylesheet)



;; (defmethod merge-rule! ((sheet stylesheet) (rule style-rule))
;;   "Add or merge a style rule RULE into the stylesheet SHEET.

;; If a rule with the same selector already exists in the stylesheet, the
;; styles of the existing rule are merged with the styles of the new rule.
;; That means if the same style property is set in both rules, the value
;; from the new rule will overwrite the value from the existing rule, otherwise
;; the new style property is added to the existing rule.

;; Arguments:
;; SHEET: The stylesheet to add the rule to.
;; RULE: The rule to add to the stylesheet.

;; Returns:
;; The stylesheet with the new or merged rule.

;; Example:
;;   (merge-rule!
;;     (defstylesheet
;;       (defrule (cls> \"button\")
;;         (:box :ascii)))
;;     (defrule (cls> \"button\") (:bg-color :blue :fg-color :white)))
;;   => #<STYLESHEET {1001F3D3B3}> ;; equiv:
;;   <=> (defstylesheet
;;         (defrule (cls> \"button\")
;;           (:box :ascii :bg-color :blue :fg-color :white)))"
;;   (let ((existing-rule
;;           (find (rule-selector rule) (stylesheet-rules sheet)
;;                 :test #'=?
;;                 :key #'rule-selector)))
;;     (if existing-rule
;;         (merge-styles! (rule-styles existing-rule) (rule-styles rule))
;;         (push rule (stylesheet-rules sheet))))
;;   sheet)

;; (defmethod query-style-sheet ((sheet stylesheet) target)
;;   "Query the stylesheet for styles that apply to the target stylable object.
;; Returns a style set containing the styles that apply to the target."
;;   (let ((styles (copy (styles target)))
;;         (specificity-table (make-hash-table :test #'eql)))
;;     ;; Add the target's own styles with base specificity
;;     (maphash
;;      (lambda (key value)
;;        (setf (gethash key specificity-table)
;;              (cons (value-value (style-val value)) 0)))
;;      (style-set-styles styles))
;;     ;; Apply rules from the stylesheet
;;     (dolist (rule (stylesheet-rules sheet))
;;       (when (selects (rule-selector rule) target)
;;         (let ((spec (selection-specificity (rule-selector rule))))
;;           (maphash
;;            (lambda (key value)
;;              ;; (log-info "Key: ~a Value: ~a" key value)
;;              (let* ((current (gethash key specificity-table))
;;                     (current-spec (or (and (listp current) (cdr current)) -1)))
;;                (when (> spec current-spec)
;;                  (setf (gethash key specificity-table)
;;                        (cons (value-value (style-val value)) spec)))))
;;            (style-set-styles (rule-styles rule))))))
;;     ;; Update styles with the highest specificity
;;     (maphash
;;      (lambda (key value)
;;        (setf (style-of styles key) (make-style key (car value))))
;;      specificity-table)
;;     styles))

;; (defmacro defstylesheet (&body rules)
;;   "Macro to define a stylesheet with the given style rules."
;;                                         ;`(make-instance 'stylesheet :rules (list ,@rules)))
;;   ;; instead: merge-rule foreach rule of rules:
;;   `(let ((sheet (make-instance 'stylesheet :rules nil)))
;;      (dolist (rule (list ,@rules))
;;        (merge-rule! sheet rule))
;;      sheet))

;; ;; specificity usage:
;; ;; TODO !
;; ;; (let ((m (make-hash-table :test #'eql)))
;; ;;   (setf (gethash :a m) 30)
;; ;;   (setf (gethash :b m) 20)
;; ;;   (key-with-highest-value m))
;; ;;;;;;;;
;; ;; TODO necessary?
;; ;; (defmethod update-matched-objects ((rule style-rule) obj-list)
;; ;;   "Update the matched objects for a style rule."
;; ;;   ;; Find all objects that match the rule's selector.
;; ;;   (let ((new nil))
;; ;;     (dolist (object obj-list)
;; ;;       (if (matches? object (rule-selector rule))
;; ;;         (progn
;; ;;           (push object new)
;; ;;           (when (not (member object (matched-objects rule)))
;; ;;             ;; Mark the object as dirty.
;; ;;             (setf (dirty object) t)))
;; ;;         (when (member object (matched-objects rule))
;; ;;           (setf (dirty object) t))))
;; ;;     ;; Clear the old matched objects.
;; ;;     (setf (matched-objects rule) new)))
;; ;; example

;; (defvar item
;;   (defrule (cls> "item")
;;     ;; (:bg-color :blue)
;;     ;; (:fg-color :white)
;;     (:box :single)
;;     ;; (:padding 0)
;;     ))

;; (defvar focus
;;   (defrule (cls> "focus")
;;     (:bg-color 102)
;;     (:fg-color 46)))

;; (defvar unfocus
;;   (defrule (cls> "unfocus")
;;     (:bg-color 26)
;;     (:fg-color 122)))

;; (defvar label
;;   (defrule (cls> "label")
;;     (:box :none)
;;     (:underline t)
;;     (:align :center)))
;; (defvar label
;;   (defrule (cls> "list-item")
;;     (:box :none)
;;     (:underline t)
;;     (:align :center)))
;; (defvar scroll
;;   (defrule (cls> "scroll")
;;     (:scrollbar-v t)
;;     (:width 12) (:height 19)))

;; (defvar my-stylesheet
;;   (defstylesheet
;;     (defrule (cls> "button")
;;       (:box :ascii))
;;     ;;   ;; ( :margin 0)
;;     ;;   )
;;     ;; (defrule (cls> "important") (:fg-color :red :bold t))
;;     ;; label focus item
;;     label
;;     (defrule (cls> "container")
;;       (:box :single :bg-color 33 :fg-color 12))
;;     focus
;;     unfocus
;;     scroll))
