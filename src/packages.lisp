(in-package :cl-user)

(uiop:define-package :cl-styles.protocols
  (:use :cl :alexandria)
  (:export
    #:stylable-id #:stylable-classes #:stylable-type #:stylable-inline-style
    #:stylable-attributes #:stylable-state
    #:stylable-parent #:stylable-children #:stylable-index
    #:set-computed-style #:get-computed-style
    #:stylable-namespace #:stylable-theme #:stylable-key))

(uiop:define-package :cl-styles.tokens
  (:use :cl :alexandria)
  (:export
    #:rgb #:rgba #:hsl #:resolve-variables #:resolve-variable-value
    #:validate-variable-environment
    #:px #:percent #:em #:root-em #:ch #:len
    #:var #:color-p #:length-p #:variable-ref-p
    #:style-variable-resolution-error #:missing-style-variable #:style-variable-cycle
    #:style-variable-name #:style-variable-chain
    #:variable-expansion #:variable-expansion-property #:variable-expansion-name
    #:variable-expansion-chain #:variable-expansion-value
    #:variable-expansion-fallback-used-p))


(uiop:define-package :cl-styles.selector
  (:use :cl :alexandria :cl-styles.protocols)
  (:export
    #:type> #:id> #:cls> #:attr> #:state>
    #:first-child #:last-child #:nth-child
    #:sel-and #:sel-or #:sel-not
    #:descendant> #:child> #:has
    #:invalid-selector #:invalid-selector-selector #:invalid-selector-reason
    #:invalid-selector-path #:validate-selector
    #:compile-selector #:selector-specificity #:match-selector-p))


(uiop:define-package :cl-styles.rule
  (:use :cl :alexandria :cl-styles.selector :cl-styles.tokens)
  (:export
    #:rule #:make-rule #:rule-selector #:rule-declarations #:rule-specificity
    #:invalid-rule #:invalid-rule-rule #:invalid-rule-reason #:validate-rule
    #:defrule #:expand-shorthands))


(uiop:define-package :cl-styles.sheet
  (:use :cl :alexandria :cl-styles.rule :cl-styles.selector :cl-styles.tokens)
  (:export
    #:stylesheet #:make-stylesheet #:stylesheet-rules #:stylesheet-variables
    #:stylesheet-namespace #:stylesheet-revision #:validate-stylesheet
    #:style-engine #:style-engine-stylesheet #:style-engine-patches #:style-engine-dirty
    #:add-rule #:remove-rule
    #:defstylesheet))




(uiop:define-package :cl-styles.properties
  (:use :cl :alexandria)
  (:export
    #:defproperty #:register-property #:register-property-alias #:property-definition
    #:property-default #:property-defaults
    #:normalize-declarations #:validate-declarations #:ensure-declarations
    #:ensure-static-declarations
    #:define-group #:properties-for-group #:groups-for-layout #:properties-for-layout
    #:style-contract-violation #:expected #:got #:where))


(uiop:define-package :cl-styles.engine
  (:use :cl :alexandria :cl-styles.protocols :cl-styles.sheet :cl-styles.rule
    :cl-styles.selector :cl-styles.tokens)
  (:export
    #:style-patch #:style-patch-path #:style-patch-computed
    #:*cascade-semantics-revision*
    #:style-revision #:style-revision-cascade #:style-revision-stylesheet
    #:declaration-trace #:declaration-trace-property #:declaration-trace-value
    #:declaration-trace-origin #:declaration-trace-selector
    #:declaration-trace-specificity #:declaration-trace-source-order
    #:declaration-trace-source-declarations #:declaration-trace-variable-expansions
    #:declaration-trace-status
    #:computed-style-result #:computed-style-result-style #:computed-style-result-revision
    #:computed-style-result-trace #:computed-style-result-diagnostics
    #:match-rules #:compute-style #:compute-style-result #:explain-style
    #:inherit-properties #:apply-stylesheet #:apply-stylesheet-to-tree))


(uiop:define-package :cl-styles.adapters
  (:use :cl)
  (:import-from :cl-styles.properties
                #:normalize-declarations)
  (:import-from :cl-styles.tokens
                #:rgb)
  (:export #:normalize-tui-declarations #:normalize-tui-style-plist))

(uiop:define-package :cl-styles.api
  (:use :cl :cl-styles.protocols :cl-styles.tokens :cl-styles.selector
    :cl-styles.rule :cl-styles.sheet :cl-styles.engine :cl-styles.properties
    :cl-styles.adapters)
  (:reexport :cl-styles.protocols :cl-styles.tokens :cl-styles.selector
    :cl-styles.rule :cl-styles.sheet :cl-styles.engine :cl-styles.properties
    :cl-styles.adapters))
