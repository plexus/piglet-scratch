(module my-pragmas)

(defn ^{:pragma :on-import} inject-extra-vars [module]
  (.intern module "oink" (fn [] (println "Oink!")))
  )

(defn ^{:pragma :dict-destructuring} destructure-attrs [dict-form]
  ;; return binding form pairs
  )

(defn ^{:pragma :emit-dict-literal} js-literal-dicts [dict]
  ;; return estree that constructs dict
  )

(defn ^{:pragma :resolve-var} alternative-for [[var-sym & args]]
  (if (= var-sym 'for)
    (resolve 'alt-for:alt-for)
    (resolve 'for)))
