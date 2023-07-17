(module wow
  (:import piglet:dom))

(map :textContent
  (dom:query-all js:document ".section-content li a code"))
(count '())
