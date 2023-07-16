(module solid-poke
  (:import
    [h :from "solid-js/h"]
    [web :from "solid-js/web"]
    [pigsolid :from solid:solid]
    piglet:dom))

(def literal? #{"string" "boolean" "number" "bigint" js:Date js:RegExp Sym Keyword PrefixName QName QSym})

(defn text-node [s]
  (dom:text-node js:document (str s)))

(defn h [arg]
  (cond
    (literal? (type arg))
    (text-node (str arg))

    (fn? arg)
    (fn [] (h (arg)))

    (vector? arg)
    (let [[tag & children] arg]
      (if (fn? tag)
        (web:createComponent (fn [props]
                               (h (apply tag (.-children props))))
          #js {:children children})
        (let [el (dom:create-el js:document tag)
              props #js {}]
          (when (dict? (first children))
            (doseq [[k v] (first children)]
              (if (fn? v)
                (js:Object.defineProperty props (name k)
                  #js {:get v :enumerable true})
                (assoc! props k v)))
            (web:spread el props false true))
          (doseq [ch (cond-> children
                       (dict? (first children))
                       rest)]
            (web:insert el (h ch) undefined))
          el)))

    (sequential? arg)
    (web:createComponent (fn [props]
                           (into []
                             (map h (.-children props))))
      #js {:children arg})))

(defn assert= [expected actual]
  (dom:prepend
    (dom:query-one js:document "#app")
    (dom:dom js:document
      (if (= expected actual)
        [:div  "✓ "
         [:span {:style {:background-color "hsl(90, 100%, 50%)"}} expected]]
        [:p {:style {:background-color "hsl(20, 90%, 80%)"}} "Expected " expected ", got " actual]))))

(defn assert-content [el expected]
  (assert= expected (.-innerHTML el)))

(defn do-render [element]
  (let [container (dom:create-el js:document :main)]
    (web:render element container)
    container))

(defn test [element expected]
  (let [container (do-render element)]
    (assert-content container expected)
    container))

(set! (.-innerHTML (dom:query-one js:document "#app")) "")

(test
  (fn [] (h "hello"))
  "hello")

(test
  (fn [] (h [:p "hello"]))
  "<p>hello</p>")

(test
  (fn [] (h [:p "hello" " " "world"]))
  "<p>hello world</p>")

(test
  (fn [] (h [:p [:h1 "hello"]]))
  "<p><h1>hello</h1></p>")

(test
  (fn [] (h [:p 1]))
  "<p>1</p>")

(test
  (fn [] (h [:p "x" [:h1 "hello"] "y" (fn [] "z")]))
  "<p>x<h1>hello</h1>yz</p>")

(let [s (pigsolid:signal 1)
      el (do-render (fn [] (h [:p s])))]
  (assert-content el "<p>1</p>")
  (swap! s inc)
  (assert-content el "<p>2</p>"))

(let [s (pigsolid:signal 1)
      el (do-render (fn [] (h [:p (fn [] (str "-" @s "-"))])))]
  (assert-content el "<p>-1-</p>")
  (swap! s inc)
  (assert-content el "<p>-2-</p>"))

(test
  (fn [] (h [(fn [] [:a "link"])]))
  "<a>link</a>")

(test
  (fn [] (h [:div
             (fn [] [:h1])
             (fn [] [:h2])
             (fn [] [:h3])]))
  "<div><h1></h1><h2></h2><h3></h3></div>")

(let [v (reference nil)
      c (fn []
          (let [s (pigsolid:signal 1)]
            (when @v (throw (js:Error. "Outer component fn called twice")))
            (reset! v s)
            (fn []
              [:p (str "-" @s "-")])))
      el (do-render (fn [] (h [c])))]
  (assert-content el "<p>-1-</p>")
  (swap! @v inc)
  (assert-content el "<p>-2-</p>")
  (swap! @v inc)
  (assert-content el "<p>-3-</p>"))

(test
  (fn [] (h [(fn [] [:a "link"])]))
  "<a>link</a>")

(let [v (reference nil)
      c (fn []
          (let [s (pigsolid:signal 1)]
            (reset! v s)
            [:p (pigsolid:reaction (str "-" @s "-"))]))
      el (do-render (fn [] (h [c])))]
  (assert-content el "<p>-1-</p>")
  (swap! @v inc)
  (assert-content el "<p>-2-</p>")
  (swap! @v inc)
  (assert-content el "<p>-3-</p>"))

;; No component-level reactivity!
(let [s (pigsolid:signal 1)
      c (fn []
          [:p (str "-" @s "-")])
      el (do-render (fn [] (h [c])))]
  (assert-content el "<p>-1-</p>")
  (swap! s inc)
  (assert-content el "<p>-1-</p>"))

(test
  (fn [] (h [:div
             (list
               [:h1]
               [:h2]
               [:h3])]))
  "<div><h1></h1><h2></h2><h3></h3></div>")

(let [s (pigsolid:signal 1)
      c (fn []
          [:ul
           (fn []
             (for [i (range @s)]
               [:li i]))
           ])
      el (do-render (fn [] (h [c])))]
  (assert-content el "<ul><li>0</li></ul>")
  (swap! s inc)
  (assert-content el "<ul><li>0</li><li>1</li></ul>"))

(let [s (pigsolid:signal 1)
      c (fn []
          [:ul
           (pigsolid:reaction
             (for [i (range @s)]
               [:li i]))
           ])
      el (do-render (fn [] (h [c])))]
  (assert-content el "<ul><li>0</li></ul>")
  (swap! s inc)
  (assert-content el "<ul><li>0</li><li>1</li></ul>"))

(test
  (fn [] (h [:a {:href "/oink"} "Oink!"]))
  "<a href=\"/oink\">Oink!</a>")

(test
  (fn [] (h [:a {:href (fn [] "/oink")} "Oink!"]))
  "<a href=\"/oink\">Oink!</a>")

(let [s (pigsolid:signal 1)
      c (fn []
          [:a {:href (fn [] (str "/oink/" @s))} "Oink!"])
      el (do-render (fn [] (h [c])))]
  (assert-content el "<a href=\"/oink/1\">Oink!</a>")
  (swap! s inc)
  (assert-content el "<a href=\"/oink/2\">Oink!</a>"))

(test
  (fn [] (h [:a
             'oink " "
             :groink " "
             :foaf:name " "
             `foo]))
  "<a>oink :groink :foaf:name https://piglet.arnebrasseur.net/scratch:solid-poke:foo</a>")

(let [x #js {}]
  (assoc-in! x [:x :y] 1))
