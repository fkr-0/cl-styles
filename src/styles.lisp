;; (uiop:define-package :cl-styles.styles (:use #:cl)
;;                      (:nicknames :styles.styles)
;;                      (:import-from :log4cl :log-info :log-debug)
;;                      (:import-from :str :split :join :upcase)
;;                      (:import-from :cl-styles.api :make-style :style :value-possible-values
;;                                    :value-type :value-value :style-prop :style-val :style-property
;;                       :style-property :style-val :property-name :value-value
;;                       :property :value :style-component
;;                                    :style-of :styles :style-of)
;;                      (:import-from :cl-styles.util :keyword-concat :keyword-split)
;;                      (:import-from :cl-styles.util :=?)
;;                      (:export :style-sub-styles :stylegroup-p
;;                               :value :value-value :=? :make-style :ordered-styles))

;; (in-package :cl-styles.styles)


;; (defmethod =? ((s1 property) (s2 property))
;;   "Compare two properties for equality."
;;   (string= (property-name s1) (property-name s2)))

;; (defmethod =? ((v1 value) (v2 value))
;;   "Compare two values for equality."
;;   (and (eql (value-value v1) (value-value v2))
;;        (eql (value-type v1) (value-type v2))
;;        (eql (value-possible-values v1) (value-possible-values v2))))

;; (defmethod =? ((a style) (b style))
;;   "Compare two styles for equality."
;;   (and (=? (style-property a) (style-property b))
;;        (=? (style-val a) (style-val b))))

;; (defun style-p (obj)
;;   "Return T if the given object is a style, NIL otherwise."
;;   (typep obj 'style))

;; (defmethod print-object ((s style) stream)
;;   "Print a representation of the style."
;;   (format stream "Style<~a: ~a>" (style-prop s) (value-value (style-val s))))

;; (defmethod style-prop ((s style))
;;   "Return the property name of the style."
;;   (property-name (style-property s)))

;; (defmethod tuple-prop ((s style))
;;   "Return the property name as a keyword."
;;   (intern (style-prop s) 'keyword))

;; (defmethod tuple-value ((s style))
;;   "Return the value of the style."
;;   (value-value (style-val s)))

;; (defmethod tuple ((s style))
;;   "Return the style as a property-value tuple."
;;   (list (tuple-prop s) (tuple-value s)))

;; (defgeneric apply-after (style stylelist)
;;   (:method ((style t) (stylelist t)) nil)
;;   (:documentation
;;    "Return the style that needs to be applied before this style, or nil if
;; no style needs to be applied before this style."))

;; (defun ordered-p (stylelist)
;;   (dolist (s stylelist)
;;     (when (apply-after s (cdr (member s stylelist)))
;;       (return-from ordered-p s)))
;;   t)

;; (defun exchange (list a b)
;;   (let ((tmp (nth a list)))
;;     (setf (nth a list) (nth b list))
;;     (setf (nth b list) tmp)
;;     list))

;; (defun ordered-styles (stylelist)
;;   "Return the given STYLELIST in the order in which they need to be applied.
;; This is done by sorting the styles according to their :after property, if no
;; valid order can be found, an error is signaled."
;;   (let ((orig (copy-list stylelist)) (ctr 0))
;;     (loop while (not (eq t (ordered-p orig)))
;;           do (let* ((s (ordered-p orig))
;;                     (after (apply-after s (cdr (member s orig)))))
;;                (log-debug "ordered-styles" s)
;;                (setf ctr (1+ ctr))
;;                (when (and after s)
;;                  (setf orig
;;                        (exchange orig (position s orig)
;;                                  (position after orig))))
;;                (when (> ctr 1000)
;;                  (error "Could not order styles: ~a" stylelist)))
;;           finally (return orig))))
;; ;; (defun ordered-styles (styles)
;; ;;   "Sort STYLES respecting dependencies using a topological sort."
;; ;;   (let ((graph (make-hash-table :test 'equal))
;; ;;         (in-degree (make-hash-table :test 'equal))
;; ;;         (sorted-styles '())
;; ;;         (queue '()))

;; ;;     ;; Initialize tables
;; ;;     (dolist (style styles)
;; ;;       (setf (gethash style in-degree) 0)
;; ;;       (setf (gethash style graph) '()))

;; ;;     ;; Populate graph with dependencies
;; ;;     (dolist (style styles)
;; ;;       (dolist (dependency (apply-after style styles))
;; ;;         (push style (gethash dependency graph))
;; ;;         (incf (gethash style in-degree))))

;; ;;     ;; Enqueue styles with no dependencies
;; ;;     (maphash (lambda (style degree)
;; ;;                (when (zerop degree)
;; ;;                  (push style queue)))
;; ;;              in-degree)

;; ;;     ;; Process queue
;; ;;     (loop while queue do
;; ;;       (let ((current (pop queue)))
;; ;;         (push current sorted-styles)
;; ;;         (dolist (dependent (gethash current graph))
;; ;;           (decf (gethash dependent in-degree))
;; ;;           (when (zerop (gethash dependent in-degree))
;; ;;             (push dependent queue)))))

;; ;;     ;; Detect cycles
;; ;;     (when (< (length sorted-styles) (length styles))
;; ;;       (error "Cycle detected in style dependencies, cannot sort"))

;; ;;     (nreverse sorted-styles)))


;; ;;; ===========
;; ;;; Style groups - grouping of styles
;; ;;; (padding-> padding-top, padding-bottom, padding-left, padding-right, padding-char, padding-charstyle...)
;; ;;; ===========


;; (defclass style-group (style)
;;   ((sub-styles :initarg :sub-styles
;;                :accessor style-sub-styles
;;                :initform nil
;;                :documentation "Sub-styles of the style. Sub styles allow grouping of styles.
;; The definition allows to implement a set of styles given a single specification of the implement
;; styles method. This is useful for example for padding and margin, where the implementation is the
;; same for all directions.
;; Styles carrying sub-styles are expected to implement an update method accepting a keyword that
;; specifies one of the sub styles and updates the style instance accordingly. The value of the parent
;; style should be used to implement a configuration of the sub styles."))
;;   (:documentation "A style group represents a group of related styles."))

;; (defmethod value-value ((s list)) "Return the value of the style group." s)

;; (defmethod print-object ((s style-group) stream)
;;   "Print a representation of the style group."
;;   (format stream "StyleGroup<~a>" (style-prop s)))

;; (defmethod stylegroup-p ((obj t)) "Return NIL for non-style-group objects." nil)

;; (defmethod stylegroup-p ((obj style-group))
;;   "Return T if the object is a style group."
;;   t)

;; (defmethod stylegroup-p ((obj symbol))
;;   "Check if the symbol corresponds to a style group."
;;   (let ((obj (find-class (intern (string-upcase (string obj))) nil)))
;;     (member (find-class 'style-group) (sb-mop:class-direct-superclasses obj))))

;; ;; (let ((class (find-class (intern (string-upcase (string obj))) nil)))
;; ;;   (and class (subclassp class (find-class 'style-group)))))

;; (defmethod stylegroup-p ((obj style))
;;   "Check if the style is a style group."
;;   (slot-boundp obj 'sub-styles))

;; (spawn-default-group :padding)
;; Usage:
;; (defstyle :wurst (list :einendig :zweiendig ))
;; (make-style :wurst :einendig) -> Style<WURST: EINENDIG>
;; (make-style :wurst :einendigg) -> Error, invalid value
;; Usage base-styling:
;; (defclass my-stylable (stylable) ())
;; (defmethod init-styles :after ((obj my-stylable))
;;   (setf (style-of (styles obj) :fg-color) :red)
;;   ;; (setf (style-of (styles obj) :box) :ascii)
;;   )
;; (defvar zy (make-instance 'stylable))
;; (setf zy (make-instance 'stylable :id :dud))
;; (defvar zz (make-instance 'my-stylable :id :dud2))
;; (setf zz (make-instance 'my-stylable :id :dud2))
;; (defclass style-group (style)
;;   ((sub-styles :initarg :sub-styles
;;      :accessor style-sub-styles
;;      :initform nil
;;      :documentation "Sub-styles of the style. Sub styles allow grouping of styles.
;; The definition allows to implement a set of styles given a single specification of the implement
;; styles method. This is useful for example for padding and margin, where the implementation is the
;; same for all directions.
;; Styles carrying sub-styles are expected to implement an update method accepting a keyword that
;; specifies one of the sub styles and updates the style instance accordingly. The value of the parent
;; style should be used to implement a configuration of the sub styles.")))
;; (defmethod print-object ((s style-group) stream)
;;   (format stream "StyleGroup<~a>" (style-prop s)))
;; (defgeneric stylegroup-p (obj)
;;   (:documentation
;;     "Return t if the given object is a style group, nil otherwise."))
;; (defmethod stylegroup-p ((obj t))
;;   nil)
;; (defmethod stylegroup-p ((obj style-group))
;;   t)
;; (defmethod stylegroup-p ((obj symbol))
;;   (let ((obj (find-class (intern (string-upcase (string obj))) nil)))
;;     (member (find-class 'style-group) (sb-mop:class-direct-superclasses obj))))
;; (defmethod stylegroup-p ((obj style)) (slot-exists-p obj 'sub-styles))


;;; ─── cl-styles/styles.lisp ────────────────────────────────────────────
(uiop:define-package :cl-styles.styles (:use #:cl)
  (:nicknames :styles.styles)
  (:import-from :log4cl :log-info :log-debug)
  (:import-from :str :split :join :upcase)
  (:import-from :cl-styles.api :make-style :style :value-possible-values
    :value-type :value-value :style-prop :style-val :style-property
    :property-name :value-value :group-styles
    :property :value :style-component :default-styling
    :style-of :styles :style-of)
  (:import-from :cl-styles.util :keyword-concat :keyword-split)
  (:import-from :cl-styles.util :=?)
  (:export :style-sub-styles :stylegroup-p :make-default-styling
    :tuple :tuple-prop :tuple-value :value-value :=?  :style-p
    :illegal-group-value
    :value :value-value :=?  :ordered-styles :style-prop))
(in-package :cl-styles.styles)

(defmethod =? ((s1 property) (s2 property))
  "Compare two properties for equality."
  (string= (property-name s1) (property-name s2)))

(define-condition illegal-group-value (error)
  ((style :initarg :style :reader style)
    (value :initarg :value :reader value))
  ;; (:report (lambda (condition stream)
  ;;            (format stream "Illegal value ~A for style ~A in stylable.." (type-of value)
  ;;              (style style)
  ;;              )))
  )

(defmethod =? ((v1 value) (v2 value))
  "Compare two values for equality."
  (and (eql (value-value v1) (value-value v2))
    (eql (value-type v1) (value-type v2))
    (eql
      (and (slot-boundp v1 'cl-styles.api::possible-values)
        (value-possible-values v1))
      (and (slot-boundp v2 'cl-styles.api::possible-values)
        (value-possible-values v2)))))
;; (defparameter sample-value (make-instance 'value :value "red" :type 'string))
;; (slot-boundp sample-value 'cl-styles.api::possible-values)

(defmethod =? ((a style) (b style))
  "Compare two styles for equality."
  (and (=? (style-property a) (style-property b))
    (=? (style-val a) (style-val b))))

(defun style-p (obj)
  "Return T if the given object is a style, NIL otherwise."
  (typep obj 'style))

(defmethod print-object ((s style) stream)
  "Print a representation of the style."
  (format stream "Style<~a: ~a>"
    (style-prop s)
    (let* ((sv (style-val s))
            (sva (and sv (value-value sv))))
      sva)))

(defmethod style-prop ((s style))
  "Return the property name of the style."
  (property-name (style-property s)))

(defmethod tuple-prop ((s style))
  "Return the property name as a keyword."
  (intern (style-prop s) 'keyword))

(defmethod tuple-value ((s style))
  "Return the value of the style."
  (value-value (style-val s)))

(defmethod tuple ((s style))
  "Return the style as a property-value tuple."
  (list (tuple-prop s) (tuple-value s)))

(defgeneric apply-after (style stylelist)
  (:method ((style t) (stylelist t)) nil)
  (:documentation
    "Return the style that needs to be applied before this style, or nil if
no style needs to be applied before this style."))

(defun ordered-p (stylelist)
  (dolist (s stylelist)
    (when (apply-after s (cdr (member s stylelist)))
      (return-from ordered-p s)))
  t)

(defun exchange (list a b)
  (let ((tmp (nth a list)))
    (setf (nth a list) (nth b list))
    (setf (nth b list) tmp)
    list))


(defun kw-specializer (meth)
  "Return the keyword specializer of the given method, or nil if the method does not have a keyword specializer.
This is a workaround for a bug in SBCL that causes the specializer of a method to be a list of the keyword
specializer and the object specializer, instead of just the keyword specializer.

See: https://bugs.launchpad.net/sbcl/+bug/1300628

  Args:
    meth: The method to get the keyword specializer of.
  Returns:
    The keyword specializer of the given method, or nil if the method does not have a keyword specializer.
  Example:
    ;; This should return :foo, but returns (:foo t) instead.
    (sb-mop:method-specializers (find-method #'foo '(:foo) '(:bar)))
    ;; This returns :foo as expected.
    (kw-specializer (find-method #'foo '(:foo) '(:bar)))"
  (when (slot-exists-p (first (sb-mop:method-specializers meth))
          'sb-pcl::object)
    (slot-value (first (sb-mop:method-specializers meth)) 'sb-pcl::object)))

(defun make-default-styling ()
  "Create a list of default styles for the style system. Calls all styles that
implement a default-styling method with the specializers of the method as arguments."
  (let ((styles nil))
    (dolist (method (sb-mop:generic-function-methods #'default-styling))
      (let ((r (kw-specializer method)))
        (when r
          (push (funcall #'default-styling r) styles))))
    styles))

;; (defgeneric default-styling (kw)
;;   (:method ((kw symbol)) (error "No default styling for ~A." kw))
;;   (:documentation "Return the default styling for a given style property."))

;; (defgeneric valid-style-value-p (style value)
;;   (:method ((style style) value)
;;     (error "No valid-style-value-p method for ~A." style))
;;   (:documentation
;;    "Return T if the given value is valid for the given style, NIL otherwise."))

(defgeneric style-group-key (style)
  (:method ((style t)) nil)
  (:documentation
    "Return the key of the style group that the given style belongs to, or NIL if it doesn't belong to a group."))



(defun ordered-styles (stylelist)
  "Return the given STYLELIST in the order in which they need to be applied.
This is done by sorting the styles according to their :after property, if no
valid order can be found, an error is signaled."
  (let ((orig (copy-list stylelist)) (ctr 0))
    (loop while (not (eq t (ordered-p orig)))
      do (let* ((s (ordered-p orig))
                 (after (apply-after s (cdr (member s orig)))))
           (log-debug "ordered-styles" s)
           (setf ctr (1+ ctr))
           (when (and after s)
             (setf orig
               (exchange orig (position s orig)
                 (position after orig))))
           (when (> ctr 1000)
             (error "Could not order styles: ~a" stylelist)))
      finally (return orig))))

;; -- Style Group Refactoring --
(defclass style-group (style)
  ((sub-styles :initarg :sub-styles
     :accessor style-sub-styles
     :initform nil
     :documentation "Sub-styles of the style. Sub styles allow grouping of related styles.
The value of the parent style is used to configure the sub-styles."))
  (:documentation "A style group represents a group of related styles."))

(defmethod print-object ((s style-group) stream)
  "Print a representation of the style group."
  (format stream "StyleGroup<~a>" (style-prop s)))

(defmethod style-sub-styles ((s null))
  "Return the sub-styles of the style group."
  nil)

(defmethod value-value ((s style-group))
  "Return the sub-styles of the style group."
  (style-sub-styles s))

;; Existing stylegroup-p methods:
(defmethod stylegroup-p ((obj t)) "Return NIL for non-style-group objects." nil)
(defmethod stylegroup-p ((obj style-group))
  "Return T if the object is a style group."
  t)
(defmethod stylegroup-p ((obj symbol))
  "Check if the symbol corresponds to a style group."
  (let ((obj (find-class (intern (string-upcase (string obj))) nil)))
    (and obj
      (member (find-class 'style-group) (sb-mop:class-direct-superclasses obj)))))
(defmethod stylegroup-p ((obj style))
  "Check if the style is a style group."
  (slot-boundp obj 'sub-styles))

;; End of styles.lisp
