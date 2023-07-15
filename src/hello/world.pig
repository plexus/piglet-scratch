(module hello/world
  (:import
    [dom :from piglet:dom]
    piglet:dom
    [xxx :from "js-dom"]
    [xxx :from "./cbor.mjs"]
    )
  (:context
    {"user" "https://my-vocab.gaiwan.co/user#"}))


(def xxx 123)

(fqn (resolve 'xxx))
=> https://piglet-scratch/:hello/world:xxx


(inspect
  :user:name)
=> "QName(:https://my-vocab.gaiwan.co/user#name)"

(def x {:https://my-vocab.gaiwan.co/user#name "hello"})

x
(:user:name  x)

(inspect
  {:rdf:type :rdfs:string})
=> "Dict(QName(:http://www.w3.org/1999/02/22-rdf-syntax-ns#type) QName(:http://www.w3.org/2000/01/rdf-schema#string))"

(:xxx #js {:xxx 123})
