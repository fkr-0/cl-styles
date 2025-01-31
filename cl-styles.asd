(in-package :asdf-user)


(defsystem "cl-styles"
  :description "A Common Lisp library for styling arbitrary objects."
  :author "Your Name <your.email@example.com>"
  :license "MIT"
  :version "0.1.0"
  :depends-on (cl-reexport alexandria uiop log4cl str)
  :pathname "./src/"
  ;; Project stucture.
  :serial t
  :components ((:file "util")
               (:file "api")
               (:file "styles")
               (:file "style-set")
               (:file "stylable")
               (:file "macros")
               (:file "properties")
               (:file "selector")
               (:file "rule")
               (:file "styled-strings")
               (:file "stylesheet")
               (:file "cl-styles")))
