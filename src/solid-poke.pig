(module solid-poke
  (:import
    [h :from "solid-js/h"]
    [web :from "solid-js/web"]
    [pigsolid :from solid:solid]
    piglet:dom
    piglet:string))

(def literal? #{"string" "boolean" "number" "bigint"
                js:Date js:RegExp Sym Keyword PrefixName QName QSym})

(def kebab-case-tags
  #{"accept-charset" "http-equiv" "accent-height"
    "alignment-baseline" "arabic-form" "baseline-shift" "cap-height" "clip-path"
    "clip-rule" "color-interpolation" "color-interpolation-filters" "color-profile"
    "color-rendering" "fill-opacity" "fill-rule" "flood-color" "flood-opacity"
    "font-family" "font-size" "font-size-adjust" "font-stretch" "font-style"
    "font-variant" "font-weight" "glyph-name" "glyph-orientation-horizontal"
    "glyph-orientation-vertical" "horiz-adv-x" "horiz-origin-x" "marker-end"
    "marker-mid" "marker-start" "overline-position" "overline-thickness" "panose-1"
    "paint-order" "stop-color" "stop-opacity" "strikethrough-position"
    "strikethrough-thickness" "stroke-dasharray" "stroke-dashoffset"
    "stroke-linecap" "stroke-linejoin" "stroke-miterlimit" "stroke-opacity"
    "stroke-width" "text-anchor" "text-decoration" "text-rendering"
    "underline-position" "underline-thickness" "unicode-bidi" "unicode-range"
    "units-per-em" "v-alphabetic" "v-hanging" "v-ideographic" "v-mathematical"
    "vert-adv-y" "vert-origin-x" "vert-origin-y" "word-spacing" "writing-mode"
    "x-height"})

(def svg-tags
  #{"a" "animate" "animateMotion" "animateTransform" "circle"
    "clipPath" "defs" "desc" "ellipse" "feBlend" "feColorMatrix"
    "feComponentTransfer" "feComposite" "feConvolveMatrix" "feDiffuseLighting"
    "feDisplacementMap" "feDistantLight" "feDropShadow" "feFlood" "feFuncA"
    "feFuncB" "feFuncG" "feFuncR" "feGaussianBlur" "feImage" "feMerge" "feMergeNode"
    "feMorphology" "feOffset" "fePointLight" "feSpecularLighting" "feSpotLight"
    "feTile" "feTurbulence" "filter" "foreignObject" "g" "hatch" "hatchpath" "image"
    "line" "linearGradient" "marker" "mask" "metadata" "mpath" "path" "pattern"
    "polygon" "polyline" "radialGradient" "rect" "script" "set" "stop" "style" "svg"
    "switch" "symbol" "text" "textPath" "title" "tspan" "use" "view"})

(defn convert-attr-name [attr]
  (let [attr (name attr)]
    (if (or
          (kebab-case-tags attr)
          (string:starts-with? attr "data-")
          (string:starts-with? attr "aria-")
          (string:starts-with? attr "hx-"))
      attr
      (string:kebap->dromedary attr))))

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
        (let [svg? (boolean (svg-tags (name tag)))
              el (if svg?
                   (dom:create-el js:document  "http://www.w3.org/2000/svg" tag)
                   (dom:create-el js:document tag))
              props #js {}]
          (when (dict? (first children))
            (doseq [[k v] (first children)]
              (let [k (convert-attr-name k)]
                (if (fn? v)
                  (js:Object.defineProperty props (name k)
                    #js {:get v :enumerable true})
                  (assoc! props k v))))
            (web:spread el props svg? true))
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

(test
  (fn [] (h [:svg {:view-box "0 0 20 20"} [:g]]))
  "<svg viewBox=\"0 0 20 20\"><g></g></svg>")

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
