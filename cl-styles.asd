(in-package :asdf-user)


(defsystem "cl-styles"
  :description "A Common Lisp library for styling arbitrary objects."
  :author "Your Name <your.email@example.com>"
  :license "MIT"
  :version "0.1.0"
  :depends-on (alexandria uiop log4cl str)
  :pathname "./src/"
  ;; Project stucture.
  :serial t
  :components ((:file "util")
               (:file "api")
               (:file "macros")
               (:file "properties")
               (:file "rule")
               (:file "selector")
               (:file "stylable")
               (:file "style-set")
               (:file "styled-strings")
               (:file "styles")
               (:file "stylesheet")))
