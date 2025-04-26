(in-package :cl-user)

(uiop:define-package :cl-styles (:nicknames :styles) (:use :cl :str)
                     (:shadow log4cl:layout) (:export :main)
                     (:import-from :log4cl :log-error :log-info :log-debug)
                     (:reexport :cl-styles.util :cl-styles.api
                                :cl-styles.styles :cl-styles.style-set
                                :cl-styles.stylable :cl-styles.macros
                                :cl-styles.properties :cl-styles.selector
                                :cl-styles.rule :cl-styles.styled-strings
                                :cl-styles.stylesheet)
                     (:documentation "CL-Styles is a Common Lisp library for managing stylesheets and styling objects."))
