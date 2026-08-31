(in-package :cl-styles.properties)

(define-condition style-contract-violation (error)
  ((expected :initarg :expected :reader expected)
    (got      :initarg :got      :reader got)
    (where    :initarg :where    :reader where))
  (:report (lambda (c s)
             (format s "Style contract violation at ~A: expected ~A, got ~S"
               (where c) (expected c) (got c))
             )))

(defparameter *property-registry* (make-hash-table :test 'eql))
(defparameter *property-aliases* (make-hash-table :test 'eql))
(defparameter *groups* (make-hash-table :test 'eql))
(defparameter *layout-groups* (make-hash-table :test 'eql))

(defun register-property (name def)
  (setf (gethash name *property-registry*) def))

(defun register-property-alias (alias canonical-name)
  "Register ALIAS as an alternate spelling for CANONICAL-NAME."
  (setf (gethash (%ensure-keyword alias) *property-aliases*)
        (%ensure-keyword canonical-name)))

(defun property-definition (name)
  (gethash name *property-registry*))

(defmacro defproperty (name &key type enum synonyms group (default nil default-p) doc)
  `(register-property ,name
     (list :type ,(if (and (consp type) (eq (car type) 'lambda)) `#',type `',type)
           :enum ',enum
           :synonyms (%mk-syns ,@synonyms)
           :group ',group
           :default ',default
           :default-supplied-p ,default-p
           :doc ,doc)))


(defun define-group (group &rest props)
  (setf (gethash group *groups*) (remove-duplicates props :test 'eql)))

(defun properties-for-group (group)
  (copy-list (or (gethash group *groups*))))

(defun groups-for-layout (layout &rest groups)
  (setf (gethash layout *layout-groups*) (remove-duplicates groups :test 'eql)))

(defun properties-for-layout (layout)
  (let ((gs (or (gethash layout *layout-groups*) )))
    (remove-duplicates (apply #'append (mapcar #'properties-for-group gs)) :test 'eql)))

;; basic type predicates
(defun %keyword-p (x) (and (symbolp x) (keywordp x)))
(defun %number-p (x) (numberp x))
(defun %string-p (x) (stringp x))
(defun %length-p (x)
  (and (consp x) (member (first x) '(:px :percent :em :rem :ch))))

(defun %ensure-keyword (x)
  (cond
    ((keywordp x) x)
    ((symbolp x) (intern (string-upcase (symbol-name x)) :keyword))
    ((stringp x) (intern (string-upcase x) :keyword))
    (t x)))

(defun %normalize-key (k)
  (let ((key (%ensure-keyword k)))
    (or (gethash key *property-aliases*) key)))

(defun %normalize-value (prop v)
  (let* ((def (property-definition prop))
          (type-of-prop (getf def :type nil))
          (syns (getf def :synonyms nil)))
    (cond
      ;; Preserve strings for string properties
      ((and (eq type-of-prop :string) (stringp v)) v)
      ;; Handle synonyms
      ((and syns (hash-table-p syns))
        (let ((vv (%ensure-keyword v)))
          (multiple-value-bind (m present) (gethash vv syns)
            (if present m vv))))
      ;; Default: convert to keyword
      (t (%ensure-keyword v)))))

(defun %check-type (prop v)
  (let* ((def (or (property-definition prop)
                  (error 'style-contract-violation
                         :expected :known-property
                         :got prop
                         :where prop)))
          (type (getf def :type nil))
          (enum (getf def :enum nil))
          (nv (%normalize-value prop v)))
    (flet ((fail (expected)
             (error 'style-contract-violation :expected expected :got nv :where prop)))
      (when enum
        (unless (member nv enum :test 'eql)
          (fail `(one-of ,@enum))))
      (when type
        (cond
          ((keywordp type)
            (case type
              (:keyword (unless (%keyword-p nv) (fail :keyword)))
              (:number  (unless (%number-p nv)  (fail :number)))
              (:length  (unless (%length-p nv)  (fail :length)))
              (:string  (unless (%string-p nv)  (fail :string)))
              (t (error "Unknown keyword property type: ~A" type))))
          ((functionp type)
            (unless (funcall type nv)
              (fail type)))
          (t (error "Invalid type specifier: ~A" type)))))
    nv))

(defun normalize-declarations (plist)
  "Normalize the keys and values in a property list (PLIST).

This function ensures that all keys in the property list are normalized
(using `%normalize-key`) and that their corresponding values are also normalized
(using `%normalize-value`). The original keys are replaced with their normalized
versions, and duplicate keys are avoided.

Arguments:
- PLIST: A property list where keys and values may need normalization.

Returns:
- A new property list with normalized keys and values.

Example:
  (normalize-declarations '(:MARGIN-LEFT 10 :MARGIN-RIGHT 10 :MARGIN-BOTTOM 5 :MARGIN-TOP 5
                           :PADDING-LEFT 10 :PADDING-BOTTOM 10 :PADDING-RIGHT 10 :PADDING-TOP 10
                           :COLOR :BLUE :PADDING 10 :MARGIN (5 10) :FONT-FAMILY \"Arial\"))
  ;; Returns: (:MARGIN-LEFT 10 :MARGIN-RIGHT 10 :MARGIN-BOTTOM 5 :MARGIN-TOP 5
  ;;           :PADDING-LEFT 10 :PADDING-BOTTOM 10 :PADDING-RIGHT 10 :PADDING-TOP 10
  ;;           :COLOR :BLUE :PADDING 10 :MARGIN (5 10) :FONT-FAMILY \"Arial\")"
  (unless (evenp (length plist))
    (error 'style-contract-violation
           :expected :property-value-pairs
           :got plist
           :where :declarations))
  (let ((result nil))
    (loop for (key value) on plist by #'cddr
          for normalized-key = (%normalize-key key)
          for normalized-value = (%normalize-value normalized-key value)
          do (setf (getf result normalized-key) normalized-value))
    result))

;; (getf (property-definition :font-family) :type)
;; (normalize-declarations '(:MARGIN-LEFT 10 :MARGIN-RIGHT 10 :MARGIN-BOTTOM 5 :MARGIN-TOP 5 :PADDING-LEFT
;;                           10 :PADDING-BOTTOM 10 :PADDING-RIGHT 10 :PADDING-TOP 10 :COLOR :BLUE :PADDING
;;                           10 :MARGIN (5 10) :FONT-FAMILY "Arial"))

(defun validate-declarations (plist)
  "Validate the types of values in a property list (PLIST) against their definitions.
This function checks each key-value pair in the property list to ensure that
the value conforms to the expected type defined for that property. If a value
does not match the expected type, a `style-contract-violation` error is raised.

Arguments:
- PLIST: A property list where keys are property names and values are the corresponding values to validate.
Returns:
- The original property list if all values are valid.
Raises:
- `style-contract-violation`: If any value does not conform to the expected type for its property."
  (loop for (k v) on plist by #'cddr do
    (let* ((kk (%normalize-key k))
            (vv (%normalize-value kk v)))
      (unless (property-definition kk)
        (error 'style-contract-violation
               :expected :known-property
               :got kk
               :where kk))
      (%check-type kk vv)))
  plist)

(defun ensure-declarations (plist)
  (validate-declarations (normalize-declarations plist)))

(defun property-default (name)
  "Return a property's explicit default and whether a default was supplied."
  (let ((definition (property-definition (%normalize-key name))))
    (if (and definition (getf definition :default-supplied-p))
        (values (getf definition :default) t)
        (values nil nil))))

(defun property-defaults ()
  "Return a deterministic plist of explicitly declared property defaults."
  (let ((keys nil))
    (maphash (lambda (key definition)
               (when (getf definition :default-supplied-p)
                 (push key keys)))
             *property-registry*)
    (loop for key in (sort keys #'string< :key #'symbol-name)
          append (multiple-value-bind (value present-p) (property-default key)
                   (if present-p (list key value) nil)))))

(defun ensure-static-declarations (plist)
  "Validate static declaration shape, known properties, and literal values.
Variable references are type-checked after resolution; a literal fallback is checked now."
  (unless (evenp (length plist))
    (error 'style-contract-violation
           :expected :property-value-pairs :got plist :where :declarations))
  (loop for (key value) on plist by #'cddr
        for normalized-key = (%normalize-key key)
        do (unless (property-definition normalized-key)
             (error 'style-contract-violation
                    :expected :known-property :got normalized-key :where normalized-key))
           (cond
             ((cl-styles.tokens:variable-ref-p value)
              (when (and (= (length value) 3)
                         (not (cl-styles.tokens:variable-ref-p (third value))))
                (%check-type normalized-key (third value))))
             (t (%check-type normalized-key value))))
  plist)


;;; ----------------- seed: groups + common properties ----------------------

;; box groups
(define-group :padding :padding :padding-top :padding-right :padding-bottom :padding-left)
(define-group :margin  :margin  :margin-top  :margin-right  :margin-bottom  :margin-left)
(define-group :border  :border :border-width :border-top-width :border-right-width :border-bottom-width :border-left-width)
(apply #'define-group :box
  (append (properties-for-group :padding)
    (properties-for-group :margin)
    (properties-for-group :border)))

;; layout groups
(define-group :flex
  :display :flex :flex-flow :flex-direction :flex-wrap :justify-content
  :align-items :align-content :gap :row-gap :column-gap :order
  :flex-grow :flex-shrink :flex-basis)

(define-group :grid :display :grid-template-columns :grid-template-rows :grid-template-areas :grid-auto-flow :grid-auto-columns :grid-auto-rows :gap :grid-gap :row-gap :column-gap :justify-items :align-items :justify-content :align-content)
(define-group :block :display :width :height :min-width :max-width :min-height :max-height)

;; layout -> groups mapping
(groups-for-layout :flex :box :flex)
(groups-for-layout :grid :box :grid)
(groups-for-layout :block :box :block)

;; common properties and enums
(defun %mk-syns (&rest pairs)
  (let ((ht (make-hash-table :test 'equal)))
    (loop for (a b) on pairs by #'cddr do (setf (gethash a ht) b)) ht))

(defproperty :display :type :keyword :enum (:block :flex :grid :none))
(defun %dimension-value-p (value)
  "Accept the dimension forms cl-styles preserves losslessly for ElmTUI."
  (or (numberp value)
      (member value '(:auto :fill) :test #'eql)))

(defproperty :width  :type (lambda (value) (%dimension-value-p value)))
(defproperty :height :type (lambda (value) (%dimension-value-p value)))

(defproperty :min-width  :type :number)
(defproperty :max-width  :type :number)
(defproperty :min-height :type :number)
(defproperty :max-height :type :number)
;; Terminal-oriented geometry hints used by maintained viewport/container DSL.
;; OFFSET-* affects placement at the owning renderer/layout boundary; SCROLL-*
;; records the logical content translation.  Registering them here makes the
;; shared style contract agree with the declarations emitted by ElmTUI widgets.
(defproperty :offset-x :type :number)
(defproperty :offset-y :type :number)
(defproperty :scroll-x :type :number)
(defproperty :scroll-y :type :number)

;; flex props
(defproperty :flex
  :type (lambda (value)
          (or (numberp value)
              (and (listp value)
                   (member (length value) '(2 3))
                   (every #'numberp value))))
  :group :flex)

(defproperty :flex-flow
  :type (lambda (value)
          (and (listp value)
               (= (length value) 2)
               (member (first value) '(:row :row-reverse :column :column-reverse))
               (member (second value) '(:nowrap :wrap :wrap-reverse))))
  :group :flex)

(defproperty :flex-direction :type :keyword :enum (:row :row-reverse :column :column-reverse))
(defproperty :flex-wrap      :type :keyword :enum (:nowrap :wrap :wrap-reverse))
(defproperty :justify-content :type :keyword :enum (:flex-start :flex-end :center :space-between :space-around :space-evenly)
  :synonyms (:start :flex-start :end :flex-end))
(defproperty :align-items    :type :keyword :enum (:stretch :flex-start :flex-end :center :baseline)
  :synonyms (:start :flex-start :end :flex-end))

(defproperty :align-content  :type :keyword :enum (:stretch :flex-start :flex-end :center :space-between :space-around :space-evenly)
  :synonyms (:start :flex-start :end :flex-end))
(defproperty :gap :type :number)
(defproperty :row-gap :type :number)
(defproperty :column-gap :type :number)
(defproperty :order :type :number)
(defproperty :flex-grow :type :number)
(defproperty :flex-shrink :type :number)
(defproperty :flex-basis :type :number)

;; grid props
(defproperty :grid-template-columns :type (lambda (v) (or (null v) (listp v))))
(defproperty :grid-template-rows    :type (lambda (v) (or (null v) (listp v))))
(defproperty :grid-template-areas   :type (lambda (v) (or (null v) (listp v))))
(defproperty :grid-auto-flow        :type :keyword :enum (:row :column :row-dense :column-dense))
(defproperty :grid-auto-columns     :type (lambda (v) (or (null v) (listp v) (numberp v))))
(defproperty :grid-auto-rows        :type (lambda (v) (or (null v) (listp v) (numberp v))))
(defproperty :justify-items         :type :keyword :enum (:start :end :center :stretch))

;; box props
(defproperty :padding :type (lambda (v) (or (numberp v) (listp v))))
(defproperty :padding-top :type :number)
(defproperty :padding-right :type :number)
(defproperty :padding-bottom :type :number)
(defproperty :padding-left :type :number)
(defproperty :margin :type (lambda (v) (or (numberp v) (listp v))))
(defproperty :margin-top :type :number)
(defproperty :margin-right :type :number)
(defproperty :margin-bottom :type :number)
(defproperty :margin-left :type :number)
(defproperty :border :type (lambda (v) (or (numberp v) (listp v))))
(defproperty :border-width :type :number)
(defproperty :border-top-width :type :number)
(defproperty :border-right-width :type :number)
(defproperty :border-bottom-width :type :number)
(defproperty :border-left-width :type :number)

;; border style and color
(defproperty :border-style :type :keyword :enum (:none :solid :ascii :dashed :dotted :double)
  :synonyms (:single :solid))
(defproperty :border-top-style :type :keyword :enum (:none :solid :dashed :dotted :double))
(defproperty :border-right-style :type :keyword :enum (:none :solid :dashed :dotted :double))
(defproperty :border-bottom-style :type :keyword :enum (:none :solid :dashed :dotted :double))
(defproperty :border-left-style :type :keyword :enum (:none :solid :dashed :dotted :double))
(defproperty :border-color :type (lambda (v) (or (keywordp v) (cl-styles.tokens:color-p v))))
(defproperty :border-top-color :type (lambda (v) (or (keywordp v) (cl-styles.tokens:color-p v))))
(defproperty :border-right-color :type (lambda (v) (or (keywordp v) (cl-styles.tokens:color-p v))))
(defproperty :border-bottom-color :type (lambda (v) (or (keywordp v) (cl-styles.tokens:color-p v))))
(defproperty :border-left-color :type (lambda (v) (or (keywordp v) (cl-styles.tokens:color-p v))))

;; text properties
(defproperty :color
  :type (lambda (v)
          (or (keywordp v)
              (cl-styles.tokens:color-p v)
              (cl-styles.tokens:variable-ref-p v))))
(defproperty :background-color
  :type (lambda (v)
          (or (keywordp v)
              (cl-styles.tokens:color-p v)
              (cl-styles.tokens:variable-ref-p v))))
;; TUI-facing aliases remain accepted at the reusable style boundary while
;; canonical declaration storage stays CSS-like.
(register-property-alias :fg-color :color)
(register-property-alias :fg :color)
(register-property-alias :foreground-color :color)
(register-property-alias :bg-color :background-color)
(register-property-alias :bg :background-color)
(register-property-alias :background :background-color)
(defproperty :attributes
  :type (lambda (value)
          (and (listp value)
               (every (lambda (attribute)
                        (member attribute
                                '(:bold :italic :underline :inverse :faint
                                  :blink :strike :invisible)
                                :test #'eql))
                      value))))
(register-property-alias :attrs :attributes)

(defproperty :opacity
  :type (lambda (v) (and (realp v) (<= 0 v 1))))
(defproperty :font-family :type :string)
(defproperty :font-size :type :number)
(defproperty :font-weight :type :keyword :enum (:normal :bold :bolder :lighter :inherit))
