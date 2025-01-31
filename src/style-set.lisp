(uiop:define-package :cl-styles.style-set
  (:nicknames :styles.style-set) (:use :cl)
  (:import-from :log4cl :log-info)
  ;; (:import-from :cl-stringbuffer :terminal-cell
  ;;   :terminal-cell-term-style)
  (:import-from :cl-styles.styles :style-p :tuple-prop :group-styles :apply-after
   :style-group-key)
  (:import-from :cl-styles.api :style
                :value-value :style-property :style-val
   :make-style :valid-style-value-p :default-styling
                :ordered-styles  :style-sub-styles)
  (:import-from :cl-styles.styles :make-default-styling)
  (:import-from :cl-styles.util :hash-table-keys :keyword-split
   :keyword-concat)
  (:import-from :cl-styles.api :make-style-set :style-set-styles
   :style-set-order :style-set)
  ;; (:import-from :cl-styles.lowterm :new-fg-color :new-bg-color
  ;;  :make-terminal-style :terminal-style :terminal-style-bold
  ;;               :terminal-style-italic :terminal-style-strike
  ;;               :terminal-style-underline :terminal-style-blink
  ;;               :terminal-style-inverse :terminal-style-invisible
  ;;               :terminal-style-fg-color :terminal-style-bg-color)
  (:import-from :alexandria :flatten)
  (:export :style-of :value-of :styles-list :invert-colors :invert-colors!
   :merge-styles! :make-terminal-style-from-style-set :new))

(in-package :cl-styles.style-set)

;; "A collection of styles represented as a hash table mapping properties to style instances.
;; Also contains an optional order list to specify the order in which styles should be applied."


(defmethod styles-list ((set style-set))
  "Return the styles of the given style set as a plist, with keys sorted alphabetically."
  (let ((l nil) (keys 'nil))
    ;; Collect all keys from the hash table into keys list
    (maphash (lambda (k v) (declare (ignore v)) (push k keys))
             (style-set-styles set))
    ;; Sort the keys alphabetically
    (setq keys
          (sort keys
                (lambda (a b) (string< (symbol-name a) (symbol-name b)))))
    ;; Now process each key in sorted order
    (dolist (k keys)
      (let ((v (gethash k (style-set-styles set))))
        (push k l)
        (when (style-group-key k)
          (push (style-group-key k) l))
        (push (value-value (style-val v)) l)))
    ;; Return the reversed list to maintain the correct order
    (nreverse l)))

(defmethod styles-list ((empty null))
  "Return an empty list for a null style set."
  nil)

(defmethod style-of ((set style-set) property)
  "Return the style instance associated with the given property in the style set.
If the property is not found, returns nil."
  (gethash property (style-set-styles set)))

(defmethod value-of ((set style-set) property)
  "Return the value of the given property in the given style set.
If the property is not found, returns nil.

Example:
  (value-of my-style-set 'background-color) ; => \"#FFFFFF\""
  (let ((v (gethash property (style-set-styles set))))
    (when v
      (value-value (style-val v)))))

(defun parse-styles (&rest styles)
  "Parse the given styles into a list of style objects.
Supports the following syntaxes:
  - '(:prop1 :val1 :prop2 :val2)
  - '((:prop1 :val1) (:prop2 :val2))
  - '(style1 style2)
  - style1

Examples:
  (parse-styles :bg-color :red :bold t)
  (parse-styles (list :bg-color :red :bold t))
  (parse-styles (list (list :bg-color :red) '(:bold t)))
  (parse-styles (list (list :bg-color :red) (make-style :bold t)))
  (parse-styles (list :bg-color :red) (make-style :bold t))
  (parse-styles :bg-color :red (make-style :bold t))"
  (declare (type list styles))
  (let ((parsed-styles nil) (styles (flatten styles)))
    (loop while styles
          do (cond
               ((listp (car styles))
                (setf parsed-styles
                      (nconc (apply #'parse-styles (pop styles))
                             parsed-styles)))
               ((style-p (car styles)) (push (pop styles) parsed-styles))
               ((symbolp (car styles))
                (push (make-style (pop styles) (pop styles)) parsed-styles))))
    (nreverse parsed-styles)))

(defmethod new ((class (eql 'style-set)) &key (styles nil))
  "Create a new style set.

Args:
  class (eql 'style-set): The class of the style set.
  styles (list): A list of styles to initialize the style set with.

Returns:
  style-set: The newly created style set.

Example:
  (new 'style-set :styles '((:background-color :red) (:foreground-color :white)))"
  (declare (type list styles))
  (let ((set (make-style-set)))
    (when styles
      (loop for p in (parse-styles styles)
            do (setf (style-of set (tuple-prop p)) p)))
    set))

(defun default-style-set ()
  "Create a default style set derived from all styles that define a default value."
  (new 'style-set :styles (make-default-styling)))

(defvar *default-styles*
  (default-style-set)
  "Default style set containing all default styles.")

(defmethod print-object ((set style-set) stream)
  "Print a representation of the style-set to the given stream."
  (format stream "#<STYLE-SET ~A>" (styles-list set)))

(defmethod around-styles ((set style-set))
  "Return the list of decorator styles in the given style set.
This is used to determine which styles need to be applied around the content."
  (let ((decorator-styles nil))
    (maphash
     (lambda (k v)
       (declare (ignore v))
       (if (and (style-group-key k)
                (not (member (style-group-key k) decorator-styles))
                (not
                 (eql (apply-after (style-group-key k) 'nil)
                      :non-decorating)))
           (push (style-group-key k) decorator-styles)
           (if (not (eql (apply-after k 'nil) :non-decorating))
               (push k decorator-styles))))
     (style-set-styles set))
    decorator-styles))

(defmethod ordered-around-styles ((set style-set))
  "Return the decorator styles of the given style set in order."
  (let ((order (or (style-set-order set) (ordered-styles (around-styles set)))))
    (setf (style-set-order set) order)
    order))

(defmethod (setf value-of) (value (set style-set) property)
  "Set the value of the given property in the given style set.

Args:
  value: The value to set.
  set (style-set): The style-set to set the value in.
  property (symbol): The property to set the value for.

Returns:
  The value that was set if successful, or nil.

Example:
  (setf (value-of my-style-set 'bg-color) :red)
  (value-of my-style-set 'bg-color) ; => :red"
  (if (null value)
      (when (style-of set property) (remhash property (style-set-styles set)))
      (let ((s (style-of set property)))
        (when s
          (unless (valid-style-value-p (style-property s) value)
            (error "Invalid value: ~a for ~a" value s)))
        (if s
            (setf (value-value (style-val s)) value)
            (setf (gethash property (style-set-styles set))
                  (make-style property value)))))
  value)

(defmethod (setf style-of)
    (value (set style-set) (property symbol) &optional args)
  "Set the style instance for the given property in the given style set.
If the property is a group style, the sub-styles are also set.

Args:
  value: The style instance to set.
  set (style-set): The style set to set the style in.
  property (symbol): The property to set the style for.
  args: Additional arguments to pass to the method.

Returns:
  The style instance that was set if successful, or nil.

Example:
  (setf (style-of my-style-set 'bg-color) (make-style :bg-color :red
    :fg-color :white
    :bold t)) ; => #<STYLE :BG-COLOR :RED :FG-COLOR :WHITE :BOLD T>"
  (declare (ignore args))
  (if (group-styles property)
      (let* ((inst (make-style property value)) (subs (style-sub-styles inst)))
        (dolist (s subs) (setf (style-of set (tuple-prop s)) s)))
      (setf (gethash property (style-set-styles set)) value)))

(defmethod (setf style-of)
    (values (set style-set) (properties list) &optional args)
  "Set multiple styles in the given style set."
  (declare (ignore args))
  (loop for property in properties
        for value in values
        do (setf (style-of set property) value)))

(defmethod merge-styles! ((set style-set) (other style-set))
  "Merge the styles from another style set into this one."
  (maphash (lambda (k v) (setf (style-of set k) v)) (style-set-styles other))
  set)

(defmethod copy ((set style-set))
  "Return a copy of the given style set."
  (let ((copy (make-style-set)))
    (merge-styles! copy set)
    copy))

;; (defvar a (default-style-set))
;; (defvar b (default-style-set))
;; (value-of a :bg-color)
;; (setf (value-of a :bg-color) :red)
;; (setf (value-of a :bg-color) nil)
;; (list a b)
;; (invert-colors (invert-colors! a))

(defmethod invert-colors! ((set style-set))
  "Mutate the given style set by inverting the foreground and background colors."
  (let ((fg (value-of set :fg-color)) (bg (value-of set :bg-color)))
    (setf (value-of set :fg-color) bg)
    (setf (value-of set :bg-color) fg)
    set))

(defmethod invert-colors ((set style-set))
  "Return a new style set with the foreground and background colors inverted."
  (invert-colors! (copy set)))

;; (defmethod make-terminal-style-from-style-set ((style-set style-set))
;;   "Create a terminal style from a style set."
;;   (let ((ts (make-terminal-style)))
;;     (setf (terminal-style-bold ts) (value-of style-set :bold))
;;     (setf (terminal-style-italic ts) (value-of style-set :italic))
;;     (setf (terminal-style-strike ts) (value-of style-set :strike))
;;     (setf (terminal-style-underline ts) (value-of style-set :underline))
;;     (setf (terminal-style-blink ts) (value-of style-set :blink))
;;     (setf (terminal-style-inverse ts) (value-of style-set :inverse))
;;     (setf (terminal-style-invisible ts) (value-of style-set :invisible))
;;     (when (style-of style-set :fg-color)
;;       (setf (terminal-style-fg-color ts)
;;             (new-fg-color (value-of style-set :fg-color))))
;;     (when (style-of style-set :bg-color)
;;       (setf (terminal-style-bg-color ts)
;;             (new-bg-color (value-of style-set :bg-color))))
;;     ts))

(defgeneric style-term-element! (styles ts)
  (:documentation "Applies a style to a terminal element.
This mutates the terminal-style object associated with the element."))

;; (defmethod style-term-element! ((styles style-set) (ts terminal-style))
;;   "Apply styles from the style-set to the terminal-style object."
;;   (setf (terminal-style-bold ts) (value-of styles :bold))
;;   (setf (terminal-style-italic ts) (value-of styles :italic))
;;   (setf (terminal-style-strike ts) (value-of styles :strike))
;;   (setf (terminal-style-underline ts) (value-of styles :underline))
;;   (setf (terminal-style-blink ts) (value-of styles :blink))
;;   (setf (terminal-style-inverse ts) (value-of styles :inverse))
;;   (setf (terminal-style-invisible ts) (value-of styles :invisible))
;;   (when (style-of styles :fg-color)
;;     (setf (terminal-style-fg-color ts)
;;           (new-fg-color (value-of styles :fg-color))))
;;   (when (style-of styles :bg-color)
;;     (setf (terminal-style-bg-color ts)
;;           (new-bg-color (value-of styles :bg-color))))
;;   ts)

;; (defmethod style-term-element! ((styles style-set) (ts t))
;;   "Apply styles from the style-set to a new terminal-style object."
;;   (style-term-element! styles (make-terminal-style)))

;; (defmethod style-term-element! ((styles style-set) (ts terminal-cell))
;;   "Apply styles from the style-set to the terminal-style of a terminal-cell."
;;   (style-term-element! styles (terminal-cell-term-style ts)))
