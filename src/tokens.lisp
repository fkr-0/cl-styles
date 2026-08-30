(in-package :cl-styles.tokens)

;; Colors
(defun rgb  (r g b)  (list :rgb r g b))
(defun rgba (r g b a) (list :rgba r g b a))
(defun hsl  (h s l)  (list :hsl h s l))
(defun color-p (x) (and (consp x) (member (first x) '(:rgb :rgba :hsl))))

;; Lengths
(defun px (n)       (list :px n))
(defun percent (n)  (list :percent n))
(defun em (n)       (list :em n))
(defun root-em (n)  (list :rem n))
(defun ch (n)       (list :ch n))
(defun len (n unit) (list unit n))
(defun length-p (x) (and (consp x) (member (first x) '(:px :percent :em :rem :ch))))

;; Variables
(define-condition style-variable-resolution-error (error)
  ((name :initarg :name :reader style-variable-name)
   (chain :initarg :chain :reader style-variable-chain :initform nil)))

(define-condition missing-style-variable (style-variable-resolution-error) ()
  (:report (lambda (condition stream)
             (format stream "Missing style variable ~S while resolving ~S"
                     (style-variable-name condition)
                     (style-variable-chain condition)))))

(define-condition style-variable-cycle (style-variable-resolution-error) ()
  (:report (lambda (condition stream)
             (format stream "Style variable cycle at ~S in ~S"
                     (style-variable-name condition)
                     (style-variable-chain condition)))))

(defstruct variable-expansion property name chain value fallback-used-p)

(defun var (name &optional (fallback nil fallback-p))
  "Construct a style variable reference, optionally with a fallback value."
  (if fallback-p
      (list :var name fallback)
      (list :var name)))

(defun variable-ref-p (x)
  (and (consp x)
       (eql (first x) :var)
       (member (length x) '(2 3))))


;; Resolve variable refs in a plist using VARS (plist or alist or hash-table)
(defun %alternate-variable-name (name)
  (cond
    ((stringp name) (intern (string-upcase name) :keyword))
    ((symbolp name) (string-downcase (symbol-name name)))
    (t nil)))

(defun %lookup-var (name vars)
  "Return the variable value and a presence flag from VARS."
  (labels ((hash-lookup (key)
             (multiple-value-bind (value present-p) (gethash key vars)
               (values value present-p)))
           (alist-lookup (key)
             (let ((cell (assoc key vars :test #'equal)))
               (if cell (values (cdr cell) t) (values nil nil))))
           (plist-lookup (key)
             (loop for (candidate value) on vars by #'cddr
                   when (equal candidate key)
                     do (return (values value t))
                   finally (return (values nil nil)))))
    (let ((alternate (%alternate-variable-name name)))
      (flet ((with-alternate (lookup)
               (multiple-value-bind (value present-p) (funcall lookup name)
                 (if (or present-p (null alternate))
                     (values value present-p)
                     (funcall lookup alternate)))))
        (cond
          ((hash-table-p vars) (with-alternate #'hash-lookup))
          ((and (listp vars) (consp (first vars)))
           (with-alternate #'alist-lookup))
          ((listp vars) (with-alternate #'plist-lookup))
          (t (values nil nil)))))))

(defun resolve-variable-value (value vars &key property)
  "Resolve VALUE recursively against VARS and return VALUE plus expansion records.
Missing variables and cycles signal typed conditions unless the reference supplies a fallback."
  (labels ((record (name chain resolved fallback-used-p nested)
             (values resolved
                     (cons (make-variable-expansion
                            :property property :name name :chain chain
                            :value resolved :fallback-used-p fallback-used-p)
                           nested)))
           (walk (candidate chain)
             (if (not (variable-ref-p candidate))
                 (values candidate nil)
                 (let* ((name (second candidate))
                        (fallback-p (= (length candidate) 3))
                        (fallback (third candidate))
                        (next-chain (append chain (list name))))
                   (labels ((use-fallback ()
                              (multiple-value-bind (resolved nested)
                                  (walk fallback chain)
                                (record name next-chain resolved t nested))))
                     (when (member name chain :test #'equal)
                       (if fallback-p
                           (return-from walk (use-fallback))
                           (error 'style-variable-cycle
                                  :name name :chain next-chain)))
                     (multiple-value-bind (bound present-p) (%lookup-var name vars)
                       (cond
                         (present-p
                          (handler-case
                              (multiple-value-bind (resolved nested)
                                  (walk bound next-chain)
                                (record name next-chain resolved nil nested))
                            (style-variable-resolution-error (condition)
                              (if fallback-p
                                  (use-fallback)
                                  (error condition)))))
                         (fallback-p (use-fallback))
                         (t
                          (error 'missing-style-variable
                                 :name name :chain next-chain)))))))))
    (walk value nil)))

(defun %variable-bindings (vars)
  (cond
    ((hash-table-p vars)
     (let ((bindings nil))
       (maphash (lambda (key value) (push (cons key value) bindings)) vars)
       bindings))
    ((and (listp vars) (consp (first vars))) (copy-list vars))
    ((listp vars)
     (loop for (key value) on vars by #'cddr collect (cons key value)))
    (t (error "Invalid style variable environment: ~S" vars))))

(defun validate-variable-environment (vars)
  "Resolve every defined variable once so cycles and missing dependencies fail early."
  (dolist (binding (%variable-bindings vars) vars)
    (resolve-variable-value (var (car binding)) vars)))

;; (let ((vars '(("--main-color" . (rgb 255 0 0))
;;               ("--padding" . (px 10)))))
;;   (%lookup-var "--main-color" vars))
;; (defun resolve-variables (plist vars)
;;   "Resolve variable references in PLIST using VARS.
;; VARS can be a plist, alist, or hash-table.
;; Returns a new plist with variable references replaced by their values.

;; Arguments:
;; - PLIST: A property list that may contain variable references (e.g., (:color (var \"--main-color\"))).
;; - VARS: A property list, association list, or hash-table mapping variable names to their values.
;; Returns:
;; - A new property list with variable references resolved to their corresponding values from VARS.

;; Example:
;;   (let ((vars '((\"--main-color\" . (rgb 255 0 0))
;;                 (\"--padding\" . (px 10)))))
;;     (resolve-variables '(:color (var \"--main-color\") :padding (var \"--padding\") :margin (px 5)) vars))
;;   ;; Returns: (:color (rgb 255 0 0) :padding (px 10) :margin (px 5))"
;;   (let ((out (copy-list (or plist nil))))
;;     (loop for (k v) on out by #'cddr do
;;       (when (variable-ref-p v)
;;         (let* ((name (second v))
;;                (val (%lookup-var name vars)))
;;           (when val (setf (getf out k) val)))))
;;     out))


;; (let ((vars '((:main-color . (rgb 255 0 0))
;;               (:padding . (px 10)))))
;;   (resolve-variables '(:color (var :main-color) :padding (var :padding) :margin (px 5)) vars))
;;
;; (let ((sheet (cl-styles.sheet:make-stylesheet
;;               :variables '(("--main-color" . :blue)))))
;;   (%normalize-decls '(:color (var "--main-color") :padding 10 :margin (5 10)) sheet))
;; ;; => (:MARGIN-LEFT 10 :MARGIN-RIGHT 10 :MARGIN-BOTTOM 5 :MARGIN-TOP 5 :PADDING-LEFT
;; ;;  10 :PADDING-BOTTOM 10 :PADDING-RIGHT 10 :PADDING-TOP 10 :COLOR
;;  (VAR "--main-color") :PADDING 10 :MARGIN (5 10))
(defun resolve-variables (plist vars)
  "Resolve top-level variable references in PLIST recursively.
Returns two values: the resolved plist and VARIABLE-EXPANSION records.
A missing variable or cycle signals a typed condition unless a VAR fallback recovers it."
  (let ((resolved-plist (copy-list (or plist nil)))
        (expansions nil))
    (loop for (key value) on resolved-plist by #'cddr
          when (variable-ref-p value)
            do (multiple-value-bind (resolved records)
                   (resolve-variable-value value vars :property key)
                 (setf (getf resolved-plist key) resolved
                       expansions (nconc expansions records))))
    (values resolved-plist expansions)))
