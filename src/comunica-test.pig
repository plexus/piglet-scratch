(module comunica-test
  (:import
    [q :from "@comunica/query-sparql"]
    [str :from piglet:string])
  (:context
    {"dbpedia" "http://dbpedia.org/resource/"
     "dbprop" "http://dbpedia.org/property/"
     "dbpont" "http://dbpedia.org/ontology/"}))


(def engine (q:QueryEngine.))

(defn sparql [m]
  (cond
    (qname? m)
    (str "<" (fqn m) ">")

    (string? m)
    (print-str m)

    (symbol? m)
    (str m)

    (dict? m)
    (let [m (expand-qnames m)]
      (str "SELECT " (str:join " " (map str (:select m))) " WHERE {"
        (str:join " .\n"
          (for [[s v o] (:where m)]
            (str (sparql s) " " (sparql v) " " (sparql o))
            ))
        "}"
        (when-let [l (:limit m)]
          (str " LIMIT " l))
        ))

    :else
    (print-str (str m))))

(defn coerce [s]
  (let [v (:value s)]
    (if (and (string? v) (str:starts-with v "http://"))
      (qname v)
      v)))

(defn query [engine d]
  (.then
    (.queryBindings engine (sparql d)
      #js {:sources (:sources d)})
    (fn [r]
      (.then (.toArray r)
        (fn [a]
          (for [e a]
            (mapv coerce (map second (.-entries e))))
          ))))))

(def r
  (await
    (query
      engine
      {:select '[?s ?v ?o]
       :where [[:dbpedia:Tea '?v '?o]
               '[?s ?v ?o]
               #_'[?v :rdfs:domain ?vt]]
       :limit 100
       :sources  ["https://fragments.dbpedia.org/2015/en"]})))
