(module terminus
  (import
    [t :from "@terminusdb/terminusdb-client"]))

(def client (t:WOQLClient. "http://localhost:6363",
              #js {:user "admin" :key "root"}))

(def db-name (str (gensym "my_first_db_")))

(.deleteDatabase client db-name)
(.createDatabase client db-name
  #js {:label "My first db" :comment "My first first db"})

(.db client db-name)
(.getSchema client)

(defn json-ld [o]
  (cond
    (string? o)
    o

    (satisfies? QualifiedName o)
    (fqn o)

    (identifier? o)
    (name o)
    
    (dict? o)
    (let [x #js {}]
      (doseq [[k v] o]
        (oset x (json-ld k) (json-ld v)))
      x)

    (sequential? o)
    (js:Array.from o json-ld)))

(defn transact [client docs msg]
  (.addDocument client
    (json-ld docs)
    #js {"graph_type" (if (:schema (meta docs))
                        "schema"
                        "instance")}
    ""
    (or msg undefined)))



(transact
  client
  ^:schema [{"@id" ::Person
             "@type" "Class"
             :foaf:name :xsd:string}])

(transact
  client
  [{"@type" ::Person
    :foaf:name "Bram"}])
(.getDocument client "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/ivLKvqOy1dX42abr")

(.queryDocument client  (json-ld {:type ::Person :query {:foaf:name "Arne"}})
  #js {:as_list true})

(do 
  #js {(str "x" "y") 123})

(.-query client)

(.json
  (.and 
    (.select t:WOQL "v:id")
    (.triple t:WOQL "v:id" (fqn :foaf:name) "Arne"))
  #_(.commits (.lib t:WOQL)))
#js

(json-ld 
  {:@type "Select"
   :variables ["id"]
   :query})

(.query client 
  (.star t:WOQL))
{:triple_builder_context #js {},
 :query #js {:@type "Triple", :subject #js {:@type "NodeValue", :variable "Subject"}, :predicate #js {:@type "NodeValue", :variable "Predicate"}, :object #js {:@type "Value", :variable "Object"}},
 :counter 1,
 :errors #js [],
 :cursor #js {:@type "Triple", :subject #js {:@type "NodeValue", :variable "Subject"}, :predicate #js {:@type "NodeValue", :variable "Predicate"}, :object #js {:@type "Value", :variable "Object"}},
 :chain_ended false,
 :contains_update false,
 :paging_transitive_properties #js ["select", "from", "start", "when", "opt", "limit"],
 :update_operators #js ["AddTriple", "DeleteTriple", "AddQuad", "DeleteQuad", "InsertDocument", "DeleteDocument", "UpdateDocument"],
 :vocab #js {:Class "owl:Class", :DatatypeProperty "owl:DatatypeProperty", :ObjectProperty "owl:ObjectProperty", :Document "system:Document", :abstract "system:abstract", :comment "rdfs:comment", :range "rdfs:range", :domain "rdfs:domain", :subClassOf "rdfs:subClassOf", :string "xsd:string", :integer "xsd:integer", :decimal "xsd:decimal", :boolean "xdd:boolean", :email "xdd:email", :json "xdd:json", :dateTime "xsd:dateTime", :date "xsd:date", :coordinate "xdd:coordinate", :line "xdd:coordinatePolyline", :polygon "xdd:coordinatePolygon"},
 :tripleBuilder false}

(.json (.value t:WOQL "@id" (fqn :foaf:name) "Arne"))

(.query client 
  #js {:containsUpdate (constantly false)
       :json (constantly
             (json-ld
               {:@type "Triple"
                :subject {:@type "NodeValue"
                          :variable "S"}
                :predicate  {:@type "NodeValue"
                             :variable "V"}
                :object {:@type "NodeValue"
                         :variable "O"}}))})

(.query client 
  #js {:containsUpdate (constantly false)
       :json (constantly
               (json-ld
                 {:@type "Triple"
                  :subject {:@type "NodeValue"
                            :variable "S"}
                  :predicate  {:@type "NodeValue"
                               :variable "V"}
                  :object {:@type "DataValue"
                           :data {:@type :xsd:string
                                  :@value "Arne"}}}))})

(map (juxt :S :V :O)
  [#js {:O "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person",
      :S "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/oQzqwlWekE00YV_k", :V "rdf:type"}
   , #js {:O #js {:@type "xsd:string", :@value "Arne"}, :S "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/oQzqwlWekE00YV_k", :V "http://xmlns.com/foaf/0.1/name"}, #js {:O "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person", :S "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/ivLKvqOy1dX42abr", :V "rdf:type"}, #js {:O #js {:@type "xsd:string", :@value "Arne"}, :S "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/ivLKvqOy1dX42abr", :V "http://xmlns.com/foaf/0.1/name"}, #js {:O "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person", :S "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/sAAnw4KwcOX00pkA", :V "rdf:type"}, #js {:O #js {:@type "xsd:string", :@value "Arne"}, :S "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/sAAnw4KwcOX00pkA", :V "http://xmlns.com/foaf/0.1/name"}, #js {:O "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person", :S "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/tnrAhce1J4VRpMab", :V "rdf:type"}, #js {:O #js {:@type "xsd:string", :@value "Bram"}, :S "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/tnrAhce1J4VRpMab", :V "http://xmlns.com/foaf/0.1/name"}])

(
  #js ["file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/oQzqwlWekE00YV_k", "rdf:type", "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person"]
  #js ["file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/oQzqwlWekE00YV_k", "http://xmlns.com/foaf/0.1/name", #js {:@type "xsd:string", :@value "Arne"}]
  #js ["file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/ivLKvqOy1dX42abr", "rdf:type", "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person"]
  #js ["file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/ivLKvqOy1dX42abr", "http://xmlns.com/foaf/0.1/name", #js {:@type "xsd:string", :@value "Arne"}]
  #js ["file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/sAAnw4KwcOX00pkA", "rdf:type", "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person"]
  #js ["file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/sAAnw4KwcOX00pkA", "http://xmlns.com/foaf/0.1/name", #js {:@type "xsd:string", :@value "Arne"}]
  #js ["file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/tnrAhce1J4VRpMab", "rdf:type", "file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person"]
  #js ["file:///home/arne/Piglet/terminus-test/src/terminus.pig#Person/tnrAhce1J4VRpMab", "http://xmlns.com/foaf/0.1/name", #js {:@type "xsd:string", :@value "Bram"}])
(.Vars t:WOQL "foo")

t:Var

(.getDocument client ::Person)

(.and 
  (t:WOQLQuery.))
